# Native Display System - Style & Theming Guide

**Updated**: January 2025

## Style System Overview

The Native Display System supports comprehensive styling through:
1. **Inline Styles** - Applied directly to elements
2. **Style Classes** - Reusable named styles
3. **Theme** - Global default styles
4. **Style Cascading** - Text properties inherited by children

---

## Style Properties

### Text Properties (Cascading)

Applied to text elements and inherited by child elements:

```kotlin
textColor: String            // Hex color (#RRGGBB or #RRGGBBAA)
fontSize: TextDimension      // Font size — number (platform units) or {"value", "unit"} object
fontFamily: String           // Font family name
fontWeight: FontWeight       // LIGHT, NORMAL, MEDIUM, BOLD
fontStyle: FontStyle         // NORMAL, ITALIC
lineHeight: TextDimension    // Line height — number (platform units) or {"value", "unit"} object
letterSpacing: Float         // Letter spacing in sp/pt
textDecoration: TextDecoration  // NONE, UNDERLINE, STRIKETHROUGH
textAlign: String            // "left", "center", "right", "justify"
maxLines: Int                // Maximum lines before truncation
overflow: TextOverflow       // CLIP, ELLIPSIS, VISIBLE
textShadow: TextShadow      // Drop shadow effect on text
textGradient: TextGradient   // Gradient effect on text
opacity: Float               // 0.0 to 1.0
```

#### TextDimension

`fontSize` and `lineHeight` accept two JSON formats (backward compatible):

| Format | Example | Meaning |
|--------|---------|---------|
| Raw number | `"fontSize": 16` | Platform units (SP on Android, points on iOS) |
| Object | `"fontSize": {"value": 40, "unit": "percent"}` | Percentage of root container height: `rootHeight × value / 1000` |

The divisor is **1000** (matching FE/dashboard behavior). For example, in a 400dp container, `{"value": 40, "unit": "percent"}` resolves to `400 × 40 / 1000 = 16` platform units.

**Example — platform units (legacy)**:
```json
{
  "style": {
    "textColor": "#212121",
    "fontSize": 16,
    "fontWeight": "bold",
    "fontStyle": "italic",
    "textAlign": "center",
    "lineHeight": 24,
    "letterSpacing": 1.5,
    "maxLines": 2,
    "overflow": "ellipsis",
    "textShadow": {
      "color": "#00000040",
      "offsetX": 2,
      "offsetY": 2,
      "blur": 4
    }
  }
}
```

**Example — percentage-based font sizing**:
```json
{
  "style": {
    "textColor": "#212121",
    "fontSize": { "value": 40, "unit": "percent" },
    "lineHeight": { "value": 56, "unit": "percent" },
    "fontWeight": "bold"
  }
}
```

### ⚠️ Important: lineHeight Cross-Platform Behavior

**Platform-Specific Defaults:**

When `lineHeight` is **not specified** in JSON, each platform uses different default calculations:

- **Android**: `lineHeight = fontSize × 1.5`
  - Example: `fontSize: 16` → lineHeight: `24sp`
- **iOS**: `lineHeight = fontSize × 1.176` (San Francisco font default)
  - Example: `fontSize: 16` → lineHeight: `18.8pt`

**Impact:**

This difference causes inconsistent rendering across platforms. For example, with a fixed container height of 160dp/pt:
- Android (24sp per text): Shows ~7 text elements
- iOS (18.8pt per text): Shows ~9 text elements

**Solution:**

**Always specify explicit `lineHeight` in JSON for cross-platform consistency:**

```json
{
  "style": {
    "fontSize": 16,
    "lineHeight": 20  // Explicit value ensures consistency
  }
}
```

**Recommended Values:**
- `lineHeight = fontSize × 1.4` - Balanced spacing for most use cases
- `lineHeight = fontSize × 1.5` - More breathing room (matches Android default)
- Custom values as needed for design requirements

**For Dashboard/JSON Generators:**

Always calculate and include `lineHeight` when generating configurations:
```typescript
const lineHeight = fontSize * 1.4;  // or user-specified value
```

This ensures WYSIWYG (What You See Is What You Get) behavior between preview and actual devices.

---

### Visual Properties (Non-cascading)

Applied to individual elements, not inherited:

```kotlin
background: Background          // Complex background support
backgroundColor: String         // Simple background color (hex)
borderRadius: Float            // Corner radius in dp
borderWidth: Float             // Border thickness in dp
borderColor: String            // Border color (hex)
shadowColor: String            // Shadow color (hex with alpha)
shadowRadius: Float            // Shadow blur radius in dp
shadowOffsetX: Float           // Shadow X offset in dp
shadowOffsetY: Float           // Shadow Y offset in dp
```

**Example**:
```json
{
  "style": {
    "backgroundColor": "#FFFFFF",
    "borderRadius": 12,
    "borderWidth": 1,
    "borderColor": "#E0E0E0",
    "shadowColor": "#00000020",
    "shadowRadius": 8,
    "shadowOffsetY": 4
  }
}
```

---

## Property Grouping and Extraction (SDK Internal)

### Overview

For SDK developers working on the renderer, style properties are organized into logical groups for better code maintainability. While clients continue to use the flat JSON structure, SDK internal code uses property extraction methods to access grouped properties.

### Property Groups

**Text Properties** - Used by TEXT and BUTTON elements:
- `textColor`, `fontSize` (TextDimension), `fontFamily`, `fontWeight`
- `lineHeight` (TextDimension), `textDecoration`, `textAlign`
- `opacity` (universal)

