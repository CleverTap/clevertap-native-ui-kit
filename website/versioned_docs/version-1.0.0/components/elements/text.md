---
title: TEXT element
sidebar_label: TEXT
description: Renders a string. Supports {{variable}} interpolation and full text styling.
---

# TEXT

The **TEXT** element renders a single string of text. It's the most-used element in any config — every label, paragraph, badge, headline.

Text can be static (`"Hello"`) or interpolated (`"Welcome, {{userName}}"`). Variables come from the config's [`variables` map](/concepts/templates-and-variables).

## Features

- `{{variable}}` interpolation in `text` binding
- Full text style cascade: `textColor`, `fontSize`, `fontFamily`, `fontWeight`, `fontStyle`, `lineHeight`, `letterSpacing`, `textDecoration`, `textAlign`
- `maxLines` + `overflow` for truncation
- `textShadow`, `textGradient` for decorative type
- Inherits text styles from any ancestor container (cascade)

## JSON schema

```json
{
  "type": "element",
  "elementType": "text",
  "id": "headline",
  "bindings": {
    "text": "Welcome, {{userName}}!"
  },
  "layout": {
    "width": { "value": 100, "unit": "percent" }
  },
  "style": {
    "textColor": "#FFFFFF",
    "fontSize":  16,
    "fontFamily": "SF Pro Display",
    "fontWeight": "bold",
    "fontStyle":  "normal",
    "lineHeight": 24,
    "letterSpacing": 0.5,
    "textDecoration": "none",
    "textAlign": "center",
    "maxLines": 2,
    "overflow": "ellipsis",
    "opacity": 1.0
  }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `elementType` | yes | `"text"` |
| `bindings.text` | yes | The string. May contain `{{variable}}` references. |
| `style.fontSize` | recommended | A number (sp/points) or `{ value, unit: "percent" }` — see [dimensions overview](/dimensions/overview). |
| `style.lineHeight` | strongly recommended | Defaults differ across platforms (Android 1.5×, iOS 1.176×) — see pitfalls. |

## Style support

All text style properties (full list above) plus inherited cascade from parent containers. Visual styles (`backgroundColor`, `borderRadius`, …) are accepted but rarely useful on TEXT — wrap in a BOX if you want a filled background behind the string.

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | `androidx.compose.material3.Text` | `ElementRenderer.kt:51–98` |
| iOS | `Text` (SwiftUI) | `NativeDisplayRenderer.swift` (TextNode branch) |

`fontSize` and `lineHeight` accept either a raw number (platform units: SP on Android, points on iOS) or a percent-of-root-height object `{ value: N, unit: "percent" }` — see [dimensions overview](/dimensions/overview).

## Examples

### Headline with variable

```json
{
  "type": "element",
  "elementType": "text",
  "id": "hello",
  "bindings": { "text": "Hello, {{user.name}} 👋" },
  "style": { "fontSize": 24, "fontWeight": "bold", "lineHeight": 32 }
}
```

### Truncated paragraph

```json
{
  "type": "element",
  "elementType": "text",
  "id": "body",
  "bindings": { "text": "{{description}}" },
  "style": {
    "fontSize": 14,
    "lineHeight": 20,
    "maxLines": 3,
    "overflow": "ellipsis"
  }
}
```

## Common pitfalls

**Always specify `lineHeight`.** Default line-height differs across platforms (Android 1.5× of fontSize; iOS 1.176×). On the same fontSize a paragraph reads taller on Android. Pin `lineHeight` for cross-platform pixel-equivalent rendering.

**`fontFamily` may not resolve.** If the host app doesn't bundle the named font, both platforms fall back to system default (Roboto on Android, San Francisco on iOS). Roboto and SF Pro have different character widths — text wrapping will differ. Bundle a single font on both platforms or pass one via the SDK's font resolver API.

**`overflow: "visible"` allows the string to spill out** of its container's bounds. Most layouts want `ellipsis` or `clip`.

**Dynamic Type / Font Manager.** iOS auto-scales `Text` based on the user's Dynamic Type setting; Android scales `sp`-sized text by the user's font scale. Both are intended — don't fight them.

## See also

- [Style cascading](/concepts/style-cascading)
- [Templates and variables](/concepts/templates-and-variables)
- [BUTTON element](/components/elements/button) — same styling, plus actions
