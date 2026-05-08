---
title: BUTTON element
sidebar_label: BUTTON
description: Tappable text element with full text styling and action triggers.
---

# BUTTON

The **BUTTON** element is a tappable text label that fires an `actions` block when interacted with. It's intentionally **not** a native platform button — the SDK renders it as a styled BOX + TEXT so designers get pixel-perfect control over corner radius, padding, color, and typography.

For most CTAs, BUTTON + an `onClick` action is what you want. For non-tappable text, use [TEXT](/components/elements/text). For an icon-only tap target, use a BOX with `actions.onClick` and a child IMAGE.

## Features

- Full text styling (same as [TEXT](/components/elements/text))
- All visual styles for the button's background frame (`backgroundColor`, `borderRadius`, `borderWidth`, shadow, …)
- Tap, long-press, and double-tap action triggers
- `{{variable}}` interpolation in the label

## JSON schema

```json
{
  "type": "element",
  "elementType": "button",
  "id": "ctaPrimary",
  "bindings": {
    "text": "Continue"
  },
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value": 48,  "unit": "dp" }
  },
  "style": {
    "backgroundColor": "#FF6B6B",
    "borderRadius":    24,
    "textColor":       "#FFFFFF",
    "fontSize":        16,
    "fontWeight":      "bold",
    "textAlign":       "center"
  },
  "actions": {
    "onClick": [ /* triggers — see Actions */ ]
  }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `bindings.text` | yes | Defaults to `"Button"` if missing. Supports `{{variables}}`. |
| `actions.onClick` | recommended | Without `actions`, the button is visually a button but has no behaviour. |

## Style support

| Property | Effect |
|----------|--------|
| `backgroundColor` | Fills the button frame. |
| `borderRadius`, `borderWidth`, `borderColor` | Pill / rounded rectangle stroke. |
| `shadow*` | Drops a shadow under the button. |
| `textColor`, `fontSize`, `fontFamily`, `fontWeight`, … | Standard text styling on the label. |
| `opacity` | Whole-button alpha. |

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | `Box` + `Text` + `Modifier.clickable` | `ElementRenderer.kt:150–197` |
| iOS | `ZStack` + `Text` + `.onTapGesture` | `NativeDisplayRenderer.swift` (ButtonNode branch) |

The SDK avoids `Button` (Material3) and `Button(action:)` (SwiftUI) so the style block has total control over visuals. Both platforms render an identical pixel result.

## Examples

### Primary CTA

```json
{
  "type": "element",
  "elementType": "button",
  "id": "primary",
  "bindings": { "text": "Get started" },
  "layout": { "width": { "value": 100, "unit": "percent" }, "height": { "value": 56, "unit": "dp" } },
  "style": {
    "backgroundColor": "#0066FF",
    "borderRadius": 28,
    "textColor": "#FFFFFF",
    "fontSize": 16,
    "fontWeight": "bold",
    "textAlign": "center"
  },
  "actions": {
    "onClick": [ { "type": "open_url", "url": "https://example.com/get-started" } ]
  }
}
```

### Outline / secondary

```json
{
  "style": {
    "backgroundColor": "#00000000",
    "borderRadius": 24,
    "borderWidth": 1,
    "borderColor": "#0066FF",
    "textColor":   "#0066FF",
    "fontWeight":  "medium"
  }
}
```

### Long-press to dismiss

```json
{
  "actions": {
    "onClick":     [ { "type": "open_url", "url": "{{ctaUrl}}" } ],
    "onLongPress": [ { "type": "dismiss" } ]
  }
}
```

## Common pitfalls

**No `actions` block.** The button renders, taps register visually (ripple), but nothing happens. Always wire at least `onClick`.

**Large tap targets.** Set a minimum height of 44dp/pt for accessibility. Smaller buttons fail mobile-accessibility audits.

**Disabled state.** v1.0.0 doesn't ship a `disabled` flag. Toggle the whole button via `visible: "{{enabled}}"` or change colors via variables.

**Two-line button labels** wrap by default. Set `style.maxLines: 1` and `overflow: "ellipsis"` if you want predictable single-line CTAs.

## See also

- [Actions](/concepts/actions) — full action trigger reference
- [TEXT element](/components/elements/text) — same text styling, no tap target
