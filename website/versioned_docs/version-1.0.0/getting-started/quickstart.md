---
title: Quickstart
sidebar_label: Quickstart
sidebar_position: 2
description: Wire up the bridge to the CleverTap Core SDK in 3 lines, then drop a slot.
---

# Quickstart

End-to-end happy path: a Native Display campaign you author on the CleverTap dashboard renders inside your app via a slot.

You'll do this once at app start:

1. Initialize the CleverTap Core SDK (you already have this if you use CleverTap).
2. Initialize `NativeDisplayBridge` and bind it to the Core SDK instance.
3. Place `NativeDisplaySlot` views with slot IDs that match your campaigns.

## 1 — Initialize the bridge

### Android

```kotlin title="App.kt"
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.sdk.CleverTapAPI

class App : Application() {
    override fun onCreate() {
        super.onCreate()

        // Your existing Core SDK init — you likely have this already
        val cleverTap = CleverTapAPI.getDefaultInstance(this)

        // Wire up the Native Display bridge
        val bridge = NativeDisplayBridge.initialize(this)
        cleverTap?.let {
            bridge.bind(it)                  // listen for campaign deliveries
            bridge.fetchNativeDisplays(it)   // pull any pending units
        }
    }
}
```

### iOS

```swift title="AppDelegate.swift"
import CleverTapNativeDisplay
import CleverTapSDK

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
    // Your existing Core SDK init
    CleverTap.autoIntegrate()

    // Wire up the Native Display bridge
    NativeDisplayBridge.shared.initialize()
    NativeDisplayBridge.shared.bind(CleverTap.sharedInstance())
    return true
}
```

That's it for setup. The bridge is now listening for campaign deliveries, parsing the JSON payloads, and routing each `NativeDisplayUnit` to whichever slot it targets.

## 2 — Drop a slot in your UI

Pick the platform / framework that matches your app:

| Platform | Slot view |
|----------|-----------|
| Jetpack Compose | `NativeDisplaySlot(slotId = "...")` Composable |
| Android XML / Views | `<com.clevertap.android.nativedisplay.placement.NativeDisplaySlotView app:slotId="..." />` |
| SwiftUI | `NativeDisplaySlot(slotId: "...")` view |
| UIKit / Objective-C | `NativeDisplaySlotUIView(slotId: "...")` |

Each detailed in its own platform page:

- **[Android (Compose)](/getting-started/android-compose)**
- **[Android (XML / Views)](/getting-started/android-xml)**
- **[iOS (SwiftUI)](/getting-started/ios-swiftui)**
- **[iOS (Objective-C / UIKit)](/getting-started/ios-objc)**

## 3 — Author the campaign

In the CleverTap dashboard, create a Native Display campaign with:

- **Slot ID**: the same string you pass to `NativeDisplaySlot(slotId: "...")` in your app.
- **JSON config**: defines the layout. See [Components](/components/containers/box) for the building blocks.

When the campaign is live, the Core SDK delivers it, the bridge parses it, and your slot view renders it. No code change required to ship a new campaign.

## What you don't need to do

- **You don't call `parse(json)` yourself.** The bridge owns parsing. You receive ready-to-render `NativeDisplayUnit` objects routed to slots automatically.
- **You don't manage unit lifecycle.** Slots auto-subscribe when shown, auto-unsubscribe when removed from the tree.
- **You don't have to render all campaigns in one place.** Different screens can have different slot IDs — the bridge routes each unit to the slot that wants it.

## When *manual* config rendering is the right tool

For unit tests, design previews, debugging, or flows that intentionally bypass the dashboard, you can construct a `NativeDisplayConfig` JSON directly and render it. See [Advanced → manual config](/advanced/manual-config). It's not the canonical path — most production code uses slots.
