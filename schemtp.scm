(module schemtp
    (make-smtp send-mail
               smtp-debug set-sender! add-receivers! set-header!
               show-header show-methods
               start-tls  smtp-auth
               start-data send-data-header send-data-body end-data
               quit-session)
  (import scheme chicken extras posix ports data-structures utils
          irregex
          srfi-4 srfi-1 srfi-13 srfi-69 coops coops-utils tcp foreign)
  (use coops-primitive-objects srfi-19 hostinfo base64 openssl hmac md5)
  (include "my-ssl.scm")
  (include "main.scm"))
