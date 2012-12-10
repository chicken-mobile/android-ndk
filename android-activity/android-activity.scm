#>
#include <android/native_activity.h>
<#

(module android-activity
*
(import chicken scheme foreign)
(use foreigners)

(define-foreign-type activity (c-pointer ANativeActivity))
(define-foreign-type asset-manager (c-pointer AAssetMaanger))


(define-foreign-record-type (callbacks ANativeActivityCallbacks)
  (constructor: make-callbacks)
  (destructor:  free-callbacks)
  ((function void activity)         onStart                start-function)
  ((function void activity)         onResume              resume-function)
  ((function void activity size)    onSaveInstanceState  suspend-function)
  ((function void activity)         onPause                pause-function)
  ((function void activity)         onStop                  stop-function)
  ((function void activity)         onDestroy            destroy-function)
  
  ((function void activity boolean) onWindowFocusChanged       window-focus-changed-function)
  ((function void activity window)  onNativeWindowCreated            window-created-function)
  ((function void activity window)  onNativeWindowResized            window-resized-function)
  ((function void activity window)  onNativeWindowRedrawNeeded        window-redraw-function)
  ((function void activity window)  onNativeWindowDestroyed        window-destroyed-function)
  
  ((function void activity input-queue) onInputQueueCreated   input-queue-created-function)
  ((function void activity input-queue) onInputQueueDestroyed input-queue-destroyed-function)

  ((function void activity rectangle) onContentRectChanged   content-rectangle-changed-function)
  ((function void activity)           onConfigurationChanged     configuration-changed-function)
  ((function void activity)           onLowMemory                           low-memory-function))

(define-foreign-record-type (activity ANativeActivity)
  ((c-pointer (struct ANativeActivityCallbacks)) callbacks callbacks)
  ((c-pointer JavaVM)  vm     activity-jvm)
  ((c-pointer JNIEnv)  env    activity-jni-env)
  ((c-pointer jobject) clazz  activity-object)
  (c-string internalDataPath  activity-internal-data-path)
  (c-string externalDataPath  activity-external-data-path)
  (integer  sdkVersion        activity-sdk-version)
  (c-pointer instance         activity-instance)
  ((c-pointer (struct AAssetManager)) assetManager activity-asset-manager))

(define-foreign-enum-type (show-soft-input-flag int)
  (show-soft-input-flag->int int->show-soft-input-flag)
  ((implicit show-soft-key-flag/implicit) ANATIVEACTIVITY_SHOW_SOFT_INPUT_IMPLICIT)
  ((forced   show-soft-key-flag/forced)   ANATIVEACTIVITY_SHOW_SOFT_INPUT_FORCED))

(define-foreign-enum-type (hide-soft-input-flag int)
  (show-soft-input-flag->int int->show-soft-input-flag)
  ((implicit-only hide-soft-key-flag/implicit-only) ANATIVEACTIVITY_HIDE_SOFT_INPUT_IMPLICIT_ONLY)
  ((not-always    hide-soft-key-flag/not-always)    ANATIVEACTIVITY_HIDE_SOFT_INPUT_NOT_ALWAYS))


(define finish
  (foreign-lambda void ANativeActivity_finish activity))

(define set-window-format!
  (foreign-lambda void ANativeActivity_setWindowFormat activity integer))
(define set-window-flags!
  (foreign-lambda void ANativeActivity_setWindowFlags activity integer integer))

(define show-soft-input
  (foreign-lambda void ANativeActivity_showSoftInput activity show-soft-input-flag))
(define hide-soft-input
  (foreign-lambda void ANativeActivity_hideSoftInput activity hide-soft-input-flag))

)
