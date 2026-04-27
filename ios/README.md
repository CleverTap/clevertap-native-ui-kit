# CleverTap Native Display iOS SDK

Server-driven UI framework for rendering native mobile interfaces from JSON configurations.

## Project Structure

```
ios/
├── CleverTapNativeDisplay.xcodeproj    # Xcode project for development
├── CleverTapNativeDisplay.podspec      # CocoaPods specification
├── Package.swift                        # Swift Package Manager manifest
├── build_xcframework.sh                 # Script to build XCFramework
├── Sources/
│   └── CleverTapNativeDisplay/          # SDK source code
│       ├── CleverTapNativeDisplay.swift # Main public API
│       ├── Models/                      # Data models
│       ├── Renderer/                    # SwiftUI renderers
│       ├── Evaluator/                   # Template evaluation
│       └── Style/                       # Style resolution
└── Tests/
    └── CleverTapNativeDisplayTests/     # Unit tests
```

## Development

### Opening in Xcode

```bash
open CleverTapNativeDisplay.xcodeproj
```

The project includes:
- **CleverTapNativeDisplay** framework target
- **CleverTapNativeDisplayTests** unit test target

### Building

1. Open `CleverTapNativeDisplay.xcodeproj` in Xcode
2. Select the `CleverTapNativeDisplay` scheme
3. Build with ⌘+B

### Running Tests

1. Select the `CleverTapNativeDisplayTests` scheme
2. Run tests with ⌘+U

### Building XCFramework for Distribution

```bash
chmod +x build_xcframework.sh
./build_xcframework.sh
```

This creates `output/CleverTapNativeDisplay.xcframework` ready for distribution.

## Client Integration

### Option 1: Swift Package Manager (Recommended)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CleverTap/clevertap-native-display-ios.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

### Option 2: CocoaPods

Add to your `Podfile`:

```ruby
pod 'CleverTapNativeDisplay', '~> 1.0'
```

Then run:
```bash
pod install
```

### Option 3: XCFramework (Manual)

1. Run `./build_xcframework.sh` to generate the XCFramework
2. Drag `CleverTapNativeDisplay.xcframework` into your Xcode project
3. Add to "Frameworks, Libraries, and Embedded Content"
4. Set "Embed & Sign"

### Option 4: Direct Source Integration

Copy the `Sources/CleverTapNativeDisplay` folder into your project.

## Usage

### Basic Usage

```swift
import CleverTapNativeDisplay

// Parse JSON configuration
let config = try ResolvedConfig.from(jsonString: jsonString)

// Create and display view
struct ContentView: View {
    var body: some View {
        NativeDisplayView(config: config)
    }
}
```

### Using the Convenience API

```swift
// Create view directly from JSON
let view = try CleverTapNativeDisplay.createView(from: jsonString)
```

## Features

### Container Types
| Type | Description                              |
|------|------------------------------------------|
| `vertical` | Stack children vertically (VStack)       |
| `horizontal` | Stack children horizontally (HStack)     |
| `box` | Single child, top-start leading (ZStack) |
| `gallery` | Scrollable carousel/list                 |

### Element Types
| Type | Description |
|------|-------------|
| `text` | Display text with styling |
| `image` | Load and display images |
| `button` | Interactive button |
| `video` | Video player |
| `spacer` | Flexible space |
| `divider` | Horizontal/vertical line |

### Gallery Modes
| Mode | Use Case |
|------|----------|
| `snapping` | Image carousels with snap behavior |
| `free_flow` | Tag lists with natural sizing |
| `free_flow_grid` | Product grids with fixed items |

### Background Types
- Solid color
- Linear/Radial/Sweep gradients
- Shimmer animation
- Pulse animation
- Pattern (dots, stripes, grid)
- Particles

### Variable Templates
```json
{
    "bindings": {
        "text": "Hello {{userName}}!"
    },
    "visible": "{{isLoggedIn}}"
}
```

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## License

MIT License - see LICENSE file for details.
