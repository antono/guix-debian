;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 Ludovic Courtès <ludo@gnu.org>
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

(define-module (test-syscalls)
  #:use-module (guix build syscalls)
  #:use-module (srfi srfi-64))

;; Test the (guix build syscalls) module, although there's not much that can
;; actually be tested without being root.

(test-begin "syscalls")

(test-equal "mount, ENOENT"
  ENOENT
  (catch 'system-error
    (lambda ()
      (mount "/dev/null" "/does-not-exist" "ext2")
      #f)
    (compose system-error-errno list)))

(test-assert "umount, ENOENT/EPERM"
  (catch 'system-error
    (lambda ()
      (umount "/does-not-exist")
      #f)
    (lambda args
      ;; Both return values have been encountered in the wild.
      (memv (system-error-errno args) (list EPERM ENOENT)))))

(test-end)


(exit (= (test-runner-fail-count (test-runner-current)) 0))
