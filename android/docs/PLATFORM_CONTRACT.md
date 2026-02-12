# Platform Implementation Contract

This document defines what **MUST** be implemented for platform parity across Android, iOS, Flutter, React Native, and Expo.

---

## 🎯 Implementation Goals

1. **Visual Parity:** Same JSON produces identical UI across all platforms
2. **Feature Complete:** All core features supported
3. **Performance:** Smooth 60fps rendering
4. **Type Safety:** Strong typing where platform supports it
5. **Error Handling:** Graceful degradation on errors

---

## ✅ Implementation Checklist

### Phase 1: Core Parsing & Models

- [ ] **JSON Parser**
  - [ ] Deserialize JSON to typed objects
  - [ ] Handle malformed JSON gracefully
  - [ ] Validate required fields
  - [ ] Support nullable optional fields

- [ ] **Type-Safe Models**
  - [ ] `ResolvedConfig` model
  - [ ] `NativeDisplayNode` (sealed/union type)
  - [ ] `NativeDisplayContainer` model
  - [ ] `NativeDisplayElement` model
  - [ ] `Theme` model
  - [ ] `Style` model
  - [ ] `Layout` model

### Phase 2: Container Rendering

- [ ] **VERTICAL Container**
  - [ ] Column/stack layout
  - [ ] Spacing between children
  - [ ] Padding support
  - [ ] Style application

- [ ] **HORIZONTAL Container**
  - [ ] Row layout
  - [ ] Spacing between children
  - [ ] Padding support
  - [ ] Style application

- [ ] **BOX Container**
  - [ ] Single child
  - [ ] Alignment options (9 positions)
  - [ ] Padding support
  - [ ] Style application

- [ ] **STACK Container**
  - [ ] Layered children (z-index)
  - [ ] Absolute positioning via margin
  - [ ] Overlapping support
  - [ ] Style application

### Phase 3: Element Rendering

- [ ] **TEXT Element**
  - [ ] Display text
  - [ ] Typography (color, size, weight, align)
  - [ ] Line height
  - [ ] Template evaluation

- [ ] **IMAGE Element**
  - [ ] Load from URL
  - [ ] Load from base64
  - [ ] Sizing (width, height)
  - [ ] Border radius
  - [ ] Error placeholder

- [ ] **VIDEO Element**
  - [ ] Load from URL
  - [ ] Playback controls
  - [ ] Auto-play, loop, mute
  - [ ] Sizing
  - [ ] Error handling

- [ ] **SPACER Element**
  - [ ] Fixed size spacing
  - [ ] Flexible spacing
  - [ ] Horizontal/vertical

- [ ] **BUTTON Element**
  - [ ] Display text
  - [ ] Click handling
  - [ ] Action execution
  - [ ] Style application

### Phase 4: Style System

- [ ] **Style Resolver**
  - [ ] Theme defaults
  - [ ] Style class resolution
  - [ ] Node-level styles
  - [ ] Style inheritance
  - [ ] Color parsing (hex)

- [ ] **Style Properties**
  - [ ] Colors (text, background, border, shadow)
  - [ ] Typography (size, weight, align, line height)
  - [ ] Spacing (padding, margin)
  - [ ] Sizing (width, height)
  - [ ] Borders (radius, width, color)
  - [ ] Shadows (radius, color, offset)
  - [ ] Effects (opacity)

### Phase 5: Layout System

- [ ] **Dimension Types**
  - [ ] DP (density-independent pixels)
  - [ ] Percent (% of parent)
  - [ ] Wrap (fit content)
  - [ ] Fill (expand to parent)

- [ ] **Spacing**
  - [ ] Padding (all, horizontal, vertical, individual)
  - [ ] Margin (all, horizontal, vertical, individual)
  - [ ] Negative margins (overlapping)

- [ ] **Layout Application**
  - [ ] Width constraints
  - [ ] Height constraints
  - [ ] Padding application
  - [ ] Offset (x, y positioning)

### Phase 6: Gallery System

- [ ] **SNAPPING Mode**
  - [ ] Horizontal/vertical paging
  - [ ] Peek support (show adjacent items)
  - [ ] Snap behavior (center/start/end)
  - [ ] Page indicators
  - [ ] Auto-scroll
  - [ ] Infinite scroll

- [ ] **FREE_FLOW Mode**
  - [ ] Horizontal/vertical scrolling
  - [ ] Self-sizing items
  - [ ] Natural scrolling (no snap)
  - [ ] Spacing between items

- [ ] **FREE_FLOW_GRID Mode**
  - [ ] Fixed items per view
  - [ ] Equal-sized items
  - [ ] Peek via itemsPerView
  - [ ] Container-based sizing
  - [ ] Natural scrolling

