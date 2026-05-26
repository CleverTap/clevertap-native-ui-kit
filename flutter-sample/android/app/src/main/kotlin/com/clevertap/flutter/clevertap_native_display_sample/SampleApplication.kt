package com.clevertap.flutter.clevertap_native_display_sample

import android.app.Application
import android.util.Log
import com.clevertap.android.sdk.ActivityLifecycleCallback
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.sdk.CleverTapAPI.LogLevel.VERBOSE
import com.clevertap.android.sdk.displayunits.DisplayUnitListener
import com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit
import org.json.JSONObject

class SampleApplication : Application() {

    companion object {
        private const val TAG = "SampleApplication"

        var cleverTapApi: CleverTapAPI? = null

        /** Last received batch — replayed to new EventChannel sinks so units aren't lost. */
        var cachedUnitJsons: List<String> = emptyList()

        /** Set by MainActivity once the EventChannel sink is ready. */
        var onUnitsLoaded: ((List<String>) -> Unit)? = null
    }

    override fun onCreate() {
        CleverTapAPI.setDebugLevel(VERBOSE)
        ActivityLifecycleCallback.register(this)
        super.onCreate()

        val ct = CleverTapAPI.getDefaultInstance(this)
        cleverTapApi = ct

        if (ct != null) {
            ct.setDisplayUnitListener(object : DisplayUnitListener {
                override fun onDisplayUnitsLoaded(units: ArrayList<CleverTapDisplayUnit>) {
                    Log.d(TAG, "Received ${units.size} display unit(s)")
                    val jsonList = units.mapNotNull { unit ->
                        extractNdConfigJson(unit.jsonObject)
                    }.filter { it.isNotEmpty() }
                    Log.d(TAG, "Extracted ${jsonList.size} NativeDisplayConfig JSON(s)")
                    cachedUnitJsons = jsonList
                    onUnitsLoaded?.invoke(jsonList)
                }
            })
            Log.d(TAG, "CleverTap initialized, display unit listener registered")
        } else {
            Log.w(TAG, "CleverTapAPI.getDefaultInstance() returned null — check manifest metadata")
        }
    }

    /**
     * Mirrors NativeDisplayConfigParser detection strategy (3 attempts in order):
     *
     * 1. `native_display_config` top-level key → parse its value as NativeDisplayConfig JSON
     * 2. `custom_kv.nd_config` string value → that string IS the NativeDisplayConfig JSON
     * 3. `root` top-level key present → entire JSON object is treated as NativeDisplayConfig
     *
     * Returns null if the unit does not contain a recognizable NativeDisplayConfig payload.
     */
    private fun extractNdConfigJson(json: JSONObject?): String? {
        if (json == null) return null

        // Strategy 1: native_display_config key
        json.optJSONObject("native_display_config")?.let { ndConfig ->
            Log.d(TAG, "Found NativeDisplayConfig via 'native_display_config' key")
            return ndConfig.toString()
        }

        // Strategy 2: custom_kv.nd_config string
        json.optJSONObject("custom_kv")
            ?.optString("nd_config", null)
            ?.takeIf { it.isNotEmpty() }
            ?.let { ndConfigStr ->
                Log.d(TAG, "Found NativeDisplayConfig via 'custom_kv.nd_config'")
                return ndConfigStr
            }

        // Strategy 3: root key present — entire JSON is NativeDisplayConfig
        if (json.has("root")) {
            Log.d(TAG, "Found NativeDisplayConfig via top-level 'root' key")
            return json.toString()
        }

        Log.w(TAG, "Display unit does not contain a NativeDisplayConfig payload, skipping")
        return null
    }
}
