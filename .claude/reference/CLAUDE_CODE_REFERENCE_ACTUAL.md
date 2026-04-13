# Native Display System - Claude Code Reference

**Status**: ✅ VERIFIED AGAINST ACTUAL KOTLIN CODE  
**Source**: `/android/sdk/src/main/kotlin/com/clevertap/android/nativedisplay/models/`  
**Updated**: January 2025

---

## Configuration Structure

```
NativeDisplayConfig {
  theme?: Theme
  styleClasses?: StyleClass[]
  variables?: Map<string, JsonElement>
  root: NativeDisplayNode (required)
}
```

---

## Container Types (5 Total)

| Type | Purpose | Layout |
|------|---------|--------|
| VERTICAL | Stack vertically | Column |
| HORIZONTAL | Stack horizontally | Row |
| BOX | Single or multiple children | Overlay |
| GALLERY | Scrollable carousel | Scroll (3 modes) |

---

## Element Types (7 Total)

| Type | Binding | Purpose |
|------|---------|---------|
| TEXT | `text` | Display text |
| IMAGE | `url` | Display image |
| BUTTON | `text` | Clickable button |
| VIDEO | `url` (+ autoPlay, loop, muted, showControls, showFullscreen) | Display video with custom controls |
| HTML | `html` or `url` (`html` wins if both present) | Render rich HTML in WebView |
| SPACER | N/A | Spacing element |
| DIVIDER | N/A | Visual divider |

---

## Layout System

### Layout Object (Required for all nodes)
```kotlin
Layout {
  width?: Dimension
  height?: Dimension
  offset?: Offset (for positioning in Box/Stack)
  padding?: Spacing
  arrangement?: ChildArrangement (for container child spacing)
}
```

Every container and element should have layout defined.

### Dimension Object
```kotlin
Dimension {
  value: Float
  unit: DimensionUnit (DP, SP, PERCENT, PX)
  special: SpecialDimension? (WRAP_CONTENT, MATCH_PARENT)
}
```

### Offset Object (For Positioning)
```kotlin
Offset {
  x: Float = 0
  y: Float = 0
  unit: DimensionUnit = DP
}
```

### Spacing Object
```kotlin
Spacing {
  all?: Float
  horizontal?: Float
  vertical?: Float
  top?: Float
  bottom?: Float
  left?: Float
  right?: Float
  unit: DimensionUnit = DP
}
```

RTL support is handled automatically by the system.

### Child Arrangement (For Container Spacing)
```kotlin
ChildArrangement {
  spacing?: Float
  spacingUnit: DimensionUnit = DP
  strategy: ArrangementStrategy = SPACED
}
```

**ArrangementStrategy options:**
- SPACED: Fixed spacing between children
- SPACE_BETWEEN: Space between, no space at edges
- SPACE_EVENLY: Equal space between and at edges
- SPACE_AROUND: Equal space around each child
- START: Align to start, no spacing
- CENTER: Center, no spacing
- END: Align to end, no spacing

---

## Style System

### Text Properties (Cascading - inherited by children)
```kotlin
textColor: String? (hex)
fontSize: TextDimension?    // number → platform units, {"value", "unit":"percent"} → rootContainerHeight*value/1000
fontFamily: String?         // JSON name; resolved via 3-layer system (see STYLE_THEMING_GUIDE.md § Font Family)
fontWeight: FontWeight? (NORMAL, MEDIUM, BOLD, LIGHT)
fontStyle: FontStyle? (NORMAL, ITALIC)
lineHeight: TextDimension?  // same as fontSize
letterSpacing: Float?
textDecoration: TextDecoration? (NONE, UNDERLINE, STRIKETHROUGH)
textAlign: String? ("left", "center", "right", "justify")
maxLines: Int? (maximum lines before truncation)
overflow: TextOverflow? (CLIP, ELLIPSIS, VISIBLE)
textShadow: TextShadow? (drop shadow on text)
textGradient: TextGradient? (gradient text effect)
opacity: Float?
```

### Visual Properties (Non-cascading)
```kotlin
background: Background? (Rich background support)
backgroundColor: String? (Legacy, backward compatible)
borderRadius: Dimension?   // dp number or {"value","unit":"percent"} — percent resolves as rootContainerHeight * value/100
borderWidth: Float?        // resolved at render time as rootContainerHeight * value/1000 (FE formula)
borderColor: String?
shadowColor: String?
shadowRadius: Float?
shadowOffsetX: Float?
shadowOffsetY: Float?
```

---

## Background System

Fully implemented sealed class with 10+ background types:

