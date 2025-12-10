# Sample App - Native Display Kit

## 🚀 Quick Start

### Step 1: Open Project in Android Studio
1. Open Android Studio
2. Open project at: `/Users/lalitkumar/StudioProjects/clevertap-native-ui-kit/android`
3. Wait for Gradle sync to complete

### Step 2: Run the Sample App
1. Select `sample-app` from the run configuration dropdown
2. Select your device or emulator
3. Click Run ▶️

### Step 3: Explore Samples
The app has 4 tabs with different samples:

#### 📋 Tab 1: Simple Card
- Basic greeting card
- Text elements with styling
- Variable interpolation: `{{userName}}`
- Demonstrates: Basic layout and styling

#### 🛍️ Tab 2: Product Card
- Complete product card UI
- Image loading
- Price with strikethrough
- Conditional rendering (discount badge)
- Button element
- Demonstrates: Complex layout, style classes, color palette

#### 📦 Tab 3: Nested Containers
- 3 levels of nested containers
- Style inheritance demonstration
- Different background colors per level
- Demonstrates: Cascading properties

#### 🎨 Tab 4: All Elements
- All element types showcase:
  - TEXT
  - IMAGE (with circular shape)
  - BUTTON
  - SPACER
  - VIDEO (placeholder)
- Demonstrates: All element types

---

## 📱 What You'll See

### Simple Card Sample
```
┌─────────────────────────────┐
│  Hello John Doe!            │  ← 24sp bold
│  Welcome to Native Display  │  ← 16sp gray
│  Kit                        │
└─────────────────────────────┘
```

### Product Card Sample
```
┌─────────────────────────────┐
│  [Product Image]            │
│                             │
│  Wireless Headphones Pro    │  ← 20sp bold
│                             │
│  Save 25% Today!            │  ← Green, conditional
│                             │
│  $299.99  $224.99          │  ← Strikethrough + bold
│                             │
│  Only 5 left in stock!      │  ← Orange, conditional
│                             │
│  ┌───────────────────────┐  │
│  │     Buy Now           │  │  ← Blue button
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Nested Containers Sample
```
┌─────────────────────────────┐  Gray background (fontSize=18)
│  ┌───────────────────────┐  │
│  │  Nested Containers    │  │  White card
│  │  ┌─────────────────┐  │  │
│  │  │  Demo           │  │  │  Blue card
│  │  │  ┌───────────┐  │  │  │
│  │  │  │ Level 3   │  │  │  │  Light blue (fontSize=12)
│  │  │  └───────────┘  │  │  │
│  │  └─────────────────┘  │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

---

## 🎯 Key Features Demonstrated

### ✅ Layout System
- Width/Height with units (DP, SP, PERCENT)
- WRAP_CONTENT and MATCH_PARENT
- Margin and Padding (all sides)
- Container spacing

### ✅ Styling
- Background colors (hex format)
- Border radius
- Shadows
- Text colors
- Font size and weight
- Text decoration (strikethrough, underline)

### ✅ Variable System
- Variable interpolation: `{{userName}}`
- Conditional expressions: `{{itemCount > 0}}`
- Ternary operators: `{{isPremium ? 'Premium' : 'Free'}}`

### ✅ Style Inheritance
- Cascading properties (fontSize, textColor, fontWeight)
- Parent → Child inheritance
- Override with inline styles

### ✅ Conditional Rendering
- `visible` property
- Boolean expressions
- Show/hide elements dynamically

### ✅ Element Types
- TEXT - Full text styling
- IMAGE - URL loading with Coil
- BUTTON - Custom Material3 button
- SPACER - Empty space
- VIDEO - Placeholder

### ✅ Container Types
- VERTICAL - Column layout
- HORIZONTAL - Row layout
- BOX/STACK - Overlay layout

---

## 🛠️ Troubleshooting

### Gradle Sync Issues
1. Click "File" → "Sync Project with Gradle Files"
2. Check that all dependencies download successfully
3. Make sure JDK 17 is selected

### Images Not Loading
- Check internet connection
- Internet permission is already added in AndroidManifest.xml
- Images use placeholder URLs from `placeholder.com`

### Compilation Errors
1. Clean project: "Build" → "Clean Project"
2. Rebuild: "Build" → "Rebuild Project"
3. Invalidate caches: "File" → "Invalidate Caches / Restart"

### Sample Not Showing
1. Check that SDK module is included in project
2. Verify `implementation(project(":sdk"))` in sample-app build.gradle
3. Make sure Gradle sync completed successfully

---

## 📂 Project Structure

```
android/
├── sample-app/                     ← You are here!
│   ├── src/main/
│   │   ├── kotlin/
│   │   │   └── com/clevertap/android/nativeui/sample/
│   │   │       └── MainActivity.kt  ← Sample app with tabs
│   │   └── AndroidManifest.xml
│   └── build.gradle.kts
│
└── sdk/                            ← SDK implementation
    ├── src/main/kotlin/
    │   └── com/clevertap/android/nativedisplay/
    │       ├── models/             ← Data models
    │       ├── style/              ← Style resolver
    │       ├── evaluator/          ← Variable evaluator
    │       ├── renderer/           ← Compose renderer
    │       └── samples/            ← Sample configs
    └── build.gradle.kts
```

---

## 🎨 Creating Your Own Samples

You can create your own samples in the SDK:

```kotlin
// In samples/SampleConfigs.kt

fun myCustomSample(): ResolvedConfig {
    return ResolvedConfig(
        theme = Theme.DEFAULT,
        styleClasses = emptyList(),
        variables = mapOf(
            "myVar" to JsonPrimitive("Hello!")
        ),
        root = NativeDisplayContainer(
            id = "root",
            containerType = ContainerType.VERTICAL,
            layout = Layout(
                width = Dimension.MATCH_PARENT,
                padding = Spacing.all(16f)
            ),
            style = Style(
                backgroundColor = "#FFFFFF",
                borderRadius = 12f
            ),
            children = listOf(
                NativeDisplayElement(
                    id = "text1",
                    elementType = ElementType.TEXT,
                    bindings = mapOf("text" to "{{myVar}}"),
                    style = Style(
                        fontSize = 20f,
                        fontWeight = FontWeight.BOLD
                    )
                )
            )
        )
    )
}
```

Then add it to MainActivity.kt:
```kotlin
// Add new tab
val tabs = listOf(
    "Simple Card",
    "Product Card", 
    "Nested Containers",
    "All Elements",
    "My Custom Sample"  // ← Add here
)

// Add case in when statement
when (selectedTabIndex) {
    0 -> SimpleGreetingCardSample()
    1 -> ProductCardSample()
    2 -> NestedContainersSample()
    3 -> AllElementsSample()
    4 -> MyCustomSample()  // ← Add here
}
```

---

## 📊 Performance Tips

- The renderer uses Compose for efficient UI updates
- Images are loaded asynchronously with Coil
- Variables are evaluated once per render
- Style resolution is cached per node

---

## 🎉 You're All Set!

Just click Run ▶️ in Android Studio and explore the samples!

**Enjoy testing the Native Display Kit!** 🚀
