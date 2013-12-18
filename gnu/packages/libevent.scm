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

(define-module (gnu packages libevent)
  #:use-module (gnu packages)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages which)
  #:use-module (gnu packages python))

(define-public libevent
  (package
    (name "libevent")
    (version "2.0.21")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "https://github.com/downloads/libevent/libevent/libevent-"
                   version
                   "-stable.tar.gz"))
             (sha256
              (base32
               "1xblymln9vihdmf1aqkp8chwvnhpdch3786bh30bj75slnl31992"))
             (patches (list (search-patch "libevent-dns-tests.patch")))))
    (build-system gnu-build-system)
    (inputs
     `(;; Dependencies used for the tests and for `event_rpcgen.py'.
       ("which" ,which)
       ("python" ,python-wrapper)))
    (home-page "http://libevent.org/")
    (synopsis
     "libevent, an event notification library")
    (description
     "The libevent API provides a mechanism to execute a callback
function when a specific event occurs on a file descriptor or after a
timeout has been reached.  Furthermore, libevent also support callbacks
due to signals or regular timeouts.

libevent is meant to replace the event loop found in event driven
network servers.  An application just needs to call event_dispatch() and
then add or remove events dynamically without having to change the event
loop.")
    (license bsd-3)))
