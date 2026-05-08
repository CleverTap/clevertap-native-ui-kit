---
title: dp — density-independent pixels
sidebar_label: dp
description: The default unit for layout dimensions on Android — and "points" on iOS.
---

# dp

`dp` (density-independent pixels) is the **recommended unit for layout sizing** when you want a fixed visual size that looks the same across devices.

| Platform | What `dp` means |
|----------|-----------------|
| Android | 1 dp = 1 / 160 inches at the device's logical density. Resolves via `value × density` to physical pixels. |
| iOS | Treated as **points** (1 pt = 1 dp on iPhone @1x; on @2x/@3x retina screens, 1 pt = 2 / 3 physical pixels). |

The mapping is intentional. Both platforms use a "logical pixel" abstraction — Android calls them dp, iOS calls them points, and they line up 1:1 visually. A `40 dp` button on Android and a `40 pt` button on iOS render the same physical size.

## JSON syntax

```json
{ "value": 16, "unit": "dp" }
```

## Where to use it

- Touch targets (`48 dp` is the Material minimum, `44 pt` is the iOS HIG minimum — the SDK harmonises with `48 dp`).
- Spacing between elements.
- Border thickness.
- Fixed-size icons.

For text size use [`sp`](/dimensions/sp) instead — text honours the user's accessibility scale only when expressed in `sp`.

## Resolution

| Platform | Code | File |
|----------|------|------|
| Android | `TypedValue.applyDimension(COMPLEX_UNIT_DIP, value, displayMetrics)` | `Extensions.kt:15–20` |
| iOS | `CGFloat(value)` (points) | `NativeDisplayRenderer.swift` |

## Example

```json
{
  "type": "container",
  "containerType": "vertical",
  "layout": {
    "padding": {
      "top":    { "value": 16, "unit": "dp" },
      "bottom": { "value": 16, "unit": "dp" },
      "left":   { "value": 16, "unit": "dp" },
      "right":  { "value": 16, "unit": "dp" }
    },
    "arrangement": { "strategy": "spaced", "spacing": 12, "spacingUnit": "dp" }
  }
}
```

## See also

- [Percent dimensions](/dimensions/percent) — for responsive sizing
- [`sp`](/dimensions/sp) — text-specific unit
- [`px`](/dimensions/px) — raw pixels (avoid in production)
