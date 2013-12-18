;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Ludovic Courtès <ludo@gnu.org>
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

(define-module (gnu packages rush)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix licenses)
  #:use-module (gnu packages))

(define-public rush
  (package
    (name "rush")
    (version "1.7")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://gnu/rush/rush-"
                   version
                   ".tar.gz"))
             (sha256
              (base32
               "0fh0gbbp0iiq3wbkf503xb40r8ljk42vyj9bnlflbz82d6ipy1rm"))
             (patches (list (search-patch "cpio-gets-undeclared.patch")))))
    (build-system gnu-build-system)
    (home-page "http://www.gnu.org/software/rush/")
    (synopsis "Restricted user (login) shell")
    (description
     "GNU Rush is a restricted user shell, for systems on which users are to
be provided with only limited functionality or resources. Administrators set
user rights via a configuration file which can be used to limit, for example,
the commands that can be executed, CPU time, or virtual memory usage.")
    (license gpl3+)))
