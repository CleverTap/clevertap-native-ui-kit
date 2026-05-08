---
title: sp — scaled pixels for text
sidebar_label: sp
description: Font sizing unit that respects the user's accessibility scale.
---

# sp

`sp` (scale-independent pixels) is the **recommended unit for text sizing**. It behaves like [`dp`](/dimensions/dp) **plus** the user's font-size accessibility setting.

| Platform | What `sp` means |
|----------|-----------------|
| Android | 1 sp = 1 dp × user's font scale (`Settings → Accessibility → Font size`). A `16 sp` heading becomes `19 sp` if the user has bumped accessibility scale to 1.2×. |
| iOS | Treated as the equivalent point value, scaled via Dynamic Type (when the host app is set up to honour it). |

## JSON syntax

```json
{ "value": 16, "unit": "sp" }
```

## When to use sp

- Every `fontSize` in a `style` block.
- Every `lineHeight` in a `style` block.
- Anywhere the value visually represents text — e.g. icon-sized-as-a-glyph if you want it to scale with text.

## When NOT to use sp

- Layout dimensions (`width`, `height`, `padding`) — use [`dp`](/dimensions/dp). If your text gets bigger but the container stays the same, the text simply re-flows into more lines; that's the right behaviour.
- Border thickness, divider thickness — use `dp`.

## Example

```json
{
  "type": "element",
  "elementType": "text",
  "id": "headline",
  "bindings": { "text": "Heading" },
  "style": {
    "fontSize":   { "value": 24, "unit": "sp" },
    "lineHeight": { "value": 32, "unit": "sp" }
  }
}
```

## Why this matters

Users who increase font scale for low-vision accessibility need text to actually grow. If you size text in `dp` (or worse, `px`), it ignores their setting — a real accessibility regression. `sp` is the default unit for `fontSize` in Material guidelines and HIG (via Dynamic Type) for exactly this reason.

## See also

- [`dp`](/dimensions/dp) — layout sizing
- [Percent dimensions](/dimensions/percent) — responsive sizing
- [TEXT element](/components/elements/text)
