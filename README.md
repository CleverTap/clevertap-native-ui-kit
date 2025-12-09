# CleverTap Native Display Kit

**Server-driven native UI framework for mobile in-app messaging**

Replace HTML/WebView-based in-app messages with true native UI components powered by JSON schemas.

---

## 🎯 Project Vision

### Current Problem
- In-app messages use HTML + WebView
- Poor performance (WebView overhead)
- Limited native features
- Inconsistent UX
- Hard to maintain

### Solution: Native Display Kit
- **Server-driven**: JSON schema → Native UI
- **True native**: Jetpack Compose (Android) + SwiftUI (iOS)
- **Type-safe**: Compile-time validation
- **Flexible**: Easy to extend
- **Performant**: Native rendering

---

## 📋 Architecture Overview

### High-Level Flow

```
Backend (Server)
    ↓ (sends JSON)
Mobile SDK
    ↓ (parses JSON)
Native Display Kit
    ↓ (renders)
Native UI (Compose/SwiftUI)
```

### Components

1. **Schema**: JSON structure defining UI
2. **Parser**: JSON → Data models
3. **Renderer**: Data models → Native UI
4. **Style System**: Theme + Style classes
5. **Layout Engine**: Positioning & sizing

---

## 🏗️ Project Structure

```
clevertap-native-ui-kit/
├── android/                    # Android implementation
│   ├── library/               # Main library
│   │   └── src/main/kotlin/
│   │       └── com/clevertap/android/nativedisplay/
│   │           ├── models/    # Data models
│   │           ├── parser/    # JSON parsing
│   │           ├── styling/   # Style resolution
│   │           ├── layout/    # Layout calculations
│   │           └── ui/        # Compose rendering
│   └── sample/                # Demo app
│
├── ios/                       # iOS implementation
│   ├── CleverTapNativeDisplay/     # Main library
│   │   ├── Models/           # Data models
│   │   ├── Parser/           # JSON parsing
│   │   ├── Styling/          # Style resolution
│   │   ├── Layout/           # Layout calculations
│   │   └── UI/               # SwiftUI rendering
│   └── Sample/               # Demo app
│
├── schema/                    # JSON schema definitions
│   ├── examples/             # Example JSON files
│   └── schema.json           # JSON Schema spec
│
├── docs/                      # Documentation
│   ├── architecture.md
│   ├── json-schema.md
│   └── style-guide.md
│
└── scripts/                   # Build & utility scripts
```

---

## 🎨 JSON Schema Design

### Core Concepts

1. **Elements**: UI components (text, image, button, etc.)
2. **Containers**: Layout managers (vertical, horizontal, box)
3. **Styles**: Visual properties (colors, fonts, etc.)
4. **Theme**: Default styles + variables

### Naming Convention: NativeDisplay*

All components use the `NativeDisplay` prefix:
- `NativeDisplayConfig` - Root configuration
- `NativeDisplayElement` - UI element
- `NativeDisplayContainer` - Layout container
- `NativeDisplayStyle` - Style properties
- `NativeDisplayTheme` - Theme definition

### Example JSON

```json
{
  "version": "1.0",
  "theme": {
    "id": "default",
    "colors": {
      "primary": "#007AFF",
      "text": "#000000"
    }
  },
  "container": {
    "type": "vertical",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "height": { "value": 400, "unit": "dp" },
      "padding": { "all": 16, "unit": "dp" }
    }
  },
  "elements": [
    {
      "id": "title",
      "type": "text",
      "content": {
        "text": "Welcome!"
      },
      "style": {
        "fontSize": 24,
        "fontWeight": "bold",
        "textColor": "#000000"
      }
    },
    {
      "id": "cta-button",
      "type": "button",
      "content": {
        "text": "Get Started"
      },
      "styleClass": "button-primary",
      "actions": {
        "onClick": {
          "type": "deeplink",
          "url": "app://onboarding"
        }
      }
    }
  ]
}
```

---

## 🚀 Supported Components

### Containers (3 types)

| Type | Description | Use Case |
|------|-------------|----------|
| `vertical` | Stack elements vertically | Lists, forms |
| `horizontal` | Stack elements horizontally | Rows, toolbars |
| `box` | Absolute positioning | Overlays, cards |

