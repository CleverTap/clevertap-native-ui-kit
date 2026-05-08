---
title: wrap_content & match_parent
sidebar_label: wrap_content / match_parent
description: Two special dimension values for content-sized and parent-filling layouts.
---

# Special dimensions

In addition to the unit-based dimensions ([dp](/dimensions/dp), [sp](/dimensions/sp), [px](/dimensions/px), [percent](/dimensions/percent)), two **special** values short-circuit the unit system entirely:

```json
{ "special": "wrap_content" }
{ "special": "match_parent" }
```

They take the place of `value` + `unit` — you set either one or the other, not both.

## `wrap_content`

> "Be exactly as big as you need to be."

The node measures itself based on its content (children's combined size for containers; intrinsic size for elements like TEXT and IMAGE).

| Platform | Implementation |
|----------|----------------|
| Android | `Modifier.wrapContentWidth()` / `wrapContentHeight()` |
| iOS | Omits the `.frame(width:height:)` modifier so SwiftUI measures naturally |

**When to use:** containers that should size to their longest child, text labels that shouldn't reserve full row width, badges that hug their content.

```json
{
  "type": "element",
  "elementType": "text",
  "bindings": { "text": "{{badge}}" },
  "layout": {
    "width":  { "special": "wrap_content" },
    "height": { "special": "wrap_content" }
  },
  "style": { "backgroundColor": "#FF6B6B", "borderRadius": 8 }
}
```

## `match_parent`

> "Fill all the available space in the parent."

The node claims as much of the parent's measured size as remains after siblings are laid out.

| Platform | Implementation |
|----------|----------------|
| Android | `Modifier.fillMaxWidth()` / `fillMaxHeight()` |
| iOS | `.frame(maxWidth: .infinity)` / `.frame(maxHeight: .infinity)` |

**When to use:** the "push siblings to the right" pattern with a flexible SPACER, full-width root containers that should never have margins, columns inside a scrolling parent that should match the parent's width.

```json
{
  "type": "element",
  "elementType": "spacer",
  "id": "push",
  "layout": {
    "width": { "special": "match_parent" }
  }
}
```

## Common pitfalls

**`wrap_content` parent + percent child = 0.** A child with `{ value: 50, unit: percent }` resolves against the parent's measured width — and the parent is measuring itself from its children. The child sees width 0 and disappears. Either give the parent a fixed dimension or use `wrap_content` on the child too.

**`match_parent` inside a `wrap_content` parent** is undefined behaviour. The parent wants to size to children; the child wants to fill the parent. Both compute against zero. Pick one.

**Nesting `match_parent` inside an unbounded scroll** (e.g. a `LazyColumn` with no height ceiling) — Android may infinite-loop or render at 0 height; iOS hits a `GeometryReader` fallback that mostly works. Avoid.

## Resolution location

| Platform | File |
|----------|------|
| Android | `ModifierExtensions.kt:123, 137` (match_parent), `:124, 138` (wrap_content) |
| iOS | Layout modifier inside `NativeDisplayRenderer.swift` |

## See also

- [Layout system](/concepts/layout-system) — the full layout object
- [Percent dimensions](/dimensions/percent)
- [Dimensions overview](/dimensions/overview)
