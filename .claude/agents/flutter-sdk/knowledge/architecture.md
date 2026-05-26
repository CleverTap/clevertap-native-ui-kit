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

The Flutter plugin is a **federated plugin** with a **pure Dart renderer**:

- **Dart-side**: JSON parsing + Flutter widget rendering (works on all platforms)
- **Platform channel bridge**: CleverTap Core SDK integration (receive/report display unit events)
- **No platform views for rendering**: avoids texture composition overhead

The rendering engine is fully in Dart — Flutter's own Skia/Impeller engine renders everything natively.

---

## Package Structure

```
flutter/                           # Plugin root (publishable to pub.dev)
├── lib/
│   ├── clevertap_native_display.dart   # Barrel export — public API
│   └── src/
│       ├── models/
│       │   ├── native_display_config.dart
│       │   ├── native_display_node.dart
│       │   ├── layout.dart
│       │   ├── style.dart
│       │   ├── background.dart
│       │   └── gallery_config.dart
│       ├── renderer/
│       │   ├── native_display_view.dart       # Entry point StatelessWidget
│       │   ├── native_display_renderer.dart   # Node dispatch + style injection
│       │   ├── container_renderer.dart        # Column/Row/Stack/PageView/GridView
│       │   └── element_renderer.dart          # Text/Image/Button/Video/HTML/Spacer/Divider
│       ├── style/
│       │   ├── style_resolver.dart            # Cascading style inheritance
│       │   └── native_display_text_style.dart # InheritedWidget for text cascading
│       ├── evaluator/
│       │   └── template_evaluator.dart        # {{variable}} interpolation
│       └── bridge/
│           ├── native_display_bridge.dart     # Dart-side MethodChannel/EventChannel
│           └── action_handler.dart            # Tap → CleverTap event reporting
├── android/
│   └── src/main/kotlin/com/clevertap/flutter/nativedisplay/
│       └── CleverTapNativeDisplayPlugin.kt    # MethodChannel handler (Kotlin)
├── ios/
│   └── Classes/
│       └── CleverTapNativeDisplayPlugin.swift # FlutterMethodChannel handler (Swift)
├── pubspec.yaml
└── example/                       # Minimal working example
```

---

## Core Layers

### 1. Data Models Layer (`src/models/`)

Pure Dart, no external dependencies. Uses factory `fromJson` constructors.

**Key models:**
- `NativeDisplayConfig` — root object: theme, styleClasses, variables, root node
- `NativeDisplayNode` — polymorphic: container (`type: "container"`) or element (`type: "element"`)
- `Layout` — width, height, padding, offset, arrangement
- `Style` — text properties + visual properties
- `Background` — sealed-class-style via enum/union (solid, gradient, image, etc.)

**Parsing approach — manual `fromJson`** (no code-gen dependency):
```dart
factory NativeDisplayNode.fromJson(Map<String, dynamic> json) {
  return switch (json['type'] as String) {
    'container' => ContainerNode.fromJson(json),
    'element'   => ElementNode.fromJson(json),
    _           => throw FormatException('Unknown node type: ${json['type']}'),
  };
}
```

### 2. Business Logic Layer (`src/style/`, `src/evaluator/`)

**StyleResolver** — O(n) traversal, builds `Map<String, Style>` (nodeId → resolvedStyle):
- Resolution order: Theme → StyleClass → Inline → Parent cascade (text props only)
- Text properties cascade: `textColor`, `fontSize`, `fontFamily`, `fontWeight`, `lineHeight`, `textDecoration`, `textAlign`, `opacity`
- Visual properties do NOT cascade: `background`, `backgroundColor`, `borderRadius`, `borderWidth`, `borderColor`, `shadow*`

**TemplateEvaluator** — replaces `{{varName}}` and `{{object.property}}` in string bindings:
- Unknown variables → return empty string (silent, consistent with Android/iOS)
- Nested paths: `{{user.name}}` → `variables['user']['name']`

### 3. Rendering Layer (`src/renderer/`)

**NativeDisplayView** — the public entry-point `StatelessWidget`. Uses `LayoutBuilder` to get available width, then:
- Pre-resolves all styles once in constructor (never inside `build()`)
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

Optional — only used when integrating with CleverTap Core SDK.

- `NativeDisplayBridge.getDisplayUnitJson(unitId)` — fetch JSON via MethodChannel
- `NativeDisplayBridge.displayUnitStream()` — receive display unit updates via EventChannel
- `NativeDisplayBridge.recordViewed(unitId)` — report viewed event
- `NativeDisplayBridge.recordClicked(unitId)` — report clicked event

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
├── clevertap_plugin          (existing: analytics, push, inbox)
└── clevertap_native_display  (new: Native Display renderer + bridge)
         └── NativeDisplayBridge connects to Core SDK via MethodChannel
```

The Core SDK on Android/iOS receives display units from CleverTap servers, caches them, and exposes them via the MethodChannel. The Flutter side fetches JSON and renders with `NativeDisplayView`.

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

### `InheritedWidget` for Text Style Cascading

Text property cascading (textColor, fontSize, etc.) passes style down the widget tree naturally via Flutter's `InheritedWidget` mechanism (similar to how `DefaultTextStyle` works). This avoids passing style as a parameter through every level of the recursion.
