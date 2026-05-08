---
title: Backend payload spec
sidebar_label: Backend payload
description: Exact JSON shape the bridge expects from the CleverTap backend.
---

# Backend payload spec

If you're authoring backend tooling that produces Native Display configs (rather than consuming them via the CleverTap dashboard), you need the exact wire shape the bridge expects.

## Top-level display-unit envelope

Each display unit is a JSON object delivered inside the Core SDK's `adUnit_notifs` response key:

```json
{
  "wzrk_id":          "uniqueUnitId",
  "slot_id":          "hero_banner",
  "type":             "native_display",
  "native_display_config": { /* see below */ },
  "custom_kv": { "anyKey": "anyValue" }
}
```

| Field | Required | Meaning |
|-------|----------|---------|
| `wzrk_id` | yes | Unique per unit. Survives until the unit is dismissed or replaced. |
| `slot_id` | yes | Logical placement (e.g. `home_hero`, `cart_promo`). Multiple units can target the same slot. |
| `type` | yes | Must be `native_display` for the bridge to claim the unit. |
| `native_display_config` | yes | The full [`NativeDisplayConfig`](/concepts/config-structure). |
| `custom_kv` | optional | Free-form host-app data. Not used by the SDK; passed through verbatim on `NativeDisplayUnit.customKV`. |

## Inner `native_display_config`

```json
{
  "theme":        { /* optional */ },
  "styleClasses": { /* optional */ },
  "variables":    { /* optional */ },
  "root":         { /* required */ }
}
```

In v1.0.0 the only documented `root` shape is a [BOX container](/components/containers/box) — children can be any container/element supported by the SDK binary, but only BOX has a documented contract for v1.0.0.

## Validation

The bridge parser is forgiving:

- Missing `theme` / `styleClasses` / `variables` → defaults to empty.
- Unknown enum values (e.g. an unknown `unit`) → falls back to the default for that field rather than rejecting the config.
- Missing `layout` on a node → all dimensions resolve to 0; the node is technically present but invisible.

This is intentional: a backend pushing a slightly-newer config to an older client should degrade gracefully rather than crash. v1.0.0 codifies this for BOX. Other components have the same tolerance in the binary.

## Sending events back

The bridge exposes `viewed` and `clicked` event hooks that thread back through the Core SDK to the CleverTap backend, surfacing display-unit attribution in dashboards. Coverage is being expanded — see the [changelog](/changelog) for current status.
