package com.clevertap.flutter.clevertap_native_display_sample

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val METHOD_CH = "com.clevertap.flutter/native_display"
        private const val EVENT_CH = "com.clevertap.flutter/native_display_events"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CH)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Replay any units that arrived before Flutter subscribed
                    val cached = SampleApplication.cachedUnitJsons
                    if (cached.isNotEmpty()) {
                        pushUnitsToFlutter(cached)
                    }
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

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

        SampleApplication.onUnitsLoaded = { jsonList -> pushUnitsToFlutter(jsonList) }
    }

    private fun pushUnitsToFlutter(jsonList: List<String>) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to "units_updated", "units" to jsonList))
        }
    }
}
