;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guix scripts import)
  #:use-module (guix ui)
  #:use-module (guix snix)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-37)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:export (guix-import))


;;;
;;; Helper.
;;;

(define (newline-rewriting-port output)
  "Return an output port that rewrites strings containing the \\n escape
to an actual newline.  This works around the behavior of `pretty-print'
and `write', which output these as \\n instead of actual newlines,
whereas we want the `description' field to contain actual newlines
rather than \\n."
  (define (write-string str)
    (let loop ((chars (string->list str)))
      (match chars
        (()
         #t)
        ((#\\ #\n rest ...)
         (newline output)
         (loop rest))
        ((chr rest ...)
         (write-char chr output)
         (loop rest)))))

  (make-soft-port (vector (cut write-char <>)
                          write-string
                          (lambda _ #t)           ; flush
                          #f
                          (lambda _ #t)           ; close
                          #f)
                  "w"))


;;;
;;; Command-line options.
;;;

(define %default-options
  '())

(define (show-help)
  (display (_ "Usage: guix import NIXPKGS ATTRIBUTE
Import and convert the Nix expression ATTRIBUTE of NIXPKGS.\n"))
  (display (_ "
  -h, --help             display this help and exit"))
  (display (_ "
  -V, --version          display version information and exit"))
  (newline)
  (show-bug-report-information))

(define %options
  ;; Specification of the command-line options.
  (list (option '(#\h "help") #f #f
                (lambda args
                  (show-help)
                  (exit 0)))
        (option '(#\V "version") #f #f
                (lambda args
                  (show-version-and-exit "guix import")))))


;;;
;;; Entry point.
;;;

(define (guix-import . args)
  (define (parse-options)
    ;; Return the alist of option values.
    (args-fold* args %options
                (lambda (opt name arg result)
                  (leave (_ "~A: unrecognized option~%") name))
                (lambda (arg result)
                  (alist-cons 'argument arg result))
                %default-options))

  (let* ((opts (parse-options))
         (args (filter-map (match-lambda
                            (('argument . value)
                             value)
                            (_ #f))
                           (reverse opts))))
    (match args
      ((nixpkgs attribute)
       (let-values (((expr loc)
                     (nixpkgs->guix-package nixpkgs attribute)))
         (format #t ";; converted from ~a:~a~%~%"
                 (location-file loc) (location-line loc))
         (pretty-print expr (newline-rewriting-port (current-output-port)))))
      (_
       (leave (_ "wrong number of arguments~%"))))))
