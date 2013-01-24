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

(declare (usual-integrations))
(declare (integrate-external "../pattern-case"))

(define (nested-patterns)
 (case* (cons (cons 1 2) 3)
   ((pair (pair a d) dd) (+ a d dd))
   ((pair a d) (+ a d))))

(define (ignores-and-as-patterns thing)
  (case* thing
    ((pair _ (pair _ d :as subthing)) (+ d (car subthing)))
    (_ thing)))

(define (arrow-clause thing)
  (case* thing
    ((null) 'null)
    (pair => (lambda (a d) (* a d)))
    (_ 'other)))

(define (evaluate-dispatchee-just-once count)
  (case* (begin (set! count (+ count 1))
                count)
    ((pair _ _) 'pair)
    ((null) 'null)
    ((boolean _ :as bool) bool)
    ((number _ :as num) num)))

(define (my-map f lst)
  (case* lst
    ((pair a d) (cons (f a) (my-map f d)))
    ((null) '())
    (_ (error "Improper list"))))
