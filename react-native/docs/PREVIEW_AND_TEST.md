# Testing with "Preview and test"

The CleverTap dashboard has a "Preview and test" action for a Native Display
campaign. It sends a push notification to one chosen device. The push carries
the campaign payload, and the device renders the Native Display preview without
waiting for the real trigger event.

For this to work the device must first deliver its push token to CleverTap. A
Native Display app that only renders campaigns does not need push at all, so a
fresh integration usually has no push wiring. This guide covers the push setup
that "Preview and test" needs, on top of the normal Native Display setup in the
[main README](../README.md).

## How it works

1. The app asks the user for notification permission at startup.
2. The platform issues a push token (APNs on iOS, FCM on Android).
3. The CleverTap SDK forwards that token to the CleverTap backend.
4. On the dashboard you pick that device and trigger "Preview and test".
5. CleverTap sends a push to the token. The SDK shows it as a notification.
6. The user taps the notification. The campaign payload rides the push under the
   `wzrk_adunit` key. On tap the app reads that payload and hands it to the
   bridge, which renders the Native Display preview.

The preview renders on the tap, not on arrival. The payload only reaches the
renderer when the notification is tapped, so the app has to listen for the
push-clicked event and feed the payload in. See
[Render the preview on tap](#javascript---render-the-preview-on-tap) for the
JavaScript side and [Android setup](#android-setup) for the native side that
makes the click reach JavaScript.

Two things must line up for the push in step 5 to arrive:

- The device token must have reached the account you are testing from.
- That account must hold the matching push credentials. For iOS that is an APNs
  key or certificate. For Android that is the FCM / Firebase service account for
  the same Firebase project the app ships with.

## What the sample apps already have

The code and config below are already wired into the `example` app (NDExample).
Use them as the reference for your own app. The `example-rn076` app (ND076) has
the push-token setup, but not yet the render-on-tap wiring, and it still needs
its own credentials - see [Per-app status](#per-app-status).

### JavaScript - request push at startup

In [`example/App.tsx`](../example/App.tsx), inside the startup `useEffect`:

```ts
import { Platform } from 'react-native';
import CleverTap from 'clevertap-react-native';

if (Platform.OS === 'ios') {
  CleverTap.registerForPush();
} else {
  CleverTap.promptForPushPermission(true);
}
```

The two platforms need different calls:

- **iOS** - `registerForPush()` asks for notification permission, then registers
  for remote notifications. The APNs token is forwarded to CleverTap by
  `[CleverTap autoIntegrate]`, which the app calls in
  [`AppDelegate.swift`](../example/ios/NDExample/AppDelegate.swift).
- **Android** - `registerForPush()` is a no-op in the SDK on Android. The runtime
  POST_NOTIFICATIONS dialog comes from `promptForPushPermission(true)`. The FCM
  token is captured and forwarded by the SDK once Firebase is configured.

`registerForPush` runs after `autoIntegrate`, because `autoIntegrate` is called
synchronously in `didFinishLaunchingWithOptions` before React Native starts
loading the JavaScript bundle. So APNs swizzling is already in place by the time
the `useEffect` fires.

### JavaScript - render the preview on tap

The "Preview and test" push is not a server-fetched display unit. It carries the
config inside the push itself, under the `wzrk_adunit` key, and it only reaches
the app when the user taps the notification. `fetchNativeDisplays` and the
`CleverTapDisplayUnitsLoaded` event are a different channel (server-fetched
units), so they never see this payload. The app has to listen for the
push-clicked event and feed the payload to the bridge.

In [`example/App.tsx`](../example/App.tsx), inside the same startup `useEffect`:

```ts
const onPushClicked = (payload: Record<string, unknown> | null): void => {
  if (!payload) return;
  const adunit = payload.wzrk_adunit;
  if (typeof adunit === 'string' && adunit.length > 0) {
    NativeDisplayBridge.shared.processDisplayUnit(adunit);
  }
};
CleverTap.addListener(CleverTap.CleverTapPushNotificationClicked, onPushClicked);

return () => {
  CleverTap.removeListener(CleverTap.CleverTapPushNotificationClicked);
};
```

`processDisplayUnit` takes the raw `wzrk_adunit` string as-is. The parser reads
the `advanced-builder` wrapper and its `native_display_config` on its own, so no
unwrapping is needed. The parsed unit is cached and sent to every registered
`NativeDisplayBridgeListener`.

A tap can reach the app before the screen that shows the unit is mounted (for
example when the app opens on a different tab). The screen in
[`CleverTapIntegrationScreen.tsx`](../example/screens/CleverTapIntegrationScreen.tsx)
seeds from `NativeDisplayBridge.shared.getAllNativeDisplays()` on mount so a unit
that arrived first still shows.

For `CleverTapPushNotificationClicked` to fire on Android, the native side must
deliver the tapped push to the SDK. See
[Deliver the tapped push to the SDK](#2-deliver-the-tapped-push-to-the-sdk).

## iOS setup

### 1. Capability and entitlement

The app needs the Push Notifications capability. In the sample this is an
entitlements file with `aps-environment`:

- [`example/ios/NDExample/NDExample.entitlements`](../example/ios/NDExample/NDExample.entitlements)
  sets `aps-environment` to `development`.
- The Xcode project points at it through the `CODE_SIGN_ENTITLEMENTS` build
  setting on both the Debug and Release app configs.

Use `development` for debug builds and local testing. Use `production` for
TestFlight and App Store builds.

### 2. Background mode

[`example/ios/NDExample/Info.plist`](../example/ios/NDExample/Info.plist) declares
the remote-notification background mode:

```xml
<key>UIBackgroundModes</key>
<array>
	<string>remote-notification</string>
</array>
```

### 3. Signing

Push needs a real signing team, not automatic unsigned builds. The sample app
sets `DEVELOPMENT_TEAM` and a unique bundle id
(`com.clevertap.nativedisplay.sample`). For your own app, pick your own bundle id
and team, and make sure the matching App ID in the Apple Developer portal has
Push Notifications enabled.

### 4. APNs key on the dashboard

Upload an APNs auth key (or certificate) for your bundle id to the CleverTap
account you are testing from. TODO(verify): exact dashboard location to upload
the APNs key - see the CleverTap iOS push docs.

## Android setup

### 1. Permission and FCM service

[`example/android/app/src/main/AndroidManifest.xml`](../example/android/app/src/main/AndroidManifest.xml)
declares the runtime notification permission, a Firebase messaging service, and
the CleverTap notification intent service:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<service
  android:name=".MyFirebaseMessagingService"
  android:exported="false">
  <intent-filter>
    <action android:name="com.google.firebase.MESSAGING_EVENT" />
  </intent-filter>
</service>

<service
  android:name="com.clevertap.android.sdk.pushnotification.CTNotificationIntentService"
  android:exported="false">
  <intent-filter>
    <action android:name="com.clevertap.PUSH_EVENT" />
  </intent-filter>
</service>
```

The Firebase service
([`MyFirebaseMessagingService.kt`](../example/android/app/src/main/java/com/ndexample/MyFirebaseMessagingService.kt))
hands the FCM token and FCM messages to CleverTap:

```kotlin
override fun onNewToken(token: String) {
  CleverTapAPI.getDefaultInstance(applicationContext)?.pushFcmRegistrationId(token, true)
}

override fun onMessageReceived(message: RemoteMessage) {
  CTFcmMessageHandler().createNotification(applicationContext, message)
}
```

`CTNotificationIntentService` routes notification action-button taps back into
the SDK. The main notification tap is handled by the activity - see the next
step.

### 2. Deliver the tapped push to the SDK

The preview only renders on a tap, so the tap has to reach the SDK. The SDK
tracks a tap automatically when it opens a fresh activity. But the sample's
`MainActivity` uses `launchMode="singleTask"`, so when the app is already running
a tap is delivered to the existing activity through `onNewIntent` instead of
creating a new one. In that case the automatic path does not run, and the tap is
dropped unless the activity forwards it.

[`MainActivity.kt`](../example/android/app/src/main/java/com/ndexample/MainActivity.kt)
forwards the push payload to the SDK:

```kotlin
override fun onNewIntent(intent: Intent) {
  super.onNewIntent(intent)
  setIntent(intent)
  CleverTapAPI.getDefaultInstance(applicationContext)
    ?.pushNotificationClickedEvent(intent.extras)
}
```

`pushNotificationClickedEvent` makes the SDK raise its push-clicked callback. The
`clevertap-react-native` bridge forwards that callback to JavaScript as
`CleverTapPushNotificationClicked`, which the
[JavaScript handler](#javascript---render-the-preview-on-tap) reads to render the
preview. Without this override, a tap while the app is already running never
reaches JavaScript.

A cold-start tap (the app was not running) is handled by the SDK automatically,
because that path opens a fresh activity. Both cases end at the same JavaScript
handler.

### 3. Gradle wiring

- [`android/app/build.gradle`](../example/android/app/build.gradle) applies the
  `com.google.gms.google-services` plugin and declares
  `com.google.firebase:firebase-messaging:23.+`.
- [`android/build.gradle`](../example/android/build.gradle) adds the plugin to the
  classpath: `com.google.gms:google-services:4.4.1`.

No separate Firebase SDK install step is needed. Gradle pulls everything from
Maven on the next sync.

### 4. google-services.json

Place a `google-services.json` at `android/app/google-services.json`. It must
contain a client whose `package_name` matches the app's `applicationId`. The
sample's `applicationId` is `com.ndexample`, and the committed
`google-services.json` has a matching client. The build fails at the
google-services plugin step until this file is present.

### 5. FCM credentials on the dashboard

The CleverTap account must hold the push credentials for the same Firebase
project the app's `google-services.json` points at. If the app uses Firebase
project `X`, upload project `X`'s FCM service account (or server key) to the
CleverTap account. A token registered from one Firebase project cannot be
delivered with another project's credentials. TODO(verify): exact dashboard
location to upload the FCM / Firebase service account - see the CleverTap Android
push docs.

## Confirm the token reached the dashboard

1. Run the app on a real device and accept the notification prompt. The iOS
   Simulator cannot receive APNs pushes, so use a physical device for iOS.
2. Turn on CleverTap debug logs to watch the token get forwarded. The sample app
   already calls `CleverTap.setDebugLevel(3)` on iOS in `AppDelegate.swift`.
   TODO(verify): exact log line that prints the registered token.
3. On the dashboard, confirm the device shows up for the test user. TODO(verify):
   where the registered device / token appears in the dashboard.

## Trigger "Preview and test"

Open the Native Display campaign, choose the device you just registered, and send
the test push. TODO(verify): exact dashboard navigation for "Preview and test"
and how the target device is selected - see the CleverTap Native Display docs.

The push arrives as a notification. Tap it to render the preview. If nothing
renders on tap, see [Troubleshooting](#troubleshooting).

## Per-app status

| App | RN | Android package | iOS bundle id | Push ready? |
|---|---|---|---|---|
| `example` (NDExample) | 0.85.3 | `com.ndexample` | `com.clevertap.nativedisplay.sample` | Yes - `google-services.json` present, iOS team and entitlement set. |
| `example-rn076` (ND076) | 0.76 | `com.nd076` | `org.reactjs.native.example.ND076` | Not yet - see below. |

`example-rn076` has the push-token setup wired, but still needs:

- **Render-on-tap wiring** - the three pieces that render the preview on a tap are
  not in `example-rn076` yet: the `CleverTapPushNotificationClicked` listener in
  `App.tsx`, the `onNewIntent` override in `MainActivity`, and the
  `CTNotificationIntentService` entry in the manifest. Port them from `example`
  using the snippets above. Without them the push arrives as a notification but
  nothing renders on tap.
- **Android** - a `google-services.json` at
  `example-rn076/android/app/google-services.json`. The current
  `google-services.json` used by `example` does not contain a `com.nd076` client,
  so either add a `com.nd076` client to a Firebase project and download a fresh
  file, or change the app's `applicationId` to a package that an existing file
  already covers.
- **iOS** - a real bundle id and `DEVELOPMENT_TEAM`. The project still uses the
  React Native default bundle id and has no signing team, so it cannot be signed
  for push as-is.

## Note on the RN 0.85 prebuilt core

Unrelated to push, but it bites when you rebuild `example` after changing native
deps. React Native 0.85 defaults to prebuilt React Native Core, which does not
link against from-source Fabric pods built in Debug. The sample's
[`Podfile`](../example/ios/Podfile) pins `RCT_USE_PREBUILT_RNCORE = '0'` to build
the core from source and avoid "Undefined symbols" at link time. Re-run
`pod install` after changing that setting. `example-rn076` (RN 0.76) predates the
prebuilt default and does not need this.

## Troubleshooting

**The push never arrives.**

1. Real device, not a simulator (iOS cannot receive APNs on the Simulator).
2. Notification permission was granted. Check the OS settings for the app.
3. The token reached the account - see
   [Confirm the token reached the dashboard](#confirm-the-token-reached-the-dashboard).
4. The account holds the matching push credentials (APNs key for iOS, FCM service
   account for the app's Firebase project on Android).

**iOS build fails to sign.**
The App ID needs Push Notifications enabled in the Apple Developer portal, and
the bundle id and `DEVELOPMENT_TEAM` must be set. Automatic unsigned builds
cannot carry the push entitlement.

**Android build fails at the google-services step.**
`google-services.json` is missing or its `package_name` does not match the app's
`applicationId`. See [google-services.json](#4-google-servicesjson).

**The push arrives as a notification but nothing renders on tap.**
The preview renders on the tap, so the tap has to reach JavaScript. Check, in
order:

1. The app listens for `CleverTapPushNotificationClicked` and calls
   `processDisplayUnit` with the `wzrk_adunit` payload - see
   [Render the preview on tap](#javascript---render-the-preview-on-tap).
2. On Android, `MainActivity.onNewIntent` forwards the payload to
   `pushNotificationClickedEvent` - see
   [Deliver the tapped push to the SDK](#2-deliver-the-tapped-push-to-the-sdk).
   Without it, a tap while the app is already running never reaches JavaScript.
   In logcat a working tap shows the SDK handling the click; a dropped tap shows
   the app resuming with no click event.
3. A listener is registered and `<NativeDisplayView />` is drawn for the units
   received. See the main README's
   [troubleshooting section](../README.md#faq-and-troubleshooting).

Note that `fetchNativeDisplays` and `CleverTapDisplayUnitsLoaded` do not deliver
the preview. They are the server-fetched channel. The preview rides the push and
only arrives through the push-clicked path above.
