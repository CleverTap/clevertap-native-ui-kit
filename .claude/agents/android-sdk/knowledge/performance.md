# Performance Optimization

## Recomposition Optimization

### Use Stable and Immutable Data Classes

```kotlin
// ✅ Mark models as Immutable
@Immutable
data class Style(
    val textColor: String? = null,
    val fontSize: Float? = null,
    // ... other properties
)

// ✅ Mark data classes as Stable
@Stable
data class NativeDisplayNode(
    val id: String,
    val layout: Layout,
    // ... other properties
)
```

**Why**: Compose can skip recomposition when parameters haven't changed.

### Remember Computed Values

```kotlin
// ✅ Remember style resolution
val style = remember(node.id, parentStyle) {
    styleResolver.resolve(node, parentStyle)
}

// ✅ Remember template evaluation
val text = remember(node.bindings, variables) {
    node.bindings?.get("text")?.let {
        templateEvaluator.evaluate(it)
    } ?: ""
}

// ❌ Don't recompute every composition
val text = node.bindings?.get("text")?.let {
    templateEvaluator.evaluate(it)  // Recomputes every time
} ?: ""
```

### Use derivedStateOf for Computed State

```kotlin
// ✅ Use derivedStateOf
val itemCount by remember {
    derivedStateOf { children.size }
}

// ❌ Don't compute directly
val itemCount = children.size  // Recomputes on every recomposition
```

### Skip Recomposition with Keys

```kotlin
// ✅ Use unique keys for list items
LazyColumn {
    items(
        items = children,
        key = { it.id }  // Unique, stable key
    ) { child ->
        RenderNode(child)
    }
}

// ❌ Without keys, entire list recomposes
LazyColumn {
    items(children) { child ->
        RenderNode(child)  // Recomposes all items
    }
}
```

## Image Loading Optimization

### Use Coil with Caching

```kotlin
@Composable
fun RenderImage(imageUrl: String) {
    AsyncImage(
        model = ImageRequest.Builder(LocalContext.current)
            .data(imageUrl)
            .crossfade(true)
            .memoryCachePolicy(CachePolicy.ENABLED)  // ✅ Memory cache
            .diskCachePolicy(CachePolicy.ENABLED)    // ✅ Disk cache
            .build(),
        contentDescription = null,
        modifier = Modifier.fillMaxWidth()
    )
}
```

### Preload Images

```kotlin
fun preloadImages(context: Context, imageUrls: List<String>) {
    val imageLoader = context.imageLoader
    imageUrls.forEach { url ->
        val request = ImageRequest.Builder(context)
            .data(url)
            .build()
        imageLoader.enqueue(request)
    }
}
```

### Use Placeholder and Error Images

```kotlin
AsyncImage(
    model = ImageRequest.Builder(LocalContext.current)
        .data(imageUrl)
        .placeholder(R.drawable.placeholder)  // Show while loading
        .error(R.drawable.error)              // Show on error
        .build(),
    contentDescription = null
)
```

## Layout Optimization

### Avoid Nested Weights

```kotlin
// ❌ Nested weights cause multiple measure passes
Column {
    Row(modifier = Modifier.weight(1f)) {
        Box(modifier = Modifier.weight(1f))
    }
}

// ✅ Use Box or explicit sizing
Box {
    // Position children absolutely
}
```

### Use BoxWithConstraints Sparingly

```kotlin
// ❌ BoxWithConstraints triggers extra recomposition
BoxWithConstraints {
    // maxWidth, maxHeight change frequently
}

// ✅ Use only when necessary (top-level)
@Composable
fun NativeDisplayView(config: NativeDisplayConfig) {
    BoxWithConstraints {  // Only at entry point
        val parentSize = IntSize(constraints.maxWidth, constraints.maxHeight)
        RenderNode(config.root, parentSize)
    }
}
```

### Prefer Lazy Lists for Long Content

```kotlin
// ✅ Use LazyColumn for long lists
LazyColumn {
    items(items) { item ->
        ItemView(item)
    }
}

// ❌ Don't use Column for long lists
Column {
    items.forEach { item ->
        ItemView(item)  // All items rendered at once
    }
}
```

## Memory Management

### Avoid Memory Leaks

```kotlin
// ✅ Use DisposableEffect for cleanup
@Composable
fun VideoPlayer(videoUrl: String) {
    val context = LocalContext.current
    val player = remember { ExoPlayer.Builder(context).build() }

    DisposableEffect(Unit) {
        onDispose {
            player.release()  // Cleanup when composable leaves
        }
    }

    AndroidView(factory = { PlayerView(it).apply { this.player = player } })
}
```

### Use rememberCoroutineScope

```kotlin
@Composable
fun AnimatedComponent() {
    val scope = rememberCoroutineScope()  // ✅ Lifecycle-aware

    Button(onClick = {
        scope.launch {
            // Coroutine cancelled when component leaves composition
        }
    })
}
```

## Background Rendering Optimization

### Cache Gradients

```kotlin
// ✅ Remember gradient brushes
val gradientBrush = remember(colors) {
    Brush.linearGradient(colors.map { it.parseColor() })
}

// ❌ Create new brush every time
val gradientBrush = Brush.linearGradient(colors.map { it.parseColor() })
```

