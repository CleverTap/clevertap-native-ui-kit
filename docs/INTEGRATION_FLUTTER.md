# Flutter Integration — CleverTap Native Display SDK

Render server-driven native UI campaigns in Flutter using pure-Dart widgets. No platform views for the core renderer, no WebViews unless you opt in.

← Back to the [project README](../README.md) · For the cross-platform JSON spec see [JSON Structure Reference](JSON_STRUCTURE_REFERENCE.md) · For Android see [Android Integration](INTEGRATION_ANDROID.md) · For iOS see [iOS Integration](INTEGRATION_IOS.md).

---

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Prerequisite: CleverTap Core SDK](#prerequisite-clevertap-core-sdk)
- [Approach 1 — Slot-based integration (recommended)](#approach-1--slot-based-integration-recommended)
- [Approach 2 — Custom rendering](#approach-2--custom-rendering)
- [Fetch on demand](#fetch-on-demand)
- [Event hooks](#event-hooks)
- [Optional elements: VIDEO & HTML](#optional-elements-video--html)
- [Custom fonts](#custom-fonts)
- [Troubleshooting](#troubleshooting)

---

## Requirements

| | Minimum |
|----------|---------|
| Flutter | 3.24.0+ |
| Dart | 3.5.0+ |
| Android | API 23+ |
| iOS | 15.0+ |
| UI | Flutter widgets (pure Dart renderer) |

---

## Installation

The Flutter integration is split across up to four packages so the core renderer stays dependency-light and standalone-safe. Add only what you need.

| Package | Version | When to add it |
|---------|---------|----------------|
| [`clevertap_native_display`](../flutter/README.md) | 1.0.0 | **Always.** The pure-Dart renderer. Deps: `cached_network_image`, `url_launcher`. No `clevertap_plugin` dependency. |
| [`clevertap_plugin_with_native_display`](../clevertap_plugin_with_native_display/README.md) | 1.0.0 | Full CleverTap integration — provides the one-call `bindCleverTap()`. Pulls in `clevertap_plugin`. |
| [`clevertap_native_display_video`](../flutter-video/README.md) | 1.0.0 | Only if your campaigns use `VIDEO` elements. Pulls in `video_player`. |
| [`clevertap_native_display_webview`](../flutter-webview/README.md) | 1.0.0 | Only if your campaigns use `HTML` elements. Pulls in `webview_flutter`. |

Core only (standalone / manual JSON):

```yaml
dependencies:
  clevertap_native_display: ^1.0.0
```

Full CleverTap integration (the add-on transitively pulls in the core and `clevertap_plugin`):

```yaml
dependencies:
  clevertap_native_display: ^1.0.0
  clevertap_plugin_with_native_display: ^1.0.0
  clevertap_plugin: ^4.3.0

  # Add only if your campaigns use these elements:
  clevertap_native_display_video: ^1.0.0
  clevertap_native_display_webview: ^1.0.0
```

Then:

```bash
flutter pub get
```

> **Why four packages?** Dart has no `compileOnly`/weak-linking or runtime reflection, so there is no way for the core package to *optionally* depend on `clevertap_plugin`, `video_player`, or `webview_flutter` the way the native SDKs do (Android `compileOnly`, iOS Obj-C runtime lookup). The only way to keep the core standalone-safe — usable with no CleverTap account and no heavy native deps — is to split the optional dependencies into separate add-on packages that each register their feature at startup. `clevertap_plugin_with_native_display` is the Flutter equivalent of the native `CleverTapAutoWire`.

---

## Prerequisite: CleverTap Core SDK

The Native Display SDK is a renderer — display unit JSON is delivered by the [CleverTap Flutter SDK (`clevertap_plugin`)](https://github.com/CleverTap/clevertap-flutter). Install and initialize it before going further.

Two integration paths are supported:

- **Approach 1 (slot-based)** — recommended for most apps. The SDK manages discovery, routing, attribution, and lifecycle via `bindCleverTap()`.
- **Approach 2 (custom rendering)** — for hosts that need to inspect units, place them in custom layouts, or run standalone without the Core SDK.

You can also run the Display SDK in standalone mode (no Core SDK, no `clevertap_plugin`) and feed JSON manually — see [Approach 2](#approach-2--custom-rendering).

---

## Approach 1 — Slot-based integration (recommended)

The slot flow is the shortest path to a working integration. Your only job is to call `bindCleverTap()` once and declare *where* a unit can appear and *which* slot ID maps to it.

This approach requires the `clevertap_plugin_with_native_display` add-on, which provides the `bindCleverTap()` extension method on `NativeDisplaySlotManager`.

**Step 1 — Register optional elements** (only if your campaigns use them) in `main()`, before the first render.

```dart
import 'package:flutter/material.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:clevertap_native_display_video/clevertap_native_display_video.dart';
import 'package:clevertap_native_display_webview/clevertap_native_display_webview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Opt in to VIDEO / HTML elements. Skip either call if you don't use them.
  registerClevertapVideoRenderer();
  registerClevertapHtmlRenderer();

  runApp(const MyApp());
}
```

**Step 2 — Link with CleverTap Core** so server-pushed units flow into the slot system. Call `bindCleverTap()` once at startup, after `clevertap_plugin` is initialized.

```dart
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_plugin_with_native_display/clevertap_plugin_with_native_display.dart'
    show CleverTapNativeDisplayBinding;

final manager = NativeDisplaySlotManager.instance;
await manager.bindCleverTap();
```

`bindCleverTap()` wires four things in one call, mirroring the native `CleverTapAutoWire`:

1. Registers the display-units handler (push) → routes units to slots.
2. Pulls already-cached units so slots mounted at startup fill immediately.
3. Wires slot-sync out to `CleverTapPlugin.recordEvent`.
4. Installs the global attribution sink → `pushDisplayUnit*Event` (viewed / clicked / element-clicked).

**Step 3 — Drop a slot widget** anywhere in your tree with the slot ID configured on the dashboard. The manager routes the matching unit to it and it renders via `NativeDisplayView`. While no unit is present it shows your `loadingBuilder` placeholder (an empty box by default).

```dart
NativeDisplaySlot(
  slotId: 'hero_banner',
  loadingBuilder: (context, slotId) => const SizedBox(height: 120),
)
```

With `bindCleverTap()` in place, attribution (viewed / clicked) is reported globally — no per-widget callbacks required. Slot widgets auto-register with the manager on mount and auto-unregister on dispose, so there's no listener to manage.

**Step 4 — Report active slots to the server** (optional). After the screen hosting your slots has mounted, let the server know which slots are live so it can target them:

```dart
NativeDisplaySlotManager.instance.syncActiveSlots();
```

This sends a `wzrk_nd_slot_sync` event (payload `{"slots": [...]}`) via the `onSlotSync` hook that `bindCleverTap()` wired to `CleverTapPlugin.recordEvent`.

**Tear-down.** When the owning screen is disposed and you want to stop the wiring:

```dart
NativeDisplaySlotManager.instance.unbindCleverTap();
```

This clears the slot-sync hook and the global attribution sink. Note that `clevertap_plugin` exposes no API to remove the display-units handler, so it stays registered but harmlessly keeps forwarding to the slot manager.

---

## Approach 2 — Custom rendering

Choose this when you need to inspect units before rendering, place them in custom layouts (carousels, `ListView`s, dynamic widget trees), filter by metadata, or run standalone without the Core SDK.

### Standalone mode (no Core SDK)

The simplest possible integration: no `clevertap_plugin`, no CleverTap account. Parse JSON from any source (assets, network, local file) and render it. This is the three-step usage model:

```dart
import 'dart:convert';
import 'package:clevertap_native_display/clevertap_native_display.dart';

// 1. Load JSON (from an asset, your backend, a local file, etc.)
final jsonString = await rootBundle.loadString('assets/banner.json');

// 2. Parse
final config = NativeDisplayConfig.fromJson(
  jsonDecode(jsonString) as Map<String, dynamic>,
);

// 3. Render
NativeDisplayView(config: config);
```

> The `config:` constructor is render-only — no attribution events fire, because there is no display unit id. Use the `unitId:` parameter (below) or the slot flow (Approach 1) when you need Notification Viewed / Clicked attribution.

### Rendering units from CleverTap manually

When you want CleverTap-delivered units but your own placement logic, feed the raw display-unit JSON into the slot manager (or parse it directly) and render each unit with its `unitId` so attribution fires.

With `bindCleverTap()` you can observe every raw batch via the `onUnits` hook — useful for a custom canvas alongside the slot system:

```dart
NativeDisplaySlotManager.instance.bindCleverTap(
  onUnits: (rawUnits) => _onUnitsLoaded(rawUnits),
);

Future<void> _onUnitsLoaded(List<dynamic> rawUnits) async {
  final units = await NativeDisplayConfigParser.parseAll(rawUnits);
  setState(() => _units = units);
}
```

Then render each `NativeDisplayUnit`, forwarding attribution to `clevertap_plugin`:

```dart
NativeDisplayView(
  config: unit.config,
  resolvedStyles: unit.resolvedStyles, // reuse the parser's pre-resolved styles
  unitId: unit.unitId,                 // enables attribution
  onNotificationViewed: (id) => CleverTapPlugin.pushDisplayUnitViewedEvent(id),
  onNotificationClicked: (id, elementId, extras) {
    if (elementId.isNotEmpty) {
      CleverTapPlugin.pushDisplayUnitElementClickedEvent(id, extras);
    } else {
      CleverTapPlugin.pushDisplayUnitClickedEvent(id);
    }
  },
)
```

> Passing `unit.resolvedStyles` lets `NativeDisplayView` skip style resolution entirely — the parser already did it off the main isolate. Pass it whenever you render from a `NativeDisplayUnit`.

If you have already called `bindCleverTap()`, the global attribution sink reports viewed/clicked automatically, so the per-widget `onNotificationViewed` / `onNotificationClicked` above are optional — supply them only when a specific render site needs custom handling.

### Feeding the slot manager without `bindCleverTap()`

If you don't use the integration add-on, you can drive the slot manager yourself from your own `clevertap_plugin` wiring:

```dart
final manager = NativeDisplaySlotManager.instance;

// Push raw CleverTap display-unit JSON in (parsed off the main isolate):
await manager.processDisplayUnits(rawUnits);

// Or push a single unit:
await manager.processDisplayUnit(rawUnit);

// Or route already-parsed units yourself:
manager.deliverUnits(units);

// Wire slot-sync out manually:
manager.onSlotSync = (eventName, eventData) =>
    CleverTapPlugin.recordEvent(eventName, Map<String, dynamic>.from(eventData));

// Clear state:
manager.clearSlot('hero_banner');
manager.clearAll();
```

---

## Fetch on demand

By default the Core SDK pushes units when they're ready. To pull on demand (e.g. screen open, pull-to-refresh), fire the events your campaigns are triggered by and then sync active slots:

```dart
await CleverTapPlugin.recordEvent('Header1', {});
NativeDisplaySlotManager.instance.syncActiveSlots();
```

Returned units arrive through the display-units handler that `bindCleverTap()` registered, are routed to the slot manager, and each `NativeDisplaySlot` renders the unit routed to its `slotId`. Already-cached units can be pulled directly via `CleverTapPlugin.getAllDisplayUnits()` — `bindCleverTap()` does this once at startup for you.

---

## Event hooks

`NativeDisplayView` (and therefore `NativeDisplaySlot`) surface several callbacks. Note that the Flutter listener signatures are **lower-level than the native `NativeDisplayActionListener`** — they are raw function typedefs, not semantic callback objects.

### Attribution callbacks

These feed CleverTap analytics. When you use `bindCleverTap()`, the SDK wires them globally and you normally don't set them per-widget.

| Typedef | Signature | Purpose |
|---------|-----------|---------|
| `NativeDisplayNotificationViewed` | `void Function(String unitId)` | Fired once per impression. Forward to `CleverTapPlugin.pushDisplayUnitViewedEvent(unitId)`. |
| `NativeDisplayNotificationClicked` | `void Function(String unitId, String elementId, Map<String, Object?> extras)` | Fired when an interactive element (BUTTON, or IMAGE with an onClick action) is tapped. Forward to `CleverTapPlugin.pushDisplayUnitElementClickedEvent(unitId, extras)` when `elementId` is non-empty, else `pushDisplayUnitClickedEvent(unitId)`. |

Both only fire when the view was given a non-empty `unitId`. The `extras` map is already flattened and sanitized ([`ActionAttributionExtras`]) — feed it straight to `clevertap_plugin`.

### Interaction callbacks

Attach these to react to user actions and run your own logic.

| Typedef | Signature | Purpose |
|---------|-----------|---------|
| `NativeDisplayActionListener` | `void Function(String action, String nodeId, Map<String, dynamic>? params)` | Fired when a node carries a server-defined action (e.g. open URL, custom action). Inspect `action` / `params` and run your own handling. |
| `NativeDisplayComponentListener` | `bool Function(String event, String nodeId, Map<String, dynamic>? params)` | Low-level node interaction. Return `true` to consume the interaction; `false` to let the SDK proceed with its default behavior. |
| `NativeDisplayOpenUrlCallback` | `bool Function(String url, bool openInBrowser)` | Intercept `open_url` actions (host opt-out, mirrors the native `onOpenUrl -> Bool`). Return `true` to handle the URL yourself (e.g. in-app routing for a deeplink) — the SDK then does **not** open it. Return `false` (or omit) to let the SDK open it externally via `url_launcher`. |

Set it per-view via `onOpenUrl:` (on `NativeDisplayView` / `NativeDisplaySlot`). When omitted, the SDK opens every `open_url` externally (app deeplinks route to the registered app; http/https to the browser).

### Attaching callbacks

On a slot:

```dart
NativeDisplaySlot(
  slotId: 'hero_banner',
  actionListener: (action, nodeId, params) {
    debugPrint('action $action on $nodeId');
  },
  componentListener: (event, nodeId, params) {
    // return true to consume
    return false;
  },
)
```

On a directly-rendered view:

```dart
NativeDisplayView(
  config: unit.config,
  unitId: unit.unitId,
  actionListener: (action, nodeId, params) { /* ... */ },
  componentListener: (event, nodeId, params) => false,
  onNotificationViewed: (id) => CleverTapPlugin.pushDisplayUnitViewedEvent(id),
  onNotificationClicked: (id, elementId, extras) =>
      CleverTapPlugin.pushDisplayUnitElementClickedEvent(id, extras),
)
```

> **Attribution precedence:** per-widget `onNotificationViewed` / `onNotificationClicked` always win. When a widget supplies none, the SDK falls back to the process-wide `NativeDisplayAttribution` sink — which `bindCleverTap()` populates. This lets one global wiring attribute every rendered unit without the host touching each render site.

---

## Optional elements: VIDEO & HTML

The core package does **not** bundle `video_player` or `webview_flutter`. `VIDEO` and `HTML` elements are opt-in via add-on packages, each registered once at startup.

```dart
import 'package:clevertap_native_display_video/clevertap_native_display_video.dart';
import 'package:clevertap_native_display_webview/clevertap_native_display_webview.dart';

void main() {
  registerClevertapVideoRenderer(); // enables VIDEO
  registerClevertapHtmlRenderer();  // enables HTML
  runApp(const MyApp());
}
```

Without the corresponding `register...()` call, that element renders nothing (with a warning log) — the rest of the campaign renders normally.

> `HTML` elements require an explicit `layout.height` in the campaign JSON — a WebView cannot auto-size to its content. See the [WebView add-on README](../flutter-webview/README.md).

---

## Custom fonts

ND text uses the platform system font by default (Roboto on Android, San Francisco on iOS). To use your own font there are three layers, applied in this resolution order (highest first) — mirroring the native SDKs' `LocalFontFamily` / `nativeDisplayFontResolver`:

### 1. A client resolver (composes with `google_fonts`)

Set a resolver once and it applies to **all** ND text. It returns a `TextStyle` whose font-identifying fields (`fontFamily`, `fontFamilyFallback`, …) the SDK adopts — the SDK keeps ownership of size / color / weight / line-height — so it drops straight into `google_fonts`:

```dart
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:google_fonts/google_fonts.dart';

// one-time, global (e.g. in main()):
NativeDisplayFont.instance.resolver =
    (ctx) => GoogleFonts.inter(fontWeight: ctx.fontWeight, fontStyle: ctx.fontStyle);

// or honour the JSON font name, falling back to a default:
NativeDisplayFont.instance.resolver =
    (ctx) => GoogleFonts.getFont(ctx.jsonFontFamily ?? 'Inter', fontWeight: ctx.fontWeight);
```

Or per render site via `NativeDisplayView(fontResolver: …)` (also available on `NativeDisplaySlot`).

### 2. A single default family

For a pubspec-declared font, set one family name for all ND text:

```dart
NativeDisplayFont.instance.defaultFamily = 'Inter';            // global
NativeDisplayView(config: unit.config, fontFamily: 'Inter');   // or per-view
```

### 3. The JSON `fontFamily`

With no resolver / default set, the renderer uses the campaign JSON's `fontFamily` string — which resolves only if you declared that exact family in `pubspec.yaml`:

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
        - asset: fonts/Inter-Bold.ttf
          weight: 700
```

```json
{ "style": { "fontFamily": "Inter", "fontSize": 16 } }
```

**Resolution order:** `fontResolver` → `fontFamily` default → JSON `fontFamily` → system font. Per-widget values override the global `NativeDisplayFont` singleton. The SDK takes **no** dependency on `google_fonts` — the resolver just returns a `TextStyle`.

> If cross-platform font parity matters, use the **same** font in your Flutter app, your Android app, and your iOS app (and reference it from the JSON) — Roboto and San Francisco have different character widths and will wrap text differently. Always specify `lineHeight` in your campaign JSON for consistent results across platforms.

---

## Troubleshooting

**Slots never fill / no units arrive**
- Confirm `bindCleverTap()` was called once at startup, after `clevertap_plugin` was initialized. Without it, no units flow into the slot manager.
- Confirm the `slotId` on your `NativeDisplaySlot` matches the slot id configured on the dashboard.
- For standalone testing, feed JSON yourself via `NativeDisplayConfigParser.parseAll(...)` / `NativeDisplaySlotManager.instance.processDisplayUnits(...)`, or render directly with `NativeDisplayView(config:)`.

**VIDEO or HTML elements render nothing**
- Add the corresponding add-on package and call `registerClevertapVideoRenderer()` / `registerClevertapHtmlRenderer()` in `main()` before the first render. Without it, the element is skipped with a warning log.

**Layout looks wrong or view has zero height**
- Always provide `layout.width` on the root node — use `"match_parent"` to fill the available space.
- `HTML` elements require an explicit `layout.height`; they cannot auto-size.
- When a view sits in a scrollable that hands it unbounded height and you want it anchored to the viewport, pass `parentSize:` to `NativeDisplayView` (mirrors the iOS `\.nativeDisplayParentSize` environment value). Omit it to mirror Android, which derives the parent from the incoming constraints.

**Attribution events don't fire**
- Attribution only fires when the view has a non-empty `unitId`. The `config:`-only render path is render-only by design.
- Either call `bindCleverTap()` (global sink) or supply per-widget `onNotificationViewed` / `onNotificationClicked`.

**Text wraps differently on Android vs iOS vs Flutter**
- Roboto (Android) and San Francisco (iOS) have different character widths. Always specify `lineHeight` in your campaign JSON, and register the same custom font across platforms.

---

For campaign JSON structure and element reference, see [JSON Structure Reference](JSON_STRUCTURE_REFERENCE.md), the bridge reference in [Core SDK Integration](CORE_SDK_INTEGRATION.md), and the [project README](../README.md).

[`ActionAttributionExtras`]: ../flutter/lib/src/handler/action_attribution_extras.dart
