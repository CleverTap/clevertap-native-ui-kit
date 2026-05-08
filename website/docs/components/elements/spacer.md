---
title: SPACER element
sidebar_label: SPACER
description: Empty space. Pushes siblings apart in VERTICAL / HORIZONTAL containers.
---

# SPACER

The **SPACER** element is empty space. It has size — and nothing else. Use it inside a [VERTICAL](/components/containers/vertical) or [HORIZONTAL](/components/containers/horizontal) to insert a fixed gap or to push siblings to opposite ends of the container.

For most spacing needs, prefer `arrangement.spacing` on the parent container — it's tighter and more declarative. Reach for SPACER only when the gap should be different at one specific position.

## Features

- Pure layout. No painting, no events.
- Accepts every dimension unit (percent, dp, sp, px, wrap_content, match_parent).

## JSON schema

```json
{
  "type": "element",
  "elementType": "spacer",
  "id": "gap-1",
  "layout": {
    "width":  { "value": 16, "unit": "dp" },
    "height": { "value": 16, "unit": "dp" }
  }
}
```

That's the entire surface. SPACER doesn't take `bindings`, doesn't honour `style` (nothing to paint), doesn't fire `actions`.

| Field | Required | Notes |
|-------|----------|-------|
| `layout.width` / `layout.height` | yes — at least one | The other can be `wrap_content`. |

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | `androidx.compose.foundation.layout.Spacer` | `ElementRenderer.kt:287–288` |
| iOS | `Spacer` (or sized `Color.clear` when fixed) | `NativeDisplayRenderer.swift` (SpacerNode branch) |

A flexible SPACER (`width: { special: "match_parent" }` inside a horizontal container) expands to fill remaining space — useful for "push to right" layouts.

## Examples

### Fixed gap between two cards

```json
{
  "type": "container",
  "containerType": "vertical",
  "children": [
    { "type": "container", "containerType": "box", "id": "cardA", "..." },
    { "type": "element",   "elementType": "spacer", "id": "gap", "layout": { "height": { "value": 24, "unit": "dp" } } },
    { "type": "container", "containerType": "box", "id": "cardB", "..." }
  ]
}
```

### Flexible push-to-end

```json
{
  "type": "container",
  "containerType": "horizontal",
  "children": [
    { "type": "element", "elementType": "text", "id": "label", "bindings": { "text": "Hello" } },
    { "type": "element", "elementType": "spacer", "id": "push", "layout": { "width": { "special": "match_parent" } } },
    { "type": "element", "elementType": "button", "id": "btn", "bindings": { "text": "Action" } }
  ]
}
```

## Common pitfalls

**SPACER without any size** renders nothing. At least `width` or `height` (whichever axis matters in the parent) must be set.

**SPACER inside a BOX** has no useful effect — BOX overlaps children, it doesn't distribute them. Use arrangement on a VERTICAL/HORIZONTAL parent instead.

**Prefer `arrangement.spacing` for uniform gaps.** Sprinkling SPACERs between every child works, but `arrangement: { strategy: "spaced", spacing: 12 }` on the parent is one config object instead of N.

## See also

- [Arrangement strategies](/concepts/arrangement-strategies)
- [DIVIDER element](/components/elements/divider) — visible separator instead of invisible space
