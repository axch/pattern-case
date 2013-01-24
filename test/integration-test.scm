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

(define compilation-env (the-environment))
(define path (self-relatively current-load-pathname))

(define (pp->list thing)
  (with-input-from-string
      (with-output-to-string
	(lambda ()
	  (pp thing)))
    read))

(in-test-group
 integration

 (define-test (expansion-examples-test)
   ;; Reset the uninterned symbol counter to something predictable
   ;; (otherwise the test results would vary depending on whether,
   ;; e.g., the source was autocompiled, because the compiler
   ;; generates uninterned symbols internally).
   (generate-uninterned-symbol 16)
   (fluid-let ((sf/default-syntax-table compilation-env))
     (sf (merge-pathnames "expansion-examples" path)))
   (let ((result (pp->list (fasload (merge-pathnames "expansion-examples" path)))))
     (check (equal? result (pp->list (with-input-from-file (merge-pathnames "expansion-results.scm" path) read))))))

 (define-test (integration-examples-test)
   ;; Reset the uninterned symbol counter to something predictable
   ;; (otherwise the test results would vary depending on whether,
   ;; e.g., the source was autocompiled, because the compiler
   ;; generates uninterned symbols internally).
   (generate-uninterned-symbol 16)
   (fluid-let ((sf/default-syntax-table compilation-env))
     (sf (merge-pathnames "integration-examples" path)))
   (let ((result (pp->list (fasload (merge-pathnames "integration-examples" path)))))
     (check (equal? result (with-input-from-file (merge-pathnames "integration-results.scm" path) read))))))
