(use posix srfi-18)

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
	  (set-buffering-mode! port #:none)

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


(redirect-output-fileno fileno/stdout (open-output-file "stdout.log"))
(redirect-output-fileno fileno/stderr (open-output-file "stderr.log"))

(set-buffering-mode! (current-output-port) #:none)
(set-buffering-mode! (current-error-port)  #:none)

(print "§bar")
(print "§bar")
(print "§bar")
(print "§bar")

(display "testo1\n" (current-error-port))
(display "testo2\n" (current-error-port))
(display "testo3\n" (current-error-port))
(display "testo4\n" (current-error-port))
(display "testo5\n" (current-error-port))

;;(thread-sleep! 0.1)
