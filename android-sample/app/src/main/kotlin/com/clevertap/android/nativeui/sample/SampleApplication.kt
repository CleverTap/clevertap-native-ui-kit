package com.clevertap.android.nativeui.sample

import android.app.Application
import android.util.Log
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.sdk.ActivityLifecycleCallback
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.sdk.CleverTapAPI.LogLevel.VERBOSE

/**
 * Sample application.
 *
 * Initializes CleverTap and the NativeDisplayBridge at app startup so that
 * any screen can observe display units without repeating setup.
 */
class SampleApplication : Application() {

    companion object {
        private const val TAG = "SampleApplication"
    }

    override fun onCreate() {
        // aarrggbb vs rrggbbaa -> #12341256
        CleverTapAPI.setDebugLevel(VERBOSE)
        ActivityLifecycleCallback.register(this)
        super.onCreate()

        // 1. Initialize NativeDisplayBridge (auto-wire mode)
        val bridge = NativeDisplayBridge.initialize(this)

        // 2. Get CleverTap default instance (auto-created from manifest metadata)
        val cleverTapApi = CleverTapAPI.getDefaultInstance(this)

        if (cleverTapApi != null) {
            // 3. Bind bridge to CleverTap — wires display unit callbacks
            bridge.bind(cleverTapApi)
            // 4. Request Native Display units from server
            bridge.fetchNativeDisplays(cleverTapApi)
            Log.d(TAG, "Bridge initialized, bound, and fetch requested")

            cleverTapApi.onUserLogin(mutableMapOf<String, Any>("Name" to "Lalit P", "Email" to "lalit@lalit@nfndnnsf.com"))
        } else {
            Log.w(TAG, "CleverTapAPI.getDefaultInstance() returned null — check manifest metadata")
        }
    }
}
