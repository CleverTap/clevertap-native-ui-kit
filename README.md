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

## Quick Start

This section walks you through the full setup from scratch — initialization, listening for campaigns, and rendering them in your UI.

### Android — complete example

**Step 1: Initialize in your `Application` class**

```kotlin
// MyApplication.kt
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // If you use the CleverTap Core SDK, call initialize() to auto-wire
        // campaign delivery from the backend.
        NativeDisplayBridge.initialize(this)
    }
}
```

Don't forget to register it in `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApplication"
    ... >
```

**Step 2: Listen for campaigns and store them in state**

```kotlin
// HomeViewModel.kt
class HomeViewModel : ViewModel() {

    private val _campaigns = MutableStateFlow<List<NativeDisplayUnit>>(emptyList())
    val campaigns: StateFlow<List<NativeDisplayUnit>> = _campaigns.asStateFlow()

    private val bridgeListener = object : NativeDisplayBridgeListener {
        override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
            // Called whenever the backend delivers new campaigns.
            // Update your state so the UI recomposes automatically.
            _campaigns.value = units
        }
    }

    init {
        NativeDisplayBridge.getInstance().addListener(bridgeListener)
    }

    override fun onCleared() {
        super.onCleared()
        NativeDisplayBridge.getInstance().removeListener(bridgeListener)
    }
}
```

**Step 3: Render campaigns in your Composable**

```kotlin
// HomeScreen.kt
@Composable
fun HomeScreen(viewModel: HomeViewModel = viewModel()) {
    val campaigns by viewModel.campaigns.collectAsState()

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {

        Text("Featured Offers", style = MaterialTheme.typography.headlineSmall)

        Spacer(modifier = Modifier.height(12.dp))

        // Render the first available campaign, if any
        val campaign = campaigns.firstOrNull()
        if (campaign != null) {
            NativeDisplayView(
                unit = campaign,
                modifier = Modifier.fillMaxWidth(),
                actionListener = rememberActionListener()
            )
        }
    }
}

