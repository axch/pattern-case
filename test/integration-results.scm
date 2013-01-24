;;; This file is part of Pattern Case, a Schemely pattern matching
;;; case facility in MIT Scheme.
;;; Copyright 2013 Alexey Radul.
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

(begin
  (define (nested-patterns)
    (let ((expr-17 (cons (cons 1 2) 3)))
      (cond ((pair? expr-17)
             (let ((part-19 (car expr-17)) (dd (cdr expr-17)))
               (cond ((pair? part-19)
                      (let ((a (car part-19)) (d (cdr part-19)))
                        (&+ a (&+ d dd))))
                     ((pair? expr-17)
                      (let ((a (car expr-17)) (d (cdr expr-17)))
                        (&+ a d))))))
            ((pair? expr-17)
             (let ((a (car expr-17)) (d (cdr expr-17)))
               (&+ a d))))))

  (define (ignores-and-as-patterns thing)
    (let ((expr-21 thing))
      (if (pair? expr-21)
          (begin
            ;; TODO How can I get sf to flush this unused accessor?
            ;; Should I?  It came from ignoring one of the pieces of
            ;; matching a pair.
            (car expr-21)
            (let ((subthing (cdr expr-21)))
              (if (pair? subthing)
                  (begin (car subthing) ; Ditto
                         (let ((d (cdr subthing))) (&+ d (car subthing))))
                  thing)))
          thing)))

  (define (arrow-clause thing)
    (let ((expr-26 thing))
      (cond ((null? expr-26) 'null)
            ((pair? expr-26)
             (let ((a (car expr-26)) (d (cdr expr-26)))
               (&* a d)))
            (else 'other))))

  (define (evaluate-dispatchee-just-once count)
    (let ((expr-30 (begin (set! count (1+ count)) count)))
      (cond ((pair? expr-30)
             ;; Two more uneliminated accessors
             (cdr expr-30) (car expr-30)
             'pair)
            ((null? expr-30) 'null)
            (else
             (let ((bool expr-30))
               (if (boolean? expr-30)
                   bool
                   (let ((num expr-30))
                     (if (let ((operand expr-30))
                           ;; This is what number? looks like underneath
                           (or (object-type? 26 operand)
                               (object-type? 14 operand)
                               (object-type? 58 operand)
                               (object-type? 6 operand)
                               (object-type? 60 operand)))
                         num)))))))))