**Visual Properties** - Used by all elements for backgrounds:
- `background`, `backgroundColor`
- `opacity` (universal)

**Border Properties** - Used for visual decorations:
- `borderRadius`, `borderWidth`, `borderColor`

**Shadow Properties** - Used for visual decorations:
- `shadowColor`, `shadowRadius`, `shadowOffsetX`, `shadowOffsetY`

### Extraction Methods (SDK Internal)

#### Android (Kotlin)

```kotlin
// In renderer code
val textProps = resolvedStyle.extractTextProperties()
Text(
    text = text,
    color = parseColor(textProps.color) ?: Color.Black,
    fontSize = (textProps.size?.resolve(rootHeightPx) ?: 14f).sp,
    fontWeight = resolveFontWeight(textProps.weight)
)

val visualProps = resolvedStyle.extractVisualProperties()
if (visualProps.background != null) {
    modifier = modifier.applyBackground(visualProps.background)
}

val borderProps = resolvedStyle.extractBorderProperties()
val shape = RoundedCornerShape((borderProps.radius ?: 0f).dp)

val shadowProps = resolvedStyle.extractShadowProperties()
if (shadowProps.radius != null && shadowProps.radius > 0f) {
    modifier = modifier.shadow(elevation = shadowProps.radius.dp, shape = shape)
}
```

#### iOS (Swift)

```swift
// In renderer code
let textProps = resolvedStyle.extractTextProperties()
let resolvedSize = textProps.size?.resolve(containerHeight: rootHeight) ?? 14
Text(text)
    .foregroundColor(ColorParser.parse(textProps.color) ?? .primary)
    .font(.system(size: resolvedSize))
    .fontWeight(resolveFontWeight(textProps.weight))

let visualProps = resolvedStyle.extractVisualProperties()
if let background = visualProps.background {
    view.applyBackground(background)
}

let borderProps = style.extractBorderProperties()
let cornerRadius = borderProps.radius ?? 0

let shadowProps = style.extractShadowProperties()
if let radius = shadowProps.radius, radius > 0 {
    view.shadow(color: parseColor(shadowProps.color), radius: radius)
}
```

### Benefits for SDK Developers

✅ **Clear Intent** - Property groups make it obvious which properties apply to which elements
✅ **Better Organization** - Grouped property access instead of scattered individual accesses
✅ **Easier Maintenance** - Adding new properties is clearer when organized by group
✅ **No Breaking Changes** - JSON format unchanged, only internal SDK organization improved

### When to Use Extraction Methods

**Use property extraction when:**
- Rendering TEXT or BUTTON elements (use `extractTextProperties()`)
- Applying backgrounds (use `extractVisualProperties()`)
- Applying borders or shadows (use `extractBorderProperties()`, `extractShadowProperties()`)
- Writing new renderers or modifying existing ones

**Direct property access is still fine for:**
- Simple one-off property checks
- Style resolution and merging logic
- Cases where only 1-2 properties are needed

---

## Theme System

Define global default styles and color palette:

```json
{
  "theme": {
    "id": "default",
    "defaultStyle": {
      "textColor": "#212121",
      "fontSize": 14,
      "fontFamily": "System",
      "fontWeight": "normal"
    },
    "colors": {
      "primary": "#007AFF",
      "success": "#34C759",
      "warning": "#FF9500",
      "error": "#FF3B30",
      "neutral": "#8E8E93"
    }
  }
}
```

---

## Style Classes

Reusable style definitions:

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
    },
    {
      "name": "heading-1",
      "style": {
        "fontSize": 32,
        "fontWeight": "bold",
        "textColor": "#000000",
        "lineHeight": 40
      }
    }
  ]
}
```

---

## Style Resolution Order

1. **Theme Default Style** - Base default styles
2. **Style Class** - Reusable style definitions
3. **Inline Style** - Element-specific styles
4. **Parent Style** - Text properties inherited from parent containers

---

## Color System

Colors are specified in hexadecimal format:

```
#RRGGBB      // RGB with full opacity
#RRGGBBAA    // RGBA with alpha channel (AA = 00 transparent to FF opaque)
```

**Examples**:
```
#FFFFFF      // White
#000000      // Black
#FF0000      // Red
#FF000080    // Red with 50% opacity
#007AFF      // iOS Blue
```

---

## Background System

### Static Backgrounds

**Solid Color**:
```json
{
  "background": {
    "type": "solid",
    "color": "#FFFFFF"
  }
}
```

**Linear Gradient**:
```json
{
  "background": {
    "type": "linear_gradient",
    "angle": 45,
    "colors": ["#FF0000", "#FFFF00", "#00FF00"],
    "stops": [0, 0.5, 1]
  }
}
```

### Animated Backgrounds

**Shimmer Effect** (loading state):
```json
{
  "background": {
    "type": "shimmer",
    "baseColor": "#E0E0E0",
    "highlightColor": "#F5F5F5",
    "angle": 45,
    "duration": 1500,
    "loop": true
  }
}
```

---

## Styling Best Practices

1. **Use Theme** for consistency across your app
2. **Create Style Classes** for reusable component styles
3. **Keep Inline Styles** for element-specific variations only
4. **Leverage Cascading** for text properties in nested elements
5. **Test on Multiple Devices** to ensure responsive behavior

---

**Ready for**: Claude Code integration and production use
