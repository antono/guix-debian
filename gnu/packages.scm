;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2014 Eric Bavier <bavier@member.fsf.org>
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

(define-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix ui)
  #:use-module (guix utils)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 vlist)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-39)
  #:export (search-patch
            search-bootstrap-binary
            %patch-directory
            %bootstrap-binaries-path

            fold-packages

            find-packages-by-name
            find-best-packages-by-name
            find-newest-available-packages

            package-direct-dependents
            package-transitive-dependents
            package-covering-dependents))

;;; Commentary:
;;;
;;; General utilities for the software distribution---i.e., the modules under
;;; (gnu packages ...).
;;;
;;; Code:

(define _ (cut gettext <> "guix"))

;; By default, we store patches and bootstrap binaries alongside Guile
;; modules.  This is so that these extra files can be found without
;; requiring a special setup, such as a specific installation directory
;; and an extra environment variable.  One advantage of this setup is
;; that everything just works in an auto-compilation setting.

(define %patch-path
  (make-parameter
   (map (cut string-append <>  "/gnu/packages/patches")
        %load-path)))

(define %bootstrap-binaries-path
  (make-parameter
   (map (cut string-append <> "/gnu/packages/bootstrap")
        %load-path)))

(define (search-patch file-name)
  "Search the patch FILE-NAME."
  (search-path (%patch-path) file-name))

(define (search-bootstrap-binary file-name system)
  "Search the bootstrap binary FILE-NAME for SYSTEM."
  (search-path (%bootstrap-binaries-path)
               (string-append system "/" file-name)))

(define %distro-module-directory
  ;; Absolute path of the (gnu packages ...) module root.
  (string-append (dirname (search-path %load-path "gnu/packages.scm"))
                 "/packages"))

(define (package-files)
  "Return the list of files that implement distro modules."
  (define prefix-len
    (string-length
     (dirname (dirname (search-path %load-path "gnu/packages.scm")))))

  (file-system-fold (const #t)                    ; enter?
                    (lambda (path stat result)    ; leaf
                      (if (string-suffix? ".scm" path)
                          (cons (substring path prefix-len) result)
                          result))
                    (lambda (path stat result)    ; down
                      result)
                    (lambda (path stat result)    ; up
                      result)
                    (const #f)                    ; skip
                    (lambda (path stat errno result)
                      (warning (_ "cannot access `~a': ~a~%")
                               path (strerror errno))
                      result)
                    '()
                    %distro-module-directory
                    stat))

(define (package-modules)
  "Return the list of modules that provide packages for the distribution."
  (define not-slash
    (char-set-complement (char-set #\/)))

  (filter-map (lambda (path)
                (let ((name (map string->symbol
                                 (string-tokenize (string-drop-right path 4)
                                                  not-slash))))
                  (false-if-exception (resolve-interface name))))
              (package-files)))

(define (fold-packages proc init)
  "Call (PROC PACKAGE RESULT) for each available package, using INIT as
the initial value of RESULT.  It is guaranteed to never traverse the
same package twice."
  (identity   ; discard second return value
   (fold2 (lambda (module result seen)
            (fold2 (lambda (var result seen)
                     (if (and (package? var)
                              (not (vhash-assq var seen)))
                         (values (proc var result)
                                 (vhash-consq var #t seen))
                         (values result seen)))
                   result
                   seen
                   (module-map (lambda (sym var)
                                 (false-if-exception (variable-ref var)))
                               module)))
          init
          vlist-null
          (package-modules))))

(define* (find-packages-by-name name #:optional version)
  "Return the list of packages with the given NAME.  If VERSION is not #f,
then only return packages whose version is equal to VERSION."
  (define right-package?
    (if version
        (lambda (p)
          (and (string=? (package-name p) name)
               (string=? (package-version p) version)))
        (lambda (p)
          (string=? (package-name p) name))))

  (fold-packages (lambda (package result)
                   (if (right-package? package)
                       (cons package result)
                       result))
                 '()))

(define find-newest-available-packages
  (memoize
   (lambda ()
     "Return a vhash keyed by package names, and with
associated values of the form

  (newest-version newest-package ...)

where the preferred package is listed first."

     ;; FIXME: Currently, the preferred package is whichever one
     ;; was found last by 'fold-packages'.  Find a better solution.
     (fold-packages (lambda (p r)
                      (let ((name    (package-name p))
                            (version (package-version p)))
                        (match (vhash-assoc name r)
                          ((_ newest-so-far . pkgs)
                           (case (version-compare version newest-so-far)
                             ((>) (vhash-cons name `(,version ,p) r))
                             ((=) (vhash-cons name `(,version ,p ,@pkgs) r))
                             ((<) r)))
                          (#f (vhash-cons name `(,version ,p) r)))))
                    vlist-null))))

(define (find-best-packages-by-name name version)
  "If version is #f, return the list of packages named NAME with the highest
version numbers; otherwise, return the list of packages named NAME and at
VERSION."
  (if version
      (find-packages-by-name name version)
      (match (vhash-assoc name (find-newest-available-packages))
        ((_ version pkgs ...) pkgs)
        (#f '()))))


(define* (vhash-refq vhash key #:optional (dflt #f))
  "Look up KEY in the vhash VHASH, and return the value (if any) associated
with it.  If KEY is not found, return DFLT (or `#f' if no DFLT argument is
supplied).  Uses `eq?' for equality testing."
  (or (and=> (vhash-assq key vhash) cdr)
      dflt))

(define package-dependencies
  (memoize
   (lambda ()
     "Return a vhash keyed by package, and with associated values that are a
list of packages that depend on that package."
     (fold-packages
      (lambda (package dag)
        (fold
         (lambda (in d)
           ;; Insert a graph edge from each of package's inputs to package.
           (vhash-consq in
                        (cons package (vhash-refq d in '()))
                        (vhash-delq in d)))
         dag
         (match (package-direct-inputs package)
           (((labels packages . _) ...)
            packages) )))
      vlist-null))))

(define (package-direct-dependents packages)
  "Return a list of packages from the distribution that directly depend on the
packages in PACKAGES."
  (delete-duplicates
   (concatenate
    (map (lambda (p)
           (vhash-refq (package-dependencies) p '()))
         packages))))

(define (package-transitive-dependents packages)
  "Return the transitive dependent packages of the distribution packages in
PACKAGES---i.e. the dependents of those packages, plus their dependents,
recursively."
  (let ((dependency-dag (package-dependencies)))
    (fold-tree
     cons '()
     (lambda (node) (vhash-refq dependency-dag node))
     ;; Start with the dependents to avoid including PACKAGES in the result.
     (package-direct-dependents packages))))

(define (package-covering-dependents packages)
  "Return a minimal list of packages from the distribution whose dependencies
include all of PACKAGES and all packages that depend on PACKAGES."
  (let ((dependency-dag (package-dependencies)))
    (fold-tree-leaves
     cons '()
     (lambda (node) (vhash-refq dependency-dag node))
     ;; Start with the dependents to avoid including PACKAGES in the result.
     (package-direct-dependents packages))))
