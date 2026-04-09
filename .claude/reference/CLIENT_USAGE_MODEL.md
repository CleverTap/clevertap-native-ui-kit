# Client Usage Model

## CRITICAL: JSON-Driven SDK

The Native Display SDK is a **JSON-driven UI framework**. Clients do NOT write custom Composables or SwiftUI views. They simply:

1. **Load JSON** configuration
2. **Pass to SDK view** (NativeDisplayView)
3. **Done** ✅

---

## Client Usage (What Apps Do)

### Android Client Usage

```kotlin
// STEP 1: Load JSON (from assets, API, etc.)
val jsonString = loadAssetAsString("product_card.json")

// STEP 2: Parse JSON to config (SDK provides parser)
val config = Json.decodeFromString<NativeDisplayConfig>(jsonString)

// STEP 3: Render with SDK view
@Composable
fun MyScreen() {
    NativeDisplayView(config = config)  // ✅ That's it!
}
```

### iOS Client Usage

```swift
// STEP 1: Load JSON
let url = Bundle.main.url(forResource: "ProductCard", withExtension: "json")!
let data = try! Data(contentsOf: url)

// STEP 2: Parse JSON to config
let config = try! JSONDecoder().decode(NativeDisplayConfig.self, from: data)

// STEP 3: Render with SDK view
struct MyScreen: View {
    var body: some View {
        NativeDisplayView(config: config)  // ✅ That's it!
    }
}
```

---

## What Clients DO NOT Do

### ❌ NO Custom Composables
```kotlin
// ❌ WRONG - Clients don't implement renderers
@Composable
fun CustomVerticalContainer() {
    Column {
        // Custom implementation
    }
}
```

### ❌ NO Custom Container Types
```kotlin
// ❌ WRONG - Clients don't extend the SDK
sealed class MyContainerType : ContainerType {
    object Grid : MyContainerType()
}
```

### ❌ NO Custom Style Resolution
```kotlin
// ❌ WRONG - Clients don't resolve styles
fun resolveStyles(node: Node, parent: Style): Style {
    // Custom resolution logic
}
```

---

## What Clients CAN Do

### ✅ Load JSON from Various Sources

```kotlin
// From assets
val json = context.assets.open("config.json").bufferedReader().use { it.readText() }

// From API
val json = apiClient.fetchConfig()

// From local storage
val json = File(context.filesDir, "config.json").readText()

// From string
val json = """{"theme": {...}, "root": {...}}"""
```

### ✅ Update Variables Dynamically

```kotlin
@Composable
fun InteractiveDemo() {
    var count by remember { mutableStateOf(0) }

    val config = NativeDisplayConfig(
        variables = mapOf("count" to JsonPrimitive(count)),
        root = loadStaticRoot()
    )

    Column {
        NativeDisplayView(config = config)  // ✅ SDK handles rendering

        Button(onClick = { count++ }) {
            Text("Increment")
        }
    }
}
```

### ✅ Handle Actions with Callbacks

```kotlin
NativeDisplayView(
    config = config,
    onAction = { action ->  // ✅ SDK provides action callback
        when (action.type) {
            "open_url" -> openUrl(action.url)
            "navigate" -> navigate(action.destination)
            "event" -> trackEvent(action.eventName)
        }
    }
)
```

### ✅ Customize SDK Behavior (Configuration)

```kotlin
NativeDisplayView(
    config = config,
    imageLoader = customImageLoader,  // ✅ Optional customization
    actionHandler = customActionHandler
)
```

### ✅ Customize Font Families (Client Font API)

Font resolution follows a 3-layer priority: client default → JSON fontFamily → platform system font.

**Android — simple: pass a font directly**
```kotlin
NativeDisplayView(config = config, fontFamily = InterFontFamily)
```

**Android — advanced: resolver maps JSON fontFamily names to font objects**
```kotlin
CompositionLocalProvider(
    LocalFontFamily provides InterFontFamily,          // brand default
    LocalFontFamilyResolver provides { name ->         // JSON name resolver
        when (name.lowercase()) {
            "inter" -> InterFontFamily
            "mono"  -> FontFamily.Monospace
            else    -> null  // falls through to system default
        }
    }
) {
    NativeDisplayView(config = config)
}
```

