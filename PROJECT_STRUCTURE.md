# Project Structure

```
clevertap-native-ui-kit/
│
├── 📚 docs/                                    # Documentation
│   ├── README.md                               # Documentation index
│   ├── architecture/                           # Architecture design docs
│   │   ├── ARCHITECTURE_DOCS_INDEX.md          # Overview & quick reference
│   │   ├── ADAPTIVE_ARCHITECTURE.md            # ⭐ Main implementation guide
│   │   ├── SCALABLE_ARCHITECTURE.md            # Style & variable systems
│   │   ├── TEMPLATE_DATA_EXAMPLE.md            # Complete working example
│   │   ├── LAYOUT_IN_TEMPLATE_EXPLAINED.md     # Layout clarification
│   │   └── LAYOUT_CONTENT_SEPARATION.md        # Design alternatives
│   └── examples/                               # Usage examples
│
├── 🤖 android/                                 # Android implementation
│   ├── sdk/                                    # Native Display SDK
│   │   ├── src/main/kotlin/                   # SDK source code
│   │   │   └── com/clevertap/android/nativeui/
│   │   │       ├── models/                     # Data models
│   │   │       ├── renderer/                   # UI rendering
│   │   │       ├── style/                      # Style system
│   │   │       └── cache/                      # Resource caching
│   │   └── build.gradle.kts                   # SDK build config
│   ├── sample-app/                            # Demo app
│   └── gradle/                                # Gradle wrapper
│
├── 🍎 ios/                                     # iOS implementation
│   ├── CleverTapNativeUIKit/                  # Native Display SDK
│   │   ├── Sources/                           # SDK source code
│   │   │   ├── Models/                        # Data models
│   │   │   ├── Renderer/                      # UI rendering
│   │   │   ├── Style/                         # Style system
│   │   │   └── Cache/                         # Resource caching
│   │   └── Package.swift                      # Swift Package config
│   └── SampleApp/                             # Demo app
│
├── 🔧 backend/                                 # Backend JSON generation (optional)
│   └── src/                                   # Backend utilities
│
├── 📋 schema/                                  # JSON schema definitions
│   ├── config-schema.json                     # Main config schema
│   └── examples/                              # Example JSON files
│       ├── phase1-monolithic.json             # Everything together
│       ├── phase2-split.json                  # Split APIs
│       └── product-card.json                  # Complete example
│
├── 🔨 scripts/                                 # Build & utility scripts
│   ├── validate-schema.sh                     # JSON validation
│   └── generate-docs.sh                       # Doc generation
│
├── 📄 README.md                                # Main project README
├── 📄 PROJECT_SETUP.md                         # Project setup guide
├── 📄 NATIVE_APPROACH.md                       # Why native vs KMP
├── 📄 CHANGELOG.md                             # Version history
├── 📄 LICENSE                                  # MIT License
└── 📄 CONTRIBUTING.md                          # Contribution guidelines
```

## 🎯 Quick Navigation

### Getting Started
1. **New to the project?** → Read [docs/README.md](docs/README.md)
2. **Want to implement?** → Read [docs/architecture/ADAPTIVE_ARCHITECTURE.md](docs/architecture/ADAPTIVE_ARCHITECTURE.md)
3. **Need examples?** → Check [docs/architecture/TEMPLATE_DATA_EXAMPLE.md](docs/architecture/TEMPLATE_DATA_EXAMPLE.md)

### Development
- **Android SDK**: `android/sdk/`
- **iOS SDK**: `ios/CleverTapNativeUIKit/`
- **Sample Apps**: `android/sample-app/` or `ios/SampleApp/`

### Documentation
- **Architecture docs**: `docs/architecture/`
- **JSON schemas**: `schema/`
- **Examples**: `schema/examples/`

## 📦 Key Directories

### `/docs/architecture/` (90KB total)
Complete architecture documentation:
- **ADAPTIVE_ARCHITECTURE.md** (18KB) - Main implementation guide
- **SCALABLE_ARCHITECTURE.md** (16KB) - Style & variable systems
- **TEMPLATE_DATA_EXAMPLE.md** (20KB) - Working example
- Plus 3 more detailed design docs

### `/android/sdk/`
Android SDK implementation using Jetpack Compose:
```kotlin
com.clevertap.android.nativeui/
├── models/           # Data models
├── renderer/         # Compose UI rendering
├── style/            # Style resolver
└── cache/            # Template/style cache
```

### `/ios/CleverTapNativeUIKit/`
iOS SDK implementation using SwiftUI:
```swift
CleverTapNativeUIKit/
├── Models/           # Data models
├── Renderer/         # SwiftUI rendering
├── Style/            # Style resolver
└── Cache/            # Template/style cache
```

### `/schema/`
JSON schema definitions and examples:
- `config-schema.json` - Main schema
- `examples/phase1-monolithic.json` - Everything together
- `examples/phase2-split.json` - Split APIs
- `examples/product-card.json` - Complete example

## 🎨 Key Files

| File | Purpose |
|------|---------|
| `README.md` | Main project overview |
| `docs/README.md` | Documentation index |
| `docs/architecture/ADAPTIVE_ARCHITECTURE.md` | ⭐ Main implementation guide |
| `PROJECT_SETUP.md` | Project setup instructions |
| `NATIVE_APPROACH.md` | Native vs KMP decision |
| `CHANGELOG.md` | Version history |

## 🔄 Data Flow

```
Backend Server
    ↓
JSON Config (Phase 1: Monolithic or Phase 2: Split)
    ↓
Mobile SDK (Adaptive Loader)
    ↓
    ├─→ Template Cache (if Phase 2)
    ├─→ Style Cache (if Phase 2)
    └─→ Fresh Data (always)
    ↓
Style Resolver
    ↓
UI Renderer (Compose/SwiftUI)
    ↓
Native UI
```

## 📊 Code Organization

### Phase 1 Implementation
```
SDK Core:
├── NativeDisplayConfig.kt/swift     # Main config model
├── NativeDisplayNode.kt/swift        # Container & Element
├── StyleResolver.kt/swift            # Style inheritance
├── VariableEvaluator.kt/swift        # Template variables
└── NativeDisplayRenderer.kt/swift    # Main renderer

Support:
├── Layout.kt/swift                   # Layout system
├── Style.kt/swift                    # Style models
└── Theme.kt/swift                    # Theme models
```

### Phase 2 Implementation (Future)
```
Additional:
├── TemplateCache.kt/swift            # Template caching
├── StyleCache.kt/swift               # Style caching
├── AdaptiveLoader.kt/swift           # Smart loader
└── ResourceManager.kt/swift          # Resource management
```

## 🚀 Next Steps

1. **Read architecture docs**: Start with `docs/architecture/ADAPTIVE_ARCHITECTURE.md`
2. **Check examples**: Look at `schema/examples/`
3. **Start coding**: Implement in `android/sdk/` or `ios/CleverTapNativeUIKit/`

---

**Project Root**: `/Users/lalitkumar/StudioProjects/clevertap-native-ui-kit`