### Phase 7: Background System

- [ ] **Static Backgrounds**
  - [ ] Solid color
  - [ ] Linear gradient
  - [ ] Radial gradient
  - [ ] Grid pattern
  - [ ] Dots pattern
  - [ ] Waves pattern

- [ ] **Animated Backgrounds**
  - [ ] Pulse (opacity animation)
  - [ ] Shimmer (sweep animation)
  - [ ] Smooth (slow transitions)
  - [ ] Particle (floating elements)
  - [ ] Breathing (scale animation)

### Phase 8: Advanced Features

- [ ] **Variable Evaluation**
  - [ ] Simple variables (`{{name}}`)
  - [ ] Nested variables (`{{user.name}}`)
  - [ ] Boolean evaluation
  - [ ] Type conversion

- [ ] **Conditional Rendering**
  - [ ] Visibility expressions
  - [ ] Show/hide based on data

- [ ] **Error Handling**
  - [ ] Parse errors
  - [ ] Missing fields
  - [ ] Invalid values
  - [ ] Network errors (images/videos)
  - [ ] Graceful fallbacks

---

## 🔒 Mandatory Requirements

### 1. Type Safety

**Required:**
```typescript
// TypeScript/Swift/Kotlin
interface NativeDisplayNode {
  id: string
  layout?: Layout
  style?: Style
  // ...
}
```

**Not Acceptable:**
```javascript
// Untyped objects
const node = {
  id: "foo",
  // anything goes
}
```

### 2. Serialization

**Android (Kotlin):**
```kotlin
@Serializable
data class NativeDisplayNode(...)
```

**iOS (Swift):**
```swift
struct NativeDisplayNode: Codable {
  // ...
}
```

**TypeScript (React Native/Expo):**
```typescript
interface NativeDisplayNode {
  // ...
}
// Use zod or io-ts for runtime validation
```

### 3. Error Handling

**Parse Errors:**
```
JSON parsing failed → Show error message, don't crash
```

**Missing Required Fields:**
```
Field validation failed → Use defaults or show error
```

**Network Errors:**
```
Image load failed → Show placeholder, retry option
```

### 4. Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| JSON Parse | < 100ms | < 500ms |
| Style Resolution | < 50ms | < 200ms |
| First Render | < 200ms | < 1s |
| Scroll FPS | 60fps | 30fps |
| Memory | Efficient | No leaks |

### 5. Container-Based Sizing

**CRITICAL:** Gallery must use container dimensions, NOT screen dimensions

```kotlin
// ✅ CORRECT
BoxWithConstraints(modifier = modifier) {
  val containerWidth = maxWidth  // Container size
  val itemWidth = containerWidth / itemsPerView
}

// ❌ WRONG
val screenWidth = configuration.screenWidthDp.dp  // Screen size
val itemWidth = screenWidth / itemsPerView
```

This applies to:
- Gallery item sizing
- Percentage dimensions
- Responsive layouts

---

## 📐 Layout Behavior Contract

### Spacing Priority

```
1. Padding (internal)
2. Margin (external positioning)
3. Container spacing (between children)
```

### Size Resolution

```
1. Explicit size (dp, percent)
2. Parent constraint (fill)
3. Content size (wrap)
```

### Style Inheritance

```
1. Theme defaults
2. Style class
3. Node style (highest priority)
4. Parent style (inherited properties only)
```

---

## 🎨 Visual Consistency Rules

### 1. Colors

**Format:** Hex with optional alpha
```
#RRGGBB
#AARRGGBB
```

**Parsing:**
```
#FF5722 → RGB(255, 87, 34)
#FF572280 → ARGB(0.5, 255, 87, 34)
```

### 2. Dimensions

**DP Conversion:**
```
Android: 1dp = 1dp (density-independent)
iOS: 1dp = 1pt (point)
Web: 1dp = 1px * dpr
```

**Percentage:**
```
50% of parent width → 0.5 * parent.width
```

### 3. Typography

**Font Sizes:**
```
Android: sp (scale-independent pixels)
iOS: pt (points)
Web: px or rem
```

**Font Weights:**
```
"normal" → 400
"bold" → 700
```

### 4. Borders

**Border Radius:**
```
Single value → all corners
Individual values → [topLeft, topRight, bottomRight, bottomLeft]
```

---

## 🧪 Testing Requirements

### Unit Tests

- [ ] JSON parsing (valid & invalid)
- [ ] Style resolution (all scenarios)
- [ ] Variable evaluation (all types)
- [ ] Layout calculations
- [ ] Model validation

