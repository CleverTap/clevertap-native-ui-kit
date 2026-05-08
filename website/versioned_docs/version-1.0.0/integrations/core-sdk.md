---
title: CleverTap Core SDK
sidebar_label: Core SDK bridge
description: Wire backend-pushed display units through the CleverTap Core SDK.
---

# CleverTap Core SDK integration

The Native Display SDK can run in two modes:

| Mode | When | Setup |
|------|------|-------|
| **Standalone** | You feed JSON directly (file, network, hardcoded) | None — just call the parser and render |
| **Bridge** | The CleverTap Core SDK delivers display units | Init the bridge once at app start |

Both modes render the same way once you have a `ResolvedConfig`. Only the **source** of that config differs.

## Standalone mode

Already covered in [Getting started](/getting-started/install). The SDK has zero awareness of the Core SDK in this mode — there is no runtime cost or dependency on it.

## Bridge mode

The bridge is a `compileOnly` integration on Android and an opt-in import on iOS. The Core SDK delivers display units via its `adUnit_notifs` response payload; the bridge extracts the embedded Native Display config and exposes it as a `NativeDisplayUnit`.

### Server payload shape

```json
{
  "wzrk_id": "unit_123",
  "slot_id": "hero_banner",
  "type": "native_display",
  "native_display_config": {
    "root": { "type": "container", "containerType": "box", "id": "r", "...": "..." }
  }
}
```

The bridge looks for `native_display_config` and parses it into `NativeDisplayUnit { unitId, slotId, config: ResolvedConfig, customKV }`.

### Android — bridge init

```kotlin
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        NativeDisplayBridge.initialize(applicationContext)
    }
}
```

Then subscribe to incoming units:

```kotlin
NativeDisplayBridge.getInstance()?.addListener(object : NativeDisplayBridgeListener {
    override fun onUnitsAvailable(units: List<NativeDisplayUnit>) {
        for (unit in units) {
            // hand `unit.config` to NativeDisplayView
        }
    }
})
```

### iOS — bridge init

```swift
import CleverTapNativeDisplay

NativeDisplayBridge.shared.initialize()

NativeDisplayBridge.shared.addListener { units in
    // each unit has unit.config: ResolvedConfig
}
```

### Slot-based rendering

For "show the latest unit for slot X" UX (banner carousels, hero placements), the SDK ships `NativeDisplaySlot` / `NativeDisplaySlotManager` (Android) and `NativeDisplaySlotUIView` / `NativeDisplaySlotCollectionViewCell` / `NativeDisplaySlotTableViewCell` (iOS). These auto-bind to the latest config available for a `slot_id` and re-render when new units arrive.

For the canonical slot-rendering path on each platform, see the [getting-started guides](/getting-started/quickstart).

## Display-unit attribution events

The bridge surfaces "viewed" and "clicked" hooks for each display unit so taps and impressions can be attributed back to the originating campaign in CleverTap dashboards. Coverage of every event type is being expanded — see the [changelog](/changelog) for current status.
