---
title: Config structure
sidebar_label: Config structure
description: The four top-level fields of a NativeDisplayConfig.
---

# Config structure

Every UI is a single JSON object — a `NativeDisplayConfig` — with four top-level fields:

```json
{
  "theme":        { /* optional global defaults */ },
  "styleClasses": { /* optional reusable style sets */ },
  "variables":    { /* optional template values */ },
  "root":         { /* required root container or element */ }
}
```

## `root` (required)

The single root node — almost always a container, often a [BOX](/components/containers/box). Everything visible is a descendant of `root`.

## `theme` (optional)

Global defaults applied as the lowest-priority layer in style resolution. Holds a `defaultStyle` (applied to every node unless overridden) and an optional `colors` palette (named colours referenced from anywhere a colour is accepted). See [theme](/concepts/theme).

## `styleClasses` (optional)

An array of `{ name, style }` pairs declaring reusable style blocks. Any node can reference one via `styleClass: "myClassName"`. See [style classes](/concepts/style-classes-deep).

## `variables` (optional)

A name → value map referenced from string bindings using `{{variableName}}` interpolation. See [Templates and variables](/concepts/templates-and-variables).

## Style resolution order

When a node renders, its final style is computed as:

```
Theme default ──► Style class ──► Inline node style ──► Parent text-style cascade
```

(Later layers override earlier ones.) See [Style cascading](/concepts/style-cascading).

## Minimal example

```json
{
  "root": {
    "type": "container",
    "containerType": "box",
    "id": "rootBox",
    "layout": {
      "width":  { "value": 100, "unit": "percent" },
      "height": { "value": 100, "unit": "percent" }
    },
    "style": { "backgroundColor": "#101010" },
    "children": []
  }
}
```

This is the smallest legal config — an empty BOX that fills its parent.
