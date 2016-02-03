(module schemtp
    (make-smtp debug set-sender! add-receivers! update-header! show-header show-methods
               data! header-send! data-send! data-end! quit!)
  (import scheme chicken extras posix
          irregex utf8-srfi-13 srfi-4 srfi-13 srfi-69 coops  coops-utils)
  (use utf8 coops-primitive-objects  srfi-19 socket hostinfo)
  (include "main.scm")
  )
