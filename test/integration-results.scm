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
  (define (example-with-pairs)
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

  (define (example-with-ignores-and-as-patterns)
    (let ((expr-21 thing))
      (if (pair? expr-21)
          (begin
            ;; TODO How can I get LIAR to flush this unused accessor?
            ;; Should I?  It came from ignoring one of the pieces of
            ;; matching a pair.
            (car expr-21)
            (let ((subthing (cdr expr-21)))
              (if (pair? subthing)
                  (begin (car subthing) ; Ditto
                         (let ((d (cdr subthing))) (&+ d (car subthing))))
                  thing)))
          thing))))

