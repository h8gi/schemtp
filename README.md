#schemtp

chicken scheme smtp client

## usage

### make-smtp
`(make-smtp <address> [<port>]) => <smtp>`   
make new smtp object. the default port is 25.

### set-sender!
`(set-sender! <smtp> <address>)`  
set sender of smtp object.

### add-receivers!
`(add-receivers! <smtp> <address>)`  
`(add-receivers! <smtp> <list-of-address>)`  

### update-header!
`(update-header! <smtp> <symbol> <string>)`  
you can send this header by `header-send!`.

## auth-plain!
`(auth-plain! <smtp> address password)`  

### data!
`(data! <smtp>)`  
start data method. 

### header-send!
`(header-send! smtp)`  
use after `data!`.

### data-send!
`(data-send! smtp <string>)`  
use after `header-send!`.

### data-end!
`(data-end! <smtp>)`  
end data method.

### quit!
`(quit! smtp)`  
quit smtp process.

### show-header

### show-methods

### debug
`(debug <boolean>)`  
enable debug mode.

## example

~~~~~{.scheme}
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


~~~~~

## non supported method
auth  

=======

