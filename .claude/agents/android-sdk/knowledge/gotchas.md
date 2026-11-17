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

### SDK color format is RGBA (`#RRGGBBAA`), NOT ARGB

The SDK consumes **RGBA** hex (matching the web/dashboard standard), and the actual parser
lives in `RenderUtils.kt` as a top-level `internal fun parseColor(colorString: String?): Color?`.
An 8-digit value is `#RRGGBBAA` — **alpha is the LOW byte**. A 6-digit value is opaque RGB.
Invalid input returns `null` (no black fallback).

```kotlin
// ✅ Correct — mirrors RenderUtils.parseColor (RGBA, alpha = low byte)
internal fun parseColor(colorString: String?): Color? {
    if (colorString == null) return null
    return try {
        val hex = colorString.removePrefix("#")
        when (hex.length) {
            6 -> {
                val rgb = hex.toLong(16)
                Color(
                    red = ((rgb shr 16) and 0xFF) / 255f,
                    green = ((rgb shr 8) and 0xFF) / 255f,
                    blue = (rgb and 0xFF) / 255f,
                    alpha = 1f
                )
            }
            8 -> {  // #RRGGBBAA — alpha is the low byte
                val rgba = hex.toLong(16)
                Color(
                    red = ((rgba shr 24) and 0xFF) / 255f,
                    green = ((rgba shr 16) and 0xFF) / 255f,
                    blue = ((rgba shr 8) and 0xFF) / 255f,
                    alpha = (rgba and 0xFF) / 255f
                )
            }
            else -> null
        }
    } catch (_: Exception) {
        null
    }
}
```

**Common mistake**: treating 8-digit hex as ARGB (alpha = high byte). That is wrong for this
SDK — `#FF000080` is **red at 50% alpha**, not a near-opaque dark color.

```
Web/JSON (RGBA): #FF0000FF  → opaque red
                 #FF000080  → red at ~50% alpha
```

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

### Problem: Assuming percent width is respected when aspectRatio is set

```kotlin
// JSON: {"width": {"value": 80, "unit": "percent"}, "aspectRatio": 1.777}

// ❌ Wrong assumption: card renders at 80% width
// ✅ Actual: card renders at FULL parent width, height = parentWidth / 1.777
```

**Why**: `applySizing` in `ModifierExtensions.kt` applies `aspectRatio` modifier BEFORE `fillMaxWidth(fraction)`. The AR modifier locks constraints to `{minW=parentWidth, H=parentWidth/ratio}`. The subsequent `fillMaxWidth(0.8f)` receives `minW=parentWidth` and cannot shrink the width — so the 80% has zero effect.

**Rule**: `aspectRatio` overrides all percent dimensions. Percent is only respected when no AR is set. Fixed (dp/px) dims override AR only when BOTH width AND height are fixed simultaneously.

See `ModifierExtensions.kt` — `applySizing()` (aspectRatio applied at ~lines 116-121, before the width `fillMaxWidth(...)`) for the exact implementation.

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

### Problem: fontSize / lineHeight accept two JSON shapes

`fontSize` and `lineHeight` can arrive as either a raw number or an object:

```json
{ "fontSize": 16 }                              // raw number (platform SP)
{ "fontSize": { "value": 40, "unit": "percent" } }  // percent of rootContainerHeight
```

**Kotlin model** (in `TextDimension.kt`): these fields are `TextDimension?`, **not** `Float?`:
```kotlin
@Immutable
@Serializable(with = TextDimensionSerializer::class)
data class TextDimension(
    val value: Float,
    val unit: TextDimensionUnit = TextDimensionUnit.PLATFORM  // PLATFORM | PERCENT
)

// In Style.kt:
val fontSize: TextDimension? = null
val lineHeight: TextDimension? = null
```

**How it already works**: `TextDimensionSerializer` is a custom `KSerializer` that accepts
both the raw-number and `{value, unit}` object forms, so there is no need to add your own
`Float` serializer. `PERCENT` resolves as `rootHeightPx * value / 1000` via `TextDimension.resolve()`.

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
- [ ] Verify color format (RGBA `#RRGGBBAA`, alpha = low byte — NOT ARGB)
- [ ] Use start/end instead of left/right for RTL
- [ ] Provide spacing value for SPACED strategy
- [ ] Specify dimensions for all elements
- [ ] Check that variables exist in config
- [ ] Verify style cascading (only text properties)
- [ ] Release resources in DisposableEffect
- [ ] Use correct number types in JSON
- [ ] Check for circular references in node tree
