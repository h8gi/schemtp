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
   [out         #:accessor out-of]))

(define (make-smtp host
                   #!optional (port (service-name->port "smtp" "tcp")) (tls #f))
  (let ([smtp (make <smtp>)])
    (receive (i o) (if tls
                       (ssl-connect host port 'tlsv1)
                       (tcp-connect host port))
      (set! (in-of smtp) i)
      (set! (out-of smtp) o)
      (when (debug)
        (display (conc "connect: " (hostname->ip-string host) ":" port "\n")
                 (current-error-port))))
    (set! (host-of smtp) host)
    (consume-line (in-of smtp))
    (send-line "EHLO localhost" (out-of smtp))
    (consume-line (in-of smtp))
    (set! (methods-of smtp) (get-methods (in-of smtp)))
    smtp))

(define-method (update-header! (smtp <smtp>) (key <symbol>) (value <string>)) ;export
  (hash-table-set! (header-of smtp) key value))

(define-method (reset-header! (smtp <smtp>))
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
    (update-header! smtp 'Content-Type "text/plain; charset=\"UTF-8\"")))


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
(define-method (show-methods (smtp <smtp>)) ;export
  (for-each pp (methods-of smtp)))
(define-method (auth-plain! (smtp <smtp>) (address <string>) (password <string>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line
     (with-input-from-string (conc address "\x00" address "\x00" password)
       (lambda () (conc "AUTH PLAIN " (base64-encode (current-input-port))))) out)
    (consume-line in)))
;;; MAIL
(define-method (set-sender! (smtp <smtp>) sender #!optional (name "")) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (set! (sender-of smtp) (conc name "<" sender ">"))
    (update-header! smtp 'Sender (sender-of smtp))
    (update-header! smtp 'From   (sender-of smtp))
    (send-line (conc "MAIL FROM:" (sender-of smtp)) out)
    (consume-line in)))
;;; RCPT
(define-method (add-receivers! (smtp <smtp>) (receiver <string>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (set! (receivers-of smtp) (cons receiver (receivers-of smtp)))
    (update-header! smtp 'To (string-join (receivers-of smtp) ","))
    (send-line (conc "RCPT TO:<" receiver ">") out)
    (consume-line in)))
(define-method (add-receivers! (smtp <smtp>) (receivers <list>))
  (for-each (cut add-receivers! smtp <>) receivers))
;;; DATA
(define-method (data! (smtp <smtp>))    ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line "DATA" out)
    (consume-line in)))
(define-method (header-send! (smtp <smtp>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (reset-header! smtp)
    (send-line (header->string (header-of smtp)) out)))
(define-method (data-send! (smtp <smtp>) (str <string>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line str out)))
(define-method (data-end! (smtp <smtp>)) ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line "\r\n." out)
    (consume-line in)))
;;; QUIT
(define-method (quit! (smtp <smtp>))    ;export
  (receive (in out) (values (in-of smtp) (out-of smtp))
    (send-line "QUIT" out)
    (consume-line in))
  (close-input-port (in-of smtp))
  (close-output-port (out-of smtp)))

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
  (display (conc line "\r\n") out))
(define (hostname->ip-string hostname)
  (let ([iaddr-vector (hostname->ip hostname)])
    (if iaddr-vector
        (string-join (map ->string (u8vector->list iaddr-vector))
                     ".")
        (error "not exist" hostname))))
