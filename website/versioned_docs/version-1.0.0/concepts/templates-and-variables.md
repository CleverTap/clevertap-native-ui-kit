---
title: Templates and variables
sidebar_label: Templates & variables
description: Inject runtime data into JSON via {{variable}} interpolation.
---

# Templates and variables

The SDK supports a lightweight `{{variableName}}` interpolation syntax for any string-valued field. Values come from the `variables` map at the top of the config.

```json
{
  "variables": {
    "userName": "Lalit",
    "showHero": true,
    "themeColor": "#FF6B6B"
  },
  "root": {
    "type": "container",
    "containerType": "box",
    "id": "root",
    "visible": "{{showHero}}",
    "style": { "backgroundColor": "{{themeColor}}" }
  }
}
```

## Where bindings work

| Field | Binding allowed |
|-------|-----------------|
| `visible` | yes — boolean expression |
| `style.*` color fields | yes — string interpolation |
| `bindings.text` (TEXT, BUTTON) | yes |
| `bindings.url` (IMAGE, VIDEO) | yes |
| `bindings.html` / `bindings.url` (HTML) | yes |
| `actions.open_url.url`, `track_event.event`, etc. | yes |

Any string-valued field that the parser sees can carry `{{variable}}` syntax. Numeric fields cannot.

## Object-property access

Variables can be objects. Reach into them with dot notation:

```json
{
  "variables": {
    "user": { "name": "Lalit", "tier": "gold" }
  },
  "root": {
    "visible": "{{user.tier}}"
  }
}
```

## Setting variables from the host app

Variables in the JSON are placeholders. Real values are merged in by the host app before rendering — typically by the integration that fetches the config from CleverTap. See [Core SDK integration](/integrations/core-sdk) for the data flow.

## Default behaviour when a variable is missing

If `{{foo}}` is referenced but `foo` is not in the variables map, the SDK substitutes an empty string for string contexts and `false` for boolean contexts (`visible`). Configs degrade gracefully rather than crash.
