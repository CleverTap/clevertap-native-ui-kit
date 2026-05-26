package com.clevertap.flutter.clevertap_native_display_sample

import android.app.Application
import android.util.Log
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridgeListener
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.sdk.ActivityLifecycleCallback
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.sdk.CleverTapAPI.LogLevel.VERBOSE

/**
 * Sample application.
 *
 * Initializes CleverTap and the NativeDisplayBridge at app startup so that
 * MainActivity can observe display units and push them to Flutter via EventChannel.
 */
class SampleApplication : Application() {

    companion object {
        private const val TAG = "SampleApplication"

        var cleverTapApi: CleverTapAPI? = null
        var nativeDisplayBridge: NativeDisplayBridge? = null

        /**
         * Set by MainActivity once the EventChannel sink is ready.
         * Called on the main thread whenever new units arrive.
         */
        var onUnitsLoaded: ((List<NativeDisplayUnit>) -> Unit)? = null
    }

    override fun onCreate() {
        CleverTapAPI.setDebugLevel(VERBOSE)
        ActivityLifecycleCallback.register(this)
        super.onCreate()

        // Initialize NativeDisplayBridge (auto-wire mode)
        val bridge = NativeDisplayBridge.initialize(this)
        nativeDisplayBridge = bridge

        // Get CleverTap default instance (auto-created from manifest metadata)
        val ct = CleverTapAPI.getDefaultInstance(this)
        cleverTapApi = ct

        if (ct != null) {
            // Bind bridge to CleverTap — wires display unit callbacks
            bridge.bind(ct)

            // Register listener — delivers units to MainActivity's EventChannel
            bridge.addListener(object : NativeDisplayBridgeListener {
                override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                    Log.d(TAG, "Received ${units.size} Native Display unit(s)")
                    onUnitsLoaded?.invoke(units)
                }
            })

            // Request Native Display units from server
            bridge.fetchNativeDisplays(ct)
            Log.d(TAG, "Bridge initialized, bound, and fetch requested")
        } else {
            Log.w(TAG, "CleverTapAPI.getDefaultInstance() returned null — check manifest metadata")
        }
    }
}
