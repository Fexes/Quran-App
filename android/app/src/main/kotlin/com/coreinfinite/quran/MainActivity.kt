package com.coreinfinite.quran

import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "quran/qibla_heading")
            .setStreamHandler(QiblaHeadingStreamHandler(this))
    }
}

private class QiblaHeadingStreamHandler(
    private val activity: MainActivity,
) : EventChannel.StreamHandler, SensorEventListener {
    private val sensorManager =
        activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val rotationMatrix = FloatArray(9)
    private val remappedMatrix = FloatArray(9)
    private val orientation = FloatArray(3)
    private var eventSink: EventChannel.EventSink? = null
    private var latitude = 0.0
    private var longitude = 0.0
    private var altitude = 0.0
    private var sensorAccuracy = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
    private var sensorSource = "android_rotation_vector"

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        val args = arguments as? Map<*, *>
        latitude = (args?.get("latitude") as? Number)?.toDouble() ?: 0.0
        longitude = (args?.get("longitude") as? Number)?.toDouble() ?: 0.0
        altitude = (args?.get("altitude") as? Number)?.toDouble() ?: 0.0
        sensorAccuracy = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM

        val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            ?: sensorManager.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)

        if (sensor == null) {
            events.error("no_sensor", "Compass heading sensor unavailable.", null)
            return
        }

        sensorSource = if (sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
            "android_rotation_vector"
        } else {
            "android_geomagnetic_rotation_vector"
        }
        sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        eventSink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (
            event.sensor.type != Sensor.TYPE_ROTATION_VECTOR &&
            event.sensor.type != Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR
        ) {
            return
        }

        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
        val matrix = remapForDisplay()
        SensorManager.getOrientation(matrix, orientation)

        val magneticHeading = normalizeDegrees(Math.toDegrees(orientation[0].toDouble()))
        val declination = GeomagneticField(
            latitude.toFloat(),
            longitude.toFloat(),
            altitude.toFloat(),
            System.currentTimeMillis(),
        ).declination.toDouble()
        val trueHeading = normalizeDegrees(magneticHeading + declination)

        eventSink?.success(
            mapOf(
                "heading" to trueHeading,
                "magneticHeading" to magneticHeading,
                "declination" to declination,
                "accuracy" to sensorAccuracy,
                "source" to sensorSource,
            ),
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        sensorAccuracy = accuracy
    }

    private fun remapForDisplay(): FloatArray {
        val rotation = displayRotation()
        val success = when (rotation) {
            Surface.ROTATION_90 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_Y,
                SensorManager.AXIS_MINUS_X,
                remappedMatrix,
            )
            Surface.ROTATION_180 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_MINUS_X,
                SensorManager.AXIS_MINUS_Y,
                remappedMatrix,
            )
            Surface.ROTATION_270 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_MINUS_Y,
                SensorManager.AXIS_X,
                remappedMatrix,
            )
            else -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_X,
                SensorManager.AXIS_Y,
                remappedMatrix,
            )
        }
        return if (success) remappedMatrix else rotationMatrix
    }

    private fun displayRotation(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.rotation ?: Surface.ROTATION_0
        } else {
            @Suppress("DEPRECATION")
            activity.windowManager.defaultDisplay.rotation
        }
    }

    private fun normalizeDegrees(degrees: Double): Double {
        val normalized = degrees % 360.0
        return if (normalized < 0) normalized + 360.0 else normalized
    }
}