### Static Backgrounds
```kotlin
Background.Solid(color: String)
Background.LinearGradient(angle: Float, colors: List<String>, stops: List<Float>?)
Background.RadialGradient(centerX: Float, centerY: Float, radius: Float, colors, stops)
Background.SweepGradient(centerX: Float, centerY: Float, startAngle: Float, colors, stops)
Background.Image(url, fit, opacity, blur, tint, tintOpacity)
Background.Pattern(patternType, primaryColor, secondaryColor, size, spacing, opacity)
```

### Animated Backgrounds
```kotlin
Background.Shimmer(baseColor, highlightColor, angle, duration, loop)
Background.AnimatedGradient(gradientType, angle, colors, duration, loop, animationStyle)
Background.Pulse(color, minOpacity, maxOpacity, duration, loop)
Background.Particles(particleColor, particleCount, particleSize, speed, direction, opacity)
Background.Layered(layers: List<Background>)
```

---

## Animation System

### Animation Configuration
```kotlin
Animation {
  type: AnimationType
  duration: Long = 300 (ms)
  delay: Long = 0 (ms)
  easing: Easing
}
```

### Animation Types
```
FADE_IN
SLIDE_IN_LEFT, SLIDE_IN_RIGHT, SLIDE_IN_TOP, SLIDE_IN_BOTTOM
SCALE_IN
FADE_SCALE_IN
FADE_SLIDE_IN
```

### Easing Functions
```
LINEAR
EASE_IN, EASE_OUT, EASE_IN_OUT
EASE_IN_BACK, EASE_OUT_BACK
SPRING
```

---

## Gallery Configuration

```kotlin
GalleryConfig {
  mode: GalleryMode (SNAPPING, FREE_FLOW, FREE_FLOW_GRID)
  orientation: Orientation (HORIZONTAL, VERTICAL)
  
  # SNAPPING mode
  snapBehavior: SnapBehavior (NONE, START, CENTER, END)
  peek: PeekConfig { before: Float (dp), after: Float (dp) }

  # FREE_FLOW_GRID mode
  itemsPerView: Float (e.g., 2.5 = 2 full + 0.5 peek)
  columns: Int? (overrides itemsPerView with integer count)
  
  # Common
  spacing: Float (dp between items)
  showIndicators: Boolean
  indicatorStyle?: IndicatorStyle
  autoScrollInterval: Long (0 = disabled)
  infiniteScroll: Boolean
  showArrows: Boolean
  arrowStyle?: ArrowStyle
  initialPage: Int = 0
}
```

---

## Divider Configuration

```kotlin
DividerConfig {
  orientation: Orientation (HORIZONTAL, VERTICAL)
  thickness: Float = 1 (dp)
  color: String = "#E0E0E0"
}
```

Used by both containers and elements.

---

## HTML Configuration

```kotlin
HtmlConfig {
  javascriptEnabled: Boolean = false
  scrollEnabled: Boolean = false
  baseUrl: String? = null
  transparentBackground: Boolean = true
}
```

**Platform implementation**: Android `WebView` via `AndroidView`, iOS `WKWebView` via `UIViewRepresentable`.

**JS Bridge**: CleverTap Core SDK JS bridge injected via reflection when Core SDK is present. Silent no-op when absent.

**Hardcoded security**: No file access, no zoom, no in-view navigation (links open externally), `textZoom=100` (Android), viewport meta injection (iOS).

---

## Style Resolution

1. Theme default style
2. Style class style
3. Inline node style
4. Inherited from parent (text properties only)

---

## Template Expressions

```
{{variableName}}       → Simple variable
{{object.property}}    → Nested property
{{!expression}}        → Negation
```

Variables are in `variables: Map<String, JsonElement>` at root level.

---

## Element Bindings

```kotlin
bindings: Map<String, String> {
  "text": "{{variableName}}",      // TEXT, BUTTON
  "url": "{{imageUrl}}",           // IMAGE, VIDEO (required), HTML (alternative)

  // VIDEO-specific bindings (optional)
  "autoPlay": "{{autoPlayFlag}}",  // Boolean: auto-start playback
  "loop": "{{loopFlag}}",          // Boolean: repeat when finished
  "muted": "{{mutedFlag}}",        // Boolean: start with audio muted
  "showControls": "true",          // Boolean: show custom controls (default: true)
  "showFullscreen": "true"         // Boolean: show fullscreen button (default: true)

  // HTML-specific bindings
  "html": "<div>...</div>",        // Inline HTML string (takes priority over url)
  "url": "https://..."             // Load remote page (fallback if html not present)
}
```

**Note**: VIDEO element requires `androidx.media3:media3-exoplayer` on Android (host app dependency)
**Note**: HTML element requires explicit `layout.height` — `wrap_content` is not supported

