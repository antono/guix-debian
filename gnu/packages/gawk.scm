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

(define-module (gnu packages gawk)
  #:use-module (guix licenses)
  #:use-module (gnu packages libsigsegv)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public gawk
  (package
   (name "gawk")
   (version "4.0.2")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/gawk/gawk-" version
                                ".tar.xz"))
            (sha256
             (base32 "04vd0axif762mf781pj3days6ilv2333b9zi9c50y5mma66g5q91"))))
   (build-system gnu-build-system)
   (arguments
    `(#:parallel-tests? #f                ; test suite fails in parallel

      ;; Work around test failure on Cygwin.
      #:tests? ,(not (string=? (%current-system) "i686-cygwin"))

      #:phases (alist-cons-before
                'configure 'set-shell-file-name
                (lambda* (#:key inputs #:allow-other-keys)
                  ;; Refer to the right shell.
                  (let ((bash (assoc-ref inputs "bash")))
                    (substitute* "io.c"
                      (("/bin/sh")
                       (string-append bash "/bin/bash")))))
                %standard-phases)))
   (inputs `(("libsigsegv" ,libsigsegv)))
   (home-page "http://www.gnu.org/software/gawk/")
   (synopsis "A text scanning and processing language")
   (description
    "Many computer users need to manipulate text files: extract and then
operate on data from parts of certain lines while discarding the rest, make
changes in various text files wherever certain patterns appear, and so on.
To write a program to do these things in a language such as C or Pascal is a
time-consuming inconvenience that may take many lines of code.  The job is
easy with awk, especially the GNU implementation: Gawk.

The awk utility interprets a special-purpose programming language that makes
it possible to handle many data-reformatting jobs with just a few lines of
code.")
   (license gpl3+)))
