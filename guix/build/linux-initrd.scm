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

(define-module (guix build linux-initrd)
  #:use-module (rnrs io ports)
  #:use-module (system foreign)
  #:export (mount-essential-file-systems
            linux-command-line
            make-essential-device-nodes
            configure-qemu-networking
            mount-qemu-smb-share
            bind-mount
            load-linux-module*
            device-number))

;;; Commentary:
;;;
;;; Utility procedures useful in a Linux initial RAM disk (initrd).  Note that
;;; many of these use procedures not yet available in vanilla Guile (`mount',
;;; `load-linux-module', etc.); these are provided by a Guile patch used in
;;; the GNU distribution.
;;;
;;; Code:

(define* (mount-essential-file-systems #:key (root "/"))
  "Mount /proc and /sys under ROOT."
  (define (scope dir)
    (string-append root
                   (if (string-suffix? "/" root)
                       ""
                       "/")
                   dir))

  (unless (file-exists? (scope "proc"))
    (mkdir (scope "proc")))
  (mount "none" (scope "proc") "proc")

  (unless (file-exists? (scope "sys"))
    (mkdir (scope "sys")))
  (mount "none" (scope "sys") "sysfs"))

(define (linux-command-line)
  "Return the Linux kernel command line as a list of strings."
  (string-tokenize
   (call-with-input-file "/proc/cmdline"
     get-string-all)))

(define* (make-essential-device-nodes #:key (root "/"))
  "Make essential device nodes under ROOT/dev."
  ;; The hand-made udev!

  (define (scope dir)
    (string-append root
                   (if (string-suffix? "/" root)
                       ""
                       "/")
                   dir))

  (unless (file-exists? (scope "dev"))
    (mkdir (scope "dev")))

  ;; Make the device nodes for QEMU's hard disk and partitions.
  (mknod (scope "dev/vda") 'block-special #o644 (device-number 8 0))
  (mknod (scope "dev/vda1") 'block-special #o644 (device-number 8 1))
  (mknod (scope "dev/vda2") 'block-special #o644 (device-number 8 2))

  ;; TTYs.
  (mknod (scope "dev/tty") 'char-special #o600
         (device-number 5 0))
  (let loop ((n 0))
    (and (< n 50)
         (let ((name (format #f "dev/tty~a" n)))
           (mknod (scope name) 'char-special #o600
                  (device-number 4 n))
           (loop (+ 1 n)))))

  ;; Rendez-vous point for syslogd.
  (mknod (scope "dev/log") 'socket #o666 0)
  (mknod (scope "dev/kmsg") 'char-special #o600 (device-number 1 11))

  ;; Other useful nodes.
  (mknod (scope "dev/null") 'char-special #o666 (device-number 1 3))
  (mknod (scope "dev/zero") 'char-special #o666 (device-number 1 5)))

(define %host-qemu-ipv4-address
  (inet-pton AF_INET "10.0.2.10"))

(define* (configure-qemu-networking #:optional (interface "eth0"))
  "Setup the INTERFACE network interface and /etc/resolv.conf according to
QEMU's default networking settings (see net/slirp.c in QEMU for default
networking values.)  Return #t if INTERFACE is up, #f otherwise."
  (display "configuring QEMU networking...\n")
  (let* ((sock    (socket AF_INET SOCK_STREAM 0))
         (address (make-socket-address AF_INET %host-qemu-ipv4-address 0))
         (flags   (network-interface-flags sock interface)))
    (set-network-interface-address sock interface address)
    (set-network-interface-flags sock interface (logior flags IFF_UP))

    (unless (file-exists? "/etc")
      (mkdir "/etc"))
    (call-with-output-file "/etc/resolv.conf"
      (lambda (p)
        (display "nameserver 10.0.2.3\n" p)))

    (logand (network-interface-flags sock interface) IFF_UP)))

(define (mount-qemu-smb-share share mount-point)
  "Mount QEMU's CIFS/SMB SHARE at MOUNT-POINT.

Vanilla QEMU's `-smb' option just exports a /qemu share, whereas our
`qemu-with-multiple-smb-shares' package exports the /xchg and /store shares
 (the latter allows the store to be shared between the host and guest.)"

  (format #t "mounting QEMU's SMB share `~a'...\n" share)
  (let ((server "10.0.2.4"))
    (mount (string-append "//" server share) mount-point "cifs" 0
           (string->pointer "guest,sec=none"))))

(define (bind-mount source target)
  "Bind-mount SOURCE at TARGET."
  (define MS_BIND 4096)                           ; from libc's <sys/mount.h>

  (mount source target "" MS_BIND))

(define (load-linux-module* file)
  "Load Linux module from FILE, the name of a `.ko' file."
  (define (slurp module)
    (call-with-input-file file get-bytevector-all))

  (load-linux-module (slurp file)))

(define (device-number major minor)
  "Return the device number for the device with MAJOR and MINOR, for use as
the last argument of `mknod'."
  (+ (* major 256) minor))

;;; linux-initrd.scm ends here
