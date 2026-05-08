---
title: Theme
sidebar_label: Theme
description: Set config-wide style defaults and a named-colour palette.
---

# Theme

The optional `theme` block at the root of a config sets **defaults** that every node inherits unless it sets its own value. Use it to centralise brand colour, default text colour, default font family, and a named-colour palette referenced from elsewhere in the JSON.

```json
{
  "theme": {
    "id": "brandDark",
    "defaultStyle": {
      "textColor":  "#FFFFFF",
      "fontFamily": "InterVariable",
      "fontSize":   16,
      "lineHeight": 24,
      "backgroundColor": "#101820"
    },
    "colors": {
      "brand":   "#FF6B6B",
      "accent":  "#0066FF",
      "muted":   "#999999",
      "danger":  "#E63946"
    }
  },
  "root": { /* ... */ }
}
```

## Resolution order

```
Theme defaults  ──►  styleClass  ──►  inline style  ──►  parent text cascade
   (lowest)                                              (highest, text only)
```

Theme is the **lowest-priority layer**. Anything more specific wins. See [Style cascading](/concepts/style-cascading) for the full picture.

## `defaultStyle`

A regular `Style` object. Every property in this block becomes the implicit default for the entire tree. Useful for:

- Brand-wide font family
- Default text colour against a dark background
- Default font size that flows through every TEXT and BUTTON

If a node sets `style.fontFamily: "Special"`, that wins. If a node sets nothing, it inherits the theme value.

## `colors` — named palette

A `name → hex` map referenced from anywhere a colour is accepted. Many style fields accept a colour name as well as a hex literal:

```json
{
  "style": {
    "backgroundColor": "brand",
    "textColor":       "muted"
  }
}
```

Named colours are resolved by `StyleResolver` before rendering. Useful for theming consistency — change one entry in the palette and every reference updates.

## Platform parity

| Platform | Resolution code | File |
|----------|-----------------|------|
| Android | `StyleResolver.resolveAll(...)` | `StyleResolver.kt:15–48` |
| iOS | `StyleResolver.resolveAll(...)` | `StyleResolver.swift` |

Both platforms run resolution exactly once during config parsing — there's no per-frame cost.

## Example — minimal theme

```json
{
  "theme": {
    "defaultStyle": { "textColor": "#FFFFFF", "fontFamily": "Roboto" }
  },
  "root": {
    "type": "element",
    "elementType": "text",
    "bindings": { "text": "Hello" }
    // No `style` — picks up theme defaults
  }
}
```

## Example — palette referenced from inline styles

```json
{
  "theme": {
    "colors": { "brand": "#FF6B6B", "ink": "#0F0F12" }
  },
  "root": {
    "type": "container",
    "containerType": "box",
    "style": { "backgroundColor": "ink" },
    "children": [
      {
        "type": "element",
        "elementType": "button",
        "bindings": { "text": "Buy" },
        "style": { "backgroundColor": "brand", "textColor": "#FFFFFF" }
      }
    ]
  }
}
```

## Common pitfalls

**Theme `defaultStyle` cascades into elements only.** It defines defaults but doesn't override anything — a node's explicit `style` always wins.

**Hex vs named colour.** Both are valid in any colour-accepting field. The renderer first checks the theme palette for a match, then falls back to parsing as hex. So a palette key of `"red"` will be picked up before the literal hex `#FF0000`.

**Theme is not "live".** Changing the theme requires re-parsing the config (or shipping a new one from backend). v1.0.0 doesn't ship a runtime "switch theme" API.

## See also

- [Style cascading](/concepts/style-cascading)
- [Style classes](/concepts/style-classes-deep) — for reusable named style sets beyond the theme defaults
- [Config structure](/concepts/config-structure)
