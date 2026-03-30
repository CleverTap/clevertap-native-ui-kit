# Native Display — Backend Payload Specification

Reference for the backend team on how to structure display unit payloads so the Native Display SDK can parse and render them.

---

## How Payloads Flow

```
Backend API response
  └─ "adUnit_notifs": [ ... ]        ← JSONArray of display units
       └─ each item is a JSONObject   ← one display unit
            └─ CleverTap Core SDK passes the raw JSONObject to the ND SDK
```

The CleverTap Core SDK reads the `adUnit_notifs` array from the API response (`DisplayUnitResponse.java`), wraps each item as a `CleverTapDisplayUnit`, and forwards the **raw JSONObject** to the Native Display SDK's bridge. The ND SDK parser then looks for the config inside that object.

---

## Display Unit Structure

Every item in the `adUnit_notifs` array is a JSON object. The ND SDK parser expects:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `wzrk_id` | string | **Yes** | Unique campaign/unit identifier. Parser rejects the unit without it. |
| `type` | string | No | e.g. `"native_display"`. Informational — not used by the ND parser. |
| `native_display_config` | object | Conditional | The ND config (shared across platforms). |
| `native_display_config_android` | object | No | Android-only ND config. Takes precedence over `native_display_config` on Android. |
| `native_display_config_ios` | object | No | iOS-only ND config. Takes precedence over `native_display_config` on iOS. |
| `custom_kv` | object | No | Flat key-value pairs passed through to the client app as `customExtras`. |
| `bg` | string | No | Legacy field — used by old display unit rendering, ignored by ND SDK. |
| `content` | array | No | Legacy field — used by old display unit rendering, ignored by ND SDK. |

> At least one of `native_display_config`, `native_display_config_android`, or `native_display_config_ios` must be present for the ND SDK to parse the unit. Otherwise the unit is silently skipped.

---

## Config Resolution Order

The ND SDK parser tries these strategies **in order** and uses the first that succeeds:

| Priority | Key | Description |
|----------|-----|-------------|
| 0 | `native_display_config_android` / `_ios` | Platform-specific config. Android checks `_android`, iOS checks `_ios`. |
| 1 | `native_display_config` | Shared config, used by both platforms. |
| 2 | `custom_kv.nd_config` | Config embedded as a JSON **string** inside `custom_kv`. |
| 3 | `root` (top-level) | Entire JSON object treated as a config (must contain a `root` key). |

For new integrations, use **Strategy 0 or 1**. Strategies 2 and 3 exist for backward compatibility.

---

## ND Config Object Schema

The value under `native_display_config` (or the platform-specific keys) is a `NativeDisplayConfig` object:

```json
{
  "theme": { },
  "styleClasses": [ ],
  "variables": { },
  "root": { }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `root` | object | **Yes** | Root UI node (container or element). Parser rejects config without it. |
| `theme` | object | No | Global theme with default styles and color palette. |
| `styleClasses` | array | No | Reusable named style definitions. |
| `variables` | object | No | Key-value pairs for template substitution (`{{varName}}`). |

---

## Payload Samples

### 1. Minimal Payload (shared config, both platforms)

```json
{
  "adUnit_notifs": [
    {
      "wzrk_id": "campaign_123",
      "type": "native_display",
      "native_display_config": {
        "root": {
          "type": "element",
          "elementType": "text",
          "bindings": { "text": "Hello World" },
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 2.0
          }
        }
      }
    }
  ]
}
```

### 2. Shared Config with Custom KV

```json
{
  "adUnit_notifs": [
    {
      "wzrk_id": "campaign_456",
      "type": "native_display",
      "native_display_config": {
        "root": {
          "type": "container",
          "containerType": "vertical",
          "children": [
            {
              "type": "element",
              "elementType": "text",
              "bindings": { "text": "Product Card" },
              "layout": {
                "width": { "value": 100, "unit": "percent" }
              }
            }
          ],
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 1.5
          }
        }
      },
      "custom_kv": {
        "placement": "home_screen",
        "campaign_type": "promotional"
      }
    }
  ]
}
```

### 3. Platform-Specific Configs (different UI per platform)

```json
{
  "adUnit_notifs": [
    {
      "wzrk_id": "campaign_789",
      "type": "native_display",
      "native_display_config_android": {
        "root": {
          "type": "element",
          "elementType": "text",
          "bindings": { "text": "Android-optimized layout" },
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 1.777
          }
        }
      },
      "native_display_config_ios": {
        "root": {
          "type": "element",
          "elementType": "text",
          "bindings": { "text": "iOS-optimized layout" },
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 1.777
          }
        }
      }
    }
  ]
}
```

- Android parses `native_display_config_android`, ignores `_ios`.
- iOS parses `native_display_config_ios`, ignores `_android`.

### 4. One Platform Customized, Shared Fallback for the Other

```json
{
  "adUnit_notifs": [
    {
      "wzrk_id": "campaign_101",
      "type": "native_display",
      "native_display_config_android": {
        "root": {
          "type": "element",
          "elementType": "text",
          "bindings": { "text": "Android-specific design" },
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 1.777
          }
        }
      },
      "native_display_config": {
        "root": {
          "type": "element",
          "elementType": "text",
          "bindings": { "text": "Default for all platforms" },
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 2.0
          }
        }
      }
    }
  ]
}
```

- Android gets `"Android-specific design"` (platform key wins).
- iOS gets `"Default for all platforms"` (no `_ios` key present, falls back to shared).

### 5. Multiple Display Units in One Response

```json
{
  "adUnit_notifs": [
    {
      "wzrk_id": "banner_001",
      "type": "native_display",
      "native_display_config": {
        "root": {
          "type": "element",
          "elementType": "image",
          "bindings": { "url": "https://example.com/banner.png" },
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 1.777
          }
        }
      }
    },
    {
      "wzrk_id": "card_002",
      "type": "native_display",
      "native_display_config": {
        "root": {
          "type": "container",
          "containerType": "vertical",
          "children": [
            {
              "type": "element",
              "elementType": "text",
              "bindings": { "text": "{{title}}" },
              "layout": {
                "width": { "value": 100, "unit": "percent" }
              }
            }
          ],
          "layout": {
            "width": { "value": 100, "unit": "percent" },
            "aspectRatio": 1.5
          }
        },
        "variables": {
          "title": "Summer Sale"
        }
      },
      "custom_kv": {
        "placement": "feed",
        "priority": "1"
      }
    }
  ]
}
```

### 6. Legacy: Config via custom_kv.nd_config (backward compat)

```json
{
  "adUnit_notifs": [
    {
      "wzrk_id": "legacy_unit",
      "custom_kv": {
        "nd_config": "{\"root\":{\"type\":\"element\",\"elementType\":\"text\",\"bindings\":{\"text\":\"Hello\"},\"layout\":{\"width\":{\"value\":100,\"unit\":\"percent\"},\"aspectRatio\":2.0}}}",
        "placement": "home"
      }
    }
  ]
}
```

> Note: `nd_config` value is a **JSON string** (escaped), not a nested object.

---

## Key Rules

1. **`wzrk_id` is mandatory** — units without it are silently dropped.
2. **`root` is mandatory inside the config** — a config object without `root` is treated as invalid.
3. **Platform keys take precedence** — if `native_display_config_android` exists, `native_display_config` is not checked on Android (same for iOS with `_ios`).
4. **Unknown keys are ignored** — the parser uses `ignoreUnknownKeys`, so you can add new fields without breaking older SDK versions.
5. **`custom_kv` is pass-through** — everything in `custom_kv` is forwarded to the client app as string key-value pairs. The client app can use these for placement logic, analytics, etc.
