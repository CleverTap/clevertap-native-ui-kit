---
title: px — raw pixels
sidebar_label: px
description: Bypass density scaling. Avoid in production layouts.
---

# px

`px` (raw pixels) is a **device-pixel** value — not density-scaled, not accessibility-scaled. It's the lowest-level unit in the SDK.

In almost every layout, you do **not** want `px`. Prefer [`dp`](/dimensions/dp) for layout, [`sp`](/dimensions/sp) for text, [`percent`](/dimensions/percent) for responsive sizing.

| Platform | What `px` means |
|----------|-----------------|
| Android | Raw device pixels. A `40 px` button is 40 hardware pixels — visually tiny on a 3× density device, large on a 1× tablet. |
| iOS | Currently treated identically to points (no separate raw-pixel concept). |

The Android–iOS mismatch is intentional: iOS doesn't expose a "raw pixel" abstraction in SwiftUI without dropping into Core Graphics, and the use cases for `px` are rare enough that the SDK accepts the divergence rather than introducing a host-specific shim.

## JSON syntax

```json
{ "value": 1, "unit": "px" }
```

## When `px` is acceptable

- A 1-pixel hairline divider on Android specifically (where `1 dp` rounds to 2-3 physical pixels and looks chunky on high-density screens).
- Pixel-perfect alignment with a server-pre-rendered image where you've also pre-computed the device's pixel ratio. Rare.

## When `px` is wrong

Almost everywhere else. If your design system uses `px` values from a Figma file, those values are usually meant to be `dp` — Figma's "px" is a logical unit, not a device pixel.

## Resolution

| Platform | Code | File |
|----------|------|------|
| Android | Raw integer pixels (no scaling) | `ModifierExtensions.kt:128, 142` |
| iOS | Same as `dp` (points) | `NativeDisplayRenderer.swift` |

## See also

- [`dp`](/dimensions/dp) — what you almost certainly want instead
- [Percent dimensions](/dimensions/percent)
- [Dimensions overview](/dimensions/overview)
