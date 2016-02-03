(use schemtp)
(define host "smtp.example.com")
(define sender "sender@hoge.hoge.com")
(define receivers
  '(
    "rec1@foo.bar.com"
    "rec2@aaa.bbb.com"
    ))
(define contents (conc "HELLO\n"
                       "WORLD\n"
                       (random 100) "\n"
                       "こんにちは\n"))
(debug #t)
(define smtp (make-smtp host 587))
;;; auth
(auth-plain! smtp sender "password")
;;; 送信者
(set-sender! smtp sender)
;;; 受信者
(add-receivers! smtp receivers)
;;; heaer
(update-header! smtp 'Subject "ほげあああ")
(update-header! smtp 'Replay-To sender)
;;; data
(data! smtp)                            ; start
(header-send! smtp)                     ; send
(data-send! smtp contents)              ; send
(data-end! smtp)                        ; end
;;; quit
(quit! smtp)
