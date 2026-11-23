# iOS SDK Architecture

## CRITICAL: SDK Usage Model

**The Native Display SDK is JSON-driven.** Clients do NOT write custom SwiftUI views or implement renderers.

**Client Usage (3 steps):**
1. Load JSON configuration
2. Parse: `let config = try ResolvedConfig.from(jsonData: data)` (or `JSONDecoder().decode(ResolvedConfig.self, from: data)`)
3. Render: `NativeDisplayView(config: config)`

**That's it.** ✅ No custom implementations needed.

See: `.claude/reference/CLIENT_USAGE_MODEL.md` for complete details.

---

## Overview
The Native Display iOS SDK is built with Swift and SwiftUI, following clean architecture principles with separation between models, business logic, and UI rendering.

**This document describes SDK INTERNAL implementation** - not client usage.

## Core Layers

### 1. Data Models (`ios/Sources/CleverTapNativeDisplay/Models/`)
All models conform to `Codable` for JSON parsing. The decode-ready config is `ResolvedConfig` (what `NativeDisplayView(config:)` takes); `NativeDisplayConfig` is the Phase 1/Phase 2 wrapper with optional external references:
```swift
public struct ResolvedConfig: Codable, Equatable {
    public let theme: Theme
    public let styleClasses: [StyleClass]
    public let variables: [String: AnyCodable]
    public let root: NativeDisplayNode
}
```

### 2. Business Logic
- **Style Resolution**: Cascading styles with inheritance
- **Template Evaluation**: Variable interpolation
- **Layout Calculation**: Dimension resolution, RTL support

#### aspectRatio Sizing Priority (critical — matches Android/Flutter)

When `aspectRatio` is set, width/height percent values are **ignored**. The node uses full available parent width; height = `parentWidth / aspectRatio`. Implementation in `NativeDisplayRenderer.swift`:

```swift
case .percent:
    // Aspect ratio present → percent is ignored, width fills parent.
    guard (layout?.aspectRatio ?? 0) <= 0 else { return parentWidth }
    return parentWidth * dim.value / 100
```

And for the root:
```swift
} else if let ar = config.root.layout?.aspectRatio, ar > 0 {
    // .frame(maxWidth: .infinity) fills parent width
    // .aspectRatio(.fit) derives height = width / ar
    .aspectRatio(ar, contentMode: .fit)
    .frame(maxWidth: .infinity)
}
```

`aspectRatio` is skipped only when **both** width AND height are fixed (non-percent, non-nil special). See `.claude/reference/CLAUDE_CODE_REFERENCE_ACTUAL.md` for the full priority table.

### 3. UI Rendering (`ios/Sources/CleverTapNativeDisplay/Renderer/`)
- `NativeDisplayView` - Main entry point (in `NativeDisplayRenderer.swift`)
- `RenderNode` - Dispatches each node to container/element rendering
- `RenderContainer` / `RenderElement` - Render containers and elements
- `GalleryRenderer.swift` (`SnappingGalleryView`, etc.) - Gallery rendering
- `BackgroundRenderer.swift`, `AnimationModifier.swift` - Backgrounds, animations

## SwiftUI Components

### Container Mapping
- VERTICAL → VStack
- HORIZONTAL → HStack
- BOX → ZStack with alignment
- GALLERY → TabView or ScrollView

### Element Mapping
- TEXT → Text
- IMAGE → AsyncImage
- BUTTON → Button
- VIDEO → VideoPlayer
- HTML → HtmlWebView (UIViewRepresentable + WKWebView, iOS only)
- SPACER → Spacer
- DIVIDER → Divider

## Key Patterns

### View Modifiers
```swift
.frame(width: width, height: height)
.background(background)
.padding(padding)
.border(borderWidth, color: borderColor)
```

### Environment Values
SwiftUI environment for passing context (defined in `NativeDisplayRenderer.swift`):
```swift
@Environment(\.nativeDisplayParentSize) var parentSize   // explicit parent size, overrides GeometryReader
// Also available: \.nativeDisplayFontFamily, \.nativeDisplayFontResolver
```
Note: styles are **not** passed via the environment — they are pre-resolved once in `init()` and threaded through the view tree as a `[String: Style]` map.

### State Management
```swift
@State private var selectedIndex = 0
@StateObject private var viewModel = ViewModel()
```

## References
- SwiftUI Documentation: https://developer.apple.com/xcode/swiftui/
- Swift Codable: https://developer.apple.com/documentation/swift/codable
