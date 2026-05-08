---
title: Arrangement strategies
sidebar_label: Arrangement
description: Seven strategies for laying out children inside VERTICAL / HORIZONTAL containers.
---

# Arrangement strategies

`VERTICAL` and `HORIZONTAL` containers control how their children are spaced via `layout.arrangement`. There are **seven** strategies. Pick one — they're mutually exclusive.

```json
{
  "layout": {
    "arrangement": {
      "strategy": "spaced",
      "spacing":  12,
      "spacingUnit": "dp"
    }
  }
}
```

> **The `spacing` field is honoured only by `spaced`.** Every other strategy ignores it.

## The seven strategies

### `spaced`

Fixed gap between every pair of children. Edges flush.

```
[child1]──spacing──[child2]──spacing──[child3]
```

```json
{ "strategy": "spaced", "spacing": 16, "spacingUnit": "dp" }
```

### `space_between`

Children flush at both edges; remaining space distributed equally between them.

```
[child1]────────[child2]────────[child3]
```

`spacing` ignored.

### `space_evenly`

Equal gap **before**, **between**, and **after** every child.

```
────[child1]────[child2]────[child3]────
```

`spacing` ignored.

### `space_around`

Equal gap on each side of each child (so end gaps are half the inter-child gap).

```
──[child1]────[child2]────[child3]──
```

`spacing` ignored.

### `start`

All children pushed to the start. No extra spacing.

```
[child1][child2][child3]
```

(`start` = top in VERTICAL, leading in HORIZONTAL.)

### `center`

All children clustered in the centre. No extra spacing between them.

```
        [child1][child2][child3]
```

### `end`

All children pushed to the end (bottom for VERTICAL, trailing for HORIZONTAL).

```
                  [child1][child2][child3]
```

## When to pick which

| Goal | Strategy |
|------|----------|
| "Always exactly 12 dp between buttons" | `spaced` with `spacing: 12` |
| "Push back button to left, more button to right" | `space_between` |
| "Three pricing tiers evenly distributed in a row" | `space_evenly` |
| "Tab bar with breathing room around each tab" | `space_around` |
| "Form fields stacked from top" | `start` (VERTICAL default-ish behaviour) |
| "Bottom-anchored CTA inside a tall column" | `end` |
| "Cluster three icons in the middle" | `center` |

## Default

If `arrangement` is omitted, the parser uses `{ strategy: "spaced", spacing: 0 }` — children touch.

If `arrangement.strategy` is set but `spacingUnit` is omitted, the unit defaults to `dp`.

## Platform parity

| Platform | Implementation |
|----------|----------------|
| Android | `Arrangement.spacedBy(...)`, `Arrangement.SpaceBetween`, etc. — all native to Compose `Column`/`Row`. |
| iOS | SwiftUI `VStack`/`HStack` only natively support `spaced` (the `spacing:` parameter). The SDK emulates the others by inserting calculated `Spacer()` views to match Android pixel-equivalent. Source: `NativeDisplayRenderer.swift:545–802`. |

The emulation is exact — same on-screen result, modulo sub-pixel rounding.

## Common pitfalls

**Setting `spacing` with a non-`spaced` strategy.** It does nothing. Either switch to `spaced` or remove the field.

**Expecting `space_between` to keep edge gaps.** It doesn't — children touch the container's edges. Add `padding` on the container if you want breathing room.

**`space_around` confused with `space_evenly`.** `around` puts a half-gap at each end; `evenly` puts a full gap. Use `evenly` for tab-bar layouts where you want symmetric distribution.

## See also

- [VERTICAL container](/components/containers/vertical)
- [HORIZONTAL container](/components/containers/horizontal)
- [Layout system](/concepts/layout-system)
