---
title: Style classes
sidebar_label: Style classes
description: Define reusable Style objects once, reference them from any node.
---

# Style classes

Style classes are **named, reusable Style objects** declared at the root of the config. Any node can reference one via `styleClass: "name"` and pick up that block's properties as defaults.

Think of them like CSS classes: define `cardStyle` once, apply it to every card-like BOX in the tree.

## Declaration

```json
{
  "styleClasses": [
    {
      "name": "card",
      "style": {
        "backgroundColor": "#1A1A1A",
        "borderRadius":    12,
        "borderWidth":     1,
        "borderColor":     "#FFFFFF22",
        "shadowColor":     "#00000066",
        "shadowRadius":    8
      }
    },
    {
      "name": "headline",
      "style": {
        "fontSize":   24,
        "fontWeight": "bold",
        "lineHeight": 32,
        "textColor":  "#FFFFFF"
      }
    }
  ]
}
```

`styleClasses` is an array of `{ name, style }` pairs at the top level of the config (next to `theme`, `variables`, `root`).

## Reference

Any node sets `styleClass: "name"`:

```json
{
  "type": "container",
  "containerType": "box",
  "id": "promoCard",
  "styleClass": "card",
  "children": [
    { "type": "element", "elementType": "text", "id": "title", "styleClass": "headline", "bindings": { "text": "50% off" } }
  ]
}
```

`promoCard` picks up the entire `card` style block; `title` picks up `headline`.

## Resolution order

```
Theme defaults  ──►  Style class  ──►  Inline `style`  ──►  Parent text cascade
   (lowest)                          (your `styleClass` block)        (text only, highest)
```

A node can have **both** a `styleClass` and an inline `style`:

```json
{
  "styleClass": "card",
  "style": {
    "backgroundColor": "#0066FF"  // overrides the class's #1A1A1A
  }
}
```

Inline wins property-by-property. The class's other properties (`borderRadius`, `shadowColor`, …) still apply.

## A node references **one** class

`styleClass` is a string, not an array. There's no class composition (no `class="cardA cardB"`). To layer multiple style sets, declare a class that already contains both blocks of properties.

## Platform parity

Identical between platforms. Style class resolution runs once during parsing on both Android and iOS — no per-render cost.

| Platform | Resolution | File |
|----------|------------|------|
| Android | `StyleResolver.resolve(node)` merges class → inline | `StyleResolver.kt` |
| iOS | Same logic | `StyleResolver.swift` |

## Common pitfalls

**Class name not in `styleClasses`** ⇒ silently treated as no-class. The node still renders, just without the class's defaults. Watch for typos.

**Layering classes by chaining `styleClass`** doesn't work — it's a single string, not a list. Combine the styles in a new declared class instead.

**Class wins over theme, but not over inline.** If you set both an inline `style.fontSize` and `styleClass: "headline"`, the inline value wins. That's intentional — local overrides should win over reuse.

## See also

- [Style cascading](/concepts/style-cascading)
- [Theme](/concepts/theme) — for config-wide defaults that sit below classes
- [Config structure](/concepts/config-structure)
