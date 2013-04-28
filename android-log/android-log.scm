#>
#include <android/log.h>
<#

(module android-log
*
(import chicken scheme foreign)
(use foreigners srfi-13 ports extras posix srfi-18)

(define-foreign-enum-type (log-priority int)
  (priority->int int->priority)
  ((unknown priority/unknown) ANDROID_LOG_UNKNOWN)
  ((default priority/default) ANDROID_LOG_DEFAULT)
  ((verbose priority/verbose) ANDROID_LOG_VERBOSE)
  ((debug   priority/debug)   ANDROID_LOG_DEBUG)
  ((info    priority/info)    ANDROID_LOG_INFO)
  ((warn    priority/warn)    ANDROID_LOG_WARN)
  ((error   priority/error)   ANDROID_LOG_ERROR)
  ((fatal   priority/fatal)   ANDROID_LOG_FATAL)
  ((silent  priority/silent)  ANDROID_LOG_SILENT))

(define app-name "NativeChicken")

(define log-write
  (foreign-lambda void __android_log_print int c-string c-string))


(define (log-thread-exit-handler mutex condition port %exit)
  (lambda exit-code
    (mutex-lock! mutex)
    (mutex-unlock! mutex condition)

    (flush-output port)
    (close-output-port port)
    (apply %exit exit-code)))


(define (redirect-output-fileno fileno port)
  (let ((mutex  (make-mutex))
	(condition (make-condition-variable))
	(ready! (make-condition-variable)))

    (exit-handler          (log-thread-exit-handler mutex condition port (exit-handler)))
    (implicit-exit-handler (log-thread-exit-handler mutex condition port (exit-handler)))

    (mutex-lock! mutex)
    (thread-start!
     (make-thread
      (lambda ()
	(let-values (((in out) (create-pipe)))

	  (duplicate-fileno out fileno)
	  (current-output-port port)

	  (condition-variable-signal! ready!)
	  (let loop ()
	    (thread-wait-for-i/o! in)
	    (mutex-lock! mutex)
	    (let get-chars ()
	      (let* ((foo (file-read in 64))
		     (data (car foo))
		     (length (cadr foo)))
		(print* (substring data 0 length))
		(if (or (> 64 length) (= length 0)) 
		    (condition-variable-signal! condition)
		    (get-chars))))
	    (mutex-unlock! mutex condition)
	    (loop))))))
    (mutex-unlock! mutex ready!)))

#;
(define (make-logcat-port tag log-level)
  (make-output-port
   (let ((string-buffer ""))
     (lambda (msg)
       (let loop ((message msg))
	 (let ((nl-idx (string-index message #\n)))
	   (if nl-idx
	       (begin
		 (log-write app-name (string-append string-buffer (substring message 0 nl-idx)))
		 (loop (substring message  nl-idx (length message))))
	       (set! string-buffer (string-append string-buffer message)))))))
   void))

(use udp)
(define remote-logger (udp-open-socket))

(udp-set-multicast-interface remote-logger "10.10.10.179")
(udp-connect! remote-logger "225.0.0.231" 7890)

(duplicate-fileno (udp-socket-fd remote-logger) fileno/stderr)
(duplicate-fileno (udp-socket-fd remote-logger) fileno/stdout)

)
