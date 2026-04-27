# Jetpack Compose Patterns & Best Practices

## Modifier Chains

### Order Matters
Modifiers are applied in order from top to bottom:

```kotlin
// ✅ Correct: padding inside, border outside
Box(
    modifier = Modifier
        .size(100.dp)           // 1. Set size
        .background(Color.White) // 2. Background inside
        .padding(16.dp)          // 3. Padding inside
        .border(2.dp, Color.Black) // 4. Border outside
)

// ❌ Wrong: border will be inside padding
Box(
    modifier = Modifier
        .size(100.dp)
        .border(2.dp, Color.Black) // Border first
        .padding(16.dp)            // Padding outside border
        .background(Color.White)
)
```

### Common Modifier Patterns

**Layout Modifiers (apply first)**:
```kotlin
Modifier
    .size(width = 100.dp, height = 50.dp)
    .fillMaxWidth()
    .fillMaxHeight()
    .fillMaxSize()
    .width(100.dp)
    .height(50.dp)
    .widthIn(min = 50.dp, max = 200.dp)
    .heightIn(min = 50.dp, max = 200.dp)
```

**Spacing Modifiers (middle)**:
```kotlin
Modifier
    .padding(16.dp)
    .padding(horizontal = 16.dp, vertical = 8.dp)
    .padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 8.dp)
```

**Visual Modifiers (apply last)**:
```kotlin
Modifier
    .background(Color.White)
    .border(2.dp, Color.Black, shape = RoundedCornerShape(8.dp))
    .shadow(4.dp, shape = RoundedCornerShape(8.dp))
    .clip(RoundedCornerShape(8.dp))
```

**Standard Order**:
```kotlin
Modifier
    // 1. Size/Layout
    .fillMaxWidth()
    .height(200.dp)
    // 2. Background
    .background(Color.White)
    // 3. Padding
    .padding(16.dp)
    // 4. Border/Shadow
    .border(1.dp, Color.Gray, RoundedCornerShape(8.dp))
    .shadow(2.dp, RoundedCornerShape(8.dp))
    // 5. Clip
    .clip(RoundedCornerShape(8.dp))
    // 6. Interactions
    .clickable { /* ... */ }
```

## Container Rendering

### Vertical (Column)

```kotlin
@Composable
fun RenderVerticalContainer(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style
) {
    Column(
        modifier = Modifier
            .applyDimension(node.layout.width, parentSize.width, isWidth = true)
            .applyDimension(node.layout.height, parentSize.height, isWidth = false)
            .applyBackground(style.background)
            .applyPadding(node.layout.padding),
        verticalArrangement = node.arrangement.toVerticalArrangement(),
        horizontalAlignment = Alignment.Start
    ) {
        node.children?.forEach { child ->
            RenderNode(child, parentSize, resolvedStyle)
        }
    }
}
```

### Horizontal (Row)

```kotlin
@Composable
fun RenderHorizontalContainer(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style
) {
    Row(
        modifier = Modifier
            .applyDimension(node.layout.width, parentSize.width, isWidth = true)
            .applyDimension(node.layout.height, parentSize.height, isWidth = false)
            .applyBackground(style.background)
            .applyPadding(node.layout.padding),
        horizontalArrangement = node.arrangement.toHorizontalArrangement(),
        verticalAlignment = Alignment.Top
    ) {
        node.children?.forEach { child ->
            RenderNode(child, parentSize, resolvedStyle)
        }
    }
}
```

### Box (Overlay)

```kotlin
@Composable
fun RenderBoxContainer(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style
) {
    Box(
        modifier = Modifier
            .applyDimension(node.layout.width, parentSize.width, isWidth = true)
            .applyDimension(node.layout.height, parentSize.height, isWidth = false)
            .applyBackground(style.background)
            .applyPadding(node.layout.padding)
    ) {
        node.children?.forEach { child ->
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .applyOffset(child.layout.offset)
            ) {
                RenderNode(child, parentSize, resolvedStyle)
            }
        }
    }
}
```

### Gallery (LazyRow)

```kotlin
@Composable
fun RenderGallery(
    node: NativeDisplayNode,
    galleryConfig: GalleryConfig,
    style: Style
) {
    val pagerState = rememberPagerState()

    HorizontalPager(
        state = pagerState,
        modifier = Modifier
            .fillMaxWidth()
            .applyBackground(style.background),
        contentPadding = PaddingValues(horizontal = 16.dp),
        pageSpacing = galleryConfig.spacing.dp
    ) { page ->
        val child = node.children?.getOrNull(page)
        if (child != null) {
            RenderNode(child, parentSize, resolvedStyle)
        }
    }
}
```

## Arrangement Strategies

### Converting to Compose Arrangements

```kotlin
fun ChildArrangement.toVerticalArrangement(): Arrangement.Vertical {
    return when (strategy) {
        ArrangementStrategy.SPACED -> Arrangement.spacedBy(spacing.dp)
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Top
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.Bottom
    }
}

fun ChildArrangement.toHorizontalArrangement(): Arrangement.Horizontal {
    return when (strategy) {
        ArrangementStrategy.SPACED -> Arrangement.spacedBy(spacing.dp)
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Start
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.End
    }
}
```

## Element Rendering

### Text Element

```kotlin
@Composable
fun RenderTextElement(
    node: NativeDisplayNode,
    style: Style,
    text: String
) {
    Text(
        text = text,
        modifier = Modifier
            .applyDimension(node.layout.width, parentSize.width, isWidth = true)
            .applyBackground(style.background)
            .applyPadding(node.layout.padding),
        color = style.textColor?.parseColor() ?: Color.Black,
        fontSize = style.fontSize?.sp ?: 14.sp,
        fontWeight = style.fontWeight?.toFontWeight() ?: FontWeight.Normal,
        textAlign = style.textAlign?.toTextAlign() ?: TextAlign.Start,
        textDecoration = style.textDecoration?.toTextDecoration(),
        lineHeight = style.lineHeight?.sp ?: TextUnit.Unspecified
    )
}
```

