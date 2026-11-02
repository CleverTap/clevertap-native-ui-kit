# CleverTap Native Display for Flutter

Package: `clevertap_native_display`

## What this is

CleverTap lets you design UI campaigns (banners, cards, carousels, and more) on the CleverTap dashboard and send them to your app. This package draws those campaigns as real, native Flutter widgets — no WebViews (unless you opt in to the HTML element). You design once on the dashboard; the app shows it without an app-store update.

This is the **core renderer**. It is pure Dart: it parses the campaign JSON and renders it with Flutter widgets. It has **no dependency on `clevertap_plugin`** and no CleverTap account requirement — so you can use it standalone with hand-authored or backend-served JSON, and layer CleverTap on top only when you need it.

## Quick facts

| Question | Answer |
|---|---|
| Which platforms? | Android and iOS |
| Minimum versions | Flutter 3.24+, Dart 3.5+ |
| Does it add native code of its own? | No. This package is pure Dart. Its only deps are `cached_network_image` and `url_launcher`. |
| Does it depend on `clevertap_plugin`? | **No.** Add [`clevertap_plugin_with_native_display`](../clevertap_plugin_with_native_display/README.md) for the CleverTap integration. |
| Where are campaigns designed? | On the CleverTap dashboard, not in code. |

## Install

```yaml
dependencies:
  clevertap_native_display: ^1.0.0
```

```bash
flutter pub get
```

## Standalone quick-start (manual JSON)

The usage model is three steps: **load JSON → parse → render.**

```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:clevertap_native_display/clevertap_native_display.dart';

// 1. Load the JSON (asset, backend, local file — any source)
final jsonString = await rootBundle.loadString('assets/banner.json');

// 2. Parse
final config = NativeDisplayConfig.fromJson(
  jsonDecode(jsonString) as Map<String, dynamic>,
);

// 3. Render
NativeDisplayView(config: config);
```

That's the whole standalone path — no CleverTap account, no native CleverTap SDK.

> The `config:` constructor is render-only — Notification Viewed / Clicked attribution does not fire because there is no display unit id. For attribution, pass a `unitId:` and wire the callbacks (see [Flutter Integration](../docs/INTEGRATION_FLUTTER.md#approach-2--custom-rendering)), or use the slot flow.

## Full CleverTap integration

To render server-driven campaigns delivered by CleverTap, add the integration add-on and drop slot widgets. See the dedicated guide:

- **[Flutter Integration guide](../docs/INTEGRATION_FLUTTER.md)** — slot-based (recommended) and custom rendering, step by step.
- **[`clevertap_plugin_with_native_display`](../clevertap_plugin_with_native_display/README.md)** — the one-call `bindCleverTap()` wiring.

## Optional elements

`VIDEO` and `HTML` elements are **not** bundled in the core (to keep it dependency-light). Add the add-on you need and register it once at startup:

- **[`clevertap_native_display_video`](../flutter-video/README.md)** → `registerClevertapVideoRenderer()`
- **[`clevertap_native_display_webview`](../flutter-webview/README.md)** → `registerClevertapHtmlRenderer()`

Without the add-on, that element renders nothing (with a warning log); the rest of the campaign renders normally.

## What's in the box

| Capability | API |
|---|---|
| Parse a config | `NativeDisplayConfig.fromJson(Map<String, dynamic>)` |
| Render a config | `NativeDisplayView(config: ...)` |
| Parse CleverTap display-unit JSON | `NativeDisplayConfigParser.parseAll(...)` / `.tryParse(...)` |
| Slot placement | `NativeDisplaySlot`, `NativeDisplaySlotManager` |
| Global attribution sink | `NativeDisplayAttribution` |
| Logging | `NativeDisplayBridge.setLogLevel(NDLogLevel.verbose)` |

**Containers:** `VERTICAL` `HORIZONTAL` `BOX` `GALLERY` · **Elements:** `TEXT` `IMAGE` `BUTTON` `VIDEO`\* `HTML`\* `SPACER` `DIVIDER` (\* via add-on).

## Learn more

- [Flutter Integration guide](../docs/INTEGRATION_FLUTTER.md)
- [JSON Structure Reference](../docs/JSON_STRUCTURE_REFERENCE.md)
- [Core SDK Integration](../docs/CORE_SDK_INTEGRATION.md)
- [Project README](../README.md)
