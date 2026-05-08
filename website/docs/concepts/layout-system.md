---
title: Layout system
sidebar_label: Layout system
description: The layout object — width, height, padding, offset, aspectRatio.
---

# Layout system

Every node carries a `layout` object that controls how it sizes and where it sits inside its parent.

```json
"layout": {
  "width":       { "value": N, "unit": "percent" },
  "height":      { "value": N, "unit": "percent" },
  "padding":     { "top": …, "bottom": …, "left": …, "right": … },
  "offset":      { "x": { "value": N, "unit": "percent" }, "y": { … } },
  "aspectRatio": 1.5
}
```

In v1.0.0 every dimension uses the **percent** unit. See [Percentage dimensions](/dimensions/percent) for the formula and pitfalls.

## Fields documented in v1.0.0

| Field | Type | What it does |
|-------|------|--------------|
| `width` | Dimension | Node's width. Required (or use `aspectRatio` to derive from height). |
| `height` | Dimension | Node's height. Required (or use `aspectRatio` to derive from width). |
| `padding` | object of 4 Dimensions | Inset applied *before* children render. |
| `offset` | object `{x, y}` | Displaces this node from its anchor in the parent. |
| `aspectRatio` | number | If set, locks `height = width / aspectRatio` (or vice versa). |

## Fields not in the v1.0.0 contract

`arrangement` (used by `VERTICAL`/`HORIZONTAL`/`GALLERY`) ships in the binary but is undocumented in v1.0.0. BOX does not use it — children layer at the box's anchor regardless.

## Default

If a node omits `layout` entirely, every dimension defaults to `0`. The node is parsed without error but renders invisibly. Always provide an explicit `layout` for every node you want to see.

## Padding semantics

Padding is applied to the parent *before* children render — it shrinks the box children draw inside. A child with `width: { 100% }` inside a parent with `padding.left: 20%, padding.right: 20%` ends up at 60% of the *parent's* total width.

Top/bottom padding resolves against parent **width** (Compose convention; iOS matches). This is intentional cross-platform consistency.
