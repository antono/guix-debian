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

(define-module (gnu packages cdrom)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:select (lgpl2.1+ gpl3+))
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages acl)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages help2man)
  #:use-module (gnu packages pkg-config))

(define-public libcddb
  (package
    (name "libcddb")
    (version "1.3.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/libcddb/libcddb-"
                                 version ".tar.bz2"))
             (sha256
              (base32
               "1y8bfy12dwm41m1jahayn3v47dm34fmz7m9cjxyh7xcw6fp3lzaf"))))
    (build-system gnu-build-system)
    (arguments '(#:tests? #f))      ; tests rely on access to external servers
    (home-page "http://libcddb.sourceforge.net/")
    (synopsis "C library to access data on a CDDB server")
    (description
     "Libcddb is a C library to access data on a CDDB server (freedb.org). It
allows you to:

 1. search the database for possible CD matches;

 2. retrieve detailed information about a specific CD;

 3. submit new CD entries to the database.

Libcddb supports both the custom CDDB protocol and tunnelling the query and
read operations over plain HTTP. It is also possible to use an HTTP proxy
server. If you want to speed things up, you can make use of the built-in
caching facility provided by the library.")
    (license lgpl2.1+)))

(define-public libcdio
  (package
    (name "libcdio")
    (version "0.90")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/libcdio/libcdio-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0kpp6gr5sjr30pb9klncc37fhkw0wi6r41d2fmvmw17cbj176zmg"))))
    (build-system gnu-build-system)
    (inputs
     `(("help2man" ,help2man)
       ("ncurses" ,ncurses)
       ("pkg-config" ,pkg-config)
       ("libcddb" ,libcddb)))
    (home-page "http://www.gnu.org/software/libcdio/")
    (synopsis "CD Input and Control library")
    (description
     "GNU libcdio is a library for OS-idependent CD-ROM and CD image access.
It includes a library for working with ISO-9660 filesystems (libiso9660), as
well as utility programs such as an audio CD player and an extractor.")
    (license gpl3+)))

(define-public xorriso
  (package
    (name "xorriso")
    (version "1.3.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/xorriso/xorriso-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1gvyf1ppq764hsk8iyffip7h1dnz2b9k2cchf7himnns03aadavn"))))
    (build-system gnu-build-system)
    (inputs
     `(("acl" ,acl)
       ("readline" ,readline)
       ("bzip2" ,bzip2)
       ("zlib" ,zlib)
       ("libcdio" ,libcdio)))
    (home-page "http://www.gnu.org/software/xorriso/")
    (synopsis "Create, manipulate, burn ISO-9660 filesystems")
    (description
     "GNU xorriso copies file objects from POSIX compliant filesystems into
Rock Ridge enhanced ISO 9660 filesystems and allows session-wise manipulation
of such filesystems.  It can load the management information of existing ISO
images and it writes the session results to optical media or to filesystem
objects.  Vice versa xorriso is able to copy file objects out of ISO 9660
filesystems.")
    (license gpl3+)))
