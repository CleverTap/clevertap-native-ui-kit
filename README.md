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

## Requirements

| Platform | Minimum |
|----------|---------|
| Android | API 23+, Kotlin 1.9+, Jetpack Compose |
| iOS | iOS 15+, Swift 5.9+, SwiftUI |

---

## Installation

> **Prerequisite — CleverTap Core SDK.** The Native Display SDK is a renderer; it expects display units to be delivered by the CleverTap Core SDK. Install and initialize it first:
> [Android Core SDK](https://github.com/CleverTap/clevertap-android-sdk) · [iOS Core SDK](https://github.com/CleverTap/clevertap-ios-sdk) · [General docs](https://docs.clevertap.com)
>
> You can also run the Display SDK in standalone mode (no Core SDK) and feed JSON manually — see [Approach 2](#approach-2--custom-rendering) below.

### Android

Add the SDK to your module's `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.clevertap.android:native-display-sdk:<version>")

    // Required only if your campaigns include video elements
    implementation("androidx.media3:media3-exoplayer:<version>")
}
```

### iOS

Add the package in Xcode via **File → Add Package Dependencies**:

```
https://github.com/CleverTap/clevertap-native-display-ios
```

Or add it to your `Package.swift`:

```swift
.package(url: "https://github.com/CleverTap/clevertap-native-display-ios", from: "<version>")
```

---

## Integration

### Prerequisite: CleverTap Core SDK

The Native Display SDK is a renderer — display unit JSON is delivered by the CleverTap Core SDK. Install and initialize it before going further: [Android Core SDK](https://github.com/CleverTap/clevertap-android-sdk) · [iOS Core SDK](https://github.com/CleverTap/clevertap-ios-sdk).

Two integration paths are supported. **Approach 1** (slot-based) is recommended for most apps. **Approach 2** (custom rendering) is for hosts that need to inspect units, place them in custom layouts, or run standalone without the Core SDK.

---

### Approach 1 — Slot-based integration (recommended)

The slot flow is the shortest path to a working integration. The SDK manages discovery, listening, attribution, and lifecycle — your only job is to declare *where* a unit can appear and *which* slot ID maps to it.

**Step 1 — Initialize the bridge** in your app entry point.

Android — `Application.onCreate()`:
```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        NativeDisplayBridge.initialize(this)
    }
}
```

iOS — `AppDelegate` or SwiftUI `App.init()`:
```swift
@main
struct MyApp: App {
    init() {
        NativeDisplayBridge.shared.initialize()
    }
    var body: some Scene { WindowGroup { ContentView() } }
}
```

**Step 2 — Link with CleverTap Core** so server-pushed units flow into the bridge.

- **Android**: `NativeDisplayBridge.initialize(context)` auto-detects the Core SDK on the classpath via reflection — Step 1 already linked you, no extra call needed.
- **iOS**: explicitly bind the Core SDK instance once it's available:

```swift
if let cleverTap = CleverTap.sharedInstance() {
    NativeDisplayBridge.shared.bind(cleverTap)
}
```

**Step 3 — Drop a slot view** in your UI with the slot ID configured on the dashboard. The SDK looks it up, picks the matching unit, and renders it. While no unit is present, the slot shows your placeholder (or stays empty by default).

Android — Jetpack Compose:
```kotlin
NativeDisplaySlot(
    slotId = "hero_banner",
    modifier = Modifier.fillMaxWidth(),
    loading = { /* optional placeholder, e.g. shimmer or Box */ },
)
```

Android — XML:
```xml
<com.clevertap.android.nativedisplay.placement.NativeDisplaySlotView
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    app:slotId="hero_banner" />
```

iOS — SwiftUI:
```swift
NativeDisplaySlot(slotId: "hero_banner") {
    // optional placeholder view, e.g. ProgressView()
}
```

iOS — UIKit:
```swift
let slot = NativeDisplaySlotUIView(slotId: "hero_banner")
view.addSubview(slot)
```

For list-driven UIs, the SDK ships cell wrappers: `NativeDisplaySlotTableViewCell.configure(slotId:)` for `UITableView` and `NativeDisplaySlotCollectionViewCell.configure(slotId:)` for `UICollectionView`.

Slot views auto-register with the bridge on attach and auto-unregister on detach — there's no listener to manage.

---

### Approach 2 — Custom rendering

Choose this when you need to inspect units before rendering, place them in custom layouts (carousels, RecyclerViews, dynamic Compose graphs), filter by metadata, or run standalone without the Core SDK.

After Steps 1 & 2 above, attach a `NativeDisplayBridgeListener` and render each unit with the renderer that fits your UI layer.

**Step A — attach the listener**

Android:
```kotlin
val bridgeListener = object : NativeDisplayBridgeListener {
    override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
        // Store in your state, then render with one of the options below
    }
}
NativeDisplayBridge.getInstance().addListener(bridgeListener)
```

iOS:
```swift
class MyBridgeListener: NativeDisplayBridgeListener {
    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        // Store in your state, then render with one of the options below
    }
}
NativeDisplayBridge.shared.addListener(myBridgeListener)
```

Hold a strong reference to your listener — if it's a local variable, it will be released before any callback fires.

**Step B — render each unit**

Android — Jetpack Compose:
```kotlin
@Composable
fun CampaignBanner(unit: NativeDisplayUnit) {
    NativeDisplayView(
        unit = unit,
        modifier = Modifier.fillMaxWidth(),
        actionListener = myActionListener,
    )
}
```

Android — XML / View system. Add `NativeDisplayViewGroup` to your layout, then call `setUnit(...)` when a unit arrives:
```xml
<com.clevertap.android.nativedisplay.view.NativeDisplayViewGroup
    android:id="@+id/campaign_banner"
    android:layout_width="match_parent"
    android:layout_height="wrap_content" />
