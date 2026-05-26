package com.clevertap.flutter.clevertap_native_display_sample

import android.app.Application
import android.util.Log
import com.clevertap.android.sdk.ActivityLifecycleCallback
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.sdk.CleverTapAPI.LogLevel.VERBOSE
import com.clevertap.android.sdk.displayunits.DisplayUnitListener
import com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit

class SampleApplication : Application() {

    companion object {
        private const val TAG = "SampleApplication"

        var cleverTapApi: CleverTapAPI? = null

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
                    val jsonList = units.mapNotNull { it.jsonObject?.toString() }
                        .filter { it.isNotEmpty() }
                    onUnitsLoaded?.invoke(jsonList)
                }
            })
            Log.d(TAG, "CleverTap initialized, display unit listener registered")
        } else {
            Log.w(TAG, "CleverTapAPI.getDefaultInstance() returned null — check manifest metadata")
        }
    }
}
