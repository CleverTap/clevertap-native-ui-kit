# iOS SDK — Performance Guide

This document reflects the **actual implemented architecture** as of the performance audit (Feb 2026). Always match these patterns — do not introduce old patterns.

---

## Architecture: Pre-Resolved Styles (the biggest win)

Styles are resolved **once in `NativeDisplayView.init()`**, before any view body runs. The view tree receives a flat `[String: Style]` dictionary and does an O(1) lookup per node.

```swift
// ✅ CURRENT PATTERN — resolve once in init
public struct NativeDisplayView: View {
    private let resolvedStyles: [String: Style]
    private let evaluator: VariableEvaluator

    public init(config: ResolvedConfig, ...) {
        let resolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)
        self.resolvedStyles = resolver.resolveAll(node: config.root)  // one pass, entire tree
        self.evaluator = VariableEvaluator(variables: config.variables)
    }
}

// ✅ CURRENT PATTERN — per-node lookup (O(1)) inside views
let resolvedStyle = resolvedStyles[node.id] ?? Style.empty

// ❌ OLD PATTERN — never do this (StyleResolver inside view body)
let style = styleResolver.resolveWithColors(node: node)  // runs on every body evaluation
```

**Why**: `StyleResolver` is never passed into the SwiftUI view tree. No `@State` or `.onAppear` ceremony needed per node.

---

## Avoiding Unnecessary Body Evaluations

SwiftUI recalculates `body` whenever any `@State`, `@Binding`, or environment value that the view *reads* changes. Keep `body` lightweight.

```swift
// ✅ Stable struct — body only recalculates when resolvedStyles or node instance changes
struct RenderNode: View {
    let node: NativeDisplayNode
    let resolvedStyles: [String: Style]    // plain [String: Style] — value type, fast equality
    let evaluator: VariableEvaluator
    ...
}

// ❌ Never compute style resolution inline in body
var body: some View {
    let style = styleResolver.resolveWithColors(node: node)  // runs every body evaluation
    ...
}

// ❌ Never put print() in body — runs on every evaluation
var body: some View {
    print("RenderContainer: \(container.id)")  // noise + perf cost
    ...
}
```

**Debugging tool**: Add `Self._printChanges()` as the first line in body to log exactly which property triggered a re-evaluation. Remove before committing.

---

## UIHostingController — Avoid AnyView Type Erasure

```swift
// ✅ CURRENT PATTERN — concrete root struct
struct _NativeDisplayRoot: View {
    let config: ResolvedConfig
    let parentSize: CGSize?
    let actionListener: NativeDisplayActionListener?
    let componentListener: NativeDisplayComponentListener?

    var body: some View {
        let view = NativeDisplayView(config: config, ...)
        if let size = parentSize {
            view.environment(\.nativeDisplayParentSize, size)
        } else {
            view
        }
    }
}

// UIHostingController uses the concrete type — SwiftUI can diff correctly
private var hostingController: UIHostingController<_NativeDisplayRoot>?

// ❌ OLD PATTERN — AnyView breaks SwiftUI's type-based diffing
private var hostingController: UIHostingController<AnyView>?
```

**Why**: `AnyView` makes every instance look identical to SwiftUI's diffing algorithm. The renderer can't tell if the underlying type changed, so it redraws unnecessarily.

**Rule**: Never introduce `AnyView` in the render tree or hosting layer. Use `@ViewBuilder`, conditional `if/else`, or concrete generic types instead.

---

## ForEach — Stable IDs

SwiftUI uses the ID to track element identity across updates. Index-based iteration (`\.self` on indices) breaks when items are inserted or reordered.

```swift
// ✅ CURRENT PATTERN — stable node IDs
ForEach(container.children, id: \.id) { child in
    RenderNode(node: child, resolvedStyles: resolvedStyles, ...)
}

// ✅ For SnappingGallery (TabView needs integer .tag) — use enumerated()
ForEach(Array(container.children.enumerated()), id: \.element.id) { index, child in
    RenderNode(node: child, ...)
        .tag(index)  // integer tag for TabView page binding
}

// ❌ Index-based — breaks on insert/delete, causes incorrect animations
ForEach(container.children.indices, id: \.self) { index in
    RenderNode(node: container.children[index], ...)
}
```

