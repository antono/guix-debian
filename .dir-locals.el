;; Per-directory local variables for GNU Emacs 23 and later.

((nil             . ((fill-column . 78)
                     (tab-width   .  8)))
 (c-mode          . ((c-file-style . "gnu")))
 (scheme-mode
  .
  ((indent-tabs-mode . nil)
   (eval . (put 'test-assert 'scheme-indent-function 1))
   (eval . (put 'test-equal 'scheme-indent-function 1))
   (eval . (put 'call-with-input-string 'scheme-indent-function 1))
   (eval . (put 'guard 'scheme-indent-function 1))
   (eval . (put 'lambda* 'scheme-indent-function 1))
   (eval . (put 'substitute* 'scheme-indent-function 1))
   (eval . (put 'with-directory-excursion 'scheme-indent-function 1))
   (eval . (put 'package 'scheme-indent-function 1))
   (eval . (put 'substitute-keyword-arguments 'scheme-indent-function 1))
   (eval . (put 'with-error-handling 'scheme-indent-function 0))
   (eval . (put 'with-mutex 'scheme-indent-function 1))))
 (emacs-lisp-mode . ((indent-tabs-mode . nil)))
 (texinfo-mode    . ((indent-tabs-mode . nil)
                     (fill-column . 72))))
