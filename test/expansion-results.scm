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

(define (my-map f lst)
  (let ((expr-17 lst))
    (let ((lose-18
           (lambda ()
             (let ((lose-19 (lambda () (error "Improper list"))))
               (null expr-17 (lambda () '()) lose-19)))))
      (pair expr-17 (lambda (a d) (cons (f a) (my-map f d))) lose-18))))
