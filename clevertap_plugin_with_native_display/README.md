# CleverTap Native Display — integration add-on

Package: `clevertap_plugin_with_native_display`

## What this is

One-call CleverTap integration for the [`clevertap_native_display`](../flutter/README.md) slot system. It bridges `clevertap_plugin` (the CleverTap Core SDK) to the pure-Dart Native Display renderer.

The core package is pure Dart and has **no dependency on `clevertap_plugin`**, so on its own a host must hand-wire four things: the display-units handler, the cached-units pull, slot-sync, and attribution for every rendered unit. This add-on does all of it in one call — `bindCleverTap()` — mirroring what `CleverTapAutoWire` does inside the native Android/iOS SDKs.

### Why is this a separate package?

Dart has no `compileOnly`/weak-linking or runtime reflection, so the core package cannot *optionally* depend on `clevertap_plugin` the way the native SDKs do. Splitting the CleverTap wiring into this add-on is how Flutter keeps the core **standalone-safe** — usable with no CleverTap account and no `clevertap_plugin` dependency. Add this package only when you want full CleverTap integration.

## Quick facts

| Question | Answer |
|---|---|
| Minimum versions | Flutter 3.24+, Dart 3.5+ |
| Pulls in | `clevertap_native_display` + `clevertap_plugin` ^4.3.0 |
| Provides | `bindCleverTap()` / `unbindCleverTap()` extension on `NativeDisplaySlotManager` |

## Install

```yaml
dependencies:
  clevertap_native_display: ^1.0.0
  clevertap_plugin_with_native_display: ^1.0.0
  clevertap_plugin: ^4.3.0
```

```bash
flutter pub get
```

## Usage — the 3-step flow

```dart
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_plugin_with_native_display/clevertap_plugin_with_native_display.dart'
    show CleverTapNativeDisplayBinding;

// 1. Get the slot manager singleton
final manager = NativeDisplaySlotManager.instance;

// 2. Wire CleverTap once at startup (after clevertap_plugin is initialized)
await manager.bindCleverTap();

// 3. Drop NativeDisplaySlot(slotId: ...) widgets anywhere in the tree
NativeDisplaySlot(slotId: 'hero_banner');
```

After `bindCleverTap()`, slots render server-driven units automatically and attribution (viewed / clicked / element-clicked) is reported to the Core SDK — no per-widget callbacks required.

## What `bindCleverTap()` wires

In one call it:

1. **Push** — registers the display-units handler → routes incoming units to slots.
2. **Pull** — pulls already-cached units (`CleverTapPlugin.getAllDisplayUnits()`) so slots mounted at startup fill immediately.
3. **Slot-sync** — wires `onSlotSync` out → `CleverTapPlugin.recordEvent`.
4. **Attribution** — installs the global attribution sink → `pushDisplayUnitViewedEvent` / `pushDisplayUnitClickedEvent` / `pushDisplayUnitElementClickedEvent`.

Per-widget `onNotificationViewed` / `onNotificationClicked` still take precedence when a specific widget needs custom handling.

### Parameters

```dart
Future<void> bindCleverTap({
  CleverTapPlugin? plugin,                        // inject a specific instance (defaults to the singleton)
  void Function(List<dynamic> rawUnits)? onUnits, // observe every raw display-unit batch
});
```

`onUnits` is an optional observer called with every raw display-unit batch (push and the initial cached pull). Useful for hosts that also render or inspect units outside the slot system — a debug canvas, logging, etc. Slot routing happens regardless; this is purely additive.

```dart
await manager.bindCleverTap(
  onUnits: (rawUnits) {
    debugPrint('received ${rawUnits.length} unit(s)');
  },
);
```

## Tear-down

```dart
manager.unbindCleverTap();
```

Clears `onSlotSync` and the global attribution sink. Note: `clevertap_plugin` exposes no API to remove the display-units handler, so it stays registered but harmlessly keeps forwarding to the slot manager.

## Learn more

- [Flutter Integration guide](../docs/INTEGRATION_FLUTTER.md#approach-1--slot-based-integration-recommended)
- [Core package README](../flutter/README.md)
- [Core SDK Integration](../docs/CORE_SDK_INTEGRATION.md)
