package com.clevertap.flutter.clevertap_native_display_sample

import android.app.Application
import com.clevertap.android.sdk.ActivityLifecycleCallback
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.sdk.CleverTapAPI.LogLevel.VERBOSE

class SampleApplication : Application() {
    override fun onCreate() {
        CleverTapAPI.setDebugLevel(VERBOSE)
        ActivityLifecycleCallback.register(this)
        super.onCreate()
    }
}
