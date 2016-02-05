#>
#include <errno.h>
#ifdef _WIN32
  #ifdef _MSC_VER
    #include <winsock2.h>
  #else
    #include <ws2tcpip.h>
  #endif

  #include <openssl/rand.h>
#else
  #define closesocket     close
#endif

#ifdef ECOS
  #include <sys/sockio.h>
#else
  #include <unistd.h>
#endif

#include <openssl/err.h>
#include <openssl/ssl.h>
<#

(foreign-code #<<EOF
ERR_load_crypto_strings();
SSL_load_error_strings();
SSL_library_init();

#ifdef _WIN32
  RAND_screen();
#endif

EOF
)
(define ssl-clear-error (foreign-lambda void "ERR_clear_error"))
(define ssl-set-connect-state! (foreign-lambda void "SSL_set_connect_state" c-pointer))
(define ssl-ctx-free (foreign-lambda void "SSL_CTX_free" c-pointer))

(define (ssl-new ctx)
  (ssl-clear-error)
  (cond
   (((foreign-lambda c-pointer "SSL_new" c-pointer) ctx)
    => values)
   (else
                                        ;(ssl-abort 'ssl-new #f)
    (error "FOO"))))

(define (ssl-ctx-new protocol server)
  (ssl-clear-error)
  (let ((ctx
	 ((foreign-lambda*
	   c-pointer ((c-pointer method))
	   "SSL_CTX *ctx;"
	   "if ((ctx = SSL_CTX_new((SSL_METHOD *)method)))\n"
	   "  SSL_CTX_set_mode(ctx, SSL_MODE_ENABLE_PARTIAL_WRITE | "
           "                        SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);\n"
	   "return(ctx);\n")
	  (case protocol
	    ((sslv2-or-v3)
	     (if server
		 ((foreign-lambda c-pointer "SSLv23_server_method"))
		 ((foreign-lambda c-pointer "SSLv23_client_method"))))
	    ((sslv3)
	     (if server
		 ((foreign-lambda c-pointer "SSLv3_server_method"))
		 ((foreign-lambda c-pointer "SSLv3_client_method"))))
	    ((tls tlsv1)
	     (if server
		 ((foreign-lambda c-pointer "TLSv1_server_method"))
		 ((foreign-lambda c-pointer "TLSv1_client_method"))))
	    ((tlsv11)
	     (if server
		 ((foreign-lambda c-pointer "TLSv1_1_server_method"))
		 ((foreign-lambda c-pointer "TLSv1_1_client_method"))))
	    ((tlsv12)
	     (if server
		 ((foreign-lambda c-pointer "TLSv1_2_server_method"))
		 ((foreign-lambda c-pointer "TLSv1_2_client_method"))))
	    (else
	     (abort
	      (make-composite-condition
	       (make-property-condition
		'exn
		'message "invalid SSL/TLS connection protocol"
		'location 'ssl-ctx-new
		'arguments (list protocol))
	       (make-property-condition
		'type))))))))
    (unless ctx (error "ssl ctx"))
    (set-finalizer! ctx ssl-ctx-free)
    ctx))

(define (tcp-ports->ssl-ports tcp-in tcp-out #!optional (ctx 'sslv2-or-v3))
  (let* ((fd (net-unwrap-tcp-ports tcp-in tcp-out))
         (ctx (ssl-ctx-new ctx #f))
         (ssl
          (ssl-new ctx)))
    (ssl-set-connect-state! ssl)
    (ssl-make-i/o-ports ctx fd ssl tcp-in tcp-out)))
