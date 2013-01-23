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

;;; TODO Compare to comparable facilities in other languages
;;; - destructuring-bind, bind in Common Lisp
;;; - Clojure pattern matching
;;; - ruby case
;;; TODO Implement pattern guards?  View patterns?
;;; TODO Implement known-length list patterns (issue 1)
;;; TODO Document define-algebraic-matcher

(define-syntax case*
  (er-macro-transformer
   (lambda (form rename compare)
     (let ((expr (cadr form))
           (expr-name (generate-uninterned-symbol 'expr-)))
       (define (arrow-form? clause)
         (and (= 3 (length clause))
              (compare (rename '=>) (cadr clause))))
       (define (ignore? thing)
         (compare thing (rename '_)))
       (define-integrable (as-pattern pattern win lose)
         (let loop ((pattern pattern) (skipped '()))
           (cond ((not (pair? pattern)) (lose))
                 ((null? (cdr pattern)) (lose))
                 ((and (null? (cddr pattern))
                       (symbol? (car pattern))
                       (compare (car pattern) (rename ':as)))
                  (win (reverse skipped) (cadr pattern)))
                 (else (loop (cdr pattern) (cons (car pattern) skipped))))))
       (define (parse-clause clause lose-name)
         (define (arrow-clause matcher procedure)
           `(,matcher ,expr-name ,procedure ,lose-name))
         (define (standard-clause expr-name pattern body)
           (define (standard-pattern expr-name pattern body)
             (receive (variables body)
               (let loop ((subpatterns (cdr pattern)))
                 (cond ((null? subpatterns) (values '() body))
                       ((pair? (car subpatterns))
                        (receive (true-subpattern variable)
                          (as-pattern (car subpatterns)
                           values
                           (lambda ()
                             (values (car subpatterns)
                                     (generate-uninterned-symbol 'part-))))
                          (receive (variables body) (loop (cdr subpatterns))
                            (values (cons variable variables)
                                    (list (standard-pattern variable true-subpattern body))))))
                       ;; Assume identifier
                       ((ignore? (car subpatterns))
                        (let ((variable (generate-uninterned-symbol 'dead-)))
                          (receive (variables body) (loop (cdr subpatterns))
                            (values (cons variable variables)
                                    (cons `(declare (ignore ,variable))
                                          body)))))
                       (else ;; Assume identifier
                        (receive (variables body) (loop (cdr subpatterns))
                          (values (cons (car subpatterns) variables)
                                  body)))))
               `(,(car pattern) ,expr-name (,(rename 'lambda) ,variables ,@body) ,lose-name)))
           (cond ((pair? pattern)
                  (as-pattern pattern
                   (lambda (true-pattern variable)
                     `(let ((,variable ,expr-name))
                        ,(standard-pattern expr-name true-pattern body)))
                   (lambda ()
                     (standard-pattern expr-name pattern body))))
                 ((ignore? pattern)
                  `(let ()
                     (declare (ignore ,lose-name))
                     ,@body))
                 (else
                  `(let ((,pattern ,expr-name))
                     (declare (ignore ,lose-name))
                     ,@body))))
         (if (arrow-form? clause)
             (arrow-clause (car clause) (caddr clause))
             (standard-clause expr-name (car clause) (cdr clause))))
       `(,(rename 'let) ((,expr-name ,expr))
          ,(let loop ((clauses (cddr form)))
             (if (null? clauses)
                 (rename 'unspecific)
                 (let ((lose-name (generate-uninterned-symbol 'lose-)))
                   `(,(rename 'let) ((,lose-name (,(rename 'lambda) () ,(loop (cdr clauses)))))
                     ;; This integration may not be appropriate if the
                     ;; body refers to the lose-name more than once...
                     (declare (integrate-operator ,lose-name))
                     ,(parse-clause (car clauses) lose-name))))))))))

(define-syntax define-algebraic-matcher
  (syntax-rules ()
    ((_ matcher predicate accessor ...)
     (define-integrable (matcher thing win lose)
       (if (predicate thing)
           (win (accessor thing) ...)
           (lose))))))

(define-integrable (id-project x) x)
(define-algebraic-matcher pair pair? car cdr)
(define-algebraic-matcher null null?)
(define-algebraic-matcher boolean boolean? id-project)
(define-algebraic-matcher number number? id-project)

(define-syntax define-case*
  ;; This is not a syntax-rules macro because case* will make some of
  ;; its subforms into names that are bound in other subforms, and
  ;; I fear that syntax-rules might interfere with this.
  (er-macro-transformer
   (lambda (form rename compare)
     (let ((name (cadr form))
           (clauses (cddr form))
           (defined-name (generate-uninterned-symbol)))
       `(,(rename 'define) (,name ,defined-name)
         (,(rename 'case*) ,defined-name
           ,@clauses))))))

;; TODO good error messages if syntax is wrong; define all needed matchers
