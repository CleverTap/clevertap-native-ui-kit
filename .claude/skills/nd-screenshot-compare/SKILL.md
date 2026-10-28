---
name: nd-screenshot-compare
description: Run the CleverTap Native Display (ND) cross-platform screenshot comparison. Fires the 22 canonical CleverTap events on each sample app, captures per-event screenshots across frameworks (Flutter, native, RN), and segregates them into a reviewable folder ~/Desktop/nd-screenshots-review/<os>/<event>/<framework>.png so a human can diff Flutter vs native vs RN side-by-side on Android and iOS. Use when asked to compare/diff ND rendering across platforms, validate cross-platform parity, or produce a screenshot review bundle.
---

# ND Cross-Platform Screenshot Comparison

Produce a reviewable bundle where, for every CleverTap event and every OS, you can
eyeball each framework's rendering side-by-side.

## Output layout

```
~/Desktop/nd-screenshots-review/
├── README.txt
├── android/
│   ├── header1/
│   │   ├── flutter.png
│   │   ├── native.png
│   │   └── rn.png
│   ├── header2/ ...
│   └── home/
└── ios/
    ├── header1/
    │   ├── flutter.png
    │   ├── native.png
    │   └── rn.png
    └── ...
```

- `os` ∈ {`android`, `ios`}
- `event` = the fired CleverTap event (22 canonical events, below)
- `framework` ∈ {`flutter`, `native`, `rn`}
- There is **no** per-platform top folder beyond `os`. Each event folder holds the
  frameworks together so they diff cleanly.

## The 22 canonical events (order and casing matter)

```
header1 header2 header3 header4 header5
footer1 footer2 footer3 footer4 footer5
nps topi kk mm ii iip ss cptest hi viewed html2 home
```

All sample apps fire these in this exact order and name each screenshot after the event.

---

## Prerequisites

### Devices / simulators (boot BEFORE running)
- An Android emulator booted. Verify: `flutter devices`, `adb devices`.
- An iOS simulator booted. Verify: `xcrun simctl list devices booted`.
- `flutter devices` lists the device IDs you pass as `-d <deviceId>` to `flutter drive`.

### Android emulator hygiene (recommended)
Disable animations and let the emulator warm up before capture to avoid System-UI ANRs:
```
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
```

### CleverTap staging credentials (LOCAL ONLY — DO NOT COMMIT)
All sample apps must point at the same staging account or the content will not match.

```
ACCOUNT_ID = 468-RZW-ZK6Z
TOKEN      = 012-b64
REGION     = sk1-staging-25
```

- **Android** — `<meta-data>` entries in each app's `AndroidManifest.xml`:
  - `flutter-sample/android/app/src/main/AndroidManifest.xml` — already set.
  - `android-sample/app/src/main/AndroidManifest.xml` — keys present; **verify the
    values** are the staging credentials above before running.
  - Keys: `CLEVERTAP_ACCOUNT_ID`, `CLEVERTAP_TOKEN`, `CLEVERTAP_REGION`.
- **iOS** — `Info.plist` keys `CleverTapAccountID` / `CleverTapToken` / `CleverTapRegion`:
  - `flutter-sample/ios/Runner/Info.plist`
  - `ios-sample/NativeDisplaySample/Info.plist`
  - The iOS `AppDelegate` already calls `CleverTap.autoIntegrate()`.

> ⚠️ These are staging secrets. Keep them in your local working tree only. **Never
> commit** credential changes to the sample manifests / Info.plists.

Run `scripts/check_prereqs.sh` to sanity-check devices and that credentials look set.

---

## Capture commands (per framework)

> **Run each capture TWICE.** The first run populates the image cache; the second run
> renders with a warm cache and is the one you keep. See *Cache warming* below.

### Flutter (flutter-sample) — Android or iOS
`events_screenshots_test.dart` fires all 22 events; the driver writes one PNG per event.

```bash
cd flutter-sample
ND_SCREENSHOT_DIR=<dir> flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/events_screenshots_test.dart \
  --dart-define=ND_AUTOMATION=true -d <deviceId>
```

- In-app notifications are suppressed in automation: `ND_AUTOMATION=true` makes
  `main.dart` call `CleverTapPlugin.discardInAppNotifications()`.
