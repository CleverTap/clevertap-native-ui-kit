# Gotchas and Common Pitfalls

## Modifier Order Issues

### Problem: Padding Applied After Border

```kotlin
// ❌ Wrong: Padding outside border
Box(
    modifier = Modifier
        .border(2.dp, Color.Black)
        .padding(16.dp)  // Padding OUTSIDE border
)
```

**Result**: Border appears inside the padding area.

```kotlin
// ✅ Correct: Padding inside border
Box(
    modifier = Modifier
        .padding(16.dp)  // Padding INSIDE
        .border(2.dp, Color.Black)  // Border OUTSIDE padding
)
```

### Problem: Background Covers Children

```kotlin
// ❌ Wrong: Background applied after size
Box(
    modifier = Modifier
        .size(100.dp)
        .padding(16.dp)
        .background(Color.Red)  // Background covers padding
)
```

**Result**: Background fills entire box including padding.

```kotlin
// ✅ Correct: Background before padding
Box(
    modifier = Modifier
        .size(100.dp)
        .background(Color.Red)  // Background first
        .padding(16.dp)  // Padding creates inner space
)
```

## Color Format Issues

### Problem: RGB vs ARGB Format

```kotlin
// ❌ Wrong: RGB format parsed as ARGB
val color = Color("#FF0000".toLong(16))  // Becomes #00FF0000 (transparent)
```

**Solution**: Always convert RGB to ARGB

```kotlin
// ✅ Correct: Convert RGB to ARGB
fun String.parseColor(): Color {
    val cleanHex = this.removePrefix("#")
    val argb = when (cleanHex.length) {
        6 -> "FF$cleanHex"  // RGB → ARGB (add full alpha)
        8 -> cleanHex       // Already ARGB
        else -> "FF000000"  // Fallback to black
    }
    return Color(argb.toLong(16))
}
```

### Problem: ARGB vs RGBA

Android uses ARGB format, but many web tools use RGBA:

```
Web (RGBA): #FF0000FF (red with full alpha)
Android (ARGB): #FFFF0000 (red with full alpha)
```

