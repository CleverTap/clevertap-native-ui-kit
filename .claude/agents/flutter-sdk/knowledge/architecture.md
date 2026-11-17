# Flutter SDK Architecture

## CRITICAL: SDK Usage Model

**The Native Display SDK is JSON-driven.** Flutter clients do NOT write custom widgets or implement renderers.

**Client Usage (3 steps):**
1. Load JSON configuration
2. Parse: `NativeDisplayConfig.fromJson(jsonDecode(jsonString))`
3. Render: `NativeDisplayView(config: config)`

**That's it.** ✅ No platform views, no native bridges needed for rendering.

---

## Overview

The Flutter plugin is a **pure-Dart package** (no platform channels, no native plugin code):

- **Dart-side**: JSON parsing + Flutter widget rendering (works on all platforms)
- **Attribution**: surfaced to the host via callbacks on `NativeDisplayView`
  (`onNotificationViewed` / `onNotificationClicked`); the host forwards them to the CleverTap
  Core SDK through its own `clevertap_plugin` Dart APIs. There is NO MethodChannel/EventChannel.
- **No platform views for rendering**: avoids texture composition overhead

The rendering engine is fully in Dart — Flutter's own Skia/Impeller engine renders everything natively.

---

## Package Structure

```
flutter/                           # Plugin root (publishable to pub.dev) — pure Dart, no android/ or ios/ dirs
├── lib/
│   ├── clevertap_native_display.dart   # Barrel export — public API
│   └── src/
│       ├── models/
│       │   ├── native_display_config.dart
│       │   ├── native_display_node.dart   # sealed NativeDisplayNode → Container / Element
│       │   ├── native_display_unit.dart
│       │   ├── node_config.dart
│       │   ├── action.dart
│       │   ├── layout.dart
│       │   ├── style.dart
│       │   ├── text_dimension.dart
│       │   ├── enums.dart
│       │   ├── background.dart
│       │   └── gallery_config.dart
│       ├── renderer/
│       │   ├── native_display_view.dart       # Entry point StatefulWidget
│       │   ├── native_display_renderer.dart   # Node dispatch (StatelessWidget) + style injection
│       │   ├── native_display_scope.dart      # InheritedWidget: rootHeight, styles, unitId, callbacks
│       │   ├── native_display_font.dart       # Client font API (NativeDisplayFont, resolveNativeDisplayFont)
│       │   ├── native_display_attribution.dart
│       │   ├── nd_element_registry.dart       # Registry for optional VIDEO/HTML add-on renderers
│       │   ├── style_applier.dart
│       │   ├── animation_modifier.dart
│       │   ├── containers/                    # VERTICAL/HORIZONTAL/BOX/GALLERY renderers
│       │   └── elements/                      # TEXT/IMAGE/BUTTON/SPACER/DIVIDER renderers
│       ├── style/
│       │   └── style_resolver.dart            # Cascading style inheritance (resolve-time)
│       ├── evaluator/
│       │   └── variable_evaluator.dart        # {{variable}} interpolation
│       ├── handler/
│       │   └── action_handler.dart            # Tap → action (url_launcher) + attribution callback
│       ├── placement/                         # NativeDisplaySlot / NativeDisplaySlotManager
│       ├── bridge/
│       │   ├── native_display_bridge.dart     # Dart-only config helper (log level sync) — NO channels
│       │   └── native_display_config_parser.dart
│       └── utils/                             # color_parser.dart, asset_url_collector.dart
├── pubspec.yaml
└── test/
```

VIDEO and HTML renderers are NOT in the core — they ship as optional add-on packages
(`clevertap_native_display_video`, `clevertap_native_display_webview`) that register into the
`nd_element_registry` at startup.

---

## Core Layers

### 1. Data Models Layer (`src/models/`)

Pure Dart, no external dependencies. Uses factory `fromJson` constructors.

**Key models:**
- `NativeDisplayConfig` — root object: theme, styleClasses, variables, root node
- `NativeDisplayNode` — sealed base; subclasses `NativeDisplayContainer` (`type: "container"`) and `NativeDisplayElement` (`type: "element"`, the default)
- `Layout` — width, height, padding, offset, arrangement
- `Style` — text properties + visual properties
- `Background` — sealed-class-style via enum/union (solid, gradient, image, etc.)

**Parsing approach — manual `fromJson`** (no code-gen dependency):
```dart
factory NativeDisplayNode.fromJson(Map<String, dynamic> json) {
  final type = json['type'] as String? ?? 'element';
  return switch (type) {
    'container' => NativeDisplayContainer.fromJson(json),
    _           => NativeDisplayElement.fromJson(json), // default to element; never throws
  };
}
```

### 2. Business Logic Layer (`src/style/`, `src/evaluator/`)

**StyleResolver** — O(n) traversal, builds `Map<String, Style>` (nodeId → resolvedStyle):
- Resolution order: Theme → StyleClass → Inline → Parent cascade (text props only)
- Text properties cascade: `textColor`, `fontSize`, `fontFamily`, `fontWeight`, `lineHeight`, `textDecoration`, `textAlign`, `opacity`
- Visual properties do NOT cascade: `background`, `backgroundColor`, `borderRadius`, `borderWidth`, `borderColor`, `shadow*`

