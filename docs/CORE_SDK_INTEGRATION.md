# Core SDK Integration Guide

The Native Display SDK includes a bridge adapter for integrating with the CleverTap Core SDK. The bridge parses display unit responses from the Core SDK and converts them into `ResolvedConfig` objects ready for rendering.

The SDK works in two modes: **with** the CleverTap Core SDK (bridge mode) or **without** it (standalone mode).

---

## Standalone Mode (Without Core SDK)

When the CleverTap Core SDK is not present, the Native Display SDK works as a pure rendering engine. Create a bridge manually and push JSON to it yourself.

### Android

```kotlin
// Create a bridge with no Core SDK wiring
val bridge = NativeDisplayBridge.create()
bridge.addListener(myListener)

// Feed JSON from any source (assets, network, local file, etc.)
bridge.processDisplayUnits(listOf(jsonString))

// The listener fires and you render as normal
override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
    // units[0].config is ready for NativeDisplayView
}
```

### iOS

```swift
// Use the shared bridge with no Core SDK binding
NativeDisplayBridge.shared.addListener(self)

// Feed JSON from any source
NativeDisplayBridge.shared.processDisplayUnits([jsonString])

// The listener fires and you render as normal
func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
    // units[0].config is ready for NativeDisplayView
}
```

No `initialize()` or `bind()` call is needed — just create the bridge and push JSON directly.

---

## Bridge Mode (With Core SDK)

When the CleverTap Core SDK is present, the bridge listens for display unit responses and automatically parses Native Display configs from them.

### How It Works

1. The CleverTap server sends display units via the `adUnit_notifs` response key
2. Each display unit may contain a Native Display config under the `native_display_config` key
3. The bridge extracts and parses these configs into `NativeDisplayUnit` objects
4. Clients receive parsed units via a listener callback or pull API

### Server JSON Format

The bridge expects the Native Display config to be embedded in the display unit JSON:

```json
{
  "wzrk_id": "unit_123",
  "slot_id": "hero_banner",
  "type": "native_display",
  "native_display_config": {
    "version": "1.0",
    "theme": { "name": "default", "defaults": {} },
    "styleClasses": [],
    "variables": {},
    "root": {
      "type": "container",
      "containerType": "vertical",
      "children": [ ... ]
    }
  },
  "custom_kv": {
    "key1": "value1"
  }
}
```

`slot_id` is optional — present only when the unit should route to a placement slot (`NativeDisplaySlot`). It lives at the root of the display-unit object, alongside `wzrk_id`.

The parser also supports two fallback strategies:
- `custom_kv["nd_config"]` containing the config as a JSON string
- The display unit JSON itself having a `root` key (entire unit is the config)

---

## Integration Options

There are three ways to wire the bridge to the Core SDK, from simplest to most flexible.

### Option 1: `bind()` (Recommended)

The simplest approach. Pass your `CleverTapAPI` instance directly.

**Android:**

```kotlin
// In your Application class or Activity
val bridge = NativeDisplayBridge.create()
bridge.addListener(myListener)
bridge.bind(CleverTapAPI.getDefaultInstance(applicationContext)!!)
```

**iOS:**

```swift
// In AppDelegate or SceneDelegate
let bridge = NativeDisplayBridge.shared
bridge.addListener(self)
bridge.bind(CleverTap.sharedInstance())
```

The bridge registers a composite listener on the Core SDK instance. When display units arrive, they are automatically parsed and forwarded to your bridge listener.

> **Important: Preserving your existing DisplayUnitListener**
>
> The Core SDK only supports a single `DisplayUnitListener` / display unit delegate.
> Calling `bind()` replaces any previously set listener. If you have your own listener
> for handling old-style display units, pass it to `bind()` via `forwardTo` so both
> the bridge and your listener receive callbacks:
>
> **Android:**
> ```kotlin
> bridge.bind(
>     CleverTapAPI.getDefaultInstance(applicationContext)!!,
>     forwardTo = myExistingDisplayUnitListener
> )
> ```
>
> **iOS:**
> ```swift
> bridge.bind(CleverTap.sharedInstance()) { displayUnits in
>     // Your existing display unit handling
>     self.handleLegacyDisplayUnits(displayUnits)
> }
> ```

