# Android SDK Architecture

## CRITICAL: SDK Usage Model

**The Native Display SDK is JSON-driven.** Clients do NOT write custom Composables or implement renderers.

**Client Usage (3 steps):**
1. Load JSON configuration
2. Parse: `Json.decodeFromString<NativeDisplayConfig>(json)`
3. Render: `NativeDisplayView(config)`

**That's it.** ✅ No custom implementations needed.

See: `.claude/reference/CLIENT_USAGE_MODEL.md` for complete details.

---

## Overview

The Native Display Android SDK is built with Kotlin and Jetpack Compose, following a clean architecture pattern with clear separation between data models, business logic, and UI rendering.

**This document describes SDK INTERNAL implementation** - not client usage.

## Core Layers

### 1. Data Models Layer

**Location**: `android/sdk/src/main/kotlin/com/clevertap/android/nativedisplay/models/`

All models use `@Serializable` annotation from kotlinx.serialization for JSON parsing:

```kotlin
@Serializable
data class NativeDisplayConfig(
    val theme: Theme? = null,
    val styleClasses: List<StyleClass>? = null,
    val variables: Map<String, JsonElement>? = null,
    val root: NativeDisplayNode
)
```

**Key Model Classes**:
- `NativeDisplayConfig` - Root configuration
- `NativeDisplayNode` - Base node (container or element)
- `Layout` - Layout configuration for all nodes
- `Style` - Style properties (text + visual)
- `Background` - Sealed class with 10+ background types
- `Animation` - Animation configuration
- `GalleryConfig` - Gallery-specific configuration

### 2. Business Logic Layer

**Style Resolution**:
- Cascading style inheritance for text properties
- Theme → StyleClass → Inline Style
- Visual properties do NOT cascade

**Template Evaluation**:
- Variable interpolation: `{{variableName}}`
- Nested properties: `{{object.property}}`
- Negation: `{{!expression}}`

**Layout Calculation**:
- Dimension resolution (DP, SP, PERCENT, PX)
- Special dimensions (WRAP_CONTENT, MATCH_PARENT)
- RTL support automatic
- Arrangement strategies for container spacing

### 3. UI Rendering Layer

**Jetpack Compose Components**:
- `NativeDisplayView` - Main entry point
- `ContainerRenderer` - Renders 5 container types
- `ElementRenderer` - Renders 6 element types
- `BackgroundModifier` - Applies backgrounds
- `AnimationWrapper` - Handles animations

## Architecture Principles

### 1. Immutability
All models are immutable data classes. State changes create new instances.

### 2. Type Safety
Sealed classes for exhaustive when expressions:
```kotlin
sealed class Background {
    data class Solid(val color: String) : Background()
    data class LinearGradient(...) : Background()
    // ... 8 more types
}
```

### 3. Composability
Compose modifiers chain for declarative UI:
```kotlin
Box(
    modifier = Modifier
        .applyDimension(width, parentSize)
        .applyBackground(background)
        .applyPadding(padding)
        .applyBorder(borderWidth, borderColor, borderRadius)
)
```

### 4. Separation of Concerns
- Models: Data structures only
- Resolvers: Business logic (style, template)
- Renderers: UI presentation only

## Directory Structure

```
android/sdk/src/main/kotlin/com/clevertap/android/nativedisplay/
├── models/                    # Data models
│   ├── NativeDisplayConfig.kt
│   ├── NativeDisplayNode.kt
│   ├── Layout.kt
│   ├── Style.kt
│   ├── Background.kt
│   ├── Animation.kt
│   └── GalleryConfig.kt
│
├── rendering/                 # UI rendering
│   ├── NativeDisplayView.kt
│   ├── ContainerRenderer.kt
│   ├── ElementRenderer.kt
│   ├── BackgroundModifier.kt
│   └── AnimationWrapper.kt
│
├── resolution/                # Business logic
│   ├── StyleResolver.kt
│   ├── TemplateEvaluator.kt
│   └── DimensionCalculator.kt
│
└── utils/                     # Utilities
    ├── ColorParser.kt
    └── Extensions.kt
```

## Data Flow

```
JSON Config
    ↓
Parse (kotlinx.serialization)
    ↓
NativeDisplayConfig
    ↓
Style Resolution (StyleResolver)
    ↓
Template Evaluation (TemplateEvaluator)
    ↓
Layout Calculation (DimensionCalculator)
    ↓
Compose Rendering (NativeDisplayView)
    ↓
Native UI
```

## Container Rendering Strategy

Each container type maps to Compose layouts:

| Container | Compose Component | Arrangement |
|-----------|-------------------|-------------|
| VERTICAL | Column | Vertical.Arrangement |
| HORIZONTAL | Row | Horizontal.Arrangement |
| BOX | Box | Alignment |
| STACK | Box with z-index | Layer order |
| GALLERY | LazyRow/Column | Item spacing |

## Element Rendering Strategy

Each element type maps to Compose components:

| Element | Compose Component | Key Features |
|---------|-------------------|--------------|
| TEXT | Text | Style cascading |
| IMAGE | AsyncImage | Loading states |
| BUTTON | Button | Click handling |
| VIDEO | AndroidView | Player lifecycle |
| SPACER | Spacer | Fixed/flexible |
| DIVIDER | Divider | Orientation support |

## Key Design Decisions

### 1. Sealed Classes for Variants
Background, Animation, Easing use sealed classes for type safety and exhaustive handling.

### 2. Nullable vs Required
- `theme` is optional (nullable)
- `root` is required (non-nullable)
- Most style properties are optional

### 3. Default Values
Models provide sensible defaults:
```kotlin
data class ChildArrangement(
    val spacing: Float? = null,
    val spacingUnit: DimensionUnit = DimensionUnit.DP,
    val strategy: ArrangementStrategy = ArrangementStrategy.SPACED
)
```

### 4. ARGB Color Format
Colors are stored as ARGB hex strings:
- `#RRGGBB` → `#FFRRGGBB` (opaque)
- `#AARRGGBB` → as-is (with alpha)

## Extension Points

### Custom Backgrounds
Extend the sealed `Background` class for new background types.

### Custom Animations
Add new `AnimationType` enum values and implement in `AnimationWrapper`.

### Custom Elements
Add new `ElementType` enum values and implement in `ElementRenderer`.

## Testing Strategy

- **Unit Tests**: Model parsing, style resolution, template evaluation
- **Screenshot Tests**: Visual rendering for each container/element type
- **Integration Tests**: Full JSON → UI rendering

## Performance Considerations

1. **Lazy Rendering**: Use LazyColumn/LazyRow for long lists
2. **Image Loading**: AsyncImage with proper caching
3. **Recomposition**: Minimize by using stable data classes
4. **State Hoisting**: Keep state at appropriate levels

## References

- Jetpack Compose documentation: https://developer.android.com/jetpack/compose
- kotlinx.serialization: https://github.com/Kotlin/kotlinx.serialization
