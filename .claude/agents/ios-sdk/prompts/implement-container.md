# Implement [CONTAINER_TYPE] Container (SwiftUI)

## Task
Add rendering support for the `[CONTAINER_TYPE]` container to `RenderContainer` in the Native Display iOS SDK (`Renderer/NativeDisplayRenderer.swift`). Containers are NOT separate per-type view structs — every container type is handled inside the single `RenderContainer` view, which is dispatched from `RenderNode`.

## Requirements
- Extend `RenderContainer`'s `switch container.containerType` to handle `[CONTAINER_TYPE]`
- Map to the appropriate SwiftUI container (VStack, HStack, ZStack, etc.)
- Support all layout properties (handled via `LayoutModifier`: width, height, padding, offset)
- Handle arrangement strategies (`spaced`, `space_between`, `space_evenly`, `space_around`, `start`, `center`, `end`)
- Render children recursively by constructing `RenderNode` inside a `@ViewBuilder` — never wrap children in `AnyView`

## Pattern
```swift
// RenderNode dispatches each node to RenderContainer or RenderElement
struct RenderNode: View {
    let node: NativeDisplayNode   // enum: .container(NativeDisplayContainer) / .element(NativeDisplayElement)
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    // parentSize, rootHeight, actionHandler, componentListener, ...

    @ViewBuilder
    private func renderContent() -> some View {
        switch node {
        case .container(let container):
            RenderContainer(container: container, resolvedStyles: resolvedStyles, /* ... */)
                .modifier(LayoutModifier(layout: node.layout, parentSize: parentSize, nodeId: node.id))
                .modifier(DecorationModifier(style: resolvedStyle, rootHeight: rootHeight))
        case .element(let element):
            RenderElement(element: element, resolvedStyles: resolvedStyles, /* ... */)
        }
    }
}

struct RenderContainer: View {
    let container: NativeDisplayContainer
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    // resolvedStyle, parentSize, rootHeight, actionHandler, componentListener, ...

    var body: some View {
        switch container.containerType {
        case .vertical:
            // VStack — children render through RenderNode in a @ViewBuilder (no AnyView)
            VStack(alignment: alignment, spacing: spacing) {
                ForEach(container.children, id: \.id) { child in
                    RenderNode(node: child, resolvedStyles: resolvedStyles, /* ... */)
                }
            }
            .padding(paddingInsets)
        // case .horizontal / .box / .gallery → HStack / ZStack / GalleryRenderer
        }
    }
}
```

## Container Mapping
- VERTICAL → VStack
- HORIZONTAL → HStack
- BOX → ZStack (absolute positioning; offsets applied per-child)
- GALLERY → TabView or ScrollView (see `GalleryRenderer.swift`)

## Testing
```swift
struct RenderContainer_Previews: PreviewProvider {
    static var previews: some View {
        RenderContainer(container: /* sample [CONTAINER_TYPE] node */, resolvedStyles: [:], /* ... */)
    }
}
```