### Option 2: `initialize()` (Auto-Detection)

The bridge detects the Core SDK at runtime and wires itself automatically.

**Android:**

```kotlin
val bridge = NativeDisplayBridge.initialize(applicationContext)
bridge.addListener(myListener)
```

**iOS:**

```swift
NativeDisplayBridge.shared.initialize()
NativeDisplayBridge.shared.addListener(self)
```

- On Android, uses the default `CleverTapAPI` instance via `getDefaultInstance(context)`
- On iOS, uses `NSClassFromString("CleverTap")` to detect the SDK and `sharedInstance()` to get the instance
- If the Core SDK is not present, initialization silently succeeds and the bridge works in manual mode

### Option 3: Manual JSON Input

For full control or when using a custom data source. You extract JSON from the Core SDK yourself and pass it to the bridge.

**Android:**

```kotlin
val bridge = NativeDisplayBridge.create()
bridge.addListener(myListener)

// Wire Core SDK manually
cleverTapApi.setDisplayUnitListener { units ->
    val jsonStrings = units.map { it.jsonObject.toString() }
    bridge.processDisplayUnits(jsonStrings)
}
```

**iOS:**

```swift
let bridge = NativeDisplayBridge.shared
bridge.addListener(self)

// Wire Core SDK manually
func displayUnitsUpdated(_ displayUnits: [CleverTapDisplayUnit]) {
    let jsonStrings = displayUnits.compactMap { unit -> String? in
        guard let json = unit.json,
              let data = try? JSONSerialization.data(withJSONObject: json),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
    bridge.processDisplayUnits(jsonStrings)
}
```

---

## Fetching Native Displays from Server

In addition to listening for server-pushed display units, you can explicitly request
the server to send Native Display units using `fetchNativeDisplays()`.

This sends a `wzrk_fetch` event with fetch type `9` (Native Display) to the CleverTap
server. The response arrives through the normal display unit pipeline and is picked up
by the bridge listener automatically.

**Android:**

```kotlin
bridge.fetchNativeDisplays(CleverTapAPI.getDefaultInstance(context)!!)

// Response arrives via your NativeDisplayBridgeListener
override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
    // Handle the fetched units
}
```

**iOS:**

```swift
NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap.sharedInstance())

// Response arrives via your NativeDisplayBridgeListener
func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
    // Handle the fetched units
}
```

The CleverTap instance is passed directly — the bridge does not store it.

---

## Listening for Native Display Updates

### Push API (Listener)

Register a listener to be notified when new Native Display units arrive.

**Android:**

```kotlin
class MyActivity : AppCompatActivity(), NativeDisplayBridgeListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val bridge = NativeDisplayBridge.create()
        bridge.addListener(this)
        bridge.bind(CleverTapAPI.getDefaultInstance(this)!!)
    }

    override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
        // Called whenever new display units are parsed
        for (unit in units) {
            Log.d("ND", "Received unit: ${unit.unitId}")
            // unit.config is a ResolvedConfig — render it
            // unit.customExtras contains custom_kv pairs
        }
    }
}
```

**iOS:**

```swift
class MyViewController: UIViewController, NativeDisplayBridgeListener {

    override func viewDidLoad() {
        super.viewDidLoad()
        NativeDisplayBridge.shared.addListener(self)
        NativeDisplayBridge.shared.bind(CleverTap.sharedInstance())
    }

    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        // Called on the main thread
        for unit in units {
            print("Received unit: \(unit.unitId)")
            // unit.config is a ResolvedConfig — render it
        }
    }
}
```

Listeners are held as weak references — they are automatically cleaned up when the owning object is deallocated. You do not need to call `removeListener()` on deallocation, though you can if you want to stop receiving updates early.

### Pull API (Fetch on Demand)

Retrieve cached units at any time without waiting for a callback.

**Android:**

```kotlin
// Get all cached units
val allUnits = bridge.getAllNativeDisplays()

// Get a specific unit by ID (wzrk_id)
val unit = bridge.getNativeDisplayForId("unit_123")
```

