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
    val version: String = "1.0",
    val theme: Theme? = null,
    val styleClasses: List<StyleClass> = emptyList(),
    val variables: Map<String, JsonElement> = emptyMap(),
    val root: NativeDisplayNode? = null,
    // Phase 2+ external references (optional)
    val templateRef: TemplateReference? = null,
    val styleRef: StyleReference? = null,
    val dataRef: DataReference? = null
)
```

**Key Model Classes**:
- `NativeDisplayConfig` - Root configuration
- `NativeDisplayNode` - Base **sealed class**; concrete subtypes are `NativeDisplayContainer` and `NativeDisplayElement`
- `Layout` - Layout configuration for all nodes
- `Style` - Style properties (text + visual)
- `Background` - Sealed class with multiple background types
- `Animation` - Animation configuration
- `GalleryConfig` - Gallery-specific configuration

### 2. Business Logic Layer

**Style Resolution**:
- Cascading style inheritance for text properties
- Theme → StyleClass → Inline Style
- Visual properties do NOT cascade

**Variable Evaluation** (`VariableEvaluator`):
- Variable interpolation: `{{variableName}}`
- Nested properties: `{{object.property}}`
- Negation: `{{!expression}}`

**Layout Calculation** (`ModifierExtensions.kt` — `applySizing`):
- Dimension resolution (DP, SP, PERCENT, PX)
- Special dimensions (WRAP_CONTENT, MATCH_PARENT)
- RTL support automatic
- Arrangement strategies for container spacing

### 3. UI Rendering Layer

**Jetpack Compose Components**:
- `NativeDisplayView` / `RenderNode` (`renderer/NativeDisplayRenderer.kt`) - Main entry point + node dispatcher
- `ElementRenderer` - Renders the 7 element types
- `GalleryRenderer` - Renders the GALLERY container
- `BackgroundRenderer` - Applies backgrounds
- `VideoRenderer` / `HtmlRenderer` - VIDEO and HTML elements

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
├── models/                    # Data models (@Serializable)
│   ├── NativeDisplayConfig.kt # also ResolvedConfig
│   ├── NativeDisplayNode.kt   # sealed: NativeDisplayContainer / NativeDisplayElement
│   ├── Layout.kt
│   ├── Style.kt
│   ├── StyleProperties.kt
│   ├── TextDimension.kt
│   ├── Background.kt
│   ├── Enums.kt               # ContainerType, ElementType, ArrangementStrategy, …
│   ├── Action.kt
│   ├── ActionTriggers.kt
│   └── GalleryConfig.kt
│
├── renderer/                  # UI rendering
│   ├── NativeDisplayRenderer.kt  # NativeDisplayView + RenderNode dispatcher
│   ├── ElementRenderer.kt
│   ├── GalleryRenderer.kt
│   ├── BackgroundRenderer.kt
│   ├── VideoRenderer.kt
│   ├── HtmlRenderer.kt
│   ├── ModifierExtensions.kt     # applySizing / dimension + layout modifiers
│   ├── NativeDisplayLocals.kt
│   └── RenderUtils.kt
│
├── style/                     # StyleResolver (cascading)
├── evaluator/                 # VariableEvaluator ({{var}} interpolation)
├── handler/                   # ActionHandler + attribution
├── listener/                  # Action / component listeners
├── bridge/                    # Core SDK bridge, config parser, unit cache
├── placement/                 # NativeDisplaySlot / SlotManager / SlotView
├── view/                      # NativeDisplayViewGroup (RecyclerView host)
├── internal/                  # ImageLoaderProvider, NDLogger
└── utils/                     # Extensions, MixedContentAdapter, …
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
Variable Evaluation (VariableEvaluator)
    ↓
Layout Calculation (ModifierExtensions.applySizing)
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
| GALLERY | LazyRow / LazyColumn + `rememberSnapFlingBehavior` | contentPadding peeking, snap |

## Element Rendering Strategy

Each element type maps to Compose components:

| Element | Compose Component | Key Features |
|---------|-------------------|--------------|
| TEXT | Text | Style cascading |
| IMAGE | AsyncImage | Loading states |
| BUTTON | Button | Click handling |
| VIDEO | AndroidView | Player lifecycle |
| HTML | AndroidView (WebView) | JS bridge, security hardening |
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

### 4. RGBA Color Format
Colors are stored as RGBA hex strings (parsed by `RenderUtils.parseColor`):
- `#RRGGBB` → opaque (alpha = 1.0)
- `#RRGGBBAA` → alpha is the **low byte** (RGBA, not ARGB)

## Extension Points

### Custom Backgrounds
Extend the sealed `Background` class for new background types.

### Custom Animations
Add new `AnimationType` enum values (in `Enums.kt`) and wire the enter transition in the render tree (`NativeDisplayRenderer.kt`; easing via `RenderUtils.resolveEasing`).

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
