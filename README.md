#schemtp

chicken scheme smtp client

## usage

### make-smtp

`(make-smtp <address> [<port>] [<tls>]) => <smtp>`   
make new smtp object. the default port is 25.  

### start-tls
`(start-tls <smtp> [ssl/tls-version])`  
`STARTTLS` method.  
you can use these symbols.

**'sslv2-or-v3**  
TLS protocol or SSL protocol versions 2 or 3, as appropriate  
**'sslv3**  
SSL protocol version 3  
**'tls or 'tlsv1**  
the TLS protocol version 1  
**'tlsv11**  
the TLS protocol version 1.1  
**'tlsv12**  
the TLS protocol version 1.2  

### set-sender!
`(set-sender! <smtp> <address> [<name>])`  
set sender of smtp object.

### add-receivers!
`(add-receivers! <smtp> <address>)`  
`(add-receivers! <smtp> <list-of-address>)`  

### set-header!
`(set-header! <smtp> <string> <string>)`  
you can send this header by `header-send!`.

### smtp-auth
`(smtp-auth <smtp> address password <auth-type>)`  
**'plain**  
**'login**  
**'cram-md5**

### start-data
`(start-data <smtp>)`  
start data method. 

### send-data-header
`(send-data-header smtp)`  
use after `data!`.

### send-data-body
`(send-data-body smtp <string>)`  
use after `header-send!`.

### end-data
`(end-data <smtp>)`  
end data method.

### quit-session
`(quit! smtp)`  
quit smtp process.

### show-header

### show-methods

### smtp-debug
`(smtp-debug <boolean>)`  
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
(define smtp (make-smtp host 587))
;;; starttls
(start-tls smtp 'tlsv1)
;;; auth
(smtp-auth smtp sender "password" 'plain)
;;; 送信者
(set-sender! smtp sender "NAME")
;;; 受信者
(add-receivers! smtp receivers)
;;; heaer
(set-header! smtp "Subject" "ほげあああ")
(set-header! smtp "Replay-To" sender)
;;; data
(start-data smtp)                      ; start
(data-header-send smtp)                ; send
(data-body-send smtp contents)         ; send
(data-end smtp)                        ; end
;;; quit
(quit-session smtp)

~~~~~

see [./test/test.scm](./test/test.scm)

## depends


