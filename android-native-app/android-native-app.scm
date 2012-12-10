#>
#include "android_native_app_glue.c"
#include <android/rect.h>
#include <android/native_window.h>
#include <android/input.h>
#include <android/looper.h>
#include <android/configuration.h>
#include <android/native_activity.h>

int  (handle_input)  (struct android_app* app, AInputEvent* event);
void (handle_command)(struct android_app* app, int cmd);
void (app_loop)      (struct android_app* app);

void android_main(struct android_app* app) {
  LOGI("initialize chicken :S");
  CHICKEN_run(C_toplevel);
  LOGI("chicken initialized :)");

  app->onAppCmd = handle_command;
  app->onInputEvent = handle_input;

  while (1) {
    // Read all pending events.
    int ident;
    int events;
    struct android_poll_source* source;

    while ((ident=ALooper_pollAll(0, NULL, &events, (void**)&source)) >= 0) {
      // Process this event.
      if (source != NULL) {
	source->process(app, source);
      }
    }
  }
}
<#


(module android-native-app
*
(import chicken scheme extras foreign srfi-18)
(use android-log android-activity jni foreigners)

(define-foreign-type native-app    (c-pointer android_app))
(define-foreign-type rectangle     (c-pointer ARect))
(define-foreign-type window        (c-pointer ANativeWindow))
(define-foreign-type input-queue   (c-pointer AInputQueue))
(define-foreign-type looper        (c-pointer ALooper))
(define-foreign-type configuration (c-pointer AConfiguration))
(define-foreign-type activity      (c-pointer ANativeActivity))

(define-foreign-record-type (native-app "struct android_app")
  (c-pointer userData native-app-user-data set-native-app-user-data!)
  ((function void native-app integer) onAppCmd native-app-command-function)
  ((function integer native-app input-event) onInputEvent native-app-input-function)
  ((c-pointer (struct ANativeActivity)) activity native-app-activity)
  ((c-pointer (struct AConfiguration)) config native-app-config)
  (c-pointer savedState native-app-saved-state)
  (integer savedStateSize native-app-saved-state-size)
  ((c-pointer (struct ALooper)) looper native-app-looper)
  ((c-pointer (struct AInputQueue)) inputQueue native-app-input-queue)
  ((c-pointer (struct ANativeWindow)) window native-app-window)
  ((struct ARect) contentRect native-app-content-rectangle)
  (integer activityState native-app-state)
  (bool destroyRequested native-app-destroy-requested?)
  
  ;; private implementation
  ((struct pthread_mutex_t) mutex native-app-mutex)
  ((struct pthread_cond_t) cond native-app-cond)
  (integer msgread native-app-msgread)
  (integer msgwrite native-app-msgwrite)
  ((struct pthread_t) thread native-app-thread)
  ((struct android_poll_source) cmdPollSource native-app-cmd-poll-source)
  ((struct android_poll_source) inputPollSource native-app-input-poll-source)
  (bool running native-app-running?)
  (bool stateSaved native-app-state-saved?)
  (bool destroyed native-app-destroyed?)
  (bool redrawNeeded native-app-redraw-needed)
  ((c-pointer (struct AInputQueue)) pendingInputQueue native-app-pending-input-queue)
  ((c-pointer (struct ANativeWindow)) pendingWindow native-app-pending-window)
  ((struct ARect) pendingContentRect native-app-pending-content-rectangle))

(define-foreign-record-type (poll-source "struct android_poll_source")
  (constructor: make-poll-source)
  (destructor: free-poll-source)
  (int32 id poll-source-id)
  ((c-pointer (struct android_app)) app poll-source-app)
  ((c-pointer (function void ANative poll-source)) process poll-source-process-function))

(define-foreign-enum-type (looper-id int)
  (looper-id->int int->looper-id)
  ((main looper-id/main) LOOPER_ID_MAIN)
  ((input looper-id/input) LOOPER_ID_INPUT)
  ((user looper-id/user) LOOPER_ID_USER))

(define-foreign-enum-type (poll-result int)
  (poll-result->int int->poll-result)
  ((wake poll-result/wake) ALOOPER_POLL_WAKE)
  ((callback poll-result/callback) ALOOPER_POLL_CALLBACK)
  ((timeout poll-result/timeout) ALOOPER_POLL_TIMEOUT)
  ((error poll-result/error) ALOOPER_POLL_ERROR))

(define-foreign-enum-type (app-cmd int)
  (app-cmd->int int->app-cmd)
  ((input-changed  app-command/input-changed)  APP_CMD_INPUT_CHANGED)
  ((init-window    app-command/init-window)    APP_CMD_INIT_WINDOW)
  ((term-window    app-command/term-window)    APP_CMD_TERM_WINDOW)
  ((window-resized app-command/window-resized) APP_CMD_WINDOW_RESIZED)
  ((window-redraw-needed      app-command/window-redraw-neended)     APP_CMD_WINDOW_REDRAW_NEEDED)
  ((content-rectangle-changed app-command/content-rectangle-changed) APP_CMD_CONTENT_RECT_CHANGED)
  ((gained-focues  app-command/gained-focus)   APP_CMD_GAINED_FOCUS)
  ((lost-focus     app-command/lost-focus)     APP_CMD_LOST_FOCUS)
  ((config-changed app-command/config-changed) APP_CMD_CONFIG_CHANGED)
  ((low-memory     app-command/low-memory)     APP_CMD_LOW_MEMORY)
  ((start          app-command/start)          APP_CMD_START)
  ((resume         app-command/resume)         APP_CMD_RESUME)
  ((save-state     app-command/save-state)     APP_CMD_SAVE_STATE)
  ((pause          app-command/pause)          APP_CMD_PAUSE)
  ((stop           app-command/stop)           APP_CMD_STOP)
  ((destroy        app-command/destroy)        APP_CMD_DESTROY))

(define read-cmd 
  (foreign-lambda short android_app_read_cmd native-app))
(define pre-exec-cmd 
  (foreign-lambda void android_app_pre_exec_cmd native-app short))
(define post-exec-cmd 
  (foreign-lambda void android_app_post_exec_cmd native-app short))

(define dummy
  (foreign-lambda void app_dummy))


(define pollpoll
  (foreign-lambda* int (((c-pointer int) outEvents) (poll-source outData))
    "C_return(ALooper_pollAll(-1, NULL, outEvents, (void**)&outData));"))

(define testo
  (foreign-lambda* void ((c-pointer fn) (native-app app) (poll-source source))
    "((int (*)(struct android_app*, struct android_poll_source*)) fn)(app, source);"))

(define-external (app_loop (native-app app)) void
  (let loop ()
    (let-location 
     ((events int) (source poll-source))
     (let* ((source2 (make-poll-source))
	    (ident (pollpoll (location events) source)))
       (if (and (>= ident 0) source)
	   (unless (= (poll-source-id source) 666)
		   (thread-sleep! 1)
		   (print "------------------------------------------------------------------")
		   (print (format "ident is:\t~A\t\t\tsource is:\t~A\nfunction is:\t~A\tsource id is:\t~A"
				  ident source (poll-source-process-function source) (poll-source-id source)))

		   (if (poll-source-process-function source)
		       (begin
			 (print "call---")
			 (testo (poll-source-process-function source) app  source)
			 (print "---ing"))))
	   
	   (loop))))))

(define native-app
  (make-parameter '()))

(define-external (handle_command ((c-pointer "struct android_app") app) (app-cmd cmd)) void
  (print "event received: " cmd)
  (case cmd
    ((init-window)
     (with-jvm-thread (activity-jvm (native-app-activity app))
       (lambda ()
	 (let* ((activity-class (get-object-class (activity-object (native-app-activity app))))
		(class-loader (call activity-class getClassLoader))
		(R (call class-loader loadClass (jstring "com/bevuta/androidChickenTest/R"))))

	   (print (get-int-field/0 R ))))))))



(define-external (handle_input ((c-pointer "struct android_app") app) ((c-pointer "struct AInputEvent") event)) integer
  (print "brumm brummss") 1))

(return-to-host)

