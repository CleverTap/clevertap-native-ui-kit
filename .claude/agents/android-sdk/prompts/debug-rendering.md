# Debug Rendering Issue

## Problem Description
[Describe what's not rendering correctly]

## Debugging Steps

### 1. Verify JSON Configuration
```kotlin
// Print parsed config
println(Json.encodeToString(config))

// Check for parsing errors
try {
    val config = Json.decodeFromString<NativeDisplayConfig>(jsonString)
} catch (e: SerializationException) {
    println("Parse error: ${e.message}")
}
```

### 2. Check Style Resolution
```kotlin
// Log resolved styles
val style = styleResolver.resolve(node, parentStyle)
println("Resolved style for ${node.id}: $style")

// Verify style cascading
println("Parent style: $parentStyle")
println("Node style: ${node.style}")
println("Final style: $style")
```

### 3. Verify Dimension Calculation
```kotlin
// Log calculated dimensions
println("Parent size: $parentSize")
println("Node width: ${node.layout.width}")
println("Node height: ${node.layout.height}")

// Check for PERCENT calculations
if (node.layout.width?.unit == DimensionUnit.PERCENT) {
    val widthPx = parentSize.width * (node.layout.width.value / 100)
    println("Calculated width: ${widthPx}px")
}
```

### 4. Check Modifier Application
```kotlin
// Add logging modifiers
Modifier
    .then(Modifier.onGloballyPositioned { coordinates ->
        println("Element size: ${coordinates.size}")
        println("Element position: ${coordinates.positionInRoot()}")
    })
    .applyBackground(...)
    .applyPadding(...)
```

### 5. Use Layout Inspector
1. Run app in debug mode
2. Open Tools → Layout Inspector
3. Select compose node
4. Check actual size, position, modifiers
5. Look for recomposition counts (red boxes)

### 6. Add Debug Borders
```kotlin
// Temporarily add debug borders to see element bounds
Modifier
    .border(1.dp, Color.Red)  // Debug border
    .applyNormalModifiers()
```

## Common Issues

### Nothing Renders
- Check if parent has size (BoxWithConstraints at root?)
- Verify layout dimensions aren't zero
- Check if background/content color same as parent

### Wrong Size
- Verify parent size passed correctly
- Check PERCENT calculations
- Look for WRAP_CONTENT with no content
- Verify special dimensions (MATCH_PARENT, WRAP_CONTENT)

### Wrong Position
- Check Offset calculations in BOX/STACK
- Verify arrangement strategy applied
- Look for padding applied in wrong order

### Wrong Color
- Verify ARGB format (#AARRGGBB not #RRGGBB)
- Check color parsing (RGB → ARGB conversion)
- Verify opacity applied correctly

### Style Not Applied
- Check style resolution order
- Verify style class name matches
- Look for null style properties
- Confirm text properties cascade

### Children Not Showing
- Verify children list not null/empty
- Check child dimensions
- Look for z-index issues in STACK
- Verify arrangement spacing

## Debugging Code Template
```kotlin
@Composable
fun DebugNode(node: NativeDisplayNode, style: Style) {
    Column(modifier = Modifier.border(2.dp, Color.Magenta)) {
        Text("Node: ${node.id}", fontSize = 10.sp)
        Text("Type: ${node.containerType ?: node.elementType}", fontSize = 10.sp)
        Text("Width: ${node.layout.width}", fontSize = 10.sp)
        Text("Height: ${node.layout.height}", fontSize = 10.sp)
        Text("Background: ${style.background}", fontSize = 10.sp)
        Text("Children: ${node.children?.size ?: 0}", fontSize = 10.sp)
    }
}
```

## Performance Issues
- Use Layout Inspector to find recomposition hot spots
- Check for unstable data classes (@Immutable missing?)
- Look for expensive operations in composition
- Verify images cached
- Check for unnecessary remember{} recomputation