```
```kotlin
findViewById<NativeDisplayViewGroup>(R.id.campaign_banner)
    .setUnit(unit, actionListener = myActionListener)
```

iOS — SwiftUI:
```swift
struct CampaignBanner: View {
    let unit: NativeDisplayUnit
    var body: some View {
        NativeDisplayView(unit: unit, actionListener: myActionListener)
    }
}
```

iOS — UIKit. Instantiate `NativeDisplayUIView` with the unit and add it as a subview:
```swift
let banner = NativeDisplayUIView(
    unit: unit,
    actionListener: myActionListener
)
view.addSubview(banner)
```

**Standalone mode** (no Core SDK): feed units yourself. Same `onNativeDisplaysLoaded` callback fires.

```kotlin
// Android
val bridge = NativeDisplayBridge.create()
bridge.addListener(bridgeListener)
bridge.processDisplayUnits(jsonStrings)
```

```swift
// iOS
NativeDisplayBridge.shared.addListener(myBridgeListener)
NativeDisplayBridge.shared.processDisplayUnits(jsonStrings)
```

---

### Augmenting either approach — Fetch on demand

By default the Core SDK pushes units when they're ready. To pull on demand (e.g. screen open, pull-to-refresh):

```kotlin
// Android
NativeDisplayBridge.getInstance().fetchNativeDisplays(cleverTapApi)
```

```swift
// iOS
NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap.sharedInstance())
```

Both calls return a `Bool` indicating that the **request was dispatched** — not that the fetch completed. Results arrive asynchronously via the same `onNativeDisplaysLoaded` callback. This works orthogonally to either approach above: slots in Approach 1 refresh automatically, custom listeners in Approach 2 fire again.

---

## Event hooks

The renderer surfaces two listeners. Attach one or both to a slot or to `NativeDisplayView` to react to user interactions and run your own logic.

### NativeDisplayActionListener — high-level outcomes

Semantic callbacks that describe what the user did:

| Callback | Purpose |
|----------|---------|
| `onOpenUrl(url, openInBrowser) -> Bool` | Return `true` if your app handled it (e.g. deep-link router); `false` to let the SDK open it. |
| `onCustomAction(key, value, metadata)` | Handle custom actions defined in the campaign JSON. |
| `onNavigate(destination, params)` | In-app navigation actions. |
| `onTrackEvent(eventName, properties)` | Forward to your analytics layer if needed. |
| `onDisplayUnitViewed(unitId)` / `onDisplayUnitClicked(unitId)` | Attribution callbacks — Core SDK already tracks these automatically; implement only if you need a copy. |

### NativeDisplayComponentListener — low-level node interactions

Raw gestures on specific nodes by ID. Use this when you need to intercept individual taps, long presses, or double-taps before the SDK handles them.

| Member | Purpose |
|--------|---------|
| `onComponentInteraction(nodeId, interactionType, hasServerAction) -> Bool` | Return `true` to consume the interaction; `false` to let the SDK proceed with default behavior. |
| `getInterestedNodeIds(): Set<String>?` | Narrow callbacks to specific node IDs; `null` (default) means all nodes. |
| `InteractionType` | `CLICK` / `LONG_PRESS` / `DOUBLE_TAP` (Android) · `.click` / `.longPress` / `.doubleTap` (iOS). |

### Attaching listeners

Both listeners can be attached to a slot view or directly to `NativeDisplayView`:

```kotlin
// Android
NativeDisplaySlot(
    slotId = "hero_banner",
    actionListener = myActionListener,
    componentListener = myComponentListener,
)
```

```swift
// iOS
NativeDisplaySlot(
    slotId: "hero_banner",
    actionListener: myActionListener,
    componentListener: myComponentListener,
)
```

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

---

## Campaign JSON

Campaigns are JSON configs served by CleverTap. You create them in the CleverTap dashboard — you do not write these configs manually in your app. The examples below are for reference so you understand what the SDK receives.

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

### Image banner with overlay text

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

### Horizontal card row

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

---

## Custom Fonts

### Android

Pass a `FontFamily` to `NativeDisplayView`:

```kotlin
NativeDisplayView(
    unit = unit,
    fontFamily = FontFamily(Font(R.font.my_font))
)
```

### iOS

Provide a font resolver via the SwiftUI environment:

```swift
NativeDisplayView(unit: unit)
    .environment(\.nativeDisplayFontResolver) { name, size, weight in
        Font.custom(name, size: size).weight(weight)
    }
```

---

## Common Mistakes

**Listener not called / campaigns never arrive**
- Confirm Step 2 of Approach 1 is complete — without a Core SDK link, no units will be pushed. For standalone testing, feed JSON yourself via `processDisplayUnits(...)` (Approach 2).
- Hold a strong reference to your listener. If it's a local variable, it will be released before any callback fires.

**Layout looks wrong or view has zero height**
- Always provide `layout.width` on the root node — use `"match_parent"` to fill the available space.
- `HTML` elements require an explicit `layout.height`; they cannot auto-size.

**Videos not playing on Android**
- Add `androidx.media3:media3-exoplayer` to your dependencies. Without it, video elements are silently skipped.

**Text wraps differently on Android vs iOS**
- Roboto (Android) and San Francisco (iOS) have different character widths. Always specify `lineHeight` in your campaign JSON for consistent results across platforms, and consider supplying the same custom font on both platforms via the custom font APIs.

---

## Support

- **Documentation**: [docs.clevertap.com](https://docs.clevertap.com)
- **Issues**: [GitHub Issues](https://github.com/CleverTap/clevertap-native-display/issues)
- **Email**: support@clevertap.com
