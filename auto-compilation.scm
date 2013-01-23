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

;;; Only works on MIT Scheme
(define (compiled-code-type)
  ;; Trying to support the C backend
  (if (lexical-unbound?
       (nearest-repl/environment)
       'compiler:compiled-code-pathname-type)
      "com"
      (compiler:compiled-code-pathname-type)))

(define (cf-conditionally filename #!optional environment)
  (define (default-environment)
    (if (current-eval-unit #f)
        (current-load-environment)
        (nearest-repl/environment)))
  (if (default-object? environment)
      (set! environment (default-environment)))
  (fluid-let ((sf/default-syntax-table environment))
    (sf-conditionally filename))
  (if (cf-seems-necessary? filename)
      (compile-bin-file filename)))

(define (compiler-available?)
  (not (lexical-unbound? (nearest-repl/environment) 'cf)))

(define (compilation-seems-necessary? filename)
  (or (sf-seems-necessary? filename)
      (cf-seems-necessary? filename)))

(define (sf-seems-necessary? filename)
  (not (file-processed? filename "scm" "bin")))

(define (cf-seems-necessary? filename)
  (not (file-processed? filename "bin" (compiled-code-type))))

(define (load-compiled filename #!optional environment)
  (if (compiler-available?)
      (begin (cf-conditionally filename environment)
	     (load filename environment))
      (if (compilation-seems-necessary? filename)
	  (begin (warn "The compiler does not seem to be loaded")
		 (warn "Are you running Scheme with --compiler?")
		 (warn "Skipping compilation; loading source interpreted")
		 (load (pathname-default-type filename "scm") environment))
	  (load filename environment))))

(define (load-relative-compiled filename #!optional environment)
  (self-relatively (lambda () (load-compiled filename environment))))

