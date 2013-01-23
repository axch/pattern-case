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


(case*
 thing
 (null? thing)
 (boolean? thing)
 (real? thing)
 (primitive? thing)
 ((pair a d) (list 'cons (... a) (... d)))
 (_ '(vector)))


(define (if-form expr win lose)
  (if (if-form? expr)
      (win (cadr expr) (caddr expr) (cadddr expr))
      (lose)))

(define (eliminate-in-if expr live-out)
  (case* expr
   ((if-form predicate consequent alternate)
    (receive (new-predicate pred-needs) (loop predicate #t)
      (receive (new-consequent cons-needs) (loop consequent live-out)
        (receive (new-alternate alt-needs) (loop alternate live-out)
          (values `(if ,new-predicate
                       ,new-consequent
                       ,new-alternate)
                  (var-set-union
                   pred-needs (var-set-union cons-needs alt-needs)))))))))

(case* expr
 ((fol-var) (values expr (single-used-var expr)))
 ((fol-const) (values expr (no-used-vars)))
 (if-form => eliminate-in-if)
 (let-form => eliminate-in-let)
 ...
 (pair => eliminate-in-application))

(fol-var expr
 (lambda () (values expr (single-used-var expr)))
 (lambda ()
   (case* expr
    ((fol-const) (values expr (no-used-vars)))
    (if-form => eliminate-in-if)
    (let-form => eliminate-in-let)
    ...
    (pair => eliminate-in-application))))

(define (eliminate-in-if predicate consequent alternate)
  (receive (new-predicate pred-needs) (loop predicate #t)
    (receive (new-consequent cons-needs) (loop consequent live-out)
      (receive (new-alternate alt-needs) (loop alternate live-out)
        (values `(if ,new-predicate
                     ,new-consequent
                     ,new-alternate)
                (var-set-union
                 pred-needs (var-set-union cons-needs alt-needs)))))))

(cond ((memq foo bar) => (lambda (lst) ...)))


(case* (cons (cons 1 2) 3)
 ((pair (pair a d) dd) (+ a d dd))
 ((pair a d) (+ a d)))

(let ((lose-43 (lambda () ...)))
  (pair foo (lambda (frobnozzle-42 dd)
              (case* frobnozzle-42
                     ((pair a d) stuff)
                     lose-43))
        lose-43))

(let ((lose-43 (lambda () ...)))
  (pair foo (lambda (frobnozzle-42 dd)
              (pair frobnozzle-42
                    (lambda (a d) stuff)
                    lose-43))
        lose-43))

(case* ...
 ((pair a d :as foo) ...)
 ((pair (pair f d :as foo) dr)))