### Image Element

```kotlin
@Composable
fun RenderImageElement(
    node: NativeDisplayNode,
    style: Style,
    imageUrl: String
) {
    AsyncImage(
        model = ImageRequest.Builder(LocalContext.current)
            .data(imageUrl)
            .crossfade(true)
            .build(),
        contentDescription = node.id,
        modifier = Modifier
            .applyDimension(node.layout.width, parentSize.width, isWidth = true)
            .applyDimension(node.layout.height, parentSize.height, isWidth = false)
            .applyBackground(style.background)
            .clip(RoundedCornerShape(style.borderRadius?.dp ?: 0.dp)),
        contentScale = ContentScale.Crop
    )
}
```

### Button Element

```kotlin
@Composable
fun RenderButtonElement(
    node: NativeDisplayNode,
    style: Style,
    text: String,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .applyDimension(node.layout.width, parentSize.width, isWidth = true)
            .applyDimension(node.layout.height, parentSize.height, isWidth = false),
        colors = ButtonDefaults.buttonColors(
            containerColor = style.backgroundColor?.parseColor() ?: Color.Blue
        ),
        shape = RoundedCornerShape(style.borderRadius?.dp ?: 8.dp)
    ) {
        Text(
            text = text,
            color = style.textColor?.parseColor() ?: Color.White,
            fontSize = style.fontSize?.sp ?: 16.sp,
            fontWeight = style.fontWeight?.toFontWeight() ?: FontWeight.Medium
        )
    }
}
```

## State Management

### Remember vs RememberSaveable

```kotlin
// ✅ Use remember for UI state (doesn't survive process death)
val pagerState = remember { mutableStateOf(0) }

// ✅ Use rememberSaveable for important state (survives process death)
val selectedTab = rememberSaveable { mutableStateOf(0) }
```

### State Hoisting

```kotlin
// ✅ Hoist state to parent
@Composable
fun ParentComponent() {
    var selectedIndex by remember { mutableStateOf(0) }

    ChildComponent(
        selectedIndex = selectedIndex,
        onIndexChange = { selectedIndex = it }
    )
}

@Composable
fun ChildComponent(
    selectedIndex: Int,
    onIndexChange: (Int) -> Unit
) {
    // Stateless component
}
```

## Performance Optimization

### Minimize Recomposition

```kotlin
// ✅ Use stable data classes
@Immutable
data class Style(
    val textColor: String? = null,
    val fontSize: Float? = null
)

// ✅ Use derivedStateOf for computed values
val itemCount by remember {
    derivedStateOf { items.size }
}

// ✅ Use key() for list items
LazyColumn {
    items(
        items = children,
        key = { it.id }
    ) { child ->
        RenderNode(child)
    }
}
```

### Avoid Creating Composables in Loops

```kotlin
// ❌ Wrong: Creates new composable each iteration
fun renderChildren() {
    children.forEach { child ->
        @Composable
        fun ChildItem() { /* ... */ }
        ChildItem()
    }
}

// ✅ Correct: Single composable, called multiple times
@Composable
fun ChildItem(child: Node) { /* ... */ }

fun renderChildren() {
    children.forEach { child ->
        ChildItem(child)
    }
}
```

## Testing Patterns

### Screenshot Testing

```kotlin
@Test
fun testVerticalContainer() {
    composeTestRule.setContent {
        RenderVerticalContainer(
            node = testNode,
            parentSize = IntSize(400, 800),
            style = testStyle
        )
    }

    composeTestRule.onRoot().captureToImage()
}
```

### Semantic Testing

```kotlin
@Test
fun testButtonClick() {
    var clicked = false

    composeTestRule.setContent {
        RenderButtonElement(
            node = buttonNode,
            style = buttonStyle,
            text = "Click Me",
            onClick = { clicked = true }
        )
    }

    composeTestRule.onNodeWithText("Click Me").performClick()
    assertTrue(clicked)
}
```

## Common Patterns

### Extension Functions

```kotlin
fun Modifier.applyDimension(
    dimension: Dimension?,
    parentSize: Int,
    isWidth: Boolean
): Modifier {
    if (dimension == null) return this

    return when (dimension.special) {
        SpecialDimension.MATCH_PARENT -> if (isWidth) fillMaxWidth() else fillMaxHeight()
        SpecialDimension.WRAP_CONTENT -> wrapContentSize()
        null -> when (dimension.unit) {
            DimensionUnit.DP -> if (isWidth) width(dimension.value.dp) else height(dimension.value.dp)
            DimensionUnit.PERCENT -> {
                val size = (parentSize * dimension.value / 100).dp
                if (isWidth) width(size) else height(size)
            }
            // ... other units
        }
    }
}
```

### Color Parsing

```kotlin
fun String.parseColor(): Color {
    val cleanHex = this.removePrefix("#")
    val argb = when (cleanHex.length) {
        6 -> "FF$cleanHex"  // RGB → ARGB
        8 -> cleanHex       // Already ARGB
        else -> "FF000000"  // Fallback
    }
    return Color(argb.toLong(16))
}
```

## RTL Support

```kotlin
// ✅ Use start/end instead of left/right
Modifier.padding(start = 16.dp, end = 16.dp)

// ✅ System handles RTL automatically for Row/Column
Row(
    horizontalArrangement = Arrangement.Start  // Becomes End in RTL
) { /* ... */ }
```
