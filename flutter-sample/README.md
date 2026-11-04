# CleverTap Native Display — Flutter sample app

A runnable demo of the [`clevertap_native_display`](../flutter/README.md) Flutter plugin and its add-ons. It shows both integration styles side by side: full CleverTap integration (slot-based, server-driven) and standalone rendering from local JSON.

← See the [Flutter Integration guide](../docs/INTEGRATION_FLUTTER.md) for the step-by-step setup this sample demonstrates.

## What it demonstrates

- **One-call CleverTap integration** via `NativeDisplaySlotManager.instance.bindCleverTap()` (from `clevertap_plugin_with_native_display`).
- **Slot placement** — `NativeDisplaySlot(slotId: ...)` widgets interleaved into a scrolling feed.
- **Standalone rendering** — parsing local JSON with `NativeDisplayConfig.fromJson(...)` and drawing it with `NativeDisplayView(config: ...)`.
- **Optional VIDEO / HTML elements** — the add-ons registered in `main()`.
- **Attribution** — Notification Viewed / Clicked / element-clicked forwarded to `clevertap_plugin`.

## The four tabs

The app is a bottom-nav shell (`lib/app.dart`) with four tabs:

| Tab | Screen | What it shows |
|-----|--------|---------------|
| **Events** | `clevertap_integration_screen.dart` | Fire arbitrary CleverTap events, watch the returned Native Display units render on a canvas, and follow a live event log (fired / viewed / clicked / action). This screen calls `bindCleverTap()` once in `initState` — the single integration point for the whole app. |
| **Slots** | `slot_demo_screen.dart` | A content feed with real `NativeDisplaySlot` widgets at fixed positions. "Fetch Slot Data" fires the slot-targeted events; returned units are routed to each slot by `slot_id`. Empty slots show a dashed "Ad" placeholder. "Clear slots" calls `clearAll()`. |
| **Browser** | `test_browser_screen.dart` | Standalone rendering: steps through bundled test-config JSON files, each parsed and drawn with `NativeDisplayView(config: ...)` — no CleverTap account needed. |
| **More** | `more_menu_screen.dart` | A menu of focused demos: Bridge Integration (Core SDK bridge with mock data), Banner Showcase, Arrangements (all 7 strategies), Animations, Home Screen layout, and Other Demos (gallery, e-commerce, social, dashboard). |

## Startup wiring

`lib/main.dart` shows the recommended startup sequence:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  CleverTapPlugin.setDebugLevel(3);
  NativeDisplayBridge.setLogLevel(NDLogLevel.verbose);

  // Opt in to the optional VIDEO and HTML elements.
  registerClevertapVideoRenderer();
  registerClevertapHtmlRenderer();

  runApp(const NativeDisplaySampleApp());
}
```

`bindCleverTap()` itself is called once from the Events tab (`CleverTapIntegrationScreen`), which is the single sink for incoming display units; the Slots tab just drops `NativeDisplaySlot` widgets.

## Running the app

```bash
cd flutter-sample
flutter pub get
flutter run            # pick a device, or:
flutter run -d <id>    # flutter devices to list ids
```

The sample resolves the four plugin packages from sibling paths in the monorepo (see `pubspec.yaml` `dependency_overrides`), so no `pub.dev` publish is required to build it locally.

### CleverTap credentials

The Events and Slots tabs talk to a live CleverTap account. Configure your Account ID / Token / Region the standard `clevertap_plugin` way (Android `AndroidManifest.xml`, iOS `Info.plist`). The Browser and most of the More demos render local JSON and work with no account.

### Android / iOS

- **Android:** `flutter run -d <android-device>`. Minimum API 23.
- **iOS:** `flutter run -d <ios-device>` (run `pod install` in `ios/` if prompted). Minimum iOS 15.

## Learn more

- [Flutter Integration guide](../docs/INTEGRATION_FLUTTER.md)
- [Core package README](../flutter/README.md)
- [`clevertap_plugin_with_native_display`](../clevertap_plugin_with_native_display/README.md)
- [JSON Structure Reference](../docs/JSON_STRUCTURE_REFERENCE.md)
