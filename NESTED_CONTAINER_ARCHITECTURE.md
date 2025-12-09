# Nested Container Architecture

## 🎯 Problem with Current Structure

### Current (Limited):
```json
{
  "container": { "type": "vertical" },
  "elements": [...]
}
```

**Issues**:
- ❌ Only ONE container level
- ❌ Can't nest containers
- ❌ Can't have different backgrounds/shadows at different levels
- ❌ Limited compositional power

---

## ✅ New Architecture: Tree Structure

### Concept: Unlimited Nesting

Everything is a **Node** in a tree:
- **Container Nodes**: Have children (containers or elements)
- **Element Nodes**: Leaf nodes (text, image, button)

```
Root Container
├── Container (Card with shadow)
│   ├── Text (Title)
│   ├── Image
│   └── Container (Button row)
│       ├── Button 1
│       └── Button 2
└── Container (Footer)
    └── Text
```

---

## 📊 Data Model

### NativeDisplayNode (Base)

```kotlin
@Serializable
sealed class NativeDisplayNode {
    abstract val id: String
    abstract val layout: Layout?
    abstract val style: Style?
    abstract val styleClass: String?
}
```

### Container Node

```kotlin
@Serializable
@SerialName("container")
data class NativeDisplayContainer(
    override val id: String,
    val containerType: ContainerType,
    val children: List<NativeDisplayNode>,  // ← Can contain containers OR elements!
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null
) : NativeDisplayNode()

@Serializable
enum class ContainerType {
    VERTICAL,    // Stack children vertically
    HORIZONTAL,  // Stack children horizontally
    BOX,         // Absolute positioning
    STACK        // Overlapping children (Z-order)
}
```

### Element Node

```kotlin
@Serializable
@SerialName("element")
data class NativeDisplayElement(
    override val id: String,
    val elementType: ElementType,
    val content: Map<String, String> = emptyMap(),
    val actions: Map<String, Action>? = null,
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null
) : NativeDisplayNode()

@Serializable
enum class ElementType {
    TEXT,
    IMAGE,
    BUTTON,
    VIDEO,
    SPACER
}
```

