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
textColor: String        // Hex color (#RRGGBB or #RRGGBBAA)
fontSize: Float          // Size in sp (scale-independent pixels)
fontFamily: String       // Font family name
fontWeight: FontWeight   // LIGHT, NORMAL, MEDIUM, BOLD
lineHeight: Float        // Line height in dp
letterSpacing: Float     // Letter spacing in dp
textDecoration: TextDecoration  // NONE, UNDERLINE, STRIKETHROUGH
textAlign: String        // "left", "center", "right"
opacity: Float           // 0.0 to 1.0
```

**Example**:
```json
{
  "style": {
    "textColor": "#212121",
    "fontSize": 16,
    "fontWeight": "bold",
    "textAlign": "center",
    "lineHeight": 24
  }
}
```

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
