package com.clevertap.flutter.clevertap_native_display_sample

import android.os.Handler
import android.os.Looper
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        /** MethodChannel for Dart → native calls (pushEvent). */
        private const val METHOD_CH = "com.clevertap.flutter/native_display"

        /** EventChannel for native → Dart push (units_updated). */
        private const val EVENT_CH = "com.clevertap.flutter/native_display_events"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel: push display units to Dart when they arrive
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CH)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        // MethodChannel: handle pushEvent calls from Dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CH)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pushEvent" -> {
                        val name = call.argument<String>("eventName") ?: ""
                        if (name.isNotEmpty()) {
                            SampleApplication.cleverTapApi?.pushEvent(name)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Register callback: future unit deliveries from SampleApplication go to Flutter
        SampleApplication.onUnitsLoaded = { units -> pushUnitsToFlutter(units) }
    }

    private fun pushUnitsToFlutter(units: List<NativeDisplayUnit>) {
        val jsonList = units.mapNotNull { it.rawJson }.filter { it.isNotEmpty() }
        mainHandler.post {
            eventSink?.success(mapOf("type" to "units_updated", "units" to jsonList))
        }
    }
}
