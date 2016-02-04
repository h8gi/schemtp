(use schemtp)
(define (test #!key host port
              from (name "")
              to (header '()) (contents "") file
              starttls tls auth debug)
  (smtp-debug debug)
  (let ([smtp (make-smtp host port tls)])
    (when starttls
      (start-tls smtp))
    (when auth
      (display (conc "password for " from ": "))
      (smtp-auth smtp from (read-line) auth))
    (set-sender! smtp from name)
    (add-receivers! smtp to)
    (for-each (lambda (x) (set-header! smtp (car x) (cdr x)))
              header)
    (start-data smtp)                            ; start
    (send-data-header smtp)                     ; send
    (send-data-body smtp
                    (if (and file (file-exists? file))
                        (with-input-from-file file read-all)
                        ""))
    (send-data-body smtp contents)
    (end-data smtp)                        ; end
    (quit-session smtp)
    ))

(test #:host     "smtp.gmail.com"
      #:port     587
      #:from     "user@gmail.com"
      #:name     "なまえ"
      #:to       "tekitou@dare.sore.com"
      #:header   '(("Subject" . "こんにちは")
                   ("Replay-To" . "hoge.example@foo.com"))
      #:file     "content.txt"
      #:starttls #t
      #:auth     'plain
      #:debug    #t)

(test #:host     "smtp.gmail.com"
      #:port     465
      #:from     "user@gmail.com"
      #:name     "なまえ"
      #:to       "tekitou@dare.sore.com"
      #:header   '(("Subject" . "こんにちは")
                   ("Replay-To" . "hoge.example@foo.com"))
      #:contents  "HELLO\r\nWORLD\r\nCONTENTS\r\n"
      #:tls       #t
      #:auth     'login
      #:debug    #t)

(exit 0)
