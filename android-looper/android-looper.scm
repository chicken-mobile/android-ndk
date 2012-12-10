#>
#include <android/looper.h>
<#

(module android-looper
*
(import chicken scheme foreign)
(use foreigners)

(define-foreign-type looper (c-pointer "ALooper"))
(define-foreign-type looper-callback (c-pointer "ALopper_callbackFunc")) ;;; hmmmm

(define-foreign-enum-type (prepare-option int)
  (prepare-option->int int->prepare-option)
  ((allow-non-callbacks prepare-option/allow-non-callbacks) ALOOPER_PREPARE_ALLOW_NON_CALLBACKS))

(define-foreign-enum-type (poll-result int)
  (poll-result->int int->poll-result)
  ((wake poll-result/wake) ALOOPER_POLL_WAKE)
  ((callback poll-result/callback) ALOOPER_POLL_CALLBACK)
  ((timeout poll-result/timeout) ALOOPER_POLL_TIMEOUT)
  ((error poll-result/error) ALOOPER_POLL_ERROR))

(define-foreign-enum-type (looper-flag int)
  (looper-flag->int int->looper-flag)
  ((input looper-flag/input) ALOOPER_EVENT_INPUT)
  ((output looper-flag/output) ALOOPER_EVENT_OUTPUT)
  ((error looper-flag/error) ALOOPER_EVENT_ERROR)
  ((hangup looper-flag/hangup) ALOOPER_EVENT_HANGUP)
  ((invalid looper-flag/invalid) ALOOPER_EVENT_INVALID))


(define looper-for-thread
  (foreign-lambda looper ALooper_forThread))
(define looper-prepare
  (foreign-lambda looper ALooper_prepare prepare-option))
(define looper-acquire
  (foreign-lambda void ALooper_acquire looper))
(define looper-release
  (foreign-lambda void ALooper_release looper))

(define looper-poll-once
  (foreign-lambda poll-result ALooper_pollOnce int (c-pointer int) (c-pointer int) (c-pointer c-pointer)))
(define looper-poll-all
  (foreign-lambda poll-result ALooper_pollAll int (c-pointer int) (c-pointer int) (c-pointer c-pointer)))

(define looper-wake
  (foreign-lambda void ALooper_wake looper))
(define looper-add-fd
  (foreign-lambda int ALooper_addFd looper int int int c-pointer c-pointer))
(define looper-remove-fd
  (foreign-lambda int ALooper_removeFd looper int))
)
