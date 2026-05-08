---
title: Style cascading
sidebar_label: Style cascading
description: Text styles cascade. Visual styles do not.
---

# Style cascading

Style resolution in the SDK is layered. The lower layers provide defaults; the higher layers override them. There are also two distinct *kinds* of style — text and visual — that cascade through the tree differently.

## Resolution order (lowest → highest priority)

```
1. Theme default        ← optional, set on the config root
2. Style class          ← when the node sets `styleClass: "..."`
3. Inline `style` block ← on the node itself
4. Parent text cascade  ← only for text properties, only into element children
```

Higher layers override lower ones property-by-property. A node's final style is the union of all four with the highest layer winning each field.

## Text vs visual properties

| Cascades from parent? | Properties |
|-----------------------|------------|
| **Yes — text**        | `textColor`, `fontSize`, `fontFamily`, `fontWeight`, `fontStyle`, `lineHeight`, `letterSpacing`, `textDecoration`, `textAlign`, `maxLines`, `overflow`, `textShadow`, `textGradient`, `opacity` |
| **No — visual** | `backgroundColor`, `borderRadius`, `borderWidth`, `borderColor`, `shadowColor`, `shadowRadius`, `shadowOffsetX`, `shadowOffsetY`, `background` |

Setting `textColor: "#FFFFFF"` on a BOX cascades into every descendant text element. Setting `backgroundColor: "#1A1A1A"` on the same BOX **does not** cascade — only the BOX itself is filled.

This is the same model HTML/CSS uses. It matches what designers expect.

## Inline override always wins inside its layer

```json
{
  "type": "container",
  "containerType": "box",
  "styleClass": "card",        // sets backgroundColor = #FF0000
  "style": { "backgroundColor": "#00FF00" }   // wins → #00FF00
}
```

Inline > class > theme. There is no `!important`-equivalent override.
