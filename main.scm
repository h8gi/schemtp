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
   [sock        #:initform (socket af/inet sock/stream)
                #:accessor sock-of]
   [header      #:initform (make-hash-table)
                #:accessor header-of]
   [methods     #:initform #f
                #:accessor methods-of]))

(define (make-smtp host)
  (let ([smtp (make <smtp>)]
        [sockaddr (inet-address (hostname->ip-string host)
                                (service-name->port "smtp" "tcp"))])
    (socket-connect (sock-of smtp) sockaddr)
    (set! (host-of smtp) host)
    (when (debug)
      (display (conc "connect:" (sockaddr->string (socket-peer-name (sock-of smtp))) "\n")
               (current-error-port)))
    (receive (in out) (socket-i/o-ports (sock-of smtp))
      (consume-line in)
      (send-line "EHLO localhost" out)
      (set! (methods-of smtp) (get-methods in)))
    smtp))

(define-method (update-header! (key <symbol>) (value <string>) (smtp <smtp>)) ;export
  (hash-table-set! (header-of smtp) key value))

(define-method (update-header! (smtp <smtp>))
  (define (capitalize str)
    (irregex-replace "^." (string-downcase str)
                     (lambda (m)
                       (string-upcase (irregex-match-substring m)))))
  (let ([date (time->date (current-time))])
    (update-header! smtp 'Date
                    (conc (capitalize (format-date "~a, ~d " date))
                          (capitalize (format-date "~b " date))
                          (format-date "~Y " date)
                          (irregex-replace "\\+" (format-date "~2" date) " +")))
    (update-header! smtp 'Message-ID
                    (conc (date-year date)  "-" (date-second date) "-" (date-nanosecond date)
                          "@" (host-of smtp)))
    (update-header! smtp 'Sender
                    (sender-of smtp))
    (update-header! smtp 'From
                    (sender-of smtp))
    (update-header! smtp 'To
                    (string-join (receivers-of smtp) ","))))


(define-method (header->string (header <hash-table>))
  (conc
   (string-join
    (hash-table-map header
     (lambda (key val)
       (conc (symbol->string key) ": " val)))
    "\n")
   "\n"))
(define-method (show-header (smtp <smtp>)) ;export
  (display (header->string (header-of smtp))))
(define-method (show-methods (smtp <smtp>))
  (for-each pp (methods-of smtp)))
;;; MAIL
(define-method (set-sender! (smtp <smtp>) sender) ;export
  (receive (in out) (socket-i/o-ports (sock-of smtp))
    (set! (sender-of smtp) sender)
    (update-header! smtp)               ;update header
    (send-line (conc "MAIL FROM:" sender) out)
    (consume-line in)))
;;; RCPT
(define-method (add-receivers! (smtp <smtp>) (receiver <string>)) ;export
  (receive (in out) (socket-i/o-ports (sock-of smtp))
    (set! (receivers-of smtp) (cons receiver (receivers-of smtp)))
    (update-header! smtp)               ;update header
    (send-line (conc "RCPT TO:" receiver) out)
    (consume-line in)))
(define-method (add-receivers! (smtp <smtp>) (receivers <list>))
  (for-each (cut add-receivers! smtp <>) receivers))
;;; DATA
(define-method (data! (smtp <smtp>))    ;export
  (receive (in out) (socket-i/o-ports (sock-of smtp))
    (send-line "DATA" out)
    (consume-line in)))
(define-method (header-send! (smtp <smtp>)) ;export
  (receive (in out) (socket-i/o-ports (sock-of smtp))
    (send-line (header->string (header-of smtp)) out)))
(define-method (data-send! (smtp <smtp>) (str <string>)) ;export
  (receive (in out) (socket-i/o-ports (sock-of smtp))
    (send-line str out)))
(define-method (data-end! (smtp <smtp>)) ;export
  (receive (in out) (socket-i/o-ports (sock-of smtp))
    (send-line "." out)
    (consume-line in)))
;;; QUIT
(define-method (quit! (smtp <smtp>))    ;export
  (receive (in out) (socket-i/o-ports (sock-of smtp))
    (send-line "QUIT" out)
    (consume-line in))
  (socket-close (sock-of smtp)))

;;; misc
(define debug (make-parameter #f))      ;export
(define (consume-line in)
  (let ([line (read-line in)])
    (when (debug)
      (display (conc "< " line "\n") (current-error-port)))
    (string->number (string-take line 3))))
(define (get-methods in)
  (let loop ([line (read-line in)]
             [methods '()])
    (when (debug)
      (display (conc "< " line "\n") (current-error-port)))
    (cond [(irregex-search '(: (= 3 digit) "-") line)
           (loop (read-line in) (cons (string-drop line 4) methods))]
          [else (cons (string-drop line 4) methods)])))

(define (send-line line out)
  (when (debug)
    (display (conc "> " line "\n") (current-error-port)))
  (display (conc line "\n") out))
(define (hostname->ip-string hostname)
  (let ([iaddr-vector (hostname->ip hostname)])
    (if iaddr-vector
        (string-join (map ->string (u8vector->list iaddr-vector))
                     ".")
        (error "not exist" hostname))))
