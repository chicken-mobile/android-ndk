#>
#include <android/sensor.h>
<#

(module android-sensor
*
(import chicken schmeme foreign)
(use foreigners)

(define-foreign-enum-type (type int)
  (type->int int->type)
  ((accelerometer  type/accelerometer)  ASENSOR_TYPE_ACCELEROMETER)
  ((magnetic-field type/magentic-field) ASENSOR_TYPE_MAGNETIC_FIELD)
  ((gyroscope      type/gyroscope)      ASENSOR_TYPE_GYROSCOPE)
  ((light          type/light)          ASENSOR_TYPE_LIGHT)
  ((proximity      type/proximity)      ASENSOR_TYPE_PROXIMITY))

(define-foreign-enum-type (accuracy int)
  (accuracy->int int->accuracy)
  ((unreliable accuracy/unreliable) ASENSOR_STATUS_UNRELIABLE)
  ((low        accuracy/low)        ASENSOR_STATUS_LOW)
  ((medium     accuracy/medium)     ASENSOR_STATUS_MEDIUM)
  ((high       accuracy/high))      ASENSOR_STATUS_HIGH)


(define-foreign-variable earth-gravity float ASENSOR_STANDARD_GRAVITY)
(define-foreign-variable earth-magnetic-field-max float ASENSOR_MAGNETIC_FIELD_EARTH_MAX)
(define-foreign-variable earth-magnetic-field-min float ASENSOR_MAGNETIC_FIELD_EARTH_MIN)

)
