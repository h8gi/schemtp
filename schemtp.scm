(module schemtp
    (make-smtp debug set-sender! add-receivers! update-header! show-header
               data! header-send! data-send! data-end! quit!)
  (import scheme chicken extras posix
          irregex utf8-srfi-13 srfi-4 srfi-13 srfi-69)
  (use coops socket hostinfo utf8 coops-primitive-objects coops-utils srfi-19)
  (include "main.scm")
  )