**iOS — set font family via environment**
```swift
NativeDisplayView(config: config)
    .environment(\.nativeDisplayFontFamily, "Inter")

// Or use a resolver for JSON fontFamily names:
NativeDisplayView(config: config)
    .environment(\.nativeDisplayFontResolver, { name, size, weight in
        switch name.lowercased() {
        case "inter": return Font.custom("Inter", size: size).weight(weight)
        default:      return nil
        }
    })
```

> When no font is provided, Compose/SwiftUI defers to the system default (Roboto/SF Pro). On Android 12+, this means user-selected fonts from device Settings are automatically respected.

---

## SDK Internal Implementation (What We Build)

The `.kt` and `.swift` example files in `.claude/agents/*/examples/` are **SDK INTERNAL IMPLEMENTATION**, not client usage:

### SDK Implements:
- ✅ `RenderVerticalContainer()` - Internal renderer
- ✅ `RenderTextElement()` - Internal renderer
- ✅ `StyleResolver` - Internal business logic
- ✅ `TemplateEvaluator` - Internal business logic
- ✅ `NativeDisplayView` - Public API that clients use

### Clients Use:
- ✅ `NativeDisplayView(config)` - Public API only
- ✅ JSON configurations - Data only
- ✅ Action callbacks - Optional handlers

---

## Documentation Categories

### For SDK Developers (Internal)
- `.claude/agents/android-sdk/` - How to implement SDK features
- `.claude/agents/ios-sdk/` - How to implement SDK features
- Kotlin/Swift examples - Internal implementation patterns

### For SDK Users (External/Clients)
- `.claude/agents/android-sample/` - How clients use the SDK
- `.claude/agents/ios-sample/` - How clients use the SDK
- Sample app demos - Client usage patterns

---

## JSON is the Interface

```
┌─────────────────┐
│  Client App     │
└────────┬────────┘
         │
         ▼ JSON Config
┌─────────────────┐
│  Native Display │  ← SDK (black box)
│      SDK        │
└────────┬────────┘
         │
         ▼ Native UI
┌─────────────────┐
│   Android/iOS   │
│   Native Views  │
└─────────────────┘
```

**The JSON configuration IS the entire API surface.**

Clients configure everything through JSON:
- Layout
- Styles
- Content
- Actions
- Animations
- Backgrounds

No code required beyond loading JSON and rendering the view.

---

## Sample App Purpose

Sample apps demonstrate **client usage patterns**, NOT SDK implementation:

### Sample App Shows:
```kotlin
// ✅ This is what clients do
@Composable
fun ProductCardDemo() {
    val json = loadAsset("product_card.json")
    val config = Json.decodeFromString<NativeDisplayConfig>(json)

    NativeDisplayView(config)  // Client code ends here
}
```

### Sample App Does NOT Show:
```kotlin
// ❌ Clients don't see this (internal SDK code)
@Composable
internal fun RenderVerticalContainer(
    node: NativeDisplayNode,
    styleResolver: StyleResolver,
    ...
) {
    Column(...) { ... }
}
```

---

## Key Principle

**If a client needs to write Kotlin/Swift code beyond:**
1. Loading JSON
2. Calling `NativeDisplayView(config)`
3. Handling action callbacks (optional)

**Then the SDK is not doing its job.**

The SDK should handle ALL rendering, styling, layout, and behavior based solely on JSON configuration.

---

## Exception: Custom Action Handlers

The ONLY place where clients might write custom code is action handling:

```kotlin
NativeDisplayView(
    config = config,
    onAction = { action ->
        when (action.type) {
            "custom" -> {
                // Client handles custom actions
                handleCustomAction(action.key, action.value)
            }
            else -> {
                // SDK handles built-in actions
                defaultActionHandler(action)
            }
        }
    }
)
```

But even this is **optional** - the SDK provides default handlers for all standard actions.

---

## Summary

### Clients Write:
- ✅ JSON configurations
- ✅ JSON loading code
- ✅ Action handler callbacks (optional)

### Clients DON'T Write:
- ❌ Composables for rendering
- ❌ Style resolution logic
- ❌ Layout calculation code
- ❌ Container implementations
- ❌ Element implementations

### SDK Provides:
- ✅ `NativeDisplayView` component
- ✅ JSON parser
- ✅ Complete rendering engine
- ✅ Style resolution
- ✅ Template evaluation
- ✅ Action handling
- ✅ Animations
- ✅ All container types
- ✅ All element types

**The SDK is a complete black box that takes JSON in and produces native UI out.**