### Optimize Animated Backgrounds

```kotlin
// ✅ Use infiniteRepeatable with appropriate spec
val infiniteTransition = rememberInfiniteTransition()
val offsetX by infiniteTransition.animateFloat(
    initialValue = 0f,
    targetValue = 1000f,
    animationSpec = infiniteRepeatable(
        animation = tween(3000, easing = LinearEasing),
        repeatMode = RepeatMode.Restart
    )
)

// ❌ Don't animate every frame unnecessarily
LaunchedEffect(Unit) {
    while (true) {
        offset += 1f
        delay(16)  // Inefficient
    }
}
```

## Gallery Performance

### Use HorizontalPager for Galleries

```kotlin
// ✅ Use HorizontalPager (optimized for paging)
@Composable
fun Gallery(items: List<Item>) {
    val pagerState = rememberPagerState()

    HorizontalPager(
        state = pagerState,
        pageCount = items.size,
        beyondBoundsPageCount = 1  // Preload 1 page on each side
    ) { page ->
        ItemView(items[page])
    }
}
```

### Lazy Load Gallery Items

```kotlin
// ✅ Only load visible and adjacent items
HorizontalPager(
    state = pagerState,
    pageCount = items.size,
    beyondBoundsPageCount = 1  // Only load current + 1 adjacent
) { page ->
    ItemView(items[page])
}
```

## Animation Performance

### Use Hardware Layer for Complex Animations

```kotlin
// ✅ Use graphicsLayer for transforms
Box(
    modifier = Modifier
        .graphicsLayer {
            alpha = animatedAlpha
            scaleX = animatedScale
            scaleY = animatedScale
            rotationZ = animatedRotation
        }
)

// ❌ Don't use drawing modifiers for animations
Box(
    modifier = Modifier
        .alpha(animatedAlpha)        // Creates new drawing layer each frame
        .scale(animatedScale)
        .rotate(animatedRotation)
)
```

### Optimize Animation Specs

```kotlin
// ✅ Use appropriate easing
animateFloatAsState(
    targetValue = target,
    animationSpec = tween(
        durationMillis = 300,
        easing = FastOutSlowInEasing  // Hardware-accelerated
    )
)

// ❌ Don't use overly long animations
animateFloatAsState(
    targetValue = target,
    animationSpec = tween(
        durationMillis = 5000  // Too long, poor UX
    )
)
```

## Profiling and Debugging

### Use Layout Inspector

1. Android Studio → Tools → Layout Inspector
2. Inspect recomposition counts (red boxes)
3. Identify hot spots

### Use Compose Compiler Reports

```bash
./gradlew assembleDebug -PcomposeCompilerReports=true
```

**Check reports for**:
- Unstable classes (causes recomposition)
- Skippable composables
- Restartable groups

### Use Composition Tracing

```kotlin
@Composable
fun TracedComponent() {
    val recompositions = remember { mutableStateOf(0) }

    SideEffect {
        recompositions.value++
        Log.d("Recomposition", "Count: ${recompositions.value}")
    }

    // ... component content
}
```

## Best Practices Summary

### DO

- ✅ Use `@Immutable` and `@Stable` annotations
- ✅ Remember computed values
- ✅ Use `key()` for list items
- ✅ Use LazyColumn/LazyRow for long lists
- ✅ Cache images with Coil
- ✅ Use `graphicsLayer` for animations
- ✅ Clean up resources in `DisposableEffect`
- ✅ Profile with Layout Inspector

### DON'T

- ❌ Compute expensive values in composition
- ❌ Create new objects unnecessarily
- ❌ Use Column/Row for long lists
- ❌ Nest BoxWithConstraints
- ❌ Use nested weights
- ❌ Forget to release resources
- ❌ Animate with drawing modifiers
- ❌ Skip profiling

## Performance Checklist

Before releasing:

- [ ] All data classes marked `@Immutable` or `@Stable`
- [ ] Expensive computations wrapped in `remember`
- [ ] List items use unique `key()`
- [ ] Long lists use LazyColumn/LazyRow
- [ ] Images cached with Coil
- [ ] Animations use `graphicsLayer`
- [ ] Resources properly cleaned up
- [ ] Profiled with Layout Inspector
- [ ] No memory leaks
- [ ] Smooth 60fps rendering

## Benchmarking

### Measure Recomposition Count

```kotlin
@Composable
fun BenchmarkComponent() {
    val recompositions = remember { mutableStateOf(0) }
    val lastTime = remember { mutableStateOf(System.currentTimeMillis()) }

    SideEffect {
        val now = System.currentTimeMillis()
        val delta = now - lastTime.value
        recompositions.value++
        Log.d("Benchmark", "Recomposition #${recompositions.value} (${delta}ms)")
        lastTime.value = now
    }

    // Component content
}
```

### Measure Render Time

```kotlin
@Test
fun benchmarkRendering() {
    val startTime = System.nanoTime()

    composeTestRule.setContent {
        NativeDisplayView(testConfig)
    }

    composeTestRule.waitForIdle()

    val endTime = System.nanoTime()
    val durationMs = (endTime - startTime) / 1_000_000

    println("Render time: ${durationMs}ms")
    assertTrue(durationMs < 100)  // Should render in < 100ms
}
```