**VariableEvaluator** (`src/evaluator/variable_evaluator.dart`) — replaces `{{varName}}` and
`{{object.property}}` in string bindings via `evaluateString(...)`:
- Unknown variables → return empty string (silent, consistent with Android/iOS)
- Nested paths: `{{user.name}}` → `variables['user']['name']`

### 3. Rendering Layer (`src/renderer/`)

**NativeDisplayView** — the public entry-point `StatefulWidget`. Uses `LayoutBuilder` to get available width, then:
- Pre-resolves all styles once (never inside `build()`); accepts an optional pre-resolved `resolvedStyles` map
- Computes `effectiveRootWidth` and `rootHeight` for percent font/border resolution
- Applies root sizing via `_applyRootSizing`

**Root sizing rule — aspectRatio takes full width (critical)**:
When `aspectRatio` is set on the root node, `effectiveRootWidth = availableWidth` (full parent width — percent is ignored). Height = `availableWidth / aspectRatio`. The `AspectRatio` Flutter widget in `NativeDisplayRenderer._wrapWithSizing` handles the visual constraint; no explicit `Align+SizedBox` wrapper is added.

```
layout.aspectRatio present  →  full parent width, height = parentWidth / AR
layout.width.percent only   →  Align + SizedBox(width = parentWidth * pct/100)
neither                     →  no wrapping; child fills slot naturally
```

This matches Android (Compose modifier ordering) and iOS (guard returning parentWidth for percent when AR set). See `rendering-pipeline.md` for the full priority table.

**NativeDisplayRenderer** — recursive dispatch to container or element renderers. Applies `AspectRatio` widget when `layout.aspectRatio > 0` and not both dimensions fixed.

### 4. Bridge Layer (`src/bridge/`)

Dart-only. There are NO platform channels — the plugin is a pure-Dart renderer.

- `NativeDisplayBridge.setLogLevel(level)` — configure the SDK log level (client-wins)
- `NativeDisplayBridge.syncLogLevelFromCore(coreLevel)` — align log level with the host's Core SDK debug level
- `NativeDisplayConfigParser` — parse + pre-resolve a config

Attribution (Notification Viewed / Clicked) is surfaced through the `onNotificationViewed` /
`onNotificationClicked` callbacks on `NativeDisplayView`. The host forwards those to the CleverTap
Core SDK via its own `clevertap_plugin` Dart APIs — the ND plugin never talks to native directly.

---

## Flutter Three-Tree Model — What It Means for This SDK

```
Widget tree (rebuilt frequently, cheap)
    NativeDisplayView
        └── NativeDisplayRenderer
              ├── Column (VERTICAL container)
              │   ├── TextElement
              │   └── ImageElement
              └── ...

Element tree (persistent, one-to-one with widgets, handles diffing)
    StatelessElement (NativeDisplayView)
        └── StatelessElement (NativeDisplayRenderer)
              └── ...

RenderObject tree (actual layout/paint)
    RenderFlex (Column)
        ├── RenderParagraph (Text)
        └── RenderImage (Image)
```

**Key implication for our SDK**: Because styles are pre-resolved in `NativeDisplayView` constructor (before `build()`), and model classes are immutable, the element tree can reuse render objects efficiently without unnecessary relayout.

---

## Integration with CleverTap Flutter SDK

The existing `clevertap_plugin` provides analytics and user profiles. Native Display extends it:

```
User App
├── clevertap_plugin          (existing: analytics, push, inbox — provides display unit JSON + event APIs)
└── clevertap_native_display  (new: pure-Dart Native Display renderer)
         └── NativeDisplayView fires onNotificationViewed / onNotificationClicked callbacks
                └── host forwards them to clevertap_plugin's Core SDK event APIs
```

The host app obtains display unit JSON from the Core SDK via `clevertap_plugin`, parses it, and
renders with `NativeDisplayView`. The ND plugin has no direct link to the Core SDK — all
integration flows through the host and `clevertap_plugin`.

---

## Design Decisions

### Pure Dart Renderer (not Platform Views)

Platform Views embed native views (AndroidView/UiKitView) into Flutter. They carry significant overhead:
- Texture composition (GPU context switching)
- Input event translation
- Accessibility tree bridging
- Thread synchronization

A pure Dart renderer avoids all of this. Flutter's Impeller/Skia renders Dart widgets natively at 60/120fps without any of this overhead. The JSON rendering logic is re-implemented in Dart.

### Manual `fromJson` (not `json_serializable`)

Keeps the plugin dependency-free for the core parsing layer. `json_serializable` is fine for sample apps but adds a build_runner dev dependency to the plugin itself — avoided for simplicity and faster builds.

### Text Style Cascading at Resolve Time

Text property cascading (textColor, fontSize, etc.) is computed **once** in `StyleResolver` — each
node's resolved style merges its parent's cascading-only properties (`cascadingOnly()` + `merge()`).
The result is a flat `Map<String, Style>` (node id → resolved style), so renderers do an O(1)
lookup and never recompute cascade at build time.

A single `InheritedWidget`, `NativeDisplayScope`, carries per-view render context (rootHeight, the
resolved styles map, unitId, attribution/open-url callbacks, client font) down the tree so renderers
don't thread these through every parameter — it does NOT carry a cascading `TextStyle`.
