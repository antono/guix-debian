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

(define-module (gnu packages flex)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages indent)
  #:use-module (srfi srfi-1)
  #:export (flex))

(define flex
  (package
    (name "flex")
    (version "2.5.37")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/flex/flex-"
                                 version ".tar.bz2"))
             (sha256
              (base32
               "0ah5mi4j62b85a9rllv1004mzjb5cd0mn4glvz13p88rpx77pahp"))
             (patches (list (search-patch "flex-bison-tests.patch")))))
    (build-system gnu-build-system)
    (inputs
     (let ((bison-for-tests
            ;; Work around an incompatibility with Bison 3.0:
            ;; <http://lists.gnu.org/archive/html/bug-bison/2013-09/msg00014.html>.
            (package (inherit bison)
              (version "2.7.1")
              (source (origin
                       (method url-fetch)
                       (uri (string-append "mirror://gnu/bison/bison-"
                                           version ".tar.xz"))
                       (sha256
                        (base32
                         "1yx7isx67sdmyijvihgyra1f59fwdz7sqriginvavfj5yb5ss2dl"))))

              ;; Unlike Bison 3.0, this version did not need Flex for its
              ;; tests, so it allows us to break the cycle.
              (inputs (alist-delete "flex" (package-inputs bison))))))
       `(("bison" ,bison-for-tests)
         ("indent" ,indent))))
    (propagated-inputs `(("m4" ,m4)))
    (home-page "http://flex.sourceforge.net/")
    (synopsis "A fast lexical analyser generator")
    (description
     "Flex is a tool for generating scanners. A scanner, sometimes
called a tokenizer, is a program which recognizes lexical patterns in
text. The flex program reads user-specified input files, or its standard
input if no file names are given, for a description of a scanner to
generate. The description is in the form of pairs of regular expressions
and C code, called rules. Flex generates a C source file named,
\"lex.yy.c\", which defines the function yylex(). The file \"lex.yy.c\"
can be compiled and linked to produce an executable. When the executable
is run, it analyzes its input for occurrences of text matching the
regular expressions for each rule. Whenever it finds a match, it
executes the corresponding C code.")
    (license (bsd-style "file://COPYING"
                        "See COPYING in the distribution."))))

