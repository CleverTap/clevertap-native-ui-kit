# iOS Sample App Architecture

## Purpose
Demonstrate Native Display SDK capabilities using SwiftUI.

## Structure
```
ios-sample/NativeDisplaySample/
├── Resources/        # JSON configurations
│   ├── ProductCard.json
│   ├── LoginForm.json
│   └── Gallery.json
├── ContentView.swift # Main navigation
└── Demos/           # Demo views
    ├── ProductCardDemo.swift
    ├── GalleryDemo.swift
    └── ArrangementDemo.swift
```

## Demo Patterns

### 1. Simple Demo
```swift
struct ProductCardDemo: View {
    let config: NativeDisplayConfig

    init() {
        let json = Bundle.main.url(forResource: "ProductCard", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        self.config = try! JSONDecoder().decode(NativeDisplayConfig.self, from: data)
    }

    var body: some View {
        NativeDisplayView(config: config)
    }
}
```

### 2. Interactive Demo
```swift
struct InteractiveDemo: View {
    @State private var count = 0

    var body: some View {
        VStack {
            NativeDisplayView(config: configWithVariables)

            Button("Increment") {
                count += 1
            }
        }
    }

    private var configWithVariables: NativeDisplayConfig {
        NativeDisplayConfig(
            variables: ["count": AnyCodable(count)],
            root: ...
        )
    }
}
```

## Best Practices
- Use SwiftUI previews for rapid iteration
- Load JSON from bundle resources
- Handle JSON parsing errors gracefully
- Support both light and dark mode
- Test on multiple device sizes