@Composable
fun rememberActionListener(): NativeDisplayActionListener {
    return remember {
        object : NativeDisplayActionListener {
            override fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean {
                // Return false to let the SDK handle it with the default browser.
                // Return true if your app already handled it (e.g. deep link routing).
                return false
            }

            override fun onTrackEvent(eventName: String, properties: Map<String, Any>?) {
                // Forward to your own analytics if needed.
                // CleverTap attribution events are tracked automatically.
            }

            override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
                // Handle any custom actions you defined in the campaign JSON.
            }
        }
    }
}
```

---

### iOS — complete example

**Step 1: Initialize in your `AppDelegate` or `@main` entry point**

```swift
// AppDelegate.swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize the SDK. If you use CleverTap Core SDK, pass the instance
        // to auto-wire campaign delivery from the backend.
        NativeDisplayBridge.shared.initialize()
        // NativeDisplayBridge.shared.bind(CleverTap.sharedInstance())  ← with Core SDK

        return true
    }
}
```

Using SwiftUI lifecycle instead? Initialize in your `App` struct:

```swift
// MyApp.swift
@main
struct MyApp: App {
    init() {
        NativeDisplayBridge.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Step 2: Listen for campaigns and store them in state**

```swift
// HomeViewModel.swift
import Combine

class HomeViewModel: ObservableObject {

    @Published var campaigns: [NativeDisplayUnit] = []

    private var listener: NativeDisplayBridgeListener?

    init() {
        // Keep a strong reference to the listener or it will be deallocated.
        listener = BridgeListener { [weak self] units in
            DispatchQueue.main.async {
                self?.campaigns = units
            }
        }
        NativeDisplayBridge.shared.addListener(listener!)
    }

    deinit {
        if let listener { NativeDisplayBridge.shared.removeListener(listener) }
    }
}

// A small helper to avoid subclassing in every view model.
private class BridgeListener: NativeDisplayBridgeListener {
    let handler: ([NativeDisplayUnit]) -> Void
    init(_ handler: @escaping ([NativeDisplayUnit]) -> Void) { self.handler = handler }

    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        handler(units)
    }
}
```

**Step 3: Render campaigns in your SwiftUI view**

```swift
// HomeView.swift
struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                Text("Featured Offers")
                    .font(.headline)

                // Render the first available campaign, if any
                if let campaign = viewModel.campaigns.first {
                    NativeDisplayView(
                        unit: campaign,
                        actionListener: MyActionListener()
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
    }
}

class MyActionListener: NativeDisplayActionListener {

    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        // Return false to let the SDK handle it with Safari.
        // Return true if your app already handled it (e.g. deep link routing).
        return false
    }

    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        // Forward to your own analytics if needed.
    }

    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {
        // Handle any custom actions you defined in the campaign JSON.
    }
}
```

---

## Setup (detailed)

### Android

Initialize the bridge in your `Application.onCreate()`. If you use the CleverTap Core SDK, call `initialize` to auto-wire display unit delivery:

```kotlin
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        NativeDisplayBridge.initialize(this).addListener(myBridgeListener)
    }
}
```

Without the Core SDK, create a standalone bridge and feed JSON manually:

```kotlin
val bridge = NativeDisplayBridge.create()
bridge.addListener(myBridgeListener)
```

### iOS

Initialize the bridge in your `AppDelegate` or app entry point:

```swift
NativeDisplayBridge.shared.initialize()
NativeDisplayBridge.shared.addListener(myBridgeListener)
```

To auto-wire with the CleverTap Core SDK:

```swift
NativeDisplayBridge.shared.bind(cleverTap)
```

---

## Rendering a Campaign

### Android

Use `NativeDisplayView` inside any Composable. Pass the `NativeDisplayUnit` received from the bridge for full attribution tracking (`Notification Viewed` / `Notification Clicked`):

```kotlin
@Composable
fun MyCampaignSlot(unit: NativeDisplayUnit) {
    NativeDisplayView(
        unit = unit,
        modifier = Modifier.fillMaxWidth(),
        actionListener = myActionListener
    )
}
```

### iOS

Use `NativeDisplayView` inside any SwiftUI view:

```swift
struct MyCampaignSlot: View {
    let unit: NativeDisplayUnit

    var body: some View {
        NativeDisplayView(
            unit: unit,
            actionListener: myActionListener
        )
    }
}
```

---

## Handling Actions

Implement `NativeDisplayActionListener` to respond to user interactions and track events.

### Android

```kotlin
val actionListener = object : NativeDisplayActionListener {
    override fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean {
        // Return true if your app handled it, false to use default behaviour
        return false
    }

    override fun onTrackEvent(eventName: String, properties: Map<String, Any>?) {
        // Forward to your analytics layer
    }

    override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
        // Handle custom actions defined in the campaign JSON
    }
}
```

### iOS

```swift
class MyActionListener: NativeDisplayActionListener {
    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        // Return true if your app handled it, false to use default behaviour
        return false
    }

    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        // Forward to your analytics layer
    }

    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {
        // Handle custom actions defined in the campaign JSON
    }
}
```

---

## Listening for Campaigns

Implement `NativeDisplayBridgeListener` to be notified when campaigns arrive.

### Android

```kotlin
val bridgeListener = object : NativeDisplayBridgeListener {
    override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
        // Units are ready to render — update your UI
    }
}
```

### iOS

```swift
class MyBridgeListener: NativeDisplayBridgeListener {
    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        // Units are ready to render — update your UI
    }
}
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
- On Android, make sure `NativeDisplayBridge.initialize(this)` is called in `Application.onCreate()`, not in an `Activity`.
- On iOS, initialize before the first view appears — do it in `AppDelegate` or the `App` struct `init()`.
- Make sure you're holding a strong reference to your listener object. If it's a local variable, it will be garbage-collected before any callback fires.

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
