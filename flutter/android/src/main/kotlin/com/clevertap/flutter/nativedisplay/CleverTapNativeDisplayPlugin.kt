package com.clevertap.flutter.nativedisplay

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class CleverTapNativeDisplayPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    // Set by the host app after initialising CleverTap Core SDK.
    // The plugin delegates all display-unit calls to this bridge.
    var bridge: NativeDisplayPluginBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "fetchDisplayUnit" -> {
                val unitId = call.argument<String>("unitId")
                if (unitId == null) {
                    result.error("INVALID_ARGUMENT", "unitId is required", null)
                    return
                }
                val json = bridge?.fetchDisplayUnit(unitId)
                if (json != null) result.success(json) else result.success(null)
            }
            "pushViewedEvent" -> {
                val unitId = call.argument<String>("unitId")
                if (unitId != null) bridge?.pushViewedEvent(unitId)
                result.success(null)
            }
            "pushClickedEvent" -> {
                val unitId = call.argument<String>("unitId")
                val elementId = call.argument<String?>("elementId")
                if (unitId != null) bridge?.pushClickedEvent(unitId, elementId)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.clevertap.flutter.nativedisplay"
    }
}

interface NativeDisplayPluginBridge {
    // Return display unit JSON string for the given unitId, or null if not found.
    fun fetchDisplayUnit(unitId: String): String?

    // Report viewed event to CleverTap Core SDK.
    fun pushViewedEvent(unitId: String)

    // Report clicked event to CleverTap Core SDK.
    fun pushClickedEvent(unitId: String, elementId: String?)
}
