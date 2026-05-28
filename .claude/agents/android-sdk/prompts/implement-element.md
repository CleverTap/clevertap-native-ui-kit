# Implement [ELEMENT_TYPE] Element

## Task
Implement a `[ELEMENT_TYPE]` element renderer for the Native Display Android SDK.

## Requirements
1. Create `@Composable` function `Render[ElementType]Element`
2. Extract binding value from node (text, src, etc.)
3. Evaluate template expressions if needed
4. Apply style properties (text properties for TEXT, dimensions for all)
5. Handle loading states for async content (IMAGE, VIDEO)
6. Support all style properties correctly

## Implementation Checklist
- [ ] Create composable function
- [ ] Extract and evaluate binding
- [ ] Apply correct Compose component
- [ ] Apply style properties
- [ ] Handle loading/error states (if applicable)
- [ ] Support accessibility (contentDescription, semantics)
- [ ] Add inline documentation
- [ ] Write unit test
- [ ] Create example usage

## Text Properties (TEXT, BUTTON)
- textColor
- fontSize
- fontWeight
- fontFamily
- lineHeight
- textDecoration
- textAlign
- opacity

## Template
```kotlin
@Composable
fun Render[ElementType]Element(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style,
    templateEvaluator: TemplateEvaluator
) {
    val value = node.bindings?.get("[bindingKey]")?.let {
        templateEvaluator.evaluate(it)
    } ?: ""

    val modifier = Modifier
        .applyDimension(...)
        .applyBackground(...)
        .applyPadding(...)

    [ComposeComponent](
        value = value,
        modifier = modifier,
        // ... style properties
    )
}
```

## Special Cases

### IMAGE
- Use AsyncImage with Coil
- Handle placeholder and error states
- Support contentScale

### VIDEO
- Use AndroidView with ExoPlayer
- Handle player lifecycle (DisposableEffect)
- Support controls

### BUTTON
- Handle onClick callback
- Support button colors and shape

## Testing
```kotlin
@Test
fun test[ElementType]Element() {
    composeTestRule.setContent {
        Render[ElementType]Element(testNode, testSize, testStyle, testEvaluator)
    }
    composeTestRule.onNodeWithText("expected").assertExists()
}
```

## Example Usage
Document a complete example showing the element with all relevant style properties applied.
