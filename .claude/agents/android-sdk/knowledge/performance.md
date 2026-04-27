# Android SDK — Performance Guide

This document reflects the **actual implemented architecture** as of the performance audit (Feb 2026). Always match these patterns — do not introduce old patterns.

---

## Architecture: Pre-Resolved Styles (the biggest win)

Styles are resolved **once at config-set time**, before any composable runs. The render tree receives a flat `PersistentMap<String, Style>` and does an O(1) lookup per node.

```kotlin
// ✅ CURRENT PATTERN — in NativeDisplayViewGroup.setConfig()
val resolver = StyleResolver(config.theme, config.styleClasses)
resolvedStylesState.value = resolver.resolveAll(config.root)  // one pass, entire tree

// ✅ CURRENT PATTERN — in NativeDisplayView composable
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    resolvedStyles: PersistentMap<String, Style>,  // pre-resolved, passed in
    ...
) { ... }

// ✅ CURRENT PATTERN — per-node lookup (O(1))
val resolvedStyle = resolvedStyles[node.id] ?: Style.EMPTY

// ❌ OLD PATTERN — never do this (StyleResolver in the render tree)
val style = remember(node.id) { styleResolver.resolveWithColors(node) }
```

**Why**: StyleResolver is never a composable parameter. No `remember` ceremony needed per node.

---

## Stability Annotations

### @Immutable vs @Stable — When to Use Each

| Annotation | Use on | Guarantee |
|---|---|---|
| `@Immutable` | `data class` with all `val` fields | All fields are deeply immutable after construction |
| `@Stable` | `sealed class`, `interface`, `class` with `@Stable` fields | Compose can safely read any fields and trust they won't silently change |

```kotlin
// ✅ sealed class hierarchy → @Stable on parent
@Stable
sealed class NativeDisplayNode { ... }

// ✅ data class → @Immutable
@Immutable
@Serializable
data class NativeDisplayContainer(
    val id: String,
    val children: List<NativeDisplayNode>,  // see note below
    ...
) : NativeDisplayNode()
```

### @Immutable + List<T> — The Accepted Trade-off

Our `@Serializable` model classes contain `List<T>` fields (required for kotlinx.serialization compatibility). `List<T>` is technically mutable in Kotlin's type system, so Compose's stability analyzer would normally mark these classes as unstable.

**Our approach**: Annotate with `@Immutable` as a **promise** — we parse JSON once and never mutate the collections. This is the standard production pattern across the Android ecosystem.

```kotlin
// ✅ @Immutable as a promise — correct for our use case
@Immutable
@Serializable
data class NativeDisplayConfig(
    val root: NativeDisplayNode,
    val styleClasses: List<StyleClass> = emptyList(),  // never mutated post-parse
    ...
)

// ❌ The truly "compiler-correct" fix would break @Serializable:
@Immutable
data class NativeDisplayConfig(
    val styleClasses: ImmutableList<StyleClass>,  // incompatible with kotlinx.serialization
)
```

**Why it still works**: See Strong Skipping Mode below.

### Strong Skipping Mode (Kotlin 2.0.20+ — our default)

The project uses **Kotlin 2.1.0**, so Strong Skipping Mode is active by default. This changes recomposition rules:

- **Stable params**: compared with `equals()`
- **Unstable params**: compared with **reference equality (`===`)** — composables are still skippable when the same instance is passed
- **Lambdas**: automatically memoized by the compiler (no manual `remember` needed for lambdas)

**Practical impact**: Even if a composable receives a `NativeDisplayContainer` (which has `List<T>`), it will be skipped if the same instance is passed again. Combined with `@Immutable`, our render tree is doubly protected.

---

## Stable Collections for the Style Map

Use `PersistentMap` from `kotlinx-collections-immutable` for the resolved styles map. This is the only collection type Compose's stability checker trusts.

```kotlin
// Dependency in build.gradle.kts:
implementation(libs.kotlinx.collections.immutable)

// ✅ Resolved styles — PersistentMap is stable
fun resolveAll(node: NativeDisplayNode): PersistentMap<String, Style> {
    val result = mutableMapOf<String, Style>()
    resolveAllInto(node, Style.EMPTY, result)
    return result.toPersistentMap()
}

// ✅ In composables — stable parameter, Compose can skip on reference equality
@Composable
fun RenderNode(
    node: NativeDisplayNode,
    resolvedStyles: PersistentMap<String, Style>,
    ...
)
```

**Do NOT** use `Map<String, Style>` or `HashMap` — these are unstable and defeat the purpose.

---

## remember() Patterns

```kotlin
// ✅ VariableEvaluator — keyed by variables map reference
val evaluator = remember(config.variables) {
    VariableEvaluator(variables = config.variables)
}

// ✅ ActionHandler — keyed by both listeners
val actionHandler = remember(actionListener, componentListener) {
    ActionHandler(context = context, listener = actionListener, componentListener = componentListener)
}
DisposableEffect(actionHandler) { onDispose { actionHandler.cleanup() } }

// ✅ Derived state that changes frequently (e.g. scroll position)
val showScrollButton by remember {
    derivedStateOf { listState.firstVisibleItemIndex > 0 }
}

// ❌ Never create heavyweight objects bare in composition
val evaluator = VariableEvaluator(variables = config.variables)  // recreated every recomposition
```