### Root Configuration

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String,
    val theme: Theme? = null,
    val styleClasses: List<StyleClass> = emptyList(),
    val root: NativeDisplayNode  // ← Root can be container or single element
)
```

---

## 🎨 Example: Complex UI with Nesting

### Card with Multiple Backgrounds

```json
{
  "version": "1.0",
  "root": {
    "type": "container",
    "id": "main",
    "containerType": "vertical",
    "style": {
      "backgroundColor": "#F5F5F5",
      "padding": { "all": 16 }
    },
    "children": [
      {
        "type": "container",
        "id": "hero-card",
        "containerType": "box",
        "style": {
          "backgroundColor": "#FFFFFF",
          "shadowColor": "#00000020",
          "shadowRadius": 12,
          "shadowOffsetY": 4,
          "borderRadius": 16,
          "padding": { "all": 20 }
        },
        "children": [
          {
            "type": "element",
            "id": "title",
            "elementType": "text",
            "content": { "text": "Premium Feature" },
            "style": { "fontSize": 24, "fontWeight": "bold" }
          },
          {
            "type": "container",
            "id": "image-wrapper",
            "containerType": "box",
            "style": {
              "backgroundColor": "#007AFF",
              "borderRadius": 12,
              "margin": { "top": 16, "bottom": 16 }
            },
            "children": [
              {
                "type": "element",
                "id": "feature-image",
                "elementType": "image",
                "content": { "url": "https://..." }
              }
            ]
          },
          {
            "type": "container",
            "id": "action-row",
            "containerType": "horizontal",
            "style": {
              "backgroundColor": "#F0F0F0",
              "borderRadius": 8,
              "padding": { "all": 12 }
            },
            "children": [
              {
                "type": "element",
                "id": "btn-1",
                "elementType": "button",
                "content": { "text": "Learn More" }
              },
              {
                "type": "element",
                "id": "spacer",
                "elementType": "spacer",
                "layout": { "width": { "value": 16, "unit": "dp" } }
              },
              {
                "type": "element",
                "id": "btn-2",
                "elementType": "button",
                "content": { "text": "Buy Now" },
                "styleClass": "button-primary"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

**Visual Result**:
```
┌─────────────────────────────────┐ ← Gray background (#F5F5F5)
│ ┌─────────────────────────────┐ │ ← White card with shadow
│ │ Premium Feature             │ │
│ │                             │ │
│ │ ┌─────────────────────────┐ │ │ ← Blue background (#007AFF)
│ │ │     [Image]             │ │ │
│ │ └─────────────────────────┘ │ │
│ │                             │ │
│ │ ┌─────────────────────────┐ │ │ ← Gray button row (#F0F0F0)
│ │ │ [Learn] [Spacer] [Buy]  │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## 🎨 Use Cases Enabled

### 1. Multiple Background Layers ✅

```json
{
  "type": "container",
  "containerType": "vertical",
  "style": { "backgroundColor": "#GRADIENT_1" },
  "children": [
    {
      "type": "container",
      "containerType": "box",
      "style": { "backgroundColor": "#SOLID_COLOR" },
      "children": [...]
    }
  ]
}
```

### 2. Elevation/Shadows ✅

```json
{
  "type": "container",
  "containerType": "box",
  "style": {
    "backgroundColor": "#FFFFFF",
    "shadowColor": "#00000033",
    "shadowRadius": 8,
    "shadowOffsetY": 4
  },
  "children": [...]
}
```

### 3. Complex Layouts ✅

```json
{
  "type": "container",
  "containerType": "vertical",
  "children": [
    {
      "type": "container",
      "containerType": "horizontal",
      "children": [
        { "type": "element", "elementType": "text" },
        { "type": "element", "elementType": "button" }
      ]
    },
    {
      "type": "container",
      "containerType": "box",
      "children": [...]
    }
  ]
}
```

### 4. Grouped Elements ✅

```json
{
  "type": "container",
  "containerType": "horizontal",
  "styleClass": "button-group",
  "children": [
    { "type": "element", "elementType": "button", "content": { "text": "1" } },
    { "type": "element", "elementType": "button", "content": { "text": "2" } },
    { "type": "element", "elementType": "button", "content": { "text": "3" } }
  ]
}
```

---

## 🔄 Rendering Algorithm

### Recursive Tree Traversal

```kotlin
@Composable
fun RenderNode(node: NativeDisplayNode, resolver: StyleResolver) {
    when (node) {
        is NativeDisplayContainer -> {
            RenderContainer(node, resolver)
        }
        is NativeDisplayElement -> {
            RenderElement(node, resolver)
        }
    }
}

@Composable
fun RenderContainer(container: NativeDisplayContainer, resolver: StyleResolver) {
    val style = resolver.resolve(container.styleClass, container.style)
    
    // Apply container style (background, shadow, etc.)
    Box(
        modifier = Modifier
            .background(style.backgroundColor)
            .shadow(style.shadowRadius, style.shadowColor)
            .padding(style.padding)
    ) {
        // Layout children based on containerType
        when (container.containerType) {
            ContainerType.VERTICAL -> {
                Column {
                    container.children.forEach { child ->
                        RenderNode(child, resolver)  // ← Recursive!
                    }
                }
            }
            ContainerType.HORIZONTAL -> {
                Row {
                    container.children.forEach { child ->
                        RenderNode(child, resolver)
                    }
                }
            }
            // ... other types
        }
    }
}

@Composable
fun RenderElement(element: NativeDisplayElement, resolver: StyleResolver) {
    val style = resolver.resolve(element.styleClass, element.style)
    
    when (element.elementType) {
        ElementType.TEXT -> TextElement(element, style)
        ElementType.IMAGE -> ImageElement(element, style)
        ElementType.BUTTON -> ButtonElement(element, style)
        // ... other types
    }
}
```

---

## 📊 Comparison

| Feature | Old (Single Container) | New (Nested) |
|---------|------------------------|--------------|
| **Nesting** | ❌ No | ✅ Unlimited |
| **Multiple backgrounds** | ❌ No | ✅ Yes |
| **Shadows/elevation** | ❌ Limited | ✅ Per container |
| **Complex layouts** | ❌ Hard | ✅ Easy |
| **Composition** | ❌ No | ✅ Full |
| **Flexibility** | ❌ Low | ✅ High |

---

## 🎯 Benefits

### 1. **Unlimited Composition** ✅
```
Container (Screen)
├── Container (Header with gradient)
│   └── Container (Logo area with shadow)
│       └── Image (Logo)
├── Container (Content area)
│   ├── Container (Card 1 with elevation)
│   │   ├── Text
│   │   └── Image
│   └── Container (Card 2 with elevation)
│       ├── Text
│       └── Button
└── Container (Footer)
    └── Container (Button row)
        ├── Button 1
        └── Button 2
```

### 2. **Visual Hierarchy** ✅
- Each level can have different background
- Each level can have different shadow/elevation
- Each level can have different padding/margin

### 3. **Reusable Components** ✅
```json
{
  "styleClass": "card-with-shadow",
  "containerType": "box",
  "children": [...]
}
```

### 4. **Flexibility** ✅
- Simple UIs: Use flat structure
- Complex UIs: Nest as needed
- Progressive enhancement

---

## 🚀 Implementation Steps

### 1. Update Data Models

```kotlin
// Old
data class NativeDisplayConfig(
    val container: Container,
    val elements: List<Element>
)

// New
data class NativeDisplayConfig(
    val root: NativeDisplayNode  // ← Can be nested!
)

sealed class NativeDisplayNode
data class NativeDisplayContainer(...) : NativeDisplayNode()
data class NativeDisplayElement(...) : NativeDisplayNode()
```

### 2. Update Parser

```kotlin
class NativeDisplayParser {
    fun parse(json: String): NativeDisplayConfig {
        return Json.decodeFromString(json)
    }
}
```

### 3. Update Renderer

```kotlin
@Composable
fun NativeDisplayView(config: NativeDisplayConfig) {
    RenderNode(config.root, styleResolver)
}

@Composable
fun RenderNode(node: NativeDisplayNode, resolver: StyleResolver) {
    when (node) {
        is NativeDisplayContainer -> RenderContainer(node, resolver)
        is NativeDisplayElement -> RenderElement(node, resolver)
    }
}
```

---

## 📝 Migration Path

### Phase 1: Backward Compatibility

Support both formats:

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String,
    
    // New format (preferred)
    val root: NativeDisplayNode? = null,
    
    // Old format (deprecated)
    val container: Container? = null,
    val elements: List<Element>? = null
) {
    fun getRootNode(): NativeDisplayNode {
        return root ?: convertOldFormat()
    }
}
```

### Phase 2: Full Migration

Remove old format, require nested structure.

---

## ✅ Summary

### Problem:
- ❌ Single container = limited flexibility
- ❌ Can't nest for complex layouts
- ❌ No multi-level backgrounds/shadows

### Solution:
- ✅ Tree structure with unlimited nesting
- ✅ Containers can contain containers
- ✅ Each level can have its own style
- ✅ Full compositional power

### Result:
```
Simple UI: Flat structure (easy)
Complex UI: Nested structure (powerful)
```

**This gives you the flexibility you need!** 🎉

---

## 🎯 Next Steps

1. Update data models to support tree structure
2. Update JSON schema
3. Implement recursive renderer
4. Update documentation
5. Create examples

Want me to create the updated models and examples?
