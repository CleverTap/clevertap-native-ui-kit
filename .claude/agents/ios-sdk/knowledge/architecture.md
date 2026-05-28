# iOS SDK Architecture

## CRITICAL: SDK Usage Model

**The Native Display SDK is JSON-driven.** Clients do NOT write custom SwiftUI views or implement renderers.

**Client Usage (3 steps):**
1. Load JSON configuration
2. Parse: `JSONDecoder().decode(NativeDisplayConfig.self, from: data)`
3. Render: `NativeDisplayView(config: config)`

**That's it.** ✅ No custom implementations needed.

See: `.claude/reference/CLIENT_USAGE_MODEL.md` for complete details.

---

## Overview
The Native Display iOS SDK is built with Swift and SwiftUI, following clean architecture principles with separation between models, business logic, and UI rendering.

**This document describes SDK INTERNAL implementation** - not client usage.

## Core Layers

### 1. Data Models (`ios/Sources/Models/`)
All models conform to `Codable` for JSON parsing:
```swift
struct NativeDisplayConfig: Codable {
    let theme: Theme?
    let styleClasses: [StyleClass]?
    let variables: [String: AnyCodable]?
    let root: NativeDisplayNode
}
```

### 2. Business Logic
- **Style Resolution**: Cascading styles with inheritance
- **Template Evaluation**: Variable interpolation
- **Layout Calculation**: Dimension resolution, RTL support

### 3. UI Rendering (`ios/Sources/Views/`)
- `NativeDisplayView` - Main entry point
- `ContainerView` - Renders containers
- `ElementView` - Renders elements
- View modifiers for backgrounds, animations

## SwiftUI Components

### Container Mapping
- VERTICAL → VStack
- HORIZONTAL → HStack
- BOX → ZStack with alignment
- STACK → ZStack with explicit positioning
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
SwiftUI environment for passing context:
```swift
@Environment(\.parentSize) var parentSize
@Environment(\.styleResolver) var styleResolver
```

### State Management
```swift
@State private var selectedIndex = 0
@StateObject private var viewModel = ViewModel()
```

## References
- SwiftUI Documentation: https://developer.apple.com/xcode/swiftui/
- Swift Codable: https://developer.apple.com/documentation/swift/codable
