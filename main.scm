;; main.scm
;; http://www.atmarkit.co.jp/ait/articles/0304/22/news001.html
(define-class <smtp> ()
  ([host        #:initform ""
                #:accessor host-of]
   [sender      #:initform ""
                #:accessor sender-of]
   [receivers   #:initform '()
                #:accessor receivers-of]
   [data        #:initform ""
                #:accessor data-of]
   [header      #:initform (make-hash-table)
                #:accessor header-of]
   [methods     #:initform #f
                #:accessor methods-of]
   [in          #:accessor in-of]
   [out         #:accessor out-of]
   [tls         #:accessor tls?]))

(define (make-smtp host
                   #!optional (port (service-name->port "smtp" "tcp")) (tls #f))
  (let ([smtp (make <smtp>)])
    (receive (i o) (if tls
                       (ssl-connect host port 'tlsv1)
                       (tcp-connect host port))
      (set! (tls? smtp) tls)      
      (set! (in-of smtp) i)
      (set! (out-of smtp) o)
      (when (smtp-debug)
        (display (conc "connect: " (hostname->ip-string host) ":" port "\n")
                 (current-error-port))))
    (set! (host-of smtp) host)
    (consume-lines (in-of smtp) 220)
    (ehlo smtp)
    smtp))

(define-method (set-header! (smtp <smtp>) (key <string>) (value <string>)) ;export
  (hash-table-set! (header-of smtp) key value))

(define-method (reset-header! (smtp <smtp>))
  (define (capitalize str)
    (irregex-replace "^." (string-downcase str)
                     (lambda (m)
                       (string-upcase (irregex-match-substring m)))))
  (let ([date (time->date (current-time))])
    (set-header! smtp "Date"
                 (conc (capitalize (format-date "~a, ~d " date))
                          (capitalize (format-date "~b " date))
                          (format-date "~Y " date)
                          (irregex-replace "\\+" (format-date "~2" date) " +")))
    (set-header! smtp "Message-ID"
                    (conc (date-year date)  "-" (date-second date) "-" (date-nanosecond date)
                          "@" (host-of smtp)))    
    (set-header! smtp "Content-Type" "text/plain; charset=\"UTF-8\"")))


(define-method (header->string (header <hash-table>))
  (conc (string-join (hash-table-map
                      header
                      (lambda (key val)
                        (conc key ": " val))) "\n")
        "\n"))
(define-method (show-header (smtp <smtp>)) ;export
  (display (header->string (header-of smtp))))
(define-method (show-methods (smtp <smtp>)) ;export
  (for-each pp (methods-of smtp)))
(define-method (assert-method (smtp <smtp>) (method <string>))
  (if (filter (cut irregex-search method <>) (methods-of smtp))
      #t
      (error "non-supported method" method)))
(define-method (ehlo (smtp <smtp>))
  (send-line "EHLO localhost" (out-of smtp))
  (set! (methods-of smtp) (get-methods (in-of smtp))))
(define-method (start-tls (smtp <smtp>) #!optional (ctx <symbol>))
  (assert-method smtp "STARTTLS")
  (send-line "STARTTLS" (out-of smtp))
  (consume-lines (in-of smtp) 220)
  (receive (i o) (tcp-ports->ssl-ports (in-of smtp) (out-of smtp) 'tlsv1)
    (set! (in-of smtp) i)
    (set! (out-of smtp) o))
  (ehlo smtp))

(define-method (smtp-auth (smtp <smtp>) (address <string>) (password <string>) (method <symbol>))
  (define (auth-login)
    (assert-method smtp "AUTH.* LOGIN")
    (send-line "AUTH LOGIN" (out-of smtp))
    (consume-lines (in-of smtp) 334)
    (send-line (base64-encode address) (out-of smtp))
    (consume-lines (in-of smtp) 334)
    (send-line (base64-encode password) (out-of smtp))
    (consume-lines (in-of smtp) 235))
  (define (auth-plain)
    (assert-method smtp "AUTH.* PLAIN")
    (send-line
     (with-input-from-string (conc address "\x00" address "\x00" password)
       (lambda () (conc "AUTH PLAIN " (base64-encode (current-input-port))))) (out-of smtp))
    (consume-lines (in-of smtp) 235 250 334))
  (define (auth-cram-md5)
    (assert-method smtp "AUTH.* CRAM-MD5")
    (send-line "AUTH CRAM-MD5" (out-of smtp))
    (let ([timestamp (cdr (consume-lines (in-of smtp) 334))])
      (send-line
       (md5-sub timestamp address password)
       (out-of smtp))
      (consume-lines (in-of smtp) 235)))
  (cond [(eq? method 'plain) (auth-plain)]
        [(eq? method 'login) (auth-login)]
        [(eq? method 'cram-md5) (auth-cram-md5)]
        [else (error "no such login form" method)]))

;;; MAIL
(define-method (set-sender! (smtp <smtp>) sender #!optional (name "")) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (set! (sender-of smtp) sender)
    (set-header! smtp "Sender" (conc name "<" sender ">"))
    (set-header! smtp "From"   (conc name "<" sender ">"))
    (send-line (conc "MAIL FROM:<" (sender-of smtp) ">") out)
    (consume-lines in 250)))
;;; RCPT
(define-method (add-receivers! (smtp <smtp>) (receiver <string>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (set! (receivers-of smtp) (cons receiver (receivers-of smtp)))
    (set-header! smtp "To" (string-join (receivers-of smtp) ","))
    (send-line (conc "RCPT TO:<" receiver ">") out)
    (consume-lines in 250 251)))
(define-method (add-receivers! (smtp <smtp>) (receivers <list>))
  (for-each (cut add-receivers! smtp <>) receivers))
;;; DATA
(define-method (start-data (smtp <smtp>))    ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line "DATA" out)
    (consume-lines in 354)))
(define-method (send-data-header (smtp <smtp>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (reset-header! smtp)
    (send-line (header->string (header-of smtp)) out)))
(define-method (send-data-body (smtp <smtp>) (str <string>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line str out)))
(define-method (end-data (smtp <smtp>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line "." out)
    (consume-lines in 250)))
;;; QUIT
(define-method (quit-session (smtp <smtp>))    ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line "QUIT" out)
    (consume-lines in 221))
  (close-input-port (in-of smtp))
  (close-output-port (out-of smtp)))

;;; misc
(define smtp-debug (make-parameter #f))      ;export
(define (get-methods in)
  (let loop ([line (read-line in)]
             [methods '()])
    (when (smtp-debug)
      (display (conc "S< " line "\n") (current-error-port)))
    (cond [(irregex-search '(: (= 3 digit) "-") line)
           (loop (read-line in) (cons (string-drop line 4) methods))]
          [else (cons (string-drop line 4) methods)])))
(define (consume-lines in . status-list)
  (let loop ([line (read-line in)])
    (when (smtp-debug)
      (display (conc "S< " line "\n") (current-error-port)))
    (cond [(irregex-search '(: bol (= 3 digit) "-") line)
           (loop (read-line in))]
          [(member (string->number (string-take line 3)) status-list)
           => (lambda (x) (cons (car x) (string-drop line 4)))]
          [else (error "SMTP ERROR" (string->number (string-take line 3)))])))

(define (send-line line out)
  (when (smtp-debug)
    (display (conc "C> " line "\n") (current-error-port)))
  (display (conc line "\r\n") out))

(define (hostname->ip-string hostname)
  (let ([iaddr-vector (hostname->ip hostname)])
    (if iaddr-vector
        (string-join (map ->string (u8vector->list iaddr-vector))
                     ".")
        (error "not exist" hostname))))
(define (fill-string str limit #!key (fill #\0) (right? #f))
  (let ([dif (- limit (string-length str))])
    (if (>= dif 0)
        (if right?
            (string-append str (make-string dif fill))
            (string-append (make-string dif fill) str))
        (if right?
            (string-take str limit)
            (string-drop str (abs dif))))))

(define (md5-sub timestamp user password)
  (let* ([hmac-md5 (hmac password (md5-primitive))]
         [time     (base64-decode timestamp)]
         [str      (hmac-md5 time)]
         [str16    (string-join (map (compose (cut fill-string <> 2) (cut number->string <> 16) char->integer)
                                     (string->list str))
                                "")]
         [struser  (conc user " " str16)]
         [last     (base64-encode struser)])    
    last))
