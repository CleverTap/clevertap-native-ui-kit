---
title: VERTICAL container
sidebar_label: VERTICAL
description: Stacks children top-to-bottom. Maps to Compose Column / SwiftUI VStack.
---

# VERTICAL

The **VERTICAL** container stacks its children one above another, top to bottom. It maps to Jetpack Compose `Column` on Android and `VStack` on iOS.

Use VERTICAL for any layout where reading order is top-to-bottom — forms, profile cards, lists, settings screens.

## Visual model

```
┌────────────────────┐
│      child 1       │
├────────────────────┤
│      child 2       │
├────────────────────┤
│      child 3       │
└────────────────────┘
```

Spacing between children is controlled by [arrangement strategies](/concepts/arrangement-strategies).

## Features

- Top-to-bottom stacking
- Seven [arrangement strategies](/concepts/arrangement-strategies): `spaced`, `space_between`, `space_evenly`, `space_around`, `start`, `center`, `end`
- All visual styles (`backgroundColor`, `borderRadius`, shadow, opacity, …)
- Cascades text styles to descendants

## JSON schema

```json
{
  "type": "container",
  "containerType": "vertical",
  "id": "uniqueId",
  "children": [ /* zero or more nodes */ ],
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value":  60, "unit": "percent" },
    "padding": { /* see Layout system */ },
    "arrangement": {
      "strategy": "spaced",
      "spacing": 12,
      "spacingUnit": "dp"
    }
  },
  "style": { /* visual + text styles */ },
  "styleClass": "myCard",
  "visible": "{{showHero}}",
  "actions": { "onClick": [ /* triggers */ ] },
  "animation": { /* entrance */ }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `containerType` | yes | `"vertical"` |
| `children` | yes | Zero or more nodes |
| `layout.arrangement` | optional | Defaults to `{ strategy: "spaced", spacing: 0 }` — i.e. children touch |
| `arrangement.spacing` | only with `spaced` | Other strategies ignore it ([arrangement reference](/concepts/arrangement-strategies)) |

## Layout behaviour

- Children render in source order (top → bottom).
- A child without `layout.height` shrinks to its intrinsic content height.
- A child with `layout.height: { value: 50, unit: percent }` claims 50% of the **resolved parent height** (after arrangement is applied).
- VERTICAL with no explicit height collapses to the sum of its children's heights — convenient, but make sure children carry their own size.

## Style support

| Property | Effect |
|----------|--------|
| `backgroundColor` | Fills the column behind all children. |
| `borderRadius` / `borderWidth` / `borderColor` | Rounded clip + stroke around the column. |
| `shadow*` | Drops a shadow under the column. |
| `opacity` | Multiplies into descendant alpha. |
| Text properties (`textColor`, `fontSize`, …) | Cascade into descendant `TEXT`/`BUTTON`. |

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | `androidx.compose.foundation.layout.Column` | `NativeDisplayRenderer.kt:274–292` |
| iOS | `VStack` (with arrangement emulation) | `NativeDisplayRenderer.swift:416–422` |

iOS does not natively expose `SpaceBetween` / `SpaceAround` / `SpaceEvenly` for VStack — the SDK emulates them with calculated `Spacer()` insertions to match Android pixel-equivalent.

## Example

```json
{
  "type": "container",
  "containerType": "vertical",
  "id": "form",
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "padding": {
      "top":    { "value": 16, "unit": "dp" },
      "left":   { "value": 16, "unit": "dp" },
      "right":  { "value": 16, "unit": "dp" },
      "bottom": { "value": 16, "unit": "dp" }
    },
    "arrangement": { "strategy": "spaced", "spacing": 12, "spacingUnit": "dp" }
  },
  "children": [
    { "type": "element", "elementType": "text",  "id": "title", "bindings": { "text": "Sign in" } },
    { "type": "element", "elementType": "text",  "id": "sub",   "bindings": { "text": "Welcome back" } },
    { "type": "element", "elementType": "button","id": "btn",   "bindings": { "text": "Continue" } }
  ]
}
```

## Common pitfalls

**Forgetting `arrangement` on a strategy that needs spacing.** With `arrangement.strategy: "spaced"` but no `spacing` value, children touch (default `spacing: 0`). Set both, or pick `space_between` / `space_evenly` if the spacing should distribute over remaining height.

**Percent height children inside a VERTICAL with `wrap_content` height.** The parent has no measurable height yet, so children with percent heights resolve to 0. Either give the VERTICAL an explicit height or use `wrap_content` children.

**`arrangement.spacing` is only honoured by `spaced`.** Other strategies ignore the field. See [arrangement strategies](/concepts/arrangement-strategies) for the full table.

## See also

- [HORIZONTAL container](/components/containers/horizontal)
- [Arrangement strategies](/concepts/arrangement-strategies)
- [Layout system](/concepts/layout-system)