**iOS:**

```swift
let allUnits = NativeDisplayBridge.shared.getAllNativeDisplays()
let unit = NativeDisplayBridge.shared.getNativeDisplayForId("unit_123")
```

The cache is populated whenever `processDisplayUnits()` is called (either by the bridge internally or by you manually). Calling `processDisplayUnits()` replaces the entire cache. Calling `processDisplayUnit()` (singular) adds or updates a single entry.

---

## Rendering

Once you have a `NativeDisplayUnit`, pass its `config` to the SDK's rendering components.

**Android (Compose):**

```kotlin
@Composable
fun NativeDisplayScreen(units: List<NativeDisplayUnit>) {
    LazyColumn {
        items(units) { unit ->
            // Use the unit: overload so Notification Viewed / Clicked attribution
            // fires automatically. The config: overload is render-only.
            NativeDisplayView(
                unit = unit,
                actionListener = myActionListener,
                componentListener = myComponentListener
            )
        }
    }
}
```

**Android (XML / RecyclerView):**

```kotlin
class NDViewHolder(parent: ViewGroup) : RecyclerView.ViewHolder(
    NativeDisplayViewGroup(parent.context)
) {
    fun bind(unit: NativeDisplayUnit) {
        // setUnit() consumes the pre-resolved style map and wires the unitId
        // so Notification Viewed/Clicked attribution fires. Prefer it over
        // setConfig(unit.config) whenever a NativeDisplayUnit is available.
        (itemView as NativeDisplayViewGroup).setUnit(unit)
    }
}
```

**iOS (SwiftUI):**

```swift
struct NativeDisplayList: View {
    let units: [NativeDisplayUnit]

    var body: some View {
        ScrollView {
            ForEach(units, id: \.unitId) { unit in
                // Use the unit: initializer so Notification Viewed / Clicked
                // attribution fires automatically. config: is render-only.
                NativeDisplayView(unit: unit)
            }
        }
    }
}
```

**iOS (UIKit):**

```swift
let unit = bridge.getNativeDisplayForId("unit_123")!
let vc = NativeDisplayViewController(config: unit.config)
navigationController?.pushViewController(vc, animated: true)
```

---

## NativeDisplayUnit Properties

| Property | Type | Description |
|----------|------|-------------|
| `unitId` | `String` | The `wzrk_id` from the display unit payload |
| `config` | `ResolvedConfig` | Parsed config ready for `NativeDisplayView` |
| `slotId` | `String?` | Top-level `slot_id` from the payload, used by `NativeDisplaySlotManager` to route the unit to a registered slot. `null` when absent. |
| `customExtras` | `Map<String, String>` | Key-value pairs from `custom_kv` |
| `rawJson` | `String?` | The original ND config JSON (for debugging) |

---

## Platform Differences

| Aspect | Android | iOS |
|--------|---------|-----|
| Core SDK dependency | `compileOnly` — typed `CleverTapAPI` import, not bundled | No compile dependency — uses `Any?` + Obj-C runtime |
| `bind()` signature | `bind(cleverTapApi: CleverTapAPI)` | `bind(_ cleverTap: Any?)` |
| Auto-detection | `CleverTapAPI.getDefaultInstance(context)` | `NSClassFromString("CleverTap")` + `performSelector` |
| Runtime safety | `NoClassDefFoundError` catch | `NSClassFromString` returns nil |
| Listener threading | Called on the thread the Core SDK uses | Dispatched to main thread |
| Singleton pattern | `NativeDisplayBridge.create()` / `.initialize()` / `.getInstance()` | `NativeDisplayBridge.shared` |

---

## Error Handling

- **Malformed JSON**: Logged and skipped. Only successfully parsed units appear in the cache and listener callbacks.
- **Missing `root` node**: Unit is skipped. `ResolvedConfig` requires a root node.
- **Core SDK absent at runtime**: `bind()` and `initialize()` return `false` / no-op. No crashes.
- **Mixed display units**: The bridge filters only units containing Native Display configs. Old-format display units pass through the Core SDK normally and are ignored by the bridge.