- The driver (`flutter-sample/test_driver/integration_test.dart`) writes PNGs named
  `flutter-events-<event>.png` into `ND_SCREENSHOT_DIR`.
- Works on any Android API level and on iOS simulators.
- Run once per OS: once with an Android `<deviceId>`, once with an iOS `<deviceId>`.

Helper: `scripts/capture_flutter.sh <deviceId> <outDir>` (runs twice).

### Android native (android-sample) — Compose events
```bash
cd android-sample
./gradlew :app:automationScreenshots \
  -Pandroid.testInstrumentationRunnerArguments.class=com.clevertap.android.nativeui.sample.automation.EventsScreenshotsTest#composeEventsScreen_fireAllEvents
```

- Artifacts land in:
  `app/build/outputs/connected_android_test_additional_output/debugAndroidTest/connected/<AVD>/composeEventsScreen_fireAllEvents_<event>.png`
- Requires **espresso 3.7.0 + androidx.test 1.3.0** (already pinned in
  `android-sample/gradle/libs.versions.toml`). Older espresso crashes on API 36/37 with
  `NoSuchMethodException: InputManager.getInstance`.
- In-apps are suspended in `SampleApplication` via `cleverTapApi.suspendInAppNotifications()`.
- Disable emulator animations and let it warm up (see Prerequisites) to avoid System-UI ANRs.

Helper: `scripts/capture_android_native.sh <outDir>` (runs the task, locates the AVD
output dir, copies PNGs into `<outDir>`).

### iOS native (ios-sample) — SwiftUI events
> The UIKit variant is currently flaky — use the SwiftUI test only.

```bash
cd ios-sample
xcodebuild test -scheme NativeDisplaySample \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -only-testing NativeDisplaySampleUITests/EventsScreenshotsTests/test_swiftUIEventsScreen_fireAllEvents \
  -resultBundlePath /tmp/ios_ev.xcresult
./pull_screenshots.sh /tmp/ios_ev.xcresult <outDir>   # extracts swiftui-events-<event>.png
```

- `ios-sample` uses Swift Package Manager — there is **no CocoaPods / Podfile**.
- `pull_screenshots.sh` (in `ios-sample/`) exports attachments from the `.xcresult` and
  renames them to `swiftui-events-<event>.png`.
- Run twice for a warm image cache. Delete `/tmp/ios_ev.xcresult` between runs.
- Get a booted sim UDID with: `xcrun simctl list devices booted`.

Helper: `scripts/capture_ios_native.sh <UDID> <outDir>` (runs twice).

### RN (React Native) — Android
The RN example (`react-native/example`) has no test harness, so Android is driven by adb
UI automation: tap the event input, type the event, submit via the IME ENTER action
(the input uses `returnKeyType="send"` + `onSubmitEditing`), then screencap.

```bash
scripts/capture_rn_android.sh <serial> <outDir> [settle] [package] [activity]
# defaults: settle=12  package=com.ndexample  activity=.MainActivity
```

- **Never sends BACK** — the RN app uses in-app navigation, so BACK at the root drops to
  the launcher. It verifies the app is foreground before each event and recovers if not.
- Produces `rn-events-<event>.png`.
- Preconditions: the RN example is built, installed and **launched on the Events screen**;
  Metro is running (debug build).

### RN (React Native) — iOS
`simctl` can screenshot but cannot tap/type, and there's no XCUITest harness — so the APP
drives itself. The example registers an **in-app automation mode** (SDK-6264) that fires
one event when it receives the deep link `ndautomation://event?name=<eventName>`. The
helper opens that URL once per event (full pacing control), waits `settle`, and captures
with `xcrun simctl io screenshot`.

```bash
scripts/capture_rn_ios.sh <UDID> <outDir> [settle] [bundleId]
# defaults: settle=12  bundleId=com.clevertap.nativedisplay.sample
```

- Produces `rn-events-<event>.png`.
- Preconditions: the RN example is built, installed and launched; Metro is running; the
  **automation mode (SDK-6264) is present** in the example app.
- Get a booted sim UDID with `xcrun simctl list devices booted`.

---

## Segregation (final stage)

Once the per-framework capture dirs exist, map everything into the review layout with:

