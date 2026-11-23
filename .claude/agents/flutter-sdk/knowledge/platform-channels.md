# CleverTap Integration & Attribution Model

> **There are no platform channels.** The Flutter plugin is a **pure-Dart package** — no
> MethodChannel, no EventChannel, no Pigeon, no Android Kotlin / iOS Swift plugin code, and no
> `android/` or `ios/` dirs. (This file was previously named for a platform-channel bridge that was
> only ever a plan; it never shipped. The filename is kept because other docs link to it.)

## How integration actually works

The ND plugin renders JSON and reports attribution via **callbacks**. The host app owns the link to
the CleverTap Core SDK through `clevertap_plugin`:

1. The host obtains display unit JSON from the Core SDK via `clevertap_plugin` (its concern, not the
   ND plugin's).
2. The host parses it (`NativeDisplayConfig.fromJson(...)` / `NativeDisplayConfigParser.parse(...)`)
   and renders it with `NativeDisplayView`.
3. `NativeDisplayView` fires attribution callbacks; the host forwards them to `clevertap_plugin`'s
   event APIs.

```
CleverTap servers → Core SDK → clevertap_plugin (host)
                                      │  JSON
                                      ▼
                             NativeDisplayView (pure Dart render)
                                      │  onNotificationViewed / onNotificationClicked
                                      ▼
                             host forwards to clevertap_plugin event APIs
```

## Attribution callbacks

```dart
NativeDisplayView(
  config: config,
  unitId: wzrkId, // CleverTap display unit id (wzrk_id); null for previews / test fixtures
  onNotificationViewed: (unitId) {
    // Fired exactly once per impression (gated by ViewedUnitsTracker).
    // Host forwards to clevertap_plugin.pushDisplayUnitViewedEvent(unitId).
  },
  onNotificationClicked: (unitId, elementId, extras) {
    // Fired when an interactive element (BUTTON, or IMAGE with an onClick action) is tapped.
    // `extras` is the flattened, sanitized ActionAttributionExtras payload — the host feeds it
    // straight into clevertap_plugin.pushDisplayUnitElementClickedEvent(unitId, extras).
  },
);
```

Both callbacks only fire when `unitId` is non-null/non-empty. `open_url` actions are opened by the
plugin via `url_launcher`, unless the host's `onOpenUrl(url, openInBrowser) -> bool` interceptor
returns `true` (in-app routing), mirroring the native SDKs.

## The Dart-only `NativeDisplayBridge`

The only `NativeDisplayBridge` that exists is a small Dart-only configuration helper
(`lib/src/bridge/native_display_bridge.dart`). It does **not** talk to native code:

```dart
NativeDisplayBridge.setLogLevel(NDLogLevel.verbose);      // client-wins
NativeDisplayBridge.syncLogLevelFromCore(coreDebugLevel); // align with the host's Core SDK debug
                                                          // level; no-op once setLogLevel was called
```

Parsing/pre-resolution lives in `NativeDisplayConfigParser`
(`lib/src/bridge/native_display_config_parser.dart`), which parses the JSON and pre-resolves styles
so `NativeDisplayView` can skip `StyleResolver` at build time.

## Why no channels

Because rendering is pure Dart and attribution is callback-based, the plugin needs nothing from
native code — which is what lets it stay a pure-Dart package (lower Flutter floor, no per-platform
bridge to maintain). If a future need ever requires native data the plugin can't get from the host,
a bridge would be added then; today there is none.
