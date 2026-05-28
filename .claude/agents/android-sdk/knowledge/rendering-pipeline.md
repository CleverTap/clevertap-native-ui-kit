# Rendering Pipeline

## Overview

The Native Display System rendering pipeline transforms JSON configuration into native Android UI through a series of well-defined stages.

## Pipeline Stages

```
┌─────────────────┐
│  JSON Config    │
└────────┬────────┘
         ↓
┌─────────────────┐
│  Parse Models   │  (kotlinx.serialization)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Resolve Styles  │  (StyleResolver)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Evaluate Temps  │  (TemplateEvaluator)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Calculate Layout│  (DimensionCalculator)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Render Compose  │  (ContainerRenderer/ElementRenderer)
└────────┬────────┘
         ↓
┌─────────────────┐
│  Native UI      │
└─────────────────┘
```

## Stage 1: Parse Models

**Input**: JSON string
**Output**: `NativeDisplayConfig` object
**Responsibility**: Parse JSON into typed Kotlin models

```kotlin
val config: NativeDisplayConfig = Json.decodeFromString(jsonString)
```

**Key Points**:
- Uses kotlinx.serialization for type-safe parsing
- Validates JSON structure automatically
- Throws exceptions for invalid JSON
- All models are immutable data classes

## Stage 2: Resolve Styles

**Input**: `NativeDisplayConfig` with nodes
**Output**: Map of node ID → resolved `Style`
**Responsibility**: Calculate final styles with cascading

### Resolution Order

```
1. Theme Default Style
   ↓
2. Style Class (if specified)
   ↓
3. Inline Node Style
   ↓
4. Parent Style (text properties only)
```

### Implementation

```kotlin
class StyleResolver(
    private val theme: Theme?,
    private val styleClasses: List<StyleClass>?
) {
    fun resolve(node: NativeDisplayNode, parentStyle: Style? = null): Style {
        var style = theme?.defaultStyle ?: Style()

        // Apply style class
        node.styleClass?.let { className ->
            val classStyle = styleClasses?.find { it.name == className }?.style
            style = style.merge(classStyle)
        }

        // Apply inline style
        style = style.merge(node.style)

        // Inherit text properties from parent
        style = style.inheritTextProperties(parentStyle)

        return style
    }
}
```

### Cascading Rules

**Text Properties (cascade to children)**:
- textColor
- fontSize
- fontFamily
- fontWeight
- lineHeight
- textDecoration
- textAlign
- opacity

**Visual Properties (do NOT cascade)**:
- background
- backgroundColor
- borderRadius
- borderWidth
- borderColor
- shadow*

## Stage 3: Evaluate Templates

**Input**: Nodes with template bindings
**Output**: Nodes with evaluated string values
**Responsibility**: Replace `{{variable}}` with actual values

### Template Syntax

```
{{variableName}}        → variables["variableName"]
{{object.property}}     → variables["object"]["property"]
{{!expression}}         → Negation
```

### Implementation

```kotlin
class TemplateEvaluator(
    private val variables: Map<String, JsonElement>?
) {
    fun evaluate(template: String): String {
        val regex = """\{\{([^}]+)\}\}""".toRegex()

        return regex.replace(template) { matchResult ->
            val expression = matchResult.groupValues[1].trim()
            resolveVariable(expression)
        }
    }

    private fun resolveVariable(path: String): String {
        val parts = path.split(".")
        var current: JsonElement? = variables?.get(parts[0])

        for (i in 1 until parts.size) {
            current = (current as? JsonObject)?.get(parts[i])
        }

        return current?.toString() ?: ""
    }
}
```

### Usage in Bindings

```kotlin
val text = node.bindings?.get("text")?.let { template ->
    templateEvaluator.evaluate(template)
} ?: ""
```

## Stage 4: Calculate Layout

**Input**: Layout configuration
**Output**: Compose Modifier with size constraints
**Responsibility**: Convert dimensions to actual pixel values

### Dimension Types

```kotlin
sealed class Dimension {
    data class Fixed(val value: Float, val unit: DimensionUnit)
    object WrapContent
    object MatchParent
}
```

### Calculation Logic

```kotlin
fun calculateDimension(
    dimension: Dimension?,
    parentSize: Int,
    isWidth: Boolean
): Modifier {
    return when (dimension) {
        is Dimension.Fixed -> {
            val pixels = when (dimension.unit) {
                DimensionUnit.DP -> dimension.value.dp.toPx()
                DimensionUnit.SP -> dimension.value.sp.toPx()
                DimensionUnit.PERCENT -> parentSize * dimension.value / 100
                DimensionUnit.PX -> dimension.value
            }
            if (isWidth) Modifier.width(pixels.dp) else Modifier.height(pixels.dp)
        }
        Dimension.WrapContent -> Modifier.wrapContentSize()
        Dimension.MatchParent -> {
            if (isWidth) Modifier.fillMaxWidth() else Modifier.fillMaxHeight()
        }
        null -> Modifier
    }
}
```

## Stage 5: Render Compose

**Input**: Resolved nodes, styles, and layout
**Output**: Compose UI tree
**Responsibility**: Create Jetpack Compose components

### Entry Point

```kotlin
@Composable
fun NativeDisplayView(config: NativeDisplayConfig) {
    val styleResolver = remember { StyleResolver(config.theme, config.styleClasses) }
    val templateEvaluator = remember { TemplateEvaluator(config.variables) }

    BoxWithConstraints {
        val parentSize = IntSize(
            width = constraints.maxWidth,
            height = constraints.maxHeight
        )

        RenderNode(
            node = config.root,
            parentSize = parentSize,
            parentStyle = null,
            styleResolver = styleResolver,
            templateEvaluator = templateEvaluator
        )
    }
}
```