```bash
scripts/segregate.sh \
  --flutter-android <dir with flutter-events-*.png captured on an ANDROID device> \
  --native-android  <dir with composeEventsScreen_fireAllEvents_*.png> \
  --flutter-ios     <dir with flutter-events-*.png captured on an iOS sim> \
  --native-ios      <dir with swiftui-events-*.png> \
  --rn-android      <dir with rn-events-*.png captured on an ANDROID device> \
  --rn-ios          <dir with rn-events-*.png captured on an iOS sim> \
  [--out ~/Desktop/nd-screenshots-review]
```

Mapping performed:

| Source file pattern                               | Destination                          |
|---------------------------------------------------|--------------------------------------|
| `flutter-events-<event>.png` (Android capture)    | `android/<event>/flutter.png`        |
| `composeEventsScreen_fireAllEvents_<event>.png`   | `android/<event>/native.png`         |
| `flutter-events-<event>.png` (iOS capture)        | `ios/<event>/flutter.png`            |
| `swiftui-events-<event>.png`                      | `ios/<event>/native.png`             |
| `rn-events-<event>.png` (Android capture)         | `android/<event>/rn.png`             |
| `rn-events-<event>.png` (iOS capture)             | `ios/<event>/rn.png`                 |

`segregate.sh` also writes `README.txt` at the review root describing the layout.

---

## Caveats

### Per-event content can differ across platforms (NOT a renderer bug)
A single event can resolve to **different campaign content per platform** because of
dashboard A/B tests, pivots, or platform-targeted variants. If `header3` looks different
on Android vs iOS, confirm in the dashboard whether distinct variants are being served
before filing it as a rendering parity bug.

### Cache warming (why we run twice)
Images may be **cold on first run**, so the first capture can show placeholders or
partially-loaded media. The accepted workaround is to run each capture **twice** and keep
the second (warm-cache) pass. An incremental URL cache-warm (pre-fetching each config's
image URLs before capture) is a **planned improvement** that will make a single pass
sufficient.

---

## End-to-end quick run

```bash
S=.claude/skills/nd-screenshot-compare/scripts

# 0. Prereqs
bash $S/check_prereqs.sh

# 1. Capture (run each twice; helpers already do the double-run)
bash $S/capture_flutter.sh       <androidDeviceId> /tmp/nd/flutter-android
bash $S/capture_flutter.sh       <iosDeviceId>     /tmp/nd/flutter-ios
bash $S/capture_android_native.sh                   /tmp/nd/native-android
bash $S/capture_ios_native.sh    <iosUDID>         /tmp/nd/native-ios
bash $S/capture_rn_android.sh    <androidSerial>   /tmp/nd/rn-android
bash $S/capture_rn_ios.sh        <iosUDID>         /tmp/nd/rn-ios

# 2. Segregate into the review bundle
bash $S/segregate.sh \
  --flutter-android /tmp/nd/flutter-android \
  --native-android  /tmp/nd/native-android \
  --flutter-ios     /tmp/nd/flutter-ios \
  --native-ios      /tmp/nd/native-ios \
  --rn-android      /tmp/nd/rn-android \
  --rn-ios          /tmp/nd/rn-ios

open ~/Desktop/nd-screenshots-review
```

---

## React Native specifics

The RN example is at `react-native/example`. Two different driving mechanisms (see the
capture sections above):

- **Android** — adb UI automation (`capture_rn_android.sh`), driving the real on-screen
  input + IME submit. Works against the stock example app; no app changes required.
- **iOS** — in-app automation mode triggered by the deep link
  `ndautomation://event?name=<event>` (`capture_rn_ios.sh`), because simctl can't tap/type.
  This requires the example's automation mode (**SDK-6264**). If that change isn't present
  in the RN example you're running, the deep link is a no-op and the shots will be blank —
  build an example that includes it.

Both drivers need the RN example **built, installed, launched** with Metro running, pointed
at the SAME staging credentials as the other samples. Wire `468-RZW-ZK6Z` / `012-b64` /
`sk1-staging-25` into the RN example's native config **LOCAL ONLY**:
- Android: `react-native/example/android/app/src/main/res/values/strings.xml`
- iOS: `react-native/example/ios/**/Info.plist`

> ⚠️ Same rule as the other samples — never commit RN credential changes.
