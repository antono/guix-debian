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


(define-module (test-union)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix derivations)
  #:use-module (guix packages)
  #:use-module (guix build union)
  #:use-module ((guix build utils)
                #:select (with-directory-excursion directory-exists?))
  #:use-module (gnu packages bootstrap)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-64)
  #:use-module (ice-9 match))

;; Exercise the (guix build union) module.

(define %store
  (false-if-exception (open-connection)))

(when %store
  ;; By default, use %BOOTSTRAP-GUILE for the current system.
  (let ((drv (package-derivation %store %bootstrap-guile)))
    (%guile-for-build drv)))


(test-begin "union")

(test-equal "tree-union, empty"
  '()
  (tree-union '()))

(test-equal "tree-union, leaves only"
  '(a b c d)
  (tree-union '(a b c d)))

(test-equal "tree-union, simple"
  '((bin ls touch make awk gawk))
  (tree-union '((bin ls touch)
                (bin make)
                (bin awk gawk))))

(test-equal "tree-union, several levels"
  '((share (doc (make README) (coreutils README)))
    (bin ls touch make))
  (tree-union '((bin ls touch)
                (share (doc (coreutils README)))
                (bin make)
                (share (doc (make README))))))

(test-equal "delete-duplicate-leaves, default"
  '(bin make touch ls)
  (delete-duplicate-leaves '(bin ls make touch ls)))

(test-equal "delete-duplicate-leaves, file names"
  '("doc" ("info"
           "/binutils/ld.info"
           "/gcc/gcc.info"
           "/binutils/standards.info"))
  (let ((leaf=? (lambda (a b)
                  (string=? (basename a) (basename b)))))
    (delete-duplicate-leaves '("doc"
                               ("info"
                                "/binutils/ld.info"
                                "/binutils/standards.info"
                                "/gcc/gcc.info"
                                "/gcc/standards.info"))
                             leaf=?)))

(test-skip (if (and %store
                    (false-if-exception
                     (getaddrinfo "www.gnu.org" "80" AI_NUMERICSERV)))
               0
               1))

(test-assert "union-build"
  (let* ((inputs  (map (match-lambda
                        ((name package)
                         `(,name ,(package-derivation %store package))))

                       ;; Purposefully leave duplicate entries.
                       (append %bootstrap-inputs
                               (take %bootstrap-inputs 3))))
         (builder `(begin
                     (use-modules (guix build union))
                     (union-build (assoc-ref %outputs "out")
                                  (map cdr %build-inputs))))
         (drv
          (build-expression->derivation %store "union-test"
                                        (%current-system)
                                        builder inputs
                                        #:modules '((guix build union)))))
    (and (build-derivations %store (list (pk 'drv drv)))
         (with-directory-excursion (derivation->output-path drv)
           (and (file-exists? "bin/touch")
                (file-exists? "bin/gcc")
                (file-exists? "bin/ld")
                (file-exists? "lib/libc.so")
                (directory-exists? "lib/gcc")
                (file-exists? "include/unistd.h")

                ;; The 'include' sub-directory is only found in
                ;; glibc-bootstrap, so it should be unified in a
                ;; straightforward way, without traversing it.
                (eq? 'symlink (stat:type (lstat "include")))

                ;; Conversely, several inputs have a 'bin' sub-directory, so
                ;; unifying it requires traversing them all, and creating a
                ;; new 'bin' sub-directory in the profile.
                (eq? 'directory (stat:type (lstat "bin"))))))))

(test-end)


(exit (= (test-runner-fail-count (test-runner-current)) 0))