---

## LazyList Keys

Always provide `key = { it.id }` in `LazyRow` / `LazyColumn`. Without keys, any list change causes full re-render and breaks state.

```kotlin
// ✅ Keyed — only changed items recompose; state stays with correct item
LazyRow(modifier = modifier) {
    items(container.children, key = { it.id }) { child ->
        RenderNode(child, resolvedStyles, evaluator, ...)
    }
}

// ❌ No key — position-based, full re-render on insertions/deletions
LazyRow {
    items(container.children) { child ->
        RenderNode(child, ...)  // all items recompose on any list change
    }
}
```

---

## Interface Stability Gotcha

All Kotlin **interfaces** are unstable by default in Compose (even `@Stable` doesn't help for interfaces). Our listener types are interfaces:

```kotlin
// These are interfaces → unstable
NativeDisplayActionListener
NativeDisplayComponentListener
```

**Why this doesn't cause problems**: Both are always wrapped in `remember(...)` before use in composables — the `ActionHandler` is the stable boundary. If you ever pass a listener directly as a composable parameter, wrap it in a `remember` block.

```kotlin
// ✅ Listeners are wrapped — stable boundary
val actionHandler = remember(actionListener, componentListener) {
    ActionHandler(...)
}
```

---

## Java Interop

```kotlin
// ✅ @JvmOverloads on functions with default parameters
@JvmOverloads
fun setConfig(
    config: ResolvedConfig,
    actionListener: NativeDisplayActionListener? = null,
    componentListener: NativeDisplayComponentListener? = null
) { ... }
```

Without `@JvmOverloads`, Java callers cannot use default parameters — they must pass `null` explicitly for every optional parameter.

---

## Checking Stability with Compose Compiler Reports

Generate reports to verify annotated classes are seen as stable:

```bash
cd android && ./gradlew assembleDebug -PcomposeCompilerReports=true
```

Reports appear in `sdk/build/compose_compiler/`. Look for:
- `stable class` — correct
- `unstable class` — needs `@Immutable`/`@Stable` or collection type fix
- `skippable fun` — correct
- `restartable fun (not skippable)` — composable receives unstable param

---

## Common Pitfalls

| Pitfall | Impact | Fix |
|---|---|---|
| StyleResolver as a composable parameter | Recomputes entire style chain on every recomposition | Pre-resolve via `resolveAll()` at `setConfig()` time |
| `List<T>` in `@Immutable` class | Technically unstable (but accepted with Strong Skipping) | Use `@Immutable` as promise; add `ImmutableList` only if stability report shows skippability failure |
| Missing `key` in `LazyRow`/`LazyColumn` | Full re-render on insertions/deletions, state loss | Always `key = { it.id }` |
| `Map<String, Style>` for resolved styles | Unstable, defeats the purpose | Use `PersistentMap<String, Style>` |
| Interface params passed directly to composable | Interface is always unstable | Wrap in `remember` or encapsulate in a stable class |
| Bare object creation in composable body | Recreated every recomposition | Wrap in `remember(key) { ... }` |
| Backwards writes (state write after state read in body) | Infinite recomposition loop | Only write state in event handlers or `LaunchedEffect` |

---

## Image Loading (Coil)

```kotlin
// ✅ Enable memory + disk cache
AsyncImage(
    model = ImageRequest.Builder(LocalContext.current)
        .data(imageUrl)
        .crossfade(true)
        .memoryCachePolicy(CachePolicy.ENABLED)
        .diskCachePolicy(CachePolicy.ENABLED)
        .placeholder(R.drawable.placeholder)
        .error(R.drawable.error)
        .build(),
    contentDescription = null,
    modifier = Modifier.fillMaxWidth()
)

// ✅ Preload images before they're needed
fun preloadImages(context: Context, imageUrls: List<String>) {
    val imageLoader = context.imageLoader
    imageUrls.forEach { url ->
        imageLoader.enqueue(ImageRequest.Builder(context).data(url).build())
    }
}
```

---

## Memory Management

```kotlin
// ✅ DisposableEffect for any resource that must be released
@Composable
fun VideoPlayer(videoUrl: String) {
    val context = LocalContext.current
    val player = remember { ExoPlayer.Builder(context).build() }

    DisposableEffect(Unit) {
        onDispose { player.release() }
    }
    AndroidView(factory = { PlayerView(it).apply { this.player = player } })
}

// ✅ rememberCoroutineScope for composable-scoped coroutines
@Composable
fun AnimatedComponent() {
    val scope = rememberCoroutineScope()  // cancelled when composable leaves
    Button(onClick = { scope.launch { /* ... */ } }) { Text("Go") }
}
```

---

## Background Rendering

```kotlin
// ✅ Cache gradient brushes — remember keyed by colors
val gradientBrush = remember(colors) {
    Brush.linearGradient(colors.map { it.parseColor() })
}

// ❌ Creates new brush object every recomposition
val gradientBrush = Brush.linearGradient(colors.map { it.parseColor() })

// ✅ Animated backgrounds — use infiniteRepeatable, not manual delay loops
val infiniteTransition = rememberInfiniteTransition()
val offsetX by infiniteTransition.animateFloat(
    initialValue = 0f,
    targetValue = 1000f,
    animationSpec = infiniteRepeatable(
        animation = tween(3000, easing = LinearEasing),
        repeatMode = RepeatMode.Restart
    )
)

// ❌ Inefficient — manual animation loop
LaunchedEffect(Unit) {
    while (true) { offset += 1f; delay(16) }
}
```

---

## Gallery Performance

```kotlin
// ✅ HorizontalPager — preload 1 adjacent page on each side
HorizontalPager(
    state = pagerState,
    beyondViewportPageCount = 1
) { page ->
    RenderNode(container.children[page], resolvedStyles, ...)
}
```

---

## Animation Performance

```kotlin
// ✅ graphicsLayer — runs on the RenderThread, not the main thread
Box(
    modifier = Modifier.graphicsLayer {
        alpha = animatedAlpha
        scaleX = animatedScale
        scaleY = animatedScale
        rotationZ = animatedRotation
    }
)

// ❌ Drawing modifiers — create new layers each frame, stay on main thread
Box(modifier = Modifier.alpha(animatedAlpha).scale(animatedScale))

// ✅ Use appropriate easing
animateFloatAsState(
    targetValue = target,
    animationSpec = tween(durationMillis = 300, easing = FastOutSlowInEasing)
)
```

---

## Layout Optimization

```kotlin
// ✅ Avoid nested weights — causes multiple measure passes
// ❌ Don't do this:
Column {
    Row(modifier = Modifier.weight(1f)) {
        Box(modifier = Modifier.weight(1f))
    }
}
// ✅ Use Box or explicit sizing instead

// ✅ Use BoxWithConstraints only at entry point (it triggers extra recomposition)
@Composable
fun NativeDisplayView(...) {
    BoxWithConstraints {  // ← only here
        RenderNode(config.root, resolvedStyles, ...)
    }
}

// ✅ LazyColumn/LazyRow for long content — Column/Row renders all children immediately
LazyColumn {
    items(children, key = { it.id }) { child -> RenderNode(child, ...) }
}
```

---

## Profiling and Debugging

### Layout Inspector (Android Studio)
1. Tools → Layout Inspector → attach to running app
2. Enable **Show Recomposition Counts** — red highlights = hot composables
3. Identify composables recomposing more than expected

### Compose Compiler Reports
```bash
cd android && ./gradlew assembleDebug -PcomposeCompilerReports=true
# Reports: sdk/build/compose_compiler/
# Look for: "unstable class", "restartable fun (not skippable)"
```

### Inline Recomposition Counter (debug only — remove before commit)
```kotlin
@Composable
fun TracedComponent() {
    val count = remember { mutableStateOf(0) }
    SideEffect {
        count.value++
        Log.d("Recomposition", "Count: ${count.value}")
    }
}
```

### Render Time Benchmark
```kotlin
@Test
fun benchmarkRendering() {
    val start = System.nanoTime()
    composeTestRule.setContent { NativeDisplayView(config = testConfig, resolvedStyles = testStyles) }
    composeTestRule.waitForIdle()
    val ms = (System.nanoTime() - start) / 1_000_000
    println("Render time: ${ms}ms")
    assertTrue(ms < 100)
}
```

---

## Performance Checklist (before shipping a feature)

**Recomposition / stability**
- [ ] No `StyleResolver` reference inside any composable function
- [ ] Resolved styles passed as `PersistentMap<String, Style>`
- [ ] All new model `data class` annotated with `@Immutable`
- [ ] All new sealed classes annotated with `@Stable`
- [ ] `LazyRow`/`LazyColumn` items use `key = { it.id }`
- [ ] Expensive objects in composables are in `remember(key) { ... }`
- [ ] Gradient brushes cached with `remember(colors) { Brush.linearGradient(...) }`

**Resources / memory**
- [ ] Video/audio players released in `DisposableEffect { onDispose { player.release() } }`
- [ ] Coroutines scoped to composition via `rememberCoroutineScope`
- [ ] No memory leaks verified (run LeakCanary in debug build)

**Animations**
- [ ] Transforms use `graphicsLayer { }`, not drawing modifiers (`.alpha()`, `.scale()`)
- [ ] Animated backgrounds use `rememberInfiniteTransition`, not manual delay loops

**Interop**
- [ ] New public functions with default parameters have `@JvmOverloads`

**Profiling**
- [ ] Run Compose Compiler Reports if adding new composables to the hot path
- [ ] No unexpected red highlights in Layout Inspector recomposition view

**Build**
- [ ] Verify: `cd android && ./gradlew :sdk:build`
