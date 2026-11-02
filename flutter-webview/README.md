# CleverTap Native Display — HTML / WebView element add-on

Package: `clevertap_native_display_webview`

## What this is

An optional add-on for [`clevertap_native_display`](../flutter/README.md) that enables rendering of `HTML` elements in Native Display campaigns. It is backed by [`webview_flutter`](https://pub.dev/packages/webview_flutter).

The core renderer does **not** bundle `webview_flutter` — to keep it dependency-light, HTML support is opt-in. Add this package only if your campaigns use `HTML` elements.

## Quick facts

| Question | Answer |
|---|---|
| Minimum versions | Flutter 3.24+, Dart 3.5+ |
| Backing package | `webview_flutter` ^4.9.0 |
| Needed when? | Only if your campaigns include `HTML` elements |

## Install

```yaml
dependencies:
  clevertap_native_display: ^1.0.0
  clevertap_native_display_webview: ^1.0.0
```

```bash
flutter pub get
```

## Usage

Call `registerClevertapHtmlRenderer()` once at startup, before the first Native Display render:

```dart
import 'package:flutter/material.dart';
import 'package:clevertap_native_display_webview/clevertap_native_display_webview.dart';

void main() {
  registerClevertapHtmlRenderer();
  runApp(const MyApp());
}
```

Without this call, `HTML` elements render nothing (with a warning log). The rest of the campaign renders normally.

## Campaign JSON

An `HTML` element reads these bindings:

| Binding | Purpose |
|---------|---------|
| `html` | Inline HTML string. **Takes priority over `url`.** |
| `url` | Remote URL to load (used only when `html` is empty). |

```json
{
  "type": "HTML",
  "bindings": { "html": "<h1>Hello</h1>" },
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 240, "unit": "dp" }
  }
}
```

## Explicit height is required

A WebView cannot auto-size to its content, so an `HTML` element **must** declare an explicit `layout.height`:

- `dp`/`sp`/`px` height → used directly.
- `percent` height → resolved against the root container height.
- `wrap_content`, `match_parent`, or an unspecified height → unsupported; the add-on logs a warning and falls back to **200dp**.

Always set a concrete height for HTML elements in your campaign JSON to avoid the fallback.

## Learn more

- [Flutter Integration guide](../docs/INTEGRATION_FLUTTER.md#optional-elements-video--html)
- [Core package README](../flutter/README.md)
- [JSON Structure Reference](../docs/JSON_STRUCTURE_REFERENCE.md)
