---
title: DIVIDER element
sidebar_label: DIVIDER
description: A thin visible line that separates content sections.
---

# DIVIDER

The **DIVIDER** element renders a thin coloured line — a horizontal or vertical separator between content sections. Use it to break up list items, separate header/body/footer in a card, or emphasise sectioning inside a long VERTICAL container.

For invisible spacing, use [SPACER](/components/elements/spacer) instead.

## Features

- Horizontal or vertical orientation
- Configurable thickness and colour
- Inherits the parent's available dimension on its primary axis

## JSON schema

```json
{
  "type": "element",
  "elementType": "divider",
  "id": "section-divider",
  "dividerConfig": {
    "orientation": "horizontal",
    "thickness":   1,
    "color":       "#E0E0E0"
  },
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value": 1,   "unit": "dp" }
  }
}
```

### `dividerConfig`

| Field | Default | Notes |
|-------|---------|-------|
| `orientation` | `horizontal` | `horizontal` or `vertical`. |
| `thickness` | `1` (dp) | Line thickness in dp. |
| `color` | `#E0E0E0` | Hex `#RRGGBB` or `#RRGGBBAA`. |

You also need a `layout` that gives the divider its perpendicular extent — typically `width: 100%` for horizontal, or `height: 100%` for vertical.

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | `HorizontalDivider` / `VerticalDivider` (Material3) | `ElementRenderer.kt:291–310` |
| iOS | SwiftUI `Divider` styled to match | `NativeDisplayRenderer.swift` (DividerNode branch) |

Thickness is interpreted in dp on both platforms, mapping to roughly the same on-screen pixel count.

## Examples

### List separator

```json
{
  "type": "container",
  "containerType": "vertical",
  "children": [
    { "type": "element", "elementType": "text",    "id": "rowA", "bindings": { "text": "Row A" } },
    { "type": "element", "elementType": "divider", "id": "sep1", "dividerConfig": { "color": "#22FFFFFF" }, "layout": { "width": { "value": 100, "unit": "percent" }, "height": { "value": 1, "unit": "dp" } } },
    { "type": "element", "elementType": "text",    "id": "rowB", "bindings": { "text": "Row B" } }
  ]
}
```

### Vertical divider in a horizontal toolbar

```json
{
  "type": "element",
  "elementType": "divider",
  "id": "toolbar-sep",
  "dividerConfig": { "orientation": "vertical", "thickness": 1, "color": "#33FFFFFF" },
  "layout": { "width": { "value": 1, "unit": "dp" }, "height": { "value": 24, "unit": "dp" } }
}
```

## Common pitfalls

**Forgetting `layout` on a horizontal divider** ⇒ it has no width and renders nothing. Always set `width` (and the perpendicular `height`).

**Setting `thickness` AND `layout.height`** for a horizontal divider — the renderer prefers `dividerConfig.thickness` for the visible line and uses `layout.height` only as a positioning hint. Keep them in sync, or set just `thickness`.

**Low-contrast colours on dark themes.** `#E0E0E0` (the default) is invisible on dark backgrounds. Pick a divider colour with enough contrast for the background — e.g. `#22FFFFFF` (white at 13% alpha) reads well over dark surfaces.

## See also

- [SPACER](/components/elements/spacer) — invisible spacing
- [Style cascading](/concepts/style-cascading) — colour resolution
