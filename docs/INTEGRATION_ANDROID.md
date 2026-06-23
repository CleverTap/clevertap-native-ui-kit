# Android Integration — CleverTap Native Display SDK

Render server-driven native UI campaigns on Android using Jetpack Compose — with XML/View-based support for non-Compose apps. No WebViews.

← Back to the [project README](../README.md) · For the cross-platform JSON spec see [JSON Structure Reference](JSON_STRUCTURE_REFERENCE.md) · For iOS see [iOS Integration](INTEGRATION_IOS.md).

---

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Prerequisite: CleverTap Core SDK](#prerequisite-clevertap-core-sdk)
- [Approach 1 — Slot-based integration (recommended)](#approach-1--slot-based-integration-recommended)
- [Approach 2 — Custom rendering](#approach-2--custom-rendering)
- [Fetch on demand](#fetch-on-demand)
- [Event hooks](#event-hooks)
- [Custom fonts](#custom-fonts)
- [Troubleshooting](#troubleshooting)

---

## Requirements

| | Minimum |
|----------|---------|
| Android | API 23+ |
| Kotlin | 1.9+ |
| UI | Jetpack Compose (XML / Views supported via wrappers) |

---

## Installation

Add the SDK to your module's `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.clevertap.android:native-display-sdk:<version>")

    // Required only if your campaigns include video elements
    implementation("androidx.media3:media3-exoplayer:<version>")
}
```

---

## Prerequisite: CleverTap Core SDK

The Native Display SDK is a renderer — display unit JSON is delivered by the [CleverTap Android Core SDK](https://github.com/CleverTap/clevertap-android-sdk). Install and initialize it before going further.

Two integration paths are supported:

- **Approach 1 (slot-based)** — recommended for most apps. The SDK manages discovery, listening, attribution, and lifecycle.
- **Approach 2 (custom rendering)** — for hosts that need to inspect units, place them in custom layouts (RecyclerViews, dynamic Compose graphs), or run standalone without the Core SDK.

You can also run the Display SDK in standalone mode (no Core SDK) and feed JSON manually — see [Approach 2](#approach-2--custom-rendering).

---

## Approach 1 — Slot-based integration (recommended)

The slot flow is the shortest path to a working integration. Your only job is to declare *where* a unit can appear and *which* slot ID maps to it.

**Step 1 — Initialize the bridge** in your app entry point (`Application.onCreate()`):

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        NativeDisplayBridge.initialize(this)
    }
}
```

**Step 2 — Link with CleverTap Core** so server-pushed units flow into the bridge.

`NativeDisplayBridge.initialize(context)` auto-detects the Core SDK on the classpath via reflection — Step 1 already linked you, no extra call needed.

**Step 3 — Drop a slot view** in your UI with the slot ID configured on the dashboard. The SDK looks it up, picks the matching unit, and renders it. While no unit is present, the slot shows your placeholder (or stays empty by default).

Jetpack Compose:
```kotlin
NativeDisplaySlot(
    slotId = "hero_banner",
    modifier = Modifier.fillMaxWidth(),
    loading = { /* optional placeholder, e.g. shimmer or Box */ },
)
```

<details>
<summary><b>XML / Views (no Compose)</b></summary>

Declare the slot in your layout:
```xml
<com.clevertap.android.nativedisplay.placement.NativeDisplaySlotView
    android:id="@+id/hero_slot"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    app:slotId="hero_banner" />
```

Then optionally wire listeners from your Activity/Fragment:
```kotlin
findViewById<NativeDisplaySlotView>(R.id.hero_slot).apply {
    setActionListener(myActionListener)
    setComponentListener(myComponentListener)
}
```
</details>

Slot views auto-register with the bridge on attach and auto-unregister on detach — there's no listener to manage.

---

## Approach 2 — Custom rendering

Choose this when you need to inspect units before rendering, place them in custom layouts (carousels, RecyclerViews, dynamic Compose graphs), filter by metadata, or run standalone without the Core SDK.

After Steps 1 & 2 above, attach a `NativeDisplayBridgeListener` and render each unit with the renderer that fits your UI layer.

**Step A — attach the listener**

```kotlin
val bridgeListener = object : NativeDisplayBridgeListener {
    override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
        // Store in your state, then render with one of the options below
    }
}
NativeDisplayBridge.getInstance().addListener(bridgeListener)
```

Hold a strong reference to your listener — if it's a local variable, it will be released before any callback fires.

**Step B — render each unit**

Jetpack Compose:
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

<details>
<summary><b>XML / Views (no Compose)</b></summary>

Add `NativeDisplayViewGroup` to your layout:
```xml
<com.clevertap.android.nativedisplay.view.NativeDisplayViewGroup
    android:id="@+id/campaign_banner"
    android:layout_width="match_parent"
    android:layout_height="wrap_content" />
```
Then, inside the listener you attached in Step A, push each unit into the view:
```kotlin
override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
    val unit = units.firstOrNull() ?: return
    findViewById<NativeDisplayViewGroup>(R.id.campaign_banner)
        .setUnit(unit, actionListener = myActionListener)
}
```
</details>

**Standalone mode** (no Core SDK): feed units yourself. The same `onNativeDisplaysLoaded` callback fires.

```kotlin
val bridge = NativeDisplayBridge.create()
bridge.addListener(bridgeListener)
bridge.processDisplayUnits(jsonStrings)
```

---

## Fetch on demand

By default the Core SDK pushes units when they're ready. To pull on demand (e.g. screen open, pull-to-refresh):

```kotlin
NativeDisplayBridge.getInstance().fetchNativeDisplays(cleverTapApi)
```

The call returns a `Bool` indicating that the **request was dispatched** — not that the fetch completed. Results arrive asynchronously via the same `onNativeDisplaysLoaded` callback. This works orthogonally to either approach above: slots in Approach 1 refresh automatically, custom listeners in Approach 2 fire again.

---

## Event hooks

The renderer surfaces two listeners. Attach one or both to a slot or to `NativeDisplayView` to react to user interactions and run your own logic.

### NativeDisplayActionListener — high-level outcomes

Semantic callbacks that describe what the user did:

| Callback | Purpose |
|----------|---------|
| `onOpenUrl(url, openInBrowser) -> Boolean` | Return `true` if your app handled it (e.g. deep-link router); `false` to let the SDK open it. |
| `onCustomAction(key, value, metadata)` | Handle custom actions defined in the campaign JSON. |
| `onNavigate(destination, params)` | In-app navigation actions. |
| `onTrackEvent(eventName, properties)` | Forward to your analytics layer if needed. |
| `onDisplayUnitViewed(unitId)` / `onDisplayUnitClicked(unitId)` | Attribution callbacks — Core SDK already tracks these automatically; implement only if you need a copy. |

### NativeDisplayComponentListener — low-level node interactions

Raw gestures on specific nodes by ID. Use this when you need to intercept individual taps, long presses, or double-taps before the SDK handles them.

| Member | Purpose |
|--------|---------|
| `onComponentInteraction(nodeId, interactionType, hasServerAction) -> Boolean` | Return `true` to consume the interaction; `false` to let the SDK proceed with default behavior. |
| `getInterestedNodeIds(): Set<String>?` | Narrow callbacks to specific node IDs; `null` (default) means all nodes. |
| `InteractionType` | `CLICK` / `LONG_PRESS` / `DOUBLE_TAP`. |

### Attaching listeners

Jetpack Compose:
```kotlin
NativeDisplaySlot(
    slotId = "hero_banner",
    actionListener = myActionListener,
    componentListener = myComponentListener,
)
```

<details>
<summary><b>XML / Views</b></summary>

```kotlin
findViewById<NativeDisplaySlotView>(R.id.hero_slot).apply {
    setActionListener(myActionListener)
    setComponentListener(myComponentListener)
}
```
</details>

---

## Custom fonts

Pass a `FontFamily` to `NativeDisplayView`:

```kotlin
NativeDisplayView(
    unit = unit,
    fontFamily = FontFamily(Font(R.font.my_font))
)
```

> If cross-platform font parity matters, enforce a shared font on both platforms — Roboto (Android) and San Francisco (iOS) have different character widths and will wrap text differently.

---

## Troubleshooting

**Listener not called / campaigns never arrive**
- Confirm Step 2 of Approach 1 is complete — without a Core SDK link, no units will be pushed. For standalone testing, feed JSON yourself via `processDisplayUnits(...)` (Approach 2).
- Hold a strong reference to your listener. If it's a local variable, it will be released before any callback fires.

**Layout looks wrong or view has zero height**
- Always provide `layout.width` on the root node — use `"match_parent"` to fill the available space.
- `HTML` elements require an explicit `layout.height`; they cannot auto-size.

**Videos not playing**
- Add `androidx.media3:media3-exoplayer` to your dependencies. Without it, video elements are silently skipped.

**Text wraps differently on Android vs iOS**
- Roboto (Android) and San Francisco (iOS) have different character widths. Always specify `lineHeight` in your campaign JSON for consistent results across platforms, and consider supplying the same custom font on both platforms via the custom font APIs.

---

For campaign JSON structure and element reference, see [JSON Structure Reference](JSON_STRUCTURE_REFERENCE.md) and the [project README](../README.md).