### Integration Tests

- [ ] Complete rendering pipeline
- [ ] Gallery scrolling & sizing
- [ ] Background rendering
- [ ] Error scenarios

### Visual Tests

- [ ] Screenshot comparison
- [ ] Cross-platform parity
- [ ] All widget examples
- [ ] Complex layouts

### Performance Tests

- [ ] Large JSON parsing
- [ ] Deep nesting (20+ levels)
- [ ] Long lists (1000+ items)
- [ ] Memory usage
- [ ] Scroll performance

---

## 📦 Deliverables

### 1. SDK/Library

**Package Name:**
```
Android: com.clevertap.nativedisplay
iOS: CleverTapNativeDisplay
React Native: @clevertap/native-display
Flutter: clevertap_native_display
```

**Public API:**
```kotlin
// Android
NativeDisplayView(config: ResolvedConfig)

// iOS
NativeDisplayView(config: ResolvedConfig)

// React Native
<NativeDisplayView config={resolvedConfig} />

// Flutter
NativeDisplayView(config: resolvedConfig)
```

### 2. Sample App

**Must Include:**
- Load JSON from assets
- All widget examples
- All style examples
- All layout examples
- Gallery examples (3 modes)
- Background examples (11 types)
- Error scenarios

**Test Files:**
- `test_simple.json` - Basic layout
- `showcase_ecommerce_product.json`
- `showcase_social_profile.json`
- `showcase_dashboard.json`
- `gallery_three_modes.json`

### 3. Documentation

**Required Docs:**
- Integration guide
- API reference
- Widget catalog
- Style guide
- Troubleshooting guide
- Migration guide (if applicable)

---

## 🚫 Non-Goals (Out of Scope)

The following are **NOT** required for platform parity:

- Custom animations (beyond background system)
- Web views / embedded HTML
- Native maps integration
- Camera / media capture
- Complex gestures (beyond tap)
- Local storage / persistence
- Network requests (handled by backend)
- Analytics / tracking
- Push notifications

---

## ✨ Nice-to-Have (Optional)

Features that enhance the system but aren't required:

- Live preview in design tools
- JSON schema validation
- Visual editor
- Hot reload
- Debug mode with inspector
- Accessibility improvements
- Dark mode support
- RTL layout support

---

## 🔄 Version Compatibility

### JSON Schema Version

```json
{
  "version": "1.0",
  "theme": {...},
  "root": {...}
}
```

**Backward Compatibility:**
- v1.x must support v1.0 JSON
- New features use optional fields
- Old clients ignore unknown fields

**Forward Compatibility:**
- Gracefully ignore unknown properties
- Use defaults for missing properties
- Don't crash on new enum values

---

## 📞 Platform-Specific Notes

### Android (Kotlin + Jetpack Compose)
- Use `kotlinx.serialization` for JSON
- Use `@Composable` functions for rendering
- Follow Material Design guidelines
- Use `Dp` for dimensions

### iOS (Swift + SwiftUI)
- Use `Codable` for JSON
- Use `View` protocol for rendering
- Follow Human Interface Guidelines
- Use `CGFloat` for dimensions

### Flutter (Dart)
- Use `json_serializable` for JSON
- Use `Widget` tree for rendering
- Follow Material Design or Cupertino
- Use `double` for dimensions

### React Native (TypeScript)
- Use `Zod` or `io-ts` for validation
- Use components for rendering
- Follow platform conventions
- Use `number` for dimensions

### Expo (TypeScript)
- Same as React Native
- Use Expo's image/video components
- Leverage Expo SDK features

---

## 🎯 Success Criteria

A platform implementation is **complete** when:

1. ✅ All checklist items implemented
2. ✅ All test JSON files render correctly
3. ✅ Visual output matches Android reference
4. ✅ Performance meets targets
5. ✅ Documentation is complete
6. ✅ Sample app demonstrates all features
7. ✅ Unit tests pass (>80% coverage)
8. ✅ Integration tests pass
9. ✅ No memory leaks detected
10. ✅ Code review approved

---

## 📚 Reference Implementation

**Primary Reference:** Android SDK

**Location:** `/android/sdk/`

**Key Files:**
- `models/NativeDisplayNode.kt` - Data models
- `renderer/NativeDisplayRenderer.kt` - Rendering logic
- `style/StyleResolver.kt` - Style resolution
- `evaluator/VariableEvaluator.kt` - Variable evaluation
- `background/BackgroundRenderer.kt` - Background system

---

## 🤝 Support

For implementation questions:

1. Review Android reference implementation
2. Check documentation in `/docs/`
3. Test with sample JSON files
4. Create issue with specific question

---