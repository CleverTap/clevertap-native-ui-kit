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
| STACK | Layered children | Overlay with z-index |
| GALLERY | Scrollable carousel | Scroll (3 modes) |

---

## Element Types (6 Total)

| Type | Binding | Purpose |
|------|---------|---------|
| TEXT | `text` | Display text |
| IMAGE | `src` | Display image |
| BUTTON | `text` | Clickable button |
| VIDEO | `src` | Display video |
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
fontSize: Float?
fontFamily: String?
fontWeight: FontWeight? (NORMAL, MEDIUM, BOLD, LIGHT)
lineHeight: Float?
textDecoration: TextDecoration? (NONE, UNDERLINE, STRIKETHROUGH)
textAlign: String? ("left", "center", "right")
opacity: Float?
```

### Visual Properties (Non-cascading)
```kotlin
background: Background? (Rich background support)
backgroundColor: String? (Legacy, backward compatible)
borderRadius: Float?
borderWidth: Float?
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
  peekPercentage: Float (0-100)
  
  # FREE_FLOW_GRID mode
  itemsPerView: Float (e.g., 2.5 = 2 full + 0.5 peek)
  
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
  "src": "{{imageUrl}}"            // IMAGE, VIDEO
}
```

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

## All Enumerations

### FontWeight
`LIGHT, NORMAL, MEDIUM, BOLD`

### TextDecoration
`NONE, UNDERLINE, STRIKETHROUGH`

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
- Colors must be hex format (#RRGGBB or #AARRGGBB - ARGB format)
- Opacity must be 0.0 to 1.0
- fontSize must be > 0
- Dimensions must have value and unit
- Spacing values must be non-negative

---

**All types**: Fully serializable with kotlinx.serialization  
**Ready for**: Claude Code integration and Kotlin implementation
