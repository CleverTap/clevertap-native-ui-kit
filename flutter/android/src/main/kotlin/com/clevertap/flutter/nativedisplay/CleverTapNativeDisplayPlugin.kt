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
                val additionalProperties = call.argument<Map<String, Any?>?>("additionalProperties")
                if (unitId != null) bridge?.pushViewedEvent(unitId, additionalProperties)
                result.success(null)
            }
            "pushClickedEvent" -> {
                val unitId = call.argument<String>("unitId")
                val elementId = call.argument<String?>("elementId")
                val additionalProperties = call.argument<Map<String, Any?>?>("additionalProperties")
                if (unitId != null) bridge?.pushClickedEvent(unitId, elementId, additionalProperties)
                result.success(null)
            }
            "getCoreDebugLevel" -> {
                result.success(bridge?.getCoreDebugLevel())
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
    // [additionalProperties] carries the ND SDK version stamp (nd_lib_v_*) to
    // forward to the ND SDK's viewed-with-extras path as additionalProperties.
    fun pushViewedEvent(unitId: String, additionalProperties: Map<String, Any?>?)

    // Report clicked event to CleverTap Core SDK.
    // [additionalProperties] carries the clicked action's attribution extras
    // (action_type, custom KVs, and BE-injected wzrk_* fields) to forward to the
    // ND SDK's element-clicked path as Core SDK additionalProperties.
    fun pushClickedEvent(unitId: String, elementId: String?, additionalProperties: Map<String, Any?>?)

    // Return the CleverTap Core SDK debug level (`CleverTapAPI.getDebugLevel()`),
    // or null if unavailable. Used by the Flutter SDK to align its own log
    // verbosity with the host's Core SDK unless the client set a level explicitly.
    fun getCoreDebugLevel(): Int?
}
