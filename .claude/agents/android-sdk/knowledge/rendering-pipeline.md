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
│ Evaluate Vars   │  (VariableEvaluator)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Calculate Layout│  (ModifierExtensions.applySizing)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Render Compose  │  (RenderNode → ElementRenderer/GalleryRenderer)
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
internal class StyleResolver(
    private val theme: Theme,
    styleClasses: List<StyleClass>
) {
    private val styleClassMap = styleClasses.associateBy { it.name }

    fun resolve(node: NativeDisplayNode): Style {
        var style = theme.defaultStyle

        // Apply style class (overrides theme)
        node.styleClass?.let { className ->
            styleClassMap[className]?.style?.let { classStyle ->
                style = classStyle.mergeWith(style)
            }
        }

        // Apply inline style (highest priority, overrides everything)
        node.style?.let { style = it.mergeWith(style) }

        return style
    }

    // Parent→child cascading of text properties happens in resolveAll(), which
    // walks the tree once and returns a PersistentMap<String, Style>. Each child
    // merges its own style with the parent's cascadingOnly() text properties.
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

## Stage 3: Evaluate Variables

**Input**: Nodes with template bindings
**Output**: Nodes with evaluated string values
**Responsibility**: Replace `{{variable}}` with actual values (`VariableEvaluator`)

### Template Syntax

```
{{variableName}}        → variables["variableName"]
{{object.property}}     → variables["object"]["property"]
{{!expression}}         → Negation
```

### Implementation

```kotlin
class VariableEvaluator(
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
val text = node.bindings["text"]?.let { template ->
    variableEvaluator.evaluate(template)
} ?: ""
```

## Stage 4: Calculate Layout

**Input**: Layout configuration
**Output**: Compose Modifier with size constraints
**Responsibility**: Convert dimensions to actual pixel values

### aspectRatio Precedence Rule (Critical)

`aspectRatio` is applied as a Compose modifier **before** width and height modifiers (`applySizing` in `ModifierExtensions.kt`):

```kotlin
// AspectRatio applied FIRST
if (layout.aspectRatio != null && layout.aspectRatio > 0 && !(hasFixedWidth && hasFixedHeight)) {
    modifier = modifier.aspectRatio(layout.aspectRatio, matchHeightConstraintsFirst = hasFixedHeight)
}
// Then width
modifier = modifier.fillMaxWidth(width.value / 100f)  // for percent
// Then height
```

**Effect**: `Modifier.aspectRatio(ratio)` locks constraints to `{W=parentWidth, H=parentWidth/ratio}`. The subsequent `fillMaxWidth(fraction)` receives `minW=parentWidth` and cannot shrink — so **percent width has zero effect when AR is present**.

### Sizing Resolution Priority

| Scenario | Result |
|---|---|
| Both width AND height fixed (dp/px) | `aspectRatio` skipped; explicit dims win |
| Only height fixed (dp/px) | width = `fixedHeight × AR` (`matchHeightConstraintsFirst=true`) |
| Only width fixed (dp/px) | height = `fixedWidth / AR` |
| width is percent + AR | **percent ignored**; uses full parent width; height = `parentWidth / AR` |
| height is percent + AR | AR-derived height; percent height ignored |
| No explicit width or height | full parent width; height = `parentWidth / AR` |

> Note: `hasFixedWidth`/`hasFixedHeight` check `unit in [DP, PX]` — SP and PERCENT are NOT considered "fixed" for the AR skip condition.

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

> **Note on the current implementation**: In source, `NativeDisplayView` takes a
> `ResolvedConfig` (or a parsed `NativeDisplayUnit`). Styles are pre-resolved once into
> a `PersistentMap<String, Style>` (`StyleResolver.resolveAll`) and passed down — the
> `StyleResolver` is **not** a composable parameter. The snippet below is illustrative of
> the stage flow only; see `performance.md` for the authoritative pattern.

```kotlin
@Composable
fun NativeDisplayView(config: ResolvedConfig) {
    val resolvedStyles = remember(config) {
        StyleResolver(config.theme, config.styleClasses).resolveAll(config.root)
    }
    val variableEvaluator = remember(config.variables) { VariableEvaluator(config.variables) }

    BoxWithConstraints {
        val parentSize = IntSize(
            width = constraints.maxWidth,
            height = constraints.maxHeight
        )

        RenderNode(
            node = config.root,
            parentSize = parentSize,
            resolvedStyles = resolvedStyles,
            variableEvaluator = variableEvaluator
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
    resolvedStyles: PersistentMap<String, Style>,
    variableEvaluator: VariableEvaluator
) {
    // O(1) lookup — styles were pre-resolved at config-set time
    val style = resolvedStyles[node.id] ?: Style.EMPTY

    // NativeDisplayNode is a sealed class — dispatch on subtype
    when (node) {
        is NativeDisplayContainer -> RenderContainer(node, parentSize, style, ...)
        is NativeDisplayElement -> RenderElement(node, parentSize, style, ...)
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
    node: NativeDisplayElement,
    parentSize: IntSize,
    style: Style,
    variableEvaluator: VariableEvaluator
) {
    val elementModifier = Modifier
        .applyDimension(node.layout.width, parentSize.width, true)
        .applyDimension(node.layout.height, parentSize.height, false)
        .applyBackground(style.background)
        .applyPadding(node.layout.padding)

    when (node.elementType) {
        ElementType.TEXT -> {
            val text = node.bindings["text"]?.let {
                variableEvaluator.evaluate(it)
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
            val imageUrl = node.bindings["url"]?.let {
                variableEvaluator.evaluate(it)
            } ?: ""

            AsyncImage(
                model = imageUrl,
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

`parseColor` (in `RenderUtils.kt`) returns `null` on malformed input — callers fall back to a
default at the use site rather than the parser substituting black. Note the format is RGBA
(`#RRGGBBAA`, alpha = low byte), not ARGB.

```kotlin
internal fun parseColor(colorString: String?): Color? {
    if (colorString == null) return null
    return try {
        val hex = colorString.removePrefix("#")
        when (hex.length) {
            6 -> /* opaque RGB */ ...
            8 -> /* RGBA, alpha = low byte */ ...
            else -> null
        }
    } catch (_: Exception) {
        null  // caller decides the fallback
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