---

## @State with Reference Types

`@State` is designed for value types. Using it with reference types (classes) can produce surprising lifecycle behavior.

```swift
// ⚠️ Timer is a class — acceptable here since we only store/invalidate a reference
// but be aware SwiftUI may recreate the view, so always invalidate in .onDisappear
@State private var timer: Timer?

// ✅ Always clean up reference-typed @State
.onDisappear {
    timer?.invalidate()
    timer = nil
}
```

For complex observable state, prefer `@StateObject` (iOS 14+) or `@Observable` macro (iOS 17+) over `@State` on classes.

---

## GeometryReader — Use Strategically

`GeometryReader` triggers layout recalculations. We use it in gallery views to get container dimensions — this is necessary and acceptable.

```swift
// ✅ Acceptable — needed for dynamic item sizing, used at the top of the gallery view
GeometryReader { geometry in
    let containerSize = geometry.size
    // Use containerSize for item width/height calculations
    ScrollView(.horizontal) { ... }
}

// ❌ Don't nest GeometryReader inside already-measured content
GeometryReader { outer in
    GeometryReader { inner in  // causes multiple layout passes
        ...
    }
}
```

**Future path**: When minimum deployment target reaches iOS 16, consider replacing `GeometryReader` sizing with the `Layout` protocol for single-pass measurement.

---

## Objective-C Bridging (@objc)

Protocols exposed to Objective-C clients must be carefully designed:

```swift
// ✅ CURRENT PATTERN — minimal @objc surface
@objc public enum InteractionType: Int {
    case click = 0
    case longPress = 1
    case impression = 2
}

@objc public protocol NativeDisplayComponentListener: AnyObject {
    @objc func onComponentInteraction(nodeId: String, interactionType: InteractionType)
}

// Methods using Swift-only types go in a Swift extension (not @objc)
extension NativeDisplayComponentListener {
    func getInterestedNodeIds() -> Set<String>? { return nil }  // Set<String> not ObjC-bridgeable
}
```

**Rules**:
- `@objc` protocols can only expose ObjC-compatible types: primitives, `NSObject` subclasses, ObjC collections
- `Set<String>`, `Swift.Error` (as Swift enum), and generic types are NOT ObjC-bridgeable — put them in Swift-only extensions
- `@objc enum` must be `Int`-backed
- Keep `@objc` surface area minimal — it constrains future API evolution

---

## Common Pitfalls

| Pitfall | Impact | Fix |
|---|---|---|
| `StyleResolver` as a view parameter or created in `body` | Runs on every body evaluation | Pre-resolve in `init()` via `resolveAll()`, pass `[String: Style]` |
| `AnyView` in `UIHostingController` or view tree | Disables type-based diffing | Use concrete generic types and `@ViewBuilder` |
| `ForEach(indices, id: \.self)` | Breaks on insertions/deletions | `ForEach(children, id: \.id)` |
| `print()` in `body` | Executes on every body evaluation | Remove; use `Self._printChanges()` only for debug sessions |
| Nested `GeometryReader` | Multiple layout passes | Use at highest needed level only |
| `@objc` on methods using Swift-only types | Compile error | Put Swift-only methods in a non-`@objc` extension |
| `@State` on ObservableObject without `@StateObject` | Object recreated on view redraw, orphaned subscriptions | Use `@StateObject` for owned reference types |

---

## Performance Checklist (before shipping a feature)

- [ ] No `StyleResolver` inside any `View` struct or `body`
- [ ] All gallery `ForEach` use `id: \.id` (not `id: \.self` on indices)
- [ ] No `AnyView` introduced in the render tree or `UiKit/` layer
- [ ] No `print()` in any `body` property
- [ ] `@objc` surface area is minimal — only ObjC-compatible types
- [ ] `@State` used only with value types or invalidated reference cleanup in `.onDisappear`
- [ ] `GeometryReader` not nested
- [ ] Verify build: `cd ios && swift build --sdk $(xcrun --sdk iphonesimulator --show-sdk-path) -Xswiftc "-target" -Xswiftc "arm64-apple-ios15.0-simulator"`
