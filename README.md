<p align="center">
  <img src="https://github.com/CleverTap/clevertap-ios-sdk/blob/master/docs/images/clevertap-logo.png" height="220"/>
</p>

# CleverTap Native Display SDK
![API 23+](https://img.shields.io/badge/API-23%2B-blue.svg)
![Kotlin 1.9+](https://img.shields.io/badge/Kotlin-1.9%2B-blue.svg)
![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-blue.svg)

Render server-driven native UI campaigns delivered by CleverTap — using Jetpack Compose on Android and SwiftUI on iOS. No WebViews.
The SDK receives a JSON campaign config from the CleverTap backend and renders it as fully native UI. Layouts, styles, themes, and dynamic variables are all controlled server-side without app updates.

---

## Choose your platform

Integration is documented per platform. Pick your stack and follow the guide end-to-end — install, integration, event hooks, fonts, and troubleshooting:

| Platform | Guide | UI stacks covered |
|----------|-------|-------------------|
| **iOS** | **[iOS Integration →](docs/INTEGRATION_IOS.md)** | SwiftUI · UIKit · Objective-C |
| **Android** | **[Android Integration →](docs/INTEGRATION_ANDROID.md)** | Jetpack Compose · XML / Views |

**More references**

- [Core SDK Integration](docs/CORE_SDK_INTEGRATION.md) — bridge modes, listeners, fetch, standalone
- [JSON Structure Reference](docs/JSON_STRUCTURE_REFERENCE.md) — full campaign JSON schema

---

## Requirements

| Platform | Minimum |
|----------|---------|
| Android | API 23+, Kotlin 1.9+, Jetpack Compose |
| iOS | iOS 15+, Swift 5.9+, SwiftUI |

> **Prerequisite — CleverTap Core SDK.** The Native Display SDK is a renderer; it expects display units to be delivered by the CleverTap Core SDK. Install and initialize it first:
> [Android Core SDK](https://github.com/CleverTap/clevertap-android-sdk) · [iOS Core SDK](https://github.com/CleverTap/clevertap-ios-sdk) · [General docs](https://docs.clevertap.com)
>
> You can also run the Display SDK in standalone mode (no Core SDK) and feed JSON manually — see the Approach 2 section in each platform guide.

---

## How it works

1. You author a **Native Display** campaign on the CleverTap dashboard (or feed JSON directly).
2. The CleverTap Core SDK delivers the campaign's JSON config to the device.
3. This SDK parses the JSON and renders it as fully native UI — into a **slot** you declare, or a view you place yourself.

Two integration paths exist in every platform guide: **Approach 1** (slot-based, recommended) and **Approach 2** (custom rendering / standalone).

---

## Supported Elements

Campaigns are composed of **containers** (which hold children) and **elements** (leaf nodes):

**Containers**

| Type | Description |
|------|-------------|
| `VERTICAL` | Stack children vertically |
| `HORIZONTAL` | Stack children horizontally |
| `BOX` | Overlay / absolute positioning |
| `GALLERY` | Scrollable carousel (snapping or free-flow) |

**Elements**

| Type | Description |
|------|-------------|
| `TEXT` | Styled text, supports `{{variable}}` templates |
| `IMAGE` | Remote image or GIF |
| `BUTTON` | Tappable button with actions |
| `VIDEO` | Inline video with optional controls and autoplay |
| `HTML` | WebView-rendered rich content |
| `SPACER` | Fixed or flexible spacing |
| `DIVIDER` | Visual separator |

Full schema, layout system, and styling rules: **[JSON Structure Reference](docs/JSON_STRUCTURE_REFERENCE.md)**.

---

## Creating a Native Display campaign

This SDK is the **renderer**. The most complete way to drive it is the **Native Display** feature of the CleverTap Core SDK — authored on the dashboard, delivered by the Core SDK at runtime. Going through the dashboard gives you targeting, scheduling, A/B testing, and end-to-end attribution out of the box.

To create one:

1. Sign in to the CleverTap dashboard and open **Campaigns → Create → Native Display**.
2. Use the **Advanced Builder** to compose the layout — pick containers (`VERTICAL`, `HORIZONTAL`, `BOX`, `GALLERY`), drop in elements (`TEXT`, `IMAGE`, `BUTTON`, `VIDEO`, `HTML`), and bind variables.
3. Target the slot ID (or audience segment) and publish — the campaign reaches users through the Core SDK's display unit pipeline that this SDK listens to.

Full dashboard documentation: **[Native Display — CleverTap docs](https://docs.clevertap.com/docs/native-display)**.

If your use case calls for it, you can also feed JSON to the renderer directly — see the Approach 2 (custom rendering / standalone) section in your platform guide. You'll lose the dashboard-side targeting and attribution loop, so this is rarely the right call.

---

## Campaign JSON

The examples below show the JSON shape this SDK consumes. In a typical setup you won't hand-write these — the CleverTap dashboard authors them and the Core SDK delivers them — but the format is open.

> The complete schema — layout system, aspect ratios, percentage layouts, and styling rules — is documented in the **[JSON Structure Reference](docs/JSON_STRUCTURE_REFERENCE.md)**.

### Minimal example — text + button

```json
{
  "theme": {
    "textColor": "#111111",
    "fontSize": 16
  },
  "variables": {
    "userName": "Alex"
  },
  "root": {
    "type": "VERTICAL",
    "layout": { "width": "match_parent", "padding": 16 },
    "children": [
      {
        "type": "TEXT",
        "bindings": { "text": "Welcome back, {{userName}}!" },
        "style": { "fontSize": 22, "fontWeight": "bold" }
      },
      {
        "type": "BUTTON",
        "bindings": { "text": "Shop Now" },
        "actions": {
          "onClick": { "type": "open_url", "url": "https://example.com" }
        }
      }
    ]
  }
}
```

<details>
<summary><b>Image banner with overlay text</b></summary>

```json
{
  "root": {
    "type": "BOX",
    "layout": { "width": "match_parent", "height": { "value": 200, "unit": "dp" } },
    "children": [
      {
        "type": "IMAGE",
        "bindings": { "url": "https://example.com/banner.jpg" },
        "layout": { "width": "match_parent", "height": "match_parent" }
      },
      {
        "type": "TEXT",
        "bindings": { "text": "Limited Time Offer" },
        "layout": { "width": "match_parent" },
        "style": {
          "textColor": "#FFFFFF",
          "fontSize": 24,
          "fontWeight": "bold",
          "backgroundColor": "#00000066"
        }
      }
    ]
  }
}
```
</details>

<details>
<summary><b>Horizontal card row</b></summary>

```json
{
  "root": {
    "type": "HORIZONTAL",
    "layout": {
      "width": "match_parent",
      "padding": 12,
      "arrangement": { "strategy": "spaced", "spacing": 8 }
    },
    "children": [
      {
        "type": "IMAGE",
        "bindings": { "url": "https://example.com/product.jpg" },
        "layout": { "width": { "value": 80, "unit": "dp" }, "height": { "value": 80, "unit": "dp" } },
        "style": { "borderRadius": 8 }
      },
      {
        "type": "VERTICAL",
        "layout": { "width": "match_parent" },
        "children": [
          {
            "type": "TEXT",
            "bindings": { "text": "Premium Sneakers" },
            "style": { "fontWeight": "bold", "fontSize": 16 }
          },
          {
            "type": "TEXT",
            "bindings": { "text": "$79.99" },
            "style": { "textColor": "#E53935", "fontSize": 14 }
          },
          {
            "type": "BUTTON",
            "bindings": { "text": "Add to Cart" },
            "actions": {
              "onClick": { "type": "custom", "key": "add_to_cart", "value": "sku_123" }
            }
          }
        ]
      }
    ]
  }
}
```
</details>

---

## Support

- **Documentation**: [docs.clevertap.com](https://docs.clevertap.com)
- **Issues**: [GitHub Issues](https://github.com/CleverTap/clevertap-native-display/issues)
- **Email**: support@clevertap.com
