---
title: Containers vs elements
sidebar_label: Nodes & elements
description: Two node kinds — containers hold children, elements are leaves.
---

# Containers and elements

Every node in a `NativeDisplayConfig` is one of two kinds:

| Kind | `type` | Holds children? | Members |
|------|--------|-----------------|---------|
| **Container** | `"container"` | yes — via `children: []` | [`BOX`](/components/containers/box), [`VERTICAL`](/components/containers/vertical), [`HORIZONTAL`](/components/containers/horizontal), [`GALLERY`](/components/containers/gallery) |
| **Element**   | `"element"`   | no — leaf node           | [`TEXT`](/components/elements/text), [`IMAGE`](/components/elements/image), [`BUTTON`](/components/elements/button), [`VIDEO`](/components/elements/video), [`HTML`](/components/elements/html), [`SPACER`](/components/elements/spacer), [`DIVIDER`](/components/elements/divider) |

## Picking a container

| Goal | Container |
|------|-----------|
| Overlap children (cards, badges, hero with overlay text) | [`BOX`](/components/containers/box) |
| Stack vertically (forms, settings, profile cards) | [`VERTICAL`](/components/containers/vertical) |
| Stack horizontally (toolbars, button rows) | [`HORIZONTAL`](/components/containers/horizontal) |
| Scrolling carousel / pager / grid | [`GALLERY`](/components/containers/gallery) |

## Common fields

Both kinds share the same top-level shape:

```json
{
  "type": "container" | "element",
  "id":   "uniqueId",
  "layout": { /* width, height, padding, offset */ },
  "style":  { /* visual + text style */ },
  "styleClass": "optional class name",
  "visible": "optional template expression",
  "actions": { /* see /concepts/actions */ },
  "animation": { /* see /concepts/animations */ }
}
```

## Container-specific

```json
{
  "type": "container",
  "containerType": "box",
  "children": [ /* zero or more nodes */ ]
}
```

## Element-specific

```json
{
  "type": "element",
  "elementType": "text",
  "bindings": { "text": "{{title}}" }
}
```

Each element type has its own `bindings` keys — `url` for IMAGE/VIDEO, `text` for TEXT/BUTTON, `html`/`url` for HTML, none for SPACER/DIVIDER.
