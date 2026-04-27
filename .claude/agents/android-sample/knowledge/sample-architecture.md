# Android Sample App Architecture

## Purpose
Demonstrate Native Display SDK capabilities with real-world examples.

## Structure
```
android-sample/app/src/main/
├── assets/           # JSON configurations
│   ├── product_card.json
│   ├── login_form.json
│   └── gallery_demo.json
├── MainActivity.kt   # Main navigation
└── demos/           # Demo screens
    ├── ProductCardDemo.kt
    ├── GalleryDemo.kt
    └── ArrangementDemo.kt
```

## Demo Patterns

### 1. Simple Demo
```kotlin
@Composable
fun ProductCardDemo() {
    val json = loadAsset("product_card.json")
    val config = Json.decodeFromString<NativeDisplayConfig>(json)

    NativeDisplayView(config)
}
```

### 2. Interactive Demo
```kotlin
@Composable
fun InteractiveDemo() {
    var variables by remember {
        mutableStateOf(mapOf("count" to JsonPrimitive(0)))
    }

    val config = NativeDisplayConfig(
        variables = variables,
        root = ...
    )

    Column {
        NativeDisplayView(config)

        Button(onClick = {
            variables = variables + ("count" to JsonPrimitive(variables["count"]!!.int + 1))
        }) {
            Text("Increment")
        }
    }
}
```

### 3. Comparison Demo
Show multiple arrangements side-by-side to demonstrate differences.

## Best Practices
- Each demo in separate file
- Load JSON from assets
- Show both static and dynamic examples
- Include comments explaining key concepts
- Provide "View JSON" button