### Elements (5 types initially)

| Type | Description | Properties |
|------|-------------|------------|
| `text` | Text display | text, fontSize, color |
| `image` | Image display | url, aspectRatio |
| `button` | Clickable button | text, style, onClick |
| `spacer` | Empty space | height/width |
| `video` | Video player | url, autoPlay |

---

## 🎨 Style System

### Priority Hierarchy

```
1. Inline Style    (highest - element.style)
2. Style Class     (middle - element.styleClass)
3. Theme Default   (lowest - theme.defaultStyle)
```

### Style Properties

```json
{
  "style": {
    "textColor": "#000000",
    "fontSize": 16,
    "fontWeight": "bold",
    "backgroundColor": "#FFFFFF",
    "borderRadius": 8,
    "borderWidth": 1,
    "borderColor": "#CCCCCC",
    "shadowColor": "#00000033",
    "shadowRadius": 4,
    "padding": { "all": 16 },
    "margin": { "all": 8 }
  }
}
```

### Theme Support

```json
{
  "theme": {
    "colors": {
      "primary": "#007AFF",
      "secondary": "#5AC8FA",
      "danger": "#FF3B30"
    },
    "spacing": {
      "small": 8,
      "medium": 16,
      "large": 24
    }
  }
}
```

### Style Classes (Reusable)

```json
{
  "styleClasses": [
    {
      "name": "button-primary",
      "style": {
        "backgroundColor": "#007AFF",
        "textColor": "#FFFFFF",
        "fontSize": 16,
        "fontWeight": "bold",
        "borderRadius": 8
      }
    }
  ]
}
```

---

## 📐 Layout System

### Size Units

| Unit | Description | Example | Platform |
|------|-------------|---------|----------|
| `dp` | Density-independent | 200dp | Android dp / iOS pt |
| `percent` | Percentage of parent | 80% | Both |
| `px` | Absolute pixels | 100px | Both |
| `wrap_content` | Fit content | - | Both |
| `match_parent` | Fill parent | - | Both |

### Position Types

| Type | Description |
|------|-------------|
| `relative` | Relative to previous element |
| `absolute` | Absolute positioning |
| `center` | Centered in parent |

### Gravity/Alignment

```
TOP_START    TOP_CENTER    TOP_END
CENTER_START   CENTER     CENTER_END
BOTTOM_START BOTTOM_CENTER BOTTOM_END
```

---

## 🔧 Implementation Phases

### Phase 1: Foundation (Weeks 1-2) ✅
- [x] Project setup (Android + iOS)
- [x] Basic data models
- [ ] JSON schema definition
- [ ] Documentation structure

### Phase 2: Core Features (Weeks 3-4)
- [ ] JSON parser
- [ ] Style resolution system
- [ ] Layout calculator
- [ ] Basic container rendering

### Phase 3: Elements (Weeks 5-6)
- [ ] Text element
- [ ] Image element
- [ ] Button element
- [ ] Spacer element
- [ ] Video element

### Phase 4: Advanced Features (Weeks 7-8)
- [ ] Action handling (onClick, deeplinks)
- [ ] Animation support
- [ ] Form validation
- [ ] Accessibility

### Phase 5: Polish (Weeks 9-10)
- [ ] Performance optimization
- [ ] Error handling
- [ ] Testing suite
- [ ] Documentation completion

---

## 🎯 Development Approach

### Separate Native Codebases ✅

**Decision**: Build Android and iOS separately (not KMP)

**Reasoning**:
- ✅ Full access to platform features
- ✅ Best performance (no abstraction layer)
- ✅ Native idioms (Compose Material 3, SwiftUI)
- ✅ Easier debugging
- ✅ Platform-specific optimizations
- ✅ Team expertise (Android devs know Kotlin, iOS devs know Swift)

**Trade-off**:
- ❌ Some code duplication (models, parsing logic)
- ✅ But: UI rendering is platform-specific anyway
- ✅ And: Each platform can move at its own pace

### Shared Concepts, Native Implementation

Both platforms implement the same:
1. **JSON schema** (identical)
2. **Data models** (same structure, different language)
3. **Style resolution** (same logic, native code)
4. **Layout calculations** (same math, native code)

