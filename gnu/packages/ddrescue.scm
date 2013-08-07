;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013 Nikita Karetnikov <nikita@karetnikov.org>
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

(define-module (gnu packages ddrescue)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public ddrescue
  (package
    (name "ddrescue")
    (version "1.16")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/ddrescue/ddrescue-"
                          version ".tar.gz"))
      (sha256
       (base32
        "1rixya7p8c4jrn4p0flf6h5dqwybrilf3hrj4r7x41h3zgjz5cvn"))))
    (build-system gnu-build-system)
    (home-page
     "http://www.gnu.org/software/ddrescue/ddrescue.html")
    (synopsis "Data recovery utility")
    (description
     "GNU Ddrescue is a data recovery tool.  It copies data from one
file or block device (e.g., hard disk, CD-ROM) to another, trying hard to
rescue data in case of read errors.

The basic operation of Ddrescue is fully automatic.  That is, you don't
have to wait for an error, stop the program, read the log, run it in
reverse mode, etc.

If you use the logfile feature of Ddrescue, the data is rescued very
efficiently (only the needed blocks are read).  Also, you can interrupt
the rescue at any time and resume it later at the same point.

Automatic merging of backups: If you have two or more damaged copies of
a file and run Ddrescue on all of them, one at a time, with the same
output file, you will probably obtain a complete and error-free file.")
    (license gpl3+)))
