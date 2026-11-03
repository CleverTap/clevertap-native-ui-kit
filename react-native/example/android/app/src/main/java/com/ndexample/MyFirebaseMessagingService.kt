package com.ndexample

import android.util.Log
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.sdk.pushnotification.fcm.CTFcmMessageHandler
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

// Hands the FCM token and FCM messages to CleverTap.
// onNewToken forwards the token. The dashboard needs it for "Preview and test".
// onMessageReceived lets CleverTap render the push, including Native Display.
class MyFirebaseMessagingService : FirebaseMessagingService() {

  override fun onNewToken(token: String) {
    CleverTapAPI.getDefaultInstance(applicationContext)?.pushFcmRegistrationId(token, true)
  }

  override fun onMessageReceived(message: RemoteMessage) {
    try {
      CTFcmMessageHandler().createNotification(applicationContext, message)
    } catch (t: Throwable) {
      Log.d("MyFirebaseMsgService", "Error parsing FCM message", t)
    }
  }
}
