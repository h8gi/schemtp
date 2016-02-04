(module schemtp
    (make-smtp debug set-sender! add-receivers! set-header! show-header show-methods
               start-tls auth-plain
               start-data send-data-header send-data-body end-data quit-session)
  (import scheme chicken extras posix ports
          irregex utf8-srfi-13 srfi-4 srfi-1 srfi-13 srfi-69 coops  coops-utils tcp)
  (use utf8 coops-primitive-objects srfi-19 hostinfo base64 openssl)
  (include "main.scm"))
