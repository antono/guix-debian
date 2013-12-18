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

(define-module (test-records)
  #:use-module (srfi srfi-64)
  #:use-module (ice-9 match)
  #:use-module (guix records))

(test-begin "records")

(test-assert "define-record-type*"
  (begin
    (define-record-type* <foo> foo make-foo
      foo?
      (bar foo-bar)
      (baz foo-baz (default (+ 40 2))))
    (and (match (foo (bar 1) (baz 2))
           (($ <foo> 1 2) #t))
         (match (foo (baz 2) (bar 1))
           (($ <foo> 1 2) #t))
         (match (foo (bar 1))
           (($ <foo> 1 42) #t)))))

(test-assert "define-record-type* with let* behavior"
  ;; Make sure field initializers can refer to each other as if they were in
  ;; a 'let*'.
  (begin
    (define-record-type* <bar> bar make-bar
      foo?
      (x bar-x)
      (y bar-y (default (+ 40 2)))
      (z bar-z))
    (and (match (bar (x 1) (y (+ x 1)) (z (* y 2)))
           (($ <bar> 1 2 4) #t))
         (match (bar (x 7) (z (* x 3)))
           (($ <bar> 7 42 21)))
         (match (bar (z 21) (x (/ z 3)))
           (($ <bar> 7 42 21))))))

(test-assert "define-record-type* & inherit"
  (begin
    (define-record-type* <foo> foo make-foo
      foo?
      (bar foo-bar)
      (baz foo-baz (default (+ 40 2))))
    (let* ((a (foo (bar 1)))
           (b (foo (inherit a) (baz 2)))
           (c (foo (inherit b) (bar -2)))
           (d (foo (inherit c)))
           (e (foo (inherit (foo (bar 42))) (baz 77))))
     (and (match a (($ <foo> 1 42) #t))
          (match b (($ <foo> 1 2) #t))
          (match c (($ <foo> -2 2) #t))
          (equal? c d)
          (match e (($ <foo> 42 77) #t))))))

(test-assert "define-record-type* & inherit & let* behavior"
  (begin
    (define-record-type* <foo> foo make-foo
      foo?
      (bar foo-bar)
      (baz foo-baz (default (+ 40 2))))
    (let* ((a (foo (bar 77)))
           (b (foo (inherit a) (bar 1) (baz (+ bar 1))))
           (c (foo (inherit b) (baz 2) (bar (- baz 1)))))
     (and (match a (($ <foo> 77 42) #t))
          (match b (($ <foo> 1 2) #t))
          (equal? b c)))))

(test-assert "define-record-type* & thunked"
  (begin
    (define-record-type* <foo> foo make-foo
      foo?
      (bar foo-bar)
      (baz foo-baz (thunked)))

    (let* ((calls 0)
           (x     (foo (bar 2)
                       (baz (begin (set! calls (1+ calls)) 3)))))
      (and (zero? calls)
           (equal? (foo-bar x) 2)
           (equal? (foo-baz x) 3) (= 1 calls)
           (equal? (foo-baz x) 3) (= 2 calls)))))

(test-assert "define-record-type* & thunked & default"
  (begin
    (define-record-type* <foo> foo make-foo
      foo?
      (bar foo-bar)
      (baz foo-baz (thunked) (default 42)))

    (let ((mark (make-parameter #f)))
      (let ((x (foo (bar 2) (baz (mark))))
            (y (foo (bar 2))))
        (and (equal? (foo-bar x) 2)
             (parameterize ((mark (cons 'a 'b)))
               (eq? (foo-baz x) (mark)))
             (equal? (foo-bar y) 2)
             (equal? (foo-baz y) 42))))))

(test-assert "define-record-type* & thunked & inherited"
  (begin
    (define-record-type* <foo> foo make-foo
      foo?
      (bar foo-bar (thunked))
      (baz foo-baz (thunked) (default 42)))

    (let ((mark (make-parameter #f)))
      (let* ((x (foo (bar 2) (baz (mark))))
             (y (foo (inherit x) (bar (mark)))))
        (and (equal? (foo-bar x) 2)
             (parameterize ((mark (cons 'a 'b)))
               (eq? (foo-baz x) (mark)))
             (parameterize ((mark (cons 'a 'b)))
               (eq? (foo-bar y) (mark)))
             (parameterize ((mark (cons 'a 'b)))
               (eq? (foo-baz y) (mark))))))))

(test-equal "recutils->alist"
  '((("Name" . "foo")
     ("Version" . "0.1")
     ("Synopsis" . "foo bar")
     ("Something_else" . "chbouib"))
    (("Name" . "bar")
     ("Version" . "1.5")))
  (let ((p (open-input-string "
# Comment following an empty line, and
# preceding a couple of empty lines, all of
# which should be silently consumed.


Name: foo
Version: 0.1
# Comment right in the middle,
# spanning two lines.
Synopsis: foo bar
Something_else: chbouib

# Comment right before.
Name: bar
Version: 1.5
# Comment at the end.")))
    (list (recutils->alist p)
          (recutils->alist p))))

(test-equal "recutils->alist with + lines"
  '(("Name" . "foo")
    ("Description" . "1st line,\n2nd line,\n 3rd line with extra space,\n4th line without space."))
  (recutils->alist (open-input-string "
Name: foo
Description: 1st line,
+ 2nd line,
+  3rd line with extra space,
+4th line without space.")))

(test-equal "alist->record" '((1 2) b c)
  (alist->record '(("a" . 1) ("b" . b) ("c" . c) ("a" . 2))
                 list
                 '("a" "b" "c")
                 '("a")))

(test-end)


(exit (= (test-runner-fail-count (test-runner-current)) 0))
