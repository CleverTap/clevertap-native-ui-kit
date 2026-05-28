# SwiftUI Patterns & Best Practices

## View Modifier Order

SwiftUI applies modifiers from inside out:
```swift
Text("Hello")
    .padding()       // 1. Inner padding
    .background(.red) // 2. Background
    .border(.black)  // 3. Outer border
```

## Container Views

### VStack (Vertical)
```swift
VStack(alignment: .leading, spacing: 12) {
    ForEach(children, id: \.id) { child ->
        RenderNode(child)
    }
}
```

### HStack (Horizontal)
```swift
HStack(alignment: .top, spacing: 8) {
    ForEach(children, id: \.id) { child ->
        RenderNode(child)
    }
}
```

### ZStack (Overlay)
```swift
ZStack(alignment: .topLeading) {
    ForEach(children, id: \.id) { child ->
        RenderNode(child)
            .offset(x: child.layout.offset?.x ?? 0,
                    y: child.layout.offset?.y ?? 0)
    }
}
```

## Spacing Strategies

```swift
func spacing(for strategy: ArrangementStrategy, value: CGFloat) -> CGFloat? {
    switch strategy {
    case .spaced: return value
    case .start, .center, .end: return 0
    default: return nil  // Use SwiftUI defaults
    }
}
```

## State & Binding

```swift
@State private var isVisible = false
@Binding var selectedTab: Int
@StateObject var viewModel: ViewModel
@ObservedObject var dataSource: DataSource
```

## Performance

- Use `LazyVStack`/`LazyHStack` for long lists
- Cache with `@State` and `@StateObject`
- Avoid expensive computations in body
- Use `.id()` modifier for list items