But render using:
- **Android**: Jetpack Compose + Material 3
- **iOS**: SwiftUI + SF Symbols

---

## 📦 Deliverables

### Android Library
```kotlin
// Usage
val renderer = NativeDisplayRenderer(context)
val result = renderer.render(jsonConfig)

// Integration
class MyActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        setContent {
            NativeDisplayView(config = jsonConfig)
        }
    }
}
```

### iOS Library
```swift
// Usage
let renderer = NativeDisplayRenderer()
let view = renderer.render(jsonConfig: jsonConfig)

// Integration
struct ContentView: View {
    var body: some View {
        NativeDisplayView(config: jsonConfig)
    }
}
```

---

## 🔐 Security & Validation

### JSON Validation
- Schema validation on parse
- Type checking
- Size limits
- URL whitelisting

### Security
- Sanitize all user input
- Validate URLs before navigation
- Sandbox rendering
- No code execution

---

## 🎨 Design Principles

1. **Server-Driven**: Backend controls UI
2. **Type-Safe**: Compile-time validation
3. **Native-First**: Platform best practices
4. **Performant**: No WebView overhead
5. **Extensible**: Easy to add components
6. **Testable**: Unit + UI testing
7. **Accessible**: WCAG compliance

---

## 📊 Success Metrics

### Performance
- [ ] Render time < 16ms (60fps)
- [ ] Memory usage < 50MB
- [ ] JSON parse < 100ms

### Quality
- [ ] 80%+ test coverage
- [ ] Zero crashes
- [ ] Accessibility score > 90

### Adoption
- [ ] Replace 50% of HTML messages in 6 months
- [ ] <5% rollback rate
- [ ] Positive developer feedback

---

## 🛠️ Tech Stack

### Android
- **Language**: Kotlin 1.9.0
- **UI**: Jetpack Compose + Material 3
- **JSON**: kotlinx.serialization
- **Image**: Coil
- **Video**: ExoPlayer
- **Testing**: JUnit, Espresso

### iOS
- **Language**: Swift 5.9
- **UI**: SwiftUI + SF Symbols
- **JSON**: Codable
- **Image**: AsyncImage / Kingfisher
- **Video**: AVPlayer
- **Testing**: XCTest, SwiftUI Previews

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | System design |
| [JSON Schema](docs/json-schema.md) | Complete schema spec |
| [Style Guide](docs/style-guide.md) | Style system details |
| [Android Setup](android/README.md) | Android dev guide |
| [iOS Setup](ios/README.md) | iOS dev guide |

---

## 🚀 Getting Started

### Android Development

```bash
cd android
./gradlew assembleDebug
./gradlew installDebug
```

### iOS Development

```bash
cd ios
open CleverTapNativeDisplay.xcodeproj
# Build and run in Xcode
```

### Run Sample Apps

**Android**:
```bash
cd android/sample
./gradlew installDebug
```

**iOS**:
```bash
cd ios/Sample
open Sample.xcodeproj
```

---

## 🤝 Contributing

### Code Style
- **Android**: Kotlin coding conventions
- **iOS**: Swift API design guidelines

### Naming Conventions
- Use `NativeDisplay*` prefix for all public APIs
- CamelCase for classes
- camelCase for properties/methods
- Descriptive names (avoid abbreviations)

### Git Workflow
1. Create feature branch
2. Make changes
3. Write tests
4. Submit PR
5. Code review
6. Merge

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## 👥 Team

**Project Lead**: [Your Name]  
**Android Team**: [Team members]  
**iOS Team**: [Team members]

---

## 🗓️ Roadmap

### Q1 2024
- ✅ Project setup
- ⏳ Core framework
- ⏳ Basic elements

### Q2 2024
- ⏳ Advanced elements
- ⏳ Actions & events
- ⏳ Beta release

### Q3 2024
- ⏳ Production release
- ⏳ Migration tools
- ⏳ Performance optimization

### Q4 2024
- ⏳ Advanced features
- ⏳ Analytics integration
- ⏳ A/B testing support

---

## 📞 Support

- **Issues**: GitHub Issues
- **Slack**: #native-display-kit
- **Email**: support@clevertap.com

---

**Built with ❤️ by the CleverTap team**
