(use schemtp)

(send-mail #:host     "smtp.gmail.com"
           #:port     587
           #:from     "user@gmail.com"
           #:name     "なまえ"
           #:to       "tekitou@dare.sore.com"
           #:header   '(("Subject" . "こんにちは"))
           #:file     "content.txt"
           #:starttls #t
           #:auth     'plain
           #:debug    #t)

;; (send-mail #:host     "smtp.gmail.com"
;;            #:port     465
;;            #:from     "user@gmail.com"
;;            #:name     "なまえ"
;;            #:to       "tekitou@dare.sore.com"
;;            #:header   '(("Subject" . "こんにちは")
;;                         ("Replay-To" . "hoge.example@foo.com"))
;;            #:contents  "HELLO\r\nWORLD\r\nCONTENTS\r\n"
;;            #:tls       #t
;;            #:auth     'login
;;            #:debug    #t)

(exit 0)