### Node Dispatcher

```kotlin
@Composable
fun RenderNode(
    node: NativeDisplayNode,
    parentSize: IntSize,
    parentStyle: Style?,
    styleResolver: StyleResolver,
    templateEvaluator: TemplateEvaluator
) {
    val style = remember(node) {
        styleResolver.resolve(node, parentStyle)
    }

    when {
        node.containerType != null -> RenderContainer(node, parentSize, style, ...)
        node.elementType != null -> RenderElement(node, parentSize, style, ...)
    }
}
```

### Container Rendering

```kotlin
@Composable
fun RenderContainer(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style,
    ...
) {
    val containerModifier = Modifier
        .applyDimension(node.layout.width, parentSize.width, true)
        .applyDimension(node.layout.height, parentSize.height, false)
        .applyBackground(style.background)
        .applyPadding(node.layout.padding)
        .applyBorder(style)

    when (node.containerType) {
        ContainerType.VERTICAL -> {
            Column(
                modifier = containerModifier,
                verticalArrangement = node.arrangement.toVerticalArrangement()
            ) {
                node.children?.forEach { child ->
                    RenderNode(child, parentSize, style, ...)
                }
            }
        }
        ContainerType.HORIZONTAL -> {
            Row(
                modifier = containerModifier,
                horizontalArrangement = node.arrangement.toHorizontalArrangement()
            ) {
                node.children?.forEach { child ->
                    RenderNode(child, parentSize, style, ...)
                }
            }
        }
        // ... other container types
    }
}
```

### Element Rendering

```kotlin
@Composable
fun RenderElement(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style,
    templateEvaluator: TemplateEvaluator
) {
    val elementModifier = Modifier
        .applyDimension(node.layout.width, parentSize.width, true)
        .applyDimension(node.layout.height, parentSize.height, false)
        .applyBackground(style.background)
        .applyPadding(node.layout.padding)

    when (node.elementType) {
        ElementType.TEXT -> {
            val text = node.bindings?.get("text")?.let {
                templateEvaluator.evaluate(it)
            } ?: ""

            Text(
                text = text,
                modifier = elementModifier,
                color = style.textColor.parseColor(),
                fontSize = style.fontSize.sp,
                fontWeight = style.fontWeight.toFontWeight()
            )
        }
        ElementType.IMAGE -> {
            val src = node.bindings?.get("src")?.let {
                templateEvaluator.evaluate(it)
            } ?: ""

            AsyncImage(
                model = src,
                contentDescription = node.id,
                modifier = elementModifier
            )
        }
        // ... other element types
    }
}
```

## Animation Application

Animations wrap the entire node:

```kotlin
@Composable
fun RenderNode(node: NativeDisplayNode, ...) {
    if (node.animation != null) {
        AnimatedVisibility(
            visible = true,
            enter = node.animation.toEnterTransition()
        ) {
            RenderNodeContent(node, ...)
        }
    } else {
        RenderNodeContent(node, ...)
    }
}
```

## Background Rendering

Backgrounds are applied as modifiers:

```kotlin
fun Modifier.applyBackground(background: Background?): Modifier {
    if (background == null) return this

    return when (background) {
        is Background.Solid -> {
            background(background.color.parseColor())
        }
        is Background.LinearGradient -> {
            background(
                Brush.linearGradient(
                    colors = background.colors.map { it.parseColor() },
                    start = Offset.Zero,
                    end = Offset(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY)
                )
            )
        }
        // ... other background types
    }
}
```

## Performance Considerations

### 1. Remember Computed Values

```kotlin
val style = remember(node.id) {
    styleResolver.resolve(node, parentStyle)
}
```

### 2. Use Keys for Lists

```kotlin
node.children?.forEach { child ->
    key(child.id) {
        RenderNode(child, ...)
    }
}
```

### 3. Lazy Loading for Galleries

```kotlin
LazyRow {
    items(
        items = node.children ?: emptyList(),
        key = { it.id }
    ) { child ->
        RenderNode(child, ...)
    }
}
```

### 4. Minimize Recomposition

```kotlin
@Immutable
data class Style(...)

@Stable
data class NativeDisplayNode(...)
```

## Error Handling

### Parse Errors

```kotlin
try {
    val config = Json.decodeFromString<NativeDisplayConfig>(jsonString)
    RenderConfig(config)
} catch (e: SerializationException) {
    ErrorView("Invalid JSON: ${e.message}")
}
```

### Missing Variables

```kotlin
fun resolveVariable(path: String): String {
    return try {
        // ... resolution logic
    } catch (e: Exception) {
        Logger.warn("Variable not found: $path")
        ""  // Fallback to empty string
    }
}
```

### Invalid Colors

```kotlin
fun String.parseColor(): Color {
    return try {
        Color(this.removePrefix("#").toLong(16))
    } catch (e: NumberFormatException) {
        Logger.warn("Invalid color: $this")
        Color.Black  // Fallback
    }
}
```

## Debug Tips

### Log Rendering Tree

```kotlin
@Composable
fun RenderNode(node: NativeDisplayNode, ...) {
    Log.d("Rendering", "Node: ${node.id}, Type: ${node.containerType ?: node.elementType}")
    // ... render logic
}
```

### Preview in Android Studio

```kotlin
@Preview
@Composable
fun PreviewProductCard() {
    val config = NativeDisplayConfig(
        root = NativeDisplayNode(...)
    )
    NativeDisplayView(config)
}
```

### Screenshot Testing

```kotlin
@Test
fun testRendering() {
    composeTestRule.setContent {
        NativeDisplayView(testConfig)
    }
    composeTestRule.onRoot().captureToImage().assertAgainstGolden("product_card")
}
```
