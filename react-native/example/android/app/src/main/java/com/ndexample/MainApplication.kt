package com.ndexample

import android.app.Application
import com.clevertap.android.sdk.ActivityLifecycleCallback
import com.clevertap.android.sdk.CleverTapAPI
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost

class MainApplication : Application(), ReactApplication {

  override val reactHost: ReactHost by lazy {
    getDefaultReactHost(
      context = applicationContext,
      packageList =
        PackageList(this).packages.apply {
          // Packages that cannot be autolinked yet can be added manually here, for example:
          // add(MyReactNativePackage())
        },
    )
  }

  override fun onCreate() {
    super.onCreate()
    // Mirror the iOS AppDelegate's launch sequence one-for-one:
    //   iOS                                          | Android
    //   -------------------------------------------- | -------------------------------------------------
    //   CleverTap.setDebugLevel(2)                   | CleverTapAPI.setDebugLevel(LogLevel.DEBUG)  (both = level 2)
    //   CleverTap.autoIntegrate()                    | ActivityLifecycleCallback.register(this)
    //   CleverTapReactManager...applicationDidLaunch | clevertap-react-native autolinks its ReactPackage,
    //                                                |   so no explicit RN-bridge call is needed here.
    CleverTapAPI.setDebugLevel(CleverTapAPI.LogLevel.DEBUG)
    ActivityLifecycleCallback.register(this)
    loadReactNative(this)
  }
}
