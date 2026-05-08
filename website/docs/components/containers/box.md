---
title: BOX container
sidebar_label: BOX
description: Z-stacked overlapping children. Foundation of cards, modals, and badge overlays.
---

# BOX

The **BOX** container z-stacks its children. Each child is laid on top of the previous in source order, anchored to the box's top-leading corner. Children can be displaced with percentage offsets to compose overlay layouts (a badge over an image, a label over a card, a backdrop behind a sheet).

All four sample apps in the repo use BOX as the foundation of their layouts. For row / column / scrolling layouts see [VERTICAL](/components/containers/vertical), [HORIZONTAL](/components/containers/horizontal), and [GALLERY](/components/containers/gallery).

## Visual example

A BOX with a single centered child is the simplest card primitive:

```
┌─────────────────────┐
│                     │
│   ┌──────────┐      │
│   │  child   │      │
│   └──────────┘      │
│                     │
└─────────────────────┘
```

A BOX with children at percent offsets composes overlays:

```
┌─────────────────────┐
│ child A (0,0)       │
│   ┌──────┐          │
│   │      │          │
│   │      │     ●  ← child B at offset.x=80%, offset.y=10%
│   └──────┘          │
└─────────────────────┘
```

## Features

- Overlapping (z-stacked) children — last child wins paint order
- Top-leading anchored on both platforms — same visual on Android and iOS
- Percentage **offsets** for absolute child positioning ([percent dimensions](/dimensions/percent))
- All visual styles supported: `backgroundColor`, `borderRadius`, `borderWidth`, `borderColor`, `shadow*`, `opacity`
- `aspectRatio` to lock the box's height to its width
- `padding` applied to the box itself before children render

## JSON schema

```json
{
  "type": "container",
  "containerType": "box",
  "id": "uniqueId",
  "children": [ /* zero or more child nodes */ ],
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value":  60, "unit": "percent" },
    "padding": { /* see dimensions */ },
    "offset":  { /* x, y, applied to BOX itself when nested */ },
    "aspectRatio": 1.5
  },
  "style": {
    "backgroundColor": "#1A1A1A",
    "borderRadius":   { "value": 4, "unit": "percent" },
    "borderWidth": 1,
    "borderColor": "#FFFFFF33",
    "opacity": 1.0
  },
  "styleClass": "card",
  "visible": "{{showHero}}",
  "actions": { "onClick": [ /* triggers */ ] },
  "animation": { /* entrance / exit */ }
}
```

| Field | Required | Type | v1.0.0 notes |
|-------|----------|------|--------------|
| `type` | yes | `"container"` | Constant. |
| `containerType` | yes | `"box"` | Constant. |
| `id` | yes | string | Must be unique within the config. |
| `children` | yes | array | Zero or more child nodes. Empty BOX is legal. |
| `layout` | recommended | object | See [Layout system](/concepts/layout-system). |
| `style` | optional | object | See [Style cascading](/concepts/style-cascading). |
| `styleClass` | optional | string | References a style class declared at config root. |
| `visible` | optional | string | Variable expression. Hides the BOX (and subtree) when false. |
| `actions` | optional | object | See [actions](/concepts/actions). |
| `animation` | optional | object | See [animations](/concepts/animations). |

## Layout behaviour

Children render in source order, each anchored to the BOX's top-leading corner. Use `layout.offset` on a child to displace it from that anchor — most layouts use percent offsets for responsive positioning. When two children declare the same offset, the later child paints on top.

**Sizing rules** (see [dimensions overview](/dimensions/overview) for the full unit set):

- A child with `layout.width: { value: 100, unit: percent }` fills the BOX horizontally.
- A child with no `layout` shrinks to its content (its own children's intrinsic size for containers, or its measured size for elements).
- The BOX itself sizes from its own `layout.width`/`height` — it does **not** size to its largest child.

## Style support

BOX honours every visual style; text styles cascade *into* BOX but BOX does not render them.

| Style property | Effect on BOX |
|----------------|---------------|
| `backgroundColor` | Fill behind all children. |
| `borderRadius` | Clips children + paints a rounded corner stroke. |
| `borderWidth`, `borderColor` | Stroke around the BOX bounds. |
| `shadowColor`, `shadowRadius`, `shadowOffsetX/Y` | Drops a shadow under the BOX. |
| `opacity` | Multiplies into every child's alpha. |
| `aspectRatio` | Locks `height = width / aspectRatio`. |

Text styles (`fontSize`, `textColor`, `fontFamily`, `fontWeight`, `lineHeight`, `letterSpacing`, `textAlign`) cascade through BOX into descendant `TEXT`/`BUTTON` elements. Visual styles do **not** cascade.

## Platform parity

| Aspect | Android (Compose) | iOS (SwiftUI) |
|--------|-------------------|----------------|
| Underlying primitive | `androidx.compose.foundation.layout.Box` | `ZStack(alignment: .topLeading)` |
| Default child anchor | `Alignment.TopStart` | `.topLeading` |
| Visual order | Source order — last child paints on top | Same |
| Source location | `RenderNode` Composable in `NativeDisplayRenderer.kt` (internal — see <ApiLink platform="android" path="clevertap-native-ui-kit/com.clevertap.android.nativedisplay.renderer/index.html">renderer package</ApiLink>) | <ApiLink platform="ios" path="documentation/clevertapnativedisplay/nativedisplayview">NativeDisplayView</ApiLink> |

Visually identical between the two platforms when given the same JSON. The only known difference is sub-pixel rounding on percent offsets near tight boundaries (≤1pt), which is platform-inherent.

## Code examples

### Single centered child

import JsonPreview from '@site/src/components/JsonPreview';

<JsonPreview src="/test-configs/test-017-box-single-child.json" title="test-017-box-single-child.json" />

### Three overlapping children

<JsonPreview src="/test-configs/test-018-box-3-children.json" title="test-018-box-3-children.json" />

### Children at percent offsets

<JsonPreview src="/test-configs/test-091-offset-percent-box-basic.json" title="test-091-offset-percent-box-basic.json" />

### Styled card (radius + shadow + padding)

<JsonPreview src="/test-configs/test-090-styled-profile-card.json" title="test-090-styled-profile-card.json" />

## Common pitfalls

**BOX does not size to its content.** Without an explicit `layout.width`/`height`, a BOX inside a `wrap_content` parent collapses to zero. Always set explicit percent (or fixed) dimensions, or set `aspectRatio`.

**Child offsets are relative to the BOX, not the screen.** A child with `offset.x: 50%` is offset by 50% of the *parent BOX's* resolved width — not 50% of the screen.

**Children paint in source order, not z-index.** There is no explicit z-order field. Reorder the `children` array to change layering.

**Percent on `wrap_content` parents resolves to 0.** A `wrap_content` parent has no measured size for percent children to resolve against — they compute width 0 and disappear. Give the parent an explicit width or use a non-percent unit on the children.

## See also

- [Percentage-based dimensions](/dimensions/percent)
- [Layout system](/concepts/layout-system)
- [Style cascading](/concepts/style-cascading)
- API: <ApiLink platform="android" path="clevertap-native-ui-kit/com.clevertap.android.nativedisplay.models/-container-type/-b-o-x/index.html">`ContainerType.BOX`</ApiLink> · <ApiLink platform="ios" path="documentation/clevertapnativedisplay/containertype/box">`ContainerType.box`</ApiLink>
