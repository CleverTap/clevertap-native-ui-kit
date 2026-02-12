# Implement [CONTAINER_TYPE] Container

## Task
Implement a `[CONTAINER_TYPE]` container renderer for the Native Display Android SDK.

## Requirements
1. Create `@Composable` function `Render[ContainerType]Container`
2. Support all layout properties (width, height, padding, offset)
3. Apply background and border correctly
4. Convert `ChildArrangement` to Compose arrangement
5. Render all children recursively
6. Support RTL layout direction

## Implementation Checklist
- [ ] Create composable function with correct parameters
- [ ] Apply modifier chain in correct order (size → background → padding → border)
- [ ] Map arrangement strategy to Compose Arrangement
- [ ] Iterate and render children
- [ ] Handle edge cases (null children, empty list)
- [ ] Add inline documentation
- [ ] Write unit test
- [ ] Create example usage

## Modifier Order
```kotlin
Modifier
    .applyDimension(width, height)       // 1. Size
    .applyBackground(background)          // 2. Background
    .applyPadding(padding)                // 3. Padding
    .applyBorder(border)                  // 4. Border
```

## Arrangement Mapping
| Strategy | Column | Row |
|----------|--------|-----|
| SPACED | spacedBy(n.dp) | spacedBy(n.dp) |
| SPACE_BETWEEN | SpaceBetween | SpaceBetween |
| SPACE_EVENLY | SpaceEvenly | SpaceEvenly |
| SPACE_AROUND | SpaceAround | SpaceAround |
| START | Top | Start (RTL aware) |
| CENTER | Center | Center |
| END | Bottom | End (RTL aware) |

## Template
```kotlin
@Composable
fun Render[ContainerType]Container(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style,
    onRenderChild: @Composable (NativeDisplayNode) -> Unit
) {
    val modifier = Modifier
        .applyDimension(...)
        .applyBackground(...)
        .applyPadding(...)
        .applyBorder(...)

    val arrangement = node.arrangement?.toArrangement() ?: ...

    [ComposeContainer](
        modifier = modifier,
        arrangement = arrangement
    ) {
        node.children?.forEach { child ->
            onRenderChild(child)
        }
    }
}
```

## Testing
```kotlin
@Test
fun test[ContainerType]Container() {
    composeTestRule.setContent {
        Render[ContainerType]Container(testNode, testSize, testStyle) { }
    }
    composeTestRule.onRoot().assertExists()
}
```

## Example Usage
Document a complete example showing the container with 2-3 children demonstrating the arrangement strategy.
