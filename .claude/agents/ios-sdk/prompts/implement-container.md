# Implement [CONTAINER_TYPE] Container (SwiftUI)

## Task
Implement a `[ContainerType]ContainerView` for the Native Display iOS SDK using SwiftUI.

## Requirements
- Create SwiftUI View struct
- Map to appropriate SwiftUI container (VStack, HStack, ZStack, etc.)
- Support all layout properties
- Handle arrangement strategies
- Render children recursively

## Template
```swift
struct [ContainerType]ContainerView: View {
    let node: NativeDisplayNode
    let parentSize: CGSize
    let style: Style
    let onRenderChild: (NativeDisplayNode) -> AnyView

    var body: some View {
        [SwiftUIContainer](
            alignment: alignment,
            spacing: spacing
        ) {
            ForEach(node.children ?? [], id: \.id) { child in
                onRenderChild(child)
            }
        }
        .frame(width: width, height: height)
        .applyBackground(style.background)
        .padding(padding)
        .applyBorder(...)
    }
}
```

## Container Mapping
- VERTICAL → VStack
- HORIZONTAL → HStack
- BOX/STACK → ZStack
- GALLERY → TabView or ScrollView

## Testing
```swift
struct PreviewContainer: PreviewProvider {
    static var previews: some View {
        [ContainerType]ContainerView(...)
    }
}
```
