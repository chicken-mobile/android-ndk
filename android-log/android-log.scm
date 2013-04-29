#>
#include <android/log.h>

static int enable_gc_log = 3;

static void 
gc_hook(int mode, long t)
{
   static char buffer[ 256 ];

   if(mode >= enable_gc_log) {
     switch(mode) {
     case 0: 
       strcpy(buffer, "GC: MINOR\n"); break;

     case 1:
       sprintf(buffer, "GC: %s (%ld ms)\n", mode == 1 ? "MAJOR" : "REALLOC", t);
       break;
     }

     __android_log_print(ANDROID_LOG_DEBUG, "NativeChicken", buffer);
  }
}
<#

(module android-log
*
(import chicken scheme foreign)
(use foreigners srfi-13 ports extras)

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

(define log-write
  (foreign-lambda void __android_log_print int c-string c-string))


(define (make-logcat-port tag log-level)
  (make-output-port
   (let ((string-buffer ""))
     (lambda (msg)
       (if (string-suffix? "\n" msg)
	   (begin 
	     (log-write log-level tag (string-append string-buffer msg))
	     (set! string-buffer ""))
	   (set! string-buffer (string-append string-buffer msg)))))
   void))

(define (make-logcat-output-port tag)
  (make-logcat-port tag priority/info))
(define (make-logcat-error-port tag)
  (make-logcat-port tag priority/error))

(define-foreign-variable enable_gc_log int)

(foreign-code "C_post_gc_hook = gc_hook;")

(define (enable-gc-logging mode)
  (set! enable_gc_log 
    (case mode
      ((#f) 3)
      ((#t) 1)
      (else mode))))

(define app-name "NativeChicken")
(current-output-port (make-logcat-output-port app-name))
(current-error-port (make-logcat-error-port app-name))

)
