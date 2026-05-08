---
title: HORIZONTAL container
sidebar_label: HORIZONTAL
description: Stacks children left-to-right. Maps to Compose Row / SwiftUI HStack.
---

# HORIZONTAL

The **HORIZONTAL** container stacks its children left to right. It maps to Jetpack Compose `Row` on Android and `HStack` on iOS.

Use HORIZONTAL for toolbars, button rows, side-by-side card halves, or any layout where reading order is left-to-right.

## Visual model

```
┌────────┬────────┬────────┐
│ child1 │ child2 │ child3 │
└────────┴────────┴────────┘
```

Spacing between children is controlled by [arrangement strategies](/concepts/arrangement-strategies).

## Features

- Left-to-right stacking
- Seven [arrangement strategies](/concepts/arrangement-strategies)
- All visual styles (`backgroundColor`, `borderRadius`, shadow, opacity, …)
- Cascades text styles to descendants

## JSON schema

```json
{
  "type": "container",
  "containerType": "horizontal",
  "id": "uniqueId",
  "children": [ /* zero or more nodes */ ],
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value":  56, "unit": "dp" },
    "arrangement": {
      "strategy": "space_between",
      "spacingUnit": "dp"
    }
  },
  "style": { /* visual + text styles */ }
}
```

Universal optional fields (`styleClass`, `visible`, `actions`, `animation`) work the same as on every other node.

## Layout behaviour

- Children render in source order (left → right).
- A child without `layout.width` shrinks to its intrinsic content width.
- A child with `layout.width: { value: 50, unit: percent }` claims 50% of the resolved parent width.
- HORIZONTAL with no explicit width collapses to the sum of its children's widths.

## Style support

Same matrix as [VERTICAL](/components/containers/vertical) — visual styles fill / clip / stroke / shadow the row, text styles cascade.

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | `androidx.compose.foundation.layout.Row` | `NativeDisplayRenderer.kt:295–313` |
| iOS | `HStack` (with arrangement emulation) | `NativeDisplayRenderer.swift:424–425` |

The arrangement emulation logic is shared with VERTICAL and produces pixel-equivalent layouts.

## Example — toolbar

```json
{
  "type": "container",
  "containerType": "horizontal",
  "id": "toolbar",
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value": 56,  "unit": "dp" },
    "padding": {
      "left":  { "value": 16, "unit": "dp" },
      "right": { "value": 16, "unit": "dp" }
    },
    "arrangement": { "strategy": "space_between" }
  },
  "children": [
    { "type": "element", "elementType": "button", "id": "back",  "bindings": { "text": "←" } },
    { "type": "element", "elementType": "text",   "id": "title", "bindings": { "text": "Title" } },
    { "type": "element", "elementType": "button", "id": "more",  "bindings": { "text": "⋯" } }
  ]
}
```

## Common pitfalls

**Children's combined width exceeds the row's width.** HORIZONTAL does not wrap or scroll — children clip at the right edge. Use a `GALLERY` (with `mode: free_flow`) when the child set can overflow.

**Mixing percent widths that exceed 100%.** Three children at `40% / 40% / 40%` total 120% — the third child gets pushed off-screen. Use `space_between`/`space_evenly` for fluid distribution instead.

**`arrangement.spacing` is only honoured by `spaced`.** See [arrangement strategies](/concepts/arrangement-strategies).

## See also

- [VERTICAL container](/components/containers/vertical)
- [GALLERY](/components/containers/gallery) — when children can scroll
- [Arrangement strategies](/concepts/arrangement-strategies)
