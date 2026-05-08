---
title: Percentage-based dimensions
sidebar_label: Percent
description: Resolution formula, supported properties, and pitfalls for percent units in v1.0.0.
---

# Percentage-based dimensions

In v1.0.0 the SDK supports a single dimension unit: **percent**. A percent value resolves against the parent's already-measured size, on both platforms, with the same formula:

```
resolved = parentDimension × value / 100
```

| Property | Resolves against | Both platforms |
|----------|------------------|----------------|
| `layout.width` | parent's measured width | ✓ |
| `layout.height` | parent's measured height | ✓ |
| `layout.padding.{top,bottom,left,right}` | parent's measured width (top/bottom resolve against width too — Compose convention) | ✓ |
| `layout.offset.x` | parent's measured width | ✓ |
| `layout.offset.y` | parent's measured height | ✓ |
| `style.borderRadius` | the node's resolved width (for square nodes, height) | ✓ |

**Not percent**: `style.fontSize`, `style.lineHeight`, `style.borderWidth`. These use their own units — text dimensions accept a number (sp / points) or a separate root-relative percent formula; `borderWidth` is a fixed dp value.

## JSON syntax

Two equivalent forms:

```json
{ "value": 50, "unit": "percent" }
```

The numeric `value` is in **whole percent points** (0–100). The unit string must be lowercase `percent`.

## Where percent is implemented

| Platform | Location | Method |
|----------|----------|--------|
| Android | `ModifierExtensions.kt:127, 141` (`applySizing`) | `Modifier.fillMaxWidth(value / 100f)` / `fillMaxHeight(value / 100f)` |
| Android | `ModifierExtensions.kt:200` (`percentageOffset`) | `xPercent / 100f * constraints.maxWidth` |
| iOS | `NativeDisplayRenderer.swift:464–479` (`calculateContainerSize`) | `parentSize.width * value / 100` |
| iOS | `NativeDisplayRenderer.swift:272–274` | `.offset(x: parentWidth * value / 100, ...)` |

The two implementations are intentionally identical so the same JSON renders pixel-equivalent on both platforms.

## Examples

### Half-width child centered in a full-width parent

```json
{
  "type": "container",
  "containerType": "box",
  "id": "centered",
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value": 100, "unit": "percent" }
  },
  "children": [
    {
      "type": "container",
      "containerType": "box",
      "id": "inner",
      "layout": {
        "width":  { "value": 50, "unit": "percent" },
        "height": { "value": 50, "unit": "percent" },
        "offset": {
          "x": { "value": 25, "unit": "percent" },
          "y": { "value": 25, "unit": "percent" }
        }
      },
      "style": { "backgroundColor": "#FF6B6B" }
    }
  ]
}
```

### Children at progressive percent offsets

import JsonPreview from '@site/src/components/JsonPreview';

<JsonPreview src="/test-configs/test-091-offset-percent-box-basic.json" title="test-091-offset-percent-box-basic.json" />

### Padded BOX with percent insets

<JsonPreview src="/test-configs/test-045-box-padding-large.json" title="test-045-box-padding-large.json" />

## Pitfalls

**Percent on a `wrap_content` parent resolves to 0.** Percent needs a measured size to compute against. If the parent collapses to its content (no explicit width/height), every percent child computes against width = 0 and renders invisible. Always give the root and any percent-using ancestor an explicit measurable dimension.

**Padding top/bottom resolves against parent *width*** on Android (Compose convention). iOS matches this on purpose. If you expect padding-top to be a percentage of *height*, you'll get a smaller value than you expected on tall parents.

**Sub-pixel rounding near tight boundaries.** `parent × percent / 100` can produce fractional pixels that round differently from neighbouring siblings. Differences are bounded to 1 device pixel. Don't depend on pixel-exact alignment between sibling percent values.

**Offsets are relative to the parent, not the screen.** A child of a 200dp-wide BOX with `offset.x: 50%` is displaced by 100dp — half of the *parent BOX's* width. Not half the viewport.

## Why percent first

Percent produces visually consistent layouts across the wide range of device sizes the SDK targets. It maps trivially to backend tooling: a designer specifies "card occupies 80% of width" once and it renders correctly on every device. Fixed-pixel units ([`dp`](/dimensions/dp), [`sp`](/dimensions/sp), [`px`](/dimensions/px)) are also supported when you need pixel-exact sizing.

## See also

- [Layout system](/concepts/layout-system)
- [BOX container](/components/containers/box)
- [Dimensions overview](/dimensions/overview)
