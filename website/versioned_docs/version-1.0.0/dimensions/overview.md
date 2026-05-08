---
title: Dimensions overview
sidebar_label: Overview
description: Why v1.0.0 ships with percent-only dimensions.
---

# Dimensions overview

Every layout-affecting field in the SDK — `width`, `height`, `padding`, `offset`, `borderRadius` — accepts a **Dimension** value. A Dimension has a `value` and a `unit`.

In v1.0.0 only one unit is documented: **`percent`**. See [percentage-based dimensions](/dimensions/percent) for the full story.

## Available units

| Unit | When to use | Page |
|------|-------------|------|
| [`percent`](/dimensions/percent) | Responsive layouts that adapt to device size. | Percent |
| [`dp`](/dimensions/dp) | Fixed layout sizes — padding, gaps, button heights. | dp |
| [`sp`](/dimensions/sp) | **Text only** — honours user's font-scale setting. | sp |
| [`px`](/dimensions/px) | Raw device pixels. Avoid in production layouts. | px |
| [`wrap_content`](/dimensions/special) | "Be exactly as big as I need." | Special |
| [`match_parent`](/dimensions/special) | "Fill the available parent space." | Special |

## Quick decision guide

- Sizing **text** → `sp`
- Sizing a **layout** that should look identical across devices → `dp`
- Sizing a **layout** that should adapt to device size → `percent`
- Wanting a child to size to **its own content** → `wrap_content`
- Wanting a child to **fill its parent** → `match_parent`
- Doing pixel-perfect alignment with a hardware-pixel asset → `px` (rare)

## Default

If a `Dimension` field is omitted from the JSON, the parser defaults to `value: 0, unit: dp` — i.e. a zero-sized dimension. Parsing never fails on a missing dimension; it just resolves to 0. Always specify dimensions explicitly when you want something visible.
