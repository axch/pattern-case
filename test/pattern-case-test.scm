;;; This file is part of Pattern Case, a Schemely pattern matching
;;; case facility in MIT Scheme.
;;; Copyright 2011 Alexey Radul.
;;;
;;; Pattern Case is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU Affero General Public License
;;; as published by the Free Software Foundation; either version 3 of
;;; the License, or (at your option) any later version.
;;; 
;;; Pattern Case is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;; 
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Pattern Case; if not, see
;;; <http://www.gnu.org/licenses/>.

(declare (usual-integrations))

(declare (integrate-external "../pattern-case"))

(define (test-pattern thing)
  (case* thing
    ((pair (pair a d) dd) (+ a d dd))
    ((pair a d) (+ a d))))

;; This version is too fast because it avoids doing the topmost pair?
;; test twice.
#;
 (define (my-test-pattern thing)
   (if (pair? thing)
       (let ((a (car thing)) (d (cdr thing)))
         (if (pair? a)
             (+ (car a) (cdr a) d)
             (+ a d)))))

;; This replacement is arguably too slow because it repeats accesses.
(define (my-test-pattern thing)
  (cond ((and (pair? thing) (pair? (car thing)))
         (+ (caar thing) (cdar thing) (cdr thing)))
        ((pair? thing)
         (+ (car thing) (cdr thing)))))

(define (test-pattern2 thing)
  (case* thing
    ((pair _ (pair _ d :as subthing)) (+ d (car subthing)))
    (_ thing)))

(define (my-test-pattern2 thing)
  (if (pair? thing)
      (let ((d (cdr thing)))
        (if (pair? d)
            (+ (car d) (cdr d))
            thing))
      thing))

(define (test-pattern3 thing)
  (case* thing
    ((null) 'null)
    (pair => (lambda (a d) (* a d)))
    (_ 'other)))

(define (my-test-pattern3 thing)
  (cond ((null? thing) 'null)
        ((pair? thing) (* (car thing) (cdr thing)))
        (else 'other)))

(define (timings-of thunk)
  (let ((run-time) (gc-time) (real-time))
    (with-timings
     thunk
     (lambda (got-run got-gc got-real)
       (set! run-time got-run)
       (set! gc-time got-gc)
       (set! real-time got-real)))
    (values run-time gc-time real-time)))

(define (time-repeated f input repeat)
  (timings-of
   (lambda ()
     (let loop ((count repeat))
       (if (not (= 0 count))
           (begin
             (f input)
             (loop (- count 1))))))))

(define (same-speed f1 f2 input repeat)
  (define (relative-difference x y)
    (cond ((> x y 100)
           (/ (- x y) x))
          ((> y 100)
           (/ (- y x) y))
          (else (/ (abs (- x y)) 100))))
  (check (equal? (f1 input) (f2 input)))
  (receive (run-time1 gc-time1 real-time1) (time-repeated f1 input repeat)
    (receive (run-time2 gc-time2 real-time2) (time-repeated f2 input repeat)
      ;(pp (list run-time1 gc-time1 real-time1 run-time2 gc-time2 real-time2))
      (check (< (relative-difference run-time1 run-time2) .2))
      (check (< (relative-difference gc-time1 gc-time2) .2))
      )))

(in-test-group
 pattern-case

 (define-each-check
   (equal? 6 (test-pattern (cons (cons 1 2) 3)))
   (equal? 7 (test-pattern (cons 4 3)))
   (equal? unspecific (test-pattern 'foo))

   (equal? 9 (test-pattern2 (cons 4 (cons 3 6))))
   (equal? 'foo (test-pattern2 'foo))

   (equal? 'null (test-pattern3 '()))
   (equal? 'other (test-pattern3 'null))
   (equal? 12 (test-pattern3 (cons 4 3))))

 (define-test (evaluate-only-once)
   (let ((count 0))
     (check (equal? 1
                    (case* (begin (set! count (+ count 1))
                                  count)
                      ((pair _ _) 'pair)
                      ((null) 'null)
                      ((boolean _ :as bool) bool)
                      ((number _ :as num) num))))))

 (let ((repeat-count 10000000))
  (define-each-test
    (same-speed test-pattern my-test-pattern (cons (cons 1 2) 3) repeat-count)
    (same-speed test-pattern my-test-pattern (cons 4 3) repeat-count)
    (same-speed test-pattern my-test-pattern 'foo repeat-count)

    (same-speed test-pattern2 my-test-pattern2 (cons (cons 1 2) 3) repeat-count)
    (same-speed test-pattern2 my-test-pattern2 (cons 4 3) repeat-count)
    (same-speed test-pattern2 my-test-pattern2 (cons 4 (cons 3 6)) repeat-count)
    (same-speed test-pattern2 my-test-pattern2 'foo repeat-count)

    (same-speed test-pattern3 my-test-pattern3 (cons 4 3) repeat-count)
    (same-speed test-pattern3 my-test-pattern3 '() repeat-count)
    (same-speed test-pattern3 my-test-pattern3 'foo repeat-count)
    )))
