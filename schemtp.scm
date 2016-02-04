(module schemtp
    (make-smtp debug set-sender! add-receivers! set-header! show-header show-methods
               auth-plain!
               data! send-header! send-data! end-data! quit!)
  (import scheme chicken extras posix ports
          irregex utf8-srfi-13 srfi-4 srfi-13 srfi-69 coops  coops-utils tcp)
  (use utf8 coops-primitive-objects srfi-19 hostinfo base64 openssl)
  (include "main.scm")
  )
