# Optimize Performance

## Task
Optimize rendering performance for [SPECIFIC_COMPONENT/SCENARIO].

## Performance Analysis

### 1. Measure Current Performance
```kotlin
@Test
fun measureRenderTime() {
    val startTime = System.nanoTime()

    composeTestRule.setContent {
        NativeDisplayView(config)
    }

    composeTestRule.waitForIdle()

    val durationMs = (System.nanoTime() - startTime) / 1_000_000
    println("Render time: ${durationMs}ms")
}
```

### 2. Check Recomposition Count
```kotlin
@Composable
fun TrackedComponent() {
    val recompositions = remember { mutableStateOf(0) }

    SideEffect {
        recompositions.value++
        Log.d("Perf", "Recompositions: ${recompositions.value}")
    }

    // Component content
}
```

### 3. Use Compose Compiler Reports
```bash
./gradlew assembleDebug -PcomposeCompilerReports=true
```
Check for:
- Unstable classes
- Non-skippable composables
- Restartable groups

## Optimization Strategies

### 1. Mark Data Classes as Stable/Immutable
```kotlin
// Before
data class Style(...)

// After
@Immutable
data class Style(...)
```

### 2. Remember Computed Values
```kotlin
// Before (recomputes every composition)
val text = templateEvaluator.evaluate(binding)

// After (computed once)
val text = remember(binding, variables) {
    templateEvaluator.evaluate(binding)
}
```

### 3. Use derivedStateOf
```kotlin
// Before
val itemCount = children.size

// After
val itemCount by remember {
    derivedStateOf { children.size }
}
```

### 4. Add Keys to Lists
```kotlin
// Before
children.forEach { child ->
    RenderNode(child)
}

// After
children.forEach { child ->
    key(child.id) {
        RenderNode(child)
    }
}
```

### 5. Use LazyColumn for Long Lists
```kotlin
// Before (renders all items)
Column {
    items.forEach { item ->
        ItemView(item)
    }
}

// After (lazy loading)
LazyColumn {
    items(items, key = { it.id }) { item ->
        ItemView(item)
    }
}
```

### 6. Optimize Images
```kotlin
AsyncImage(
    model = ImageRequest.Builder(context)
        .data(url)
        .memoryCachePolicy(CachePolicy.ENABLED)  // ✅ Cache
        .diskCachePolicy(CachePolicy.ENABLED)    // ✅ Cache
        .size(width, height)                     // ✅ Resize
        .build()
)
```

### 7. Use graphicsLayer for Animations
```kotlin
// Before
Modifier
    .alpha(animatedAlpha)
    .scale(animatedScale)

// After (hardware accelerated)
Modifier.graphicsLayer {
    alpha = animatedAlpha
    scaleX = animatedScale
    scaleY = animatedScale
}
```

### 8. Minimize BoxWithConstraints Usage
```kotlin
// Use only at top level
@Composable
fun NativeDisplayView(config: NativeDisplayConfig) {
    BoxWithConstraints {  // Only once
        val parentSize = IntSize(constraints.maxWidth, constraints.maxHeight)
        RenderNode(config.root, parentSize)  // Pass size down
    }
}
```

## Performance Checklist

- [ ] All data classes marked @Immutable or @Stable
- [ ] Expensive computations wrapped in remember{}
- [ ] List items use unique key()
- [ ] LazyColumn/LazyRow for >10 items
- [ ] Images cached and resized
- [ ] Animations use graphicsLayer
- [ ] No BoxWithConstraints in loops
- [ ] Resources cleaned up (DisposableEffect)
- [ ] Compose compiler reports checked
- [ ] Layout Inspector shows no hot spots

## Benchmarking

### Target Performance
- Initial render: < 100ms
- Recomposition: < 16ms (60fps)
- Memory: < 50MB for typical config
- No frame drops during animations

### Profiling Tools
- Layout Inspector (recomposition counts)
- Android Profiler (CPU, memory)
- Compose Compiler Reports (unstable classes)
- Systrace (frame timing)

## Example Optimization

### Before
```kotlin
@Composable
fun SlowComponent(node: NativeDisplayNode) {
    val style = styleResolver.resolve(node, parentStyle)  // Recomputes
    val text = templateEvaluator.evaluate(binding)        // Recomputes

    Column {
        children.forEach { child ->  // No keys
            RenderNode(child)
        }
    }
}
```

### After
```kotlin
@Composable
fun FastComponent(node: NativeDisplayNode) {
    val style = remember(node.id) {
        styleResolver.resolve(node, parentStyle)  // Cached
    }

    val text = remember(binding, variables) {
        templateEvaluator.evaluate(binding)  // Cached
    }

    LazyColumn {  // Lazy loading
        items(children, key = { it.id }) { child ->  // With keys
            RenderNode(child)
        }
    }
}
```

**Result**: 10x faster recomposition, 5x less memory usage
