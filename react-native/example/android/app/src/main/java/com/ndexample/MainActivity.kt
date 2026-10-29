package com.ndexample

import android.content.Intent
import com.clevertap.android.sdk.CleverTapAPI
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate

class MainActivity : ReactActivity() {

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  override fun getMainComponentName(): String = "NDExample"

  /**
   * Returns the instance of the [ReactActivityDelegate]. We use [DefaultReactActivityDelegate]
   * which allows you to enable New Architecture with a single boolean flags [fabricEnabled]
   */
  override fun createReactActivityDelegate(): ReactActivityDelegate =
      DefaultReactActivityDelegate(this, mainComponentName, fabricEnabled)

  /**
   * The launch mode is singleTask. When the app is already running and the user
   * taps a CleverTap push, Android delivers the notification intent here instead
   * of creating a new activity. CleverTap's automatic click tracking only runs
   * when a new activity is created, so it would miss this tap. Forwarding the
   * extras makes the SDK raise its push-clicked callback. The bridge then sends
   * CleverTapPushNotificationClicked to JS, where App.tsx reads wzrk_adunit and
   * renders the native display unit.
   */
  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    CleverTapAPI.getDefaultInstance(applicationContext)
      ?.pushNotificationClickedEvent(intent.extras)
  }
}