**Always verify**: Color format in JSON should be ARGB (#AARRGGBB).

## RTL Layout Issues

### Problem: Using left/right Instead of start/end

```kotlin
// ❌ Wrong: left/right don't flip in RTL
Modifier.padding(left = 16.dp, right = 8.dp)
```

**Result**: Layout doesn't mirror correctly in RTL languages.

```kotlin
// ✅ Correct: start/end flip automatically
Modifier.padding(start = 16.dp, end = 8.dp)
```

### Problem: Custom Offset Doesn't Respect RTL

```kotlin
// ❌ Wrong: Hardcoded offset doesn't flip
Modifier.offset(x = 100.dp, y = 0.dp)
```

**Solution**: Use RTL-aware offset

```kotlin
// ✅ Correct: Check layout direction
val layoutDirection = LocalLayoutDirection.current
val xOffset = if (layoutDirection == LayoutDirection.Rtl) {
    -100.dp
} else {
    100.dp
}
Modifier.offset(x = xOffset, y = 0.dp)
```

## Spacing and Arrangement Issues

### Problem: SPACED Strategy Without Spacing Value

```kotlin
// ❌ Wrong: SPACED with null spacing
arrangement = ChildArrangement(
    strategy = ArrangementStrategy.SPACED,
    spacing = null  // No spacing value!
)
```

**Result**: Falls back to 0.dp spacing (children touch each other).

```kotlin
// ✅ Correct: Always provide spacing for SPACED
arrangement = ChildArrangement(
    strategy = ArrangementStrategy.SPACED,
    spacing = 8f  // Explicit spacing
)
```

### Problem: SPACE_BETWEEN with One Child

```kotlin
// ❌ Unexpected: SPACE_BETWEEN with single child
Row(
    horizontalArrangement = Arrangement.SpaceBetween
) {
    SingleChild()  // Will align to start
}
```

**Result**: Single child aligns to start (no space to distribute).

**Solution**: Use START, CENTER, or END for single children.

## Dimension Calculation Issues

### Problem: Percent Dimension Without Parent Size

```kotlin
// ❌ Wrong: Percent without knowing parent
Box(
    modifier = Modifier.width(50.percent)  // Percent of what?
)
```

**Result**: Cannot calculate actual size.

**Solution**: Always pass parent size context

```kotlin
// ✅ Correct: Calculate percent based on parent
Box(
    modifier = Modifier.width((parentWidth * 0.5f).dp)
)
```

### Problem: WRAP_CONTENT for Images Without Dimensions

```kotlin
// ❌ Wrong: WRAP_CONTENT with async image
AsyncImage(
    model = imageUrl,
    modifier = Modifier.wrapContentSize()  // Size unknown until loaded
)
```

**Result**: Layout shifts when image loads.

**Solution**: Always specify image dimensions

```kotlin
// ✅ Correct: Fixed dimensions or aspect ratio
AsyncImage(
    model = imageUrl,
    modifier = Modifier
        .fillMaxWidth()
        .aspectRatio(16f / 9f)
)
```

## Gallery Issues

### Problem: Gallery Without Item Width

```kotlin
// ❌ Wrong: Gallery children without width
HorizontalPager {
    Box {  // No width specified
        Content()
    }
}
```

**Result**: Items collapse or expand unexpectedly.

**Solution**: Always specify item dimensions

```kotlin
// ✅ Correct: Fixed width per item
HorizontalPager {
    Box(modifier = Modifier.fillMaxWidth(0.8f)) {  // 80% of viewport
        Content()
    }
}
```

### Problem: Gallery Peeking Without Content Padding

```kotlin
// ❌ Wrong: Trying to peek without padding
HorizontalPager(
    state = pagerState,
    modifier = Modifier.fillMaxWidth()  // No padding
)
```

**Result**: Next item not visible (no peeking effect).

**Solution**: Use contentPadding

```kotlin
// ✅ Correct: Content padding enables peeking
HorizontalPager(
    state = pagerState,
    contentPadding = PaddingValues(horizontal = 32.dp),  // Shows adjacent items
    pageSpacing = 16.dp
)
```

## Style Cascading Issues

### Problem: Expecting Visual Properties to Cascade

```kotlin
// ❌ Wrong assumption: backgroundColor cascades
parent.style.backgroundColor = "#FF0000"
// Child does NOT inherit backgroundColor
```

**Reality**: Only text properties cascade:
- textColor ✅
- fontSize ✅
- fontWeight ✅
- backgroundColor ❌
- borderRadius ❌

### Problem: Inline Style Doesn't Override Style Class

```kotlin
// ❌ Wrong: Order matters
val style = inlineStyle.merge(classStyle)  // classStyle wins
```

**Correct order**:
```kotlin
// ✅ Correct: Inline style should override
val style = classStyle.merge(inlineStyle)  // inlineStyle wins
```

## Template Evaluation Issues

### Problem: Missing Variable Doesn't Show Error

```kotlin
// ❌ Wrong: Missing variable returns empty string
bindings = { "text": "{{missingVar}}" }  // Renders as ""
```

**Result**: Silent failure, empty text displayed.

**Solution**: Add validation or fallback

```kotlin
// ✅ Better: Log warning and use fallback
fun evaluate(template: String): String {
    return regex.replace(template) { match ->
        val variable = resolveVariable(match.value)
        if (variable.isEmpty()) {
            Log.w("Template", "Missing variable: ${match.value}")
        }
        variable
    }
}
```

### Problem: Object Property Access on Null

```kotlin
// ❌ Wrong: Accessing property on null object
{{user.name}}  // If user is null, crashes
```

**Solution**: Safe navigation in template evaluator

```kotlin
// ✅ Correct: Safe property access
fun resolveVariable(path: String): String {
    val parts = path.split(".")
    var current: JsonElement? = variables?.get(parts[0])

    for (i in 1 until parts.size) {
        if (current == null) return ""  // Safe early return
        current = (current as? JsonObject)?.get(parts[i])
    }

    return current?.toString() ?: ""
}
```

## Animation Issues

### Problem: Animation Delay Not Working

```kotlin
// ❌ Wrong: AnimatedVisibility doesn't respect enter delay
AnimatedVisibility(
    visible = true,
    enter = fadeIn(animationSpec = tween(delay = 1000))
)
```

**Issue**: Delay only works when transitioning from `visible=false` to `visible=true`.

**Solution**: Use LaunchedEffect for initial delay

```kotlin
// ✅ Correct: Delay initial visibility
var visible by remember { mutableStateOf(false) }

LaunchedEffect(Unit) {
    delay(1000)
    visible = true
}

AnimatedVisibility(visible = visible, enter = fadeIn())
```

### Problem: Animation Not Smooth

```kotlin
// ❌ Wrong: Using State instead of animate*
var scale by remember { mutableStateOf(1f) }

// Updates immediately, not animated
scale = 2f
```

**Solution**: Use animate APIs

```kotlin
// ✅ Correct: Use animateFloatAsState
var targetScale by remember { mutableStateOf(1f) }
val scale by animateFloatAsState(targetScale)

// Updates with animation
targetScale = 2f
```

## Memory Leak Issues

### Problem: Not Releasing Video Player

```kotlin
// ❌ Wrong: Player never released
@Composable
fun VideoPlayer() {
    val player = ExoPlayer.Builder(context).build()
    AndroidView(factory = { PlayerView(it).apply { this.player = player } })
    // Player leaks when composable leaves
}
```

**Solution**: Use DisposableEffect

```kotlin
// ✅ Correct: Release player on dispose
@Composable
fun VideoPlayer() {
    val player = remember { ExoPlayer.Builder(context).build() }

    DisposableEffect(Unit) {
        onDispose {
            player.release()  // Cleanup
        }
    }

    AndroidView(factory = { PlayerView(it).apply { this.player = player } })
}
```

## JSON Parsing Issues

### Problem: Float vs Int for fontSize

```json
// ❌ Wrong: JSON number type mismatch
{
  "fontSize": 16  // Int, but model expects Float
}
```

**Kotlin model**:
```kotlin
@Serializable
data class Style(
    val fontSize: Float? = null  // Expects Float
)
```

**Solution**: Define model with appropriate type or use custom serializer

```kotlin
// ✅ Option 1: Accept both
@Serializable
data class Style(
    @Serializable(with = FloatSerializer::class)
    val fontSize: Float? = null
)

object FloatSerializer : KSerializer<Float> {
    override fun deserialize(decoder: Decoder): Float {
        return when (val value = decoder.decodeJsonElement()) {
            is JsonPrimitive -> value.content.toFloat()
            else -> 0f
        }
    }
}
```

### Problem: Null vs Missing Fields

```json
// ❌ These are different
{
  "styleClass": null  // Explicit null
}

{
  // styleClass missing
}
```

**Kotlin interpretation**:
```kotlin
data class Node(
    val styleClass: String? = null  // Both parse to null
)
```

**Both are equivalent** in kotlinx.serialization with nullable fields.

## Known Limitations

### 1. Circular References
Circular references in node tree will cause infinite recursion. Validate config before rendering.

### 2. Max Nesting Depth
Deep nesting (>20 levels) may cause stack overflow. Consider flattening structure.

### 3. Large Images
Very large images (>10MB) may cause OOM. Compress or resize before using.

### 4. Complex Gradients
Gradients with >10 color stops may impact performance. Limit stops where possible.

### 5. Animated Particles
Particle backgrounds with >100 particles impact battery. Use sparingly.

## Debug Checklist

When something doesn't work:

- [ ] Check modifier order (background → padding → border)
- [ ] Verify color format (ARGB, not RGBA)
- [ ] Use start/end instead of left/right for RTL
- [ ] Provide spacing value for SPACED strategy
- [ ] Specify dimensions for all elements
- [ ] Check that variables exist in config
- [ ] Verify style cascading (only text properties)
- [ ] Release resources in DisposableEffect
- [ ] Use correct number types in JSON
- [ ] Check for circular references in node tree
