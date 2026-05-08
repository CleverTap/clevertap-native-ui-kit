---
title: GALLERY container
sidebar_label: GALLERY
description: Scrollable carousel — pager, free-flow list, or grid.
---

# GALLERY

The **GALLERY** container is a scrollable, paginating, or free-flowing carousel — pick one of three modes for the layout strategy. Use it for product carousels, image galleries, tag chip lists, hero banners with multiple slides, or any UI where children scroll past a viewport.

## Visual model — the three modes

```
SNAPPING                FREE_FLOW                FREE_FLOW_GRID
┌──────────────────┐    ┌─[A]─[B]─[C]─[D]─►     ┌─[A]─[B]─[C]─►
│  ▌  child  ▐  ←  │    │  varying widths        │  N items per
│  ▌  ◀ snap ▐     │    │  natural scroll        │  row, peek
└──────────────────┘    └────────────────►       └─────────────►
peek + page snap        no snap, no peek         fixed itemsPerView
```

| Mode | Best for | Snap | Peek | Items per view |
|------|----------|------|------|----------------|
| `snapping` | hero banners, image carousels | ✓ | ✓ | typically 1 |
| `free_flow` | tag chips, varying-width lists | ✗ | ✗ | natural |
| `free_flow_grid` | product grids | ✗ | ✓ | fixed (e.g. 2.5) |

## Features

- Three layout modes (`snapping`, `free_flow`, `free_flow_grid`)
- Horizontal or vertical scroll
- Optional snap point (`start`, `center`, `end`)
- Peek at adjacent items for visual affordance
- Optional auto-scroll, infinite-scroll, page indicators, prev/next arrows
- All visual styles work on the gallery itself; children carry their own styles

## JSON schema

```json
{
  "type": "container",
  "containerType": "gallery",
  "id": "heroCarousel",
  "children": [ /* one or more child nodes */ ],
  "layout": { "width": { "value": 100, "unit": "percent" }, "height": { "value": 220, "unit": "dp" } },
  "galleryConfig": {
    "mode": "snapping",
    "orientation": "horizontal",
    "snapBehavior": "center",
    "peek": { "before": 16, "after": 16 },
    "itemsPerView": 1,
    "spacing": 8,
    "showIndicators": true,
    "autoScrollInterval": 4000,
    "infiniteScroll": true,
    "showArrows": false,
    "initialPage": 0
  },
  "style": { /* visual styles applied to the gallery frame */ }
}
```

### `galleryConfig` reference

| Field | Type | Default | Meaning |
|-------|------|---------|---------|
| `mode` | enum | `snapping` | Layout strategy. See modes table above. |
| `orientation` | enum | `horizontal` | `horizontal` or `vertical` scroll. |
| `snapBehavior` | enum | `center` | `none`, `start`, `center`, `end`. Only honoured when `mode: snapping`. |
| `peek` | `{before, after}` in dp | `{0, 0}` | Pixels of adjacent items visible at the edges. `snapping` and `free_flow_grid` only. |
| `itemsPerView` | number | mode-dependent | `2.5` shows 2 full + half-peek. `free_flow_grid` only. |
| `spacing` | dp number | `0` | Gap between children. |
| `showIndicators` | bool | `false` | Render dots indicator. `snapping` only. |
| `autoScrollInterval` | ms | `0` | Auto-advance every N ms (0 = off). |
| `infiniteScroll` | bool | `false` | Wrap around at the ends. |
| `showArrows` | bool | `false` | Render prev/next arrows. |
| `initialPage` | int | `0` | Starting child index. |

## Mode-by-mode behaviour

### `snapping` — pager

Each child takes the full viewport width (minus peek). Scrolling snaps to the next/previous child. Use for hero banners, image carousels, onboarding sequences.

```json
{
  "galleryConfig": {
    "mode": "snapping",
    "snapBehavior": "center",
    "peek": { "before": 16, "after": 16 },
    "showIndicators": true,
    "infiniteScroll": true
  }
}
```

### `free_flow` — natural scrolling

Children size themselves; the row scrolls without snapping. Use for tag chips, side-scrolling text labels.

```json
{
  "galleryConfig": {
    "mode": "free_flow",
    "spacing": 8
  }
}
```

### `free_flow_grid` — fixed items per view

Children are forced to `1 / itemsPerView` of the viewport so a fixed count is always visible. Peek shows a slice of the next item to suggest scrollability.

```json
{
  "galleryConfig": {
    "mode": "free_flow_grid",
    "itemsPerView": 2.5,
    "spacing": 8
  }
}
```

`itemsPerView: 2.5` means 2 full children + half a child peeking — the standard product-grid pattern.

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | `HorizontalPager` / `VerticalPager` (Compose Foundation) for `snapping`; `LazyRow` / `LazyColumn` for free-flow modes | `GalleryRenderer.kt:58–100+` |
| iOS | `ScrollView` + emulated paging (no `PageView` in SwiftUI) | `NativeDisplayRenderer.swift:451–461` |

iOS emulates pager semantics with `ScrollView` + GeometryReader for snap math. Behaviour is functionally identical; the iOS emulation is roughly 60 fps on iPhone 12 and newer.

## Common pitfalls

**`peek` is dp, not percent.** Most layout fields default to percent in modern configs — `galleryConfig.peek.before / after` is **always** in dp. Don't pass a percent dimension here.

**Empty `children` crashes paging math on some Android devices.** GALLERY requires at least one child. If your data source is empty, render a placeholder child or skip the GALLERY node entirely via `visible: "{{hasItems}}"`.

**`snapping` + `itemsPerView != 1` is undefined.** `itemsPerView` is intended for `free_flow_grid`. In `snapping` mode keep it at 1 (the default).

**`infiniteScroll: true` with one child** has no effect on either platform — wrap-around needs ≥2 children.

## See also

- [Arrangement strategies](/concepts/arrangement-strategies) — used inside GALLERY children
- [Layout system](/concepts/layout-system)
- [Animations](/concepts/animations) — entrance animations apply per child as it scrolls into view