---

## Complete Configuration Example

```json
{
  "theme": {
    "id": "default",
    "defaultStyle": {
      "textColor": "#212121",
      "fontSize": 14
    }
  },
  "styleClasses": [
    {
      "name": "card",
      "style": {
        "backgroundColor": "#FFFFFF",
        "borderRadius": 12,
        "background": {
          "type": "solid",
          "color": "#FFFFFF"
        }
      }
    }
  ],
  "variables": {
    "productName": "Headphones",
    "price": "$299.99",
    "imageUrl": "https://...",
    "inStock": true
  },
  "root": {
    "id": "card",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "padding": { "all": 16 }
    },
    "containerType": "vertical",
    "arrangement": {
      "spacing": 12,
      "strategy": "spaced"
    },
    "children": [
      {
        "id": "image",
        "elementType": "image",
        "bindings": { "src": "{{imageUrl}}" },
        "layout": {
          "width": { "value": 100, "unit": "percent" },
          "height": { "value": 200, "unit": "dp" }
        }
      },
      {
        "id": "name",
        "elementType": "text",
        "bindings": { "text": "{{productName}}" },
        "layout": {
          "width": { "value": 100, "unit": "percent" }
        },
        "style": { "fontSize": 18, "fontWeight": "bold" }
      }
    ]
  }
}
```

---

## All Dimension Units

| Unit | Usage |
|------|-------|
| DP | Device-independent pixels |
| SP | Scale-independent pixels (for text) |
| PERCENT | Percentage of parent |
| PX | Absolute pixels |
| WRAP_CONTENT | Fit to content (special) |
| MATCH_PARENT | Fill parent (special) |

---

## Text Enhancement Objects

### TextShadow
```kotlin
TextShadow {
  color: String (hex with alpha, e.g., "#00000040")
  offsetX: Float (horizontal offset in DP)
  offsetY: Float (vertical offset in DP)
  blur: Float (blur radius in DP)
}
```

**Example:**
```json
{
  "textShadow": {
    "color": "#00000040",
    "offsetX": 2,
    "offsetY": 2,
    "blur": 4
  }
}
```

### TextGradient
```kotlin
TextGradient {
  type: String = "linear"
  colors: List<String> (hex colors)
  angle: Float (degrees, 0 = left to right)
  stops: List<Float>? (optional, 0.0 to 1.0)
}
```

**Example:**
```json
{
  "textGradient": {
    "type": "linear",
    "colors": ["#FF0000", "#0000FF"],
    "angle": 45
  }
}
```

---

## All Enumerations

### FontWeight
`LIGHT, NORMAL, MEDIUM, BOLD`

### FontStyle
`NORMAL, ITALIC`

### TextDecoration
`NONE, UNDERLINE, STRIKETHROUGH`

### TextOverflow
`CLIP, ELLIPSIS, VISIBLE`

### Orientation
`HORIZONTAL, VERTICAL`

### SnapBehavior
`NONE, START, CENTER, END`

### ArrangementStrategy
`SPACED, SPACE_BETWEEN, SPACE_EVENLY, SPACE_AROUND, START, CENTER, END`

### GalleryMode
`SNAPPING, FREE_FLOW, FREE_FLOW_GRID`

### AnimationType
`NONE, FADE_IN, SLIDE_IN_LEFT, SLIDE_IN_RIGHT, SLIDE_IN_TOP, SLIDE_IN_BOTTOM, SCALE_IN, FADE_SCALE_IN, FADE_SLIDE_IN`

### Easing
`LINEAR, EASE_IN, EASE_OUT, EASE_IN_OUT, EASE_IN_BACK, EASE_OUT_BACK, SPRING`

### ImageFit
`COVER, CONTAIN, FILL, TILE`

### PatternType
`DOTS, STRIPES_HORIZONTAL, STRIPES_VERTICAL, STRIPES_DIAGONAL, GRID, CHECKERBOARD, POLKA_DOTS`

### ParticleDirection
`UP, DOWN, LEFT, RIGHT, RANDOM`

### GradientType
`LINEAR, RADIAL, SWEEP`

### AnimationStyle
`SMOOTH, SHIFT, PULSE`

---

## Validation Rules

- Root node must be container or element
- All nodes must have layout defined
- Container can have zero or more children
- Elements must have elementType
- Colors must be hex format (#RRGGBB or #RRGGBBAA - RGBA format)
- Opacity must be 0.0 to 1.0
- fontSize must be > 0
- Dimensions must have value and unit
- Spacing values must be non-negative

---

**All types**: Fully serializable with kotlinx.serialization  
**Ready for**: Claude Code integration and Kotlin implementation
