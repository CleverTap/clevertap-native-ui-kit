---
title: Animations
sidebar_label: Animations
description: Per-node entrance animations triggered when a node first appears.
---

# Animations

Every node accepts an optional `animation` block that fires **once**, when the node first appears on screen. Use it for hero entrances, staggered list reveals, content that fades / slides / scales in.

There's no exit-animation API in v1.0.0 — animations apply to *appearance* only.

## JSON schema

```json
{
  "animation": {
    "type":     "fade_slide_in",
    "duration": 400,
    "delay":    100,
    "easing":   "ease_out"
  }
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `type` | enum | `none` | One of the [animation types](#animation-types) below. |
| `duration` | ms | `300` | How long the animation runs. |
| `delay` | ms | `0` | Wait this long after first appearance before starting. |
| `easing` | enum | `ease_out` | One of the [easing curves](#easing-curves) below. |

## Animation types

| Type | What it does |
|------|--------------|
| `none` | No animation. Node appears instantly. |
| `fade_in` | Opacity 0 → 1. |
| `slide_in_left` | Translate from off-screen left → final position. |
| `slide_in_right` | Translate from off-screen right → final position. |
| `slide_in_top` | Translate from above → final position. |
| `slide_in_bottom` | Translate from below → final position. |
| `scale_in` | Scale 0.8 → 1.0. |
| `fade_scale_in` | Combined fade + scale. The "soft pop" effect. |
| `fade_slide_in` | Combined fade + slide-up. The "list item reveal" effect. |

## Easing curves

| Curve | Feel |
|-------|------|
| `linear` | Robotic, constant velocity. Rarely the right choice. |
| `ease_in` | Slow start, fast finish. Good for exits (not used here). |
| `ease_out` | Fast start, slow finish. **Default.** Best for entrances. |
| `ease_in_out` | Slow at both ends, fast in the middle. |
| `ease_in_back` | Slight backward overshoot at the start. |
| `ease_out_back` | Slight forward overshoot at the end. Adds a playful "pop". |
| `spring` | Physics-based bounce. Slightly different feel per platform. |

## Staggering — delay-driven sequencing

The simplest stagger pattern: give each child an incremental `delay`. List of three cards revealing one after the other:

```json
{
  "type": "container",
  "containerType": "vertical",
  "children": [
    { "..." : "...", "animation": { "type": "fade_slide_in", "duration": 300, "delay":   0, "easing": "ease_out" } },
    { "..." : "...", "animation": { "type": "fade_slide_in", "duration": 300, "delay": 100, "easing": "ease_out" } },
    { "..." : "...", "animation": { "type": "fade_slide_in", "duration": 300, "delay": 200, "easing": "ease_out" } }
  ]
}
```

## Platform parity

| Platform | Implementation |
|----------|----------------|
| Android | `Modifier.graphicsLayer { ... }` driven by `animateFloatAsState` per node. |
| iOS | SwiftUI `.onAppear` + `withAnimation(...)` modifying scale / translation / opacity state. |

`spring` is implemented as Compose's stiffness-damping spring on Android and SwiftUI's spring on iOS. Behaviour is similar but not pixel-identical.

## Performance

- Animations are local to each node — no global timeline.
- A typical screen with ~10 animating nodes adds negligible overhead.
- Hundreds of simultaneously-animating nodes will drop frames on low-end Android devices. Throttle with `delay` or use `none` for non-hero content.

## Common pitfalls

**Animations don't replay.** They fire on the node's first appearance and stay finished. Re-rendering the same config doesn't re-run them.

**`spring` differs subtly across platforms.** If pixel-exact parity matters, use `ease_out_back` instead — it's a fixed cubic curve and renders identically on both.

**Long `delay` on a fast scroll** can make the user reach the bottom of a list before the bottom items start animating, breaking the staggered-reveal feel. Cap your max delay at ~500 ms and use shorter durations.

## See also

- [Actions](/concepts/actions) — for tap-driven animations
- [Style cascading](/concepts/style-cascading) — animations are per-node, no cascade
