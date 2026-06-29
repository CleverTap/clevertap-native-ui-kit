# Native Display JSON Structure Reference

## Complete JSON Structure Specification

This document provides a comprehensive guide to creating valid JSON configurations for the Native Display System.

---

## 📋 Table of Contents

1. [Root Configuration](#root-configuration)
2. [Node Types](#node-types)
3. [Container Types](#container-types)
4. [Element Types](#element-types)
5. [Layout System](#layout-system)
6. [Aspect Ratios](#aspect-ratios)
7. [Percentage-Based Layouts](#percentage-based-layouts)
8. [Style System](#style-system)
9. [Background System](#background-system)
10. [Actions System](#actions-system)
11. [Complete Examples](#complete-examples)
12. [Validation Checklist](#validation-checklist)

---

## Root Configuration

Every JSON must have this structure:

```json
{
  "theme": {
    "id": "string",
    "defaultStyle": { /* Style object */ },
    "colors": { /* Color palette */ }
  },
  "styleClasses": [ /* Optional array of StyleClass */ ],
  "variables": { /* Optional key-value pairs */ },
  "root": { /* NativeDisplayNode (REQUIRED) */ }
}
```

### Minimal Valid JSON

```json
{
  "theme": {
    "id": "default"
  },
  "root": {
    "type": "container",
    "id": "root",
    "containerType": "vertical",
    "children": []
  }
}
```

---

## Node Types

### CRITICAL: Every node MUST have a `type` field

There are **TWO** node types:

1. **`"type": "container"`** - Can contain children
2. **`"type": "element"`** - Leaf node, displays content

### Container Node Structure

```json
{
  "type": "container",           // REQUIRED
  "id": "unique_id",             // REQUIRED
  "containerType": "vertical",   // REQUIRED (see Container Types)
  "children": [],                // REQUIRED (can be empty array)
  "layout": {},                  // Optional
  "style": {},                   // Optional
  "styleClass": "className",     // Optional
  "visible": "{{expression}}",   // Optional
  "actions": {},                 // Optional
  "animation": {},               // Optional
  "galleryConfig": {},           // Optional (only for gallery)
  "dividerConfig": {}            // Optional
}
```

### Element Node Structure

```json
{
  "type": "element",             // REQUIRED
  "id": "unique_id",             // REQUIRED
  "elementType": "text",         // REQUIRED (see Element Types)
  "bindings": {},                // REQUIRED (can be empty object)
  "layout": {},                  // Optional
  "style": {},                   // Optional
  "styleClass": "className",     // Optional
  "visible": "{{expression}}",   // Optional
  "actions": {},                 // Optional
  "animation": {},               // Optional
  "dividerConfig": {}            // Optional (only for divider)
}
```

---

## Container Types

### 1. VERTICAL (Column/VStack)

Stacks children vertically (top to bottom).

```json
{
  "type": "container",
  "id": "myColumn",
  "containerType": "vertical",
  "children": [
    { /* child 1 */ },
    { /* child 2 */ }
  ]
}
```

**Use cases**: Forms, lists, vertical layouts

---

### 2. HORIZONTAL (Row/HStack)

Arranges children horizontally (left to right).

```json
{
  "type": "container",
  "id": "myRow",
  "containerType": "horizontal",
  "children": [
    { /* child 1 */ },
    { /* child 2 */ }
  ]
}
```

**Use cases**: Toolbars, horizontal menus, button rows

---

### 3. BOX

Centers a single child (or multiple overlapping children).

```json
{
  "type": "container",
  "id": "myBox",
  "containerType": "box",
  "children": [
    { /* centered child */ }
  ]
}
```

**Use cases**: Centering content, cards, modals

---

### 4. GALLERY

Scrollable collection with multiple modes.

```json
{
  "type": "container",
  "id": "myGallery",
  "containerType": "gallery",
  "galleryConfig": {
    "mode": "snapping",
    "orientation": "horizontal",
    "snapBehavior": "center",
    "peek": 20,
    "itemsPerView": 1.2
  },
  "children": [ /* gallery items */ ]
}
```

**Gallery Modes**:
- `"snapping"` - Pager with snapping
- `"free_flow"` - Natural scrolling
- `"free_flow_grid"` - Fixed items per view

---

## Element Types

### 1. TEXT

Displays text content.

```json
{
  "type": "element",
  "id": "myText",
  "elementType": "text",
  "bindings": {
    "text": "Hello World"
  },
  "style": {
    "fontSize": 16,
    "textColor": "#000000",
    "fontWeight": "bold",
    "textAlign": "center"
  }
}
```

**Binding keys**: `text`

---

### 2. IMAGE

Displays an image from URL or base64.

```json
{
  "type": "element",
  "id": "myImage",
  "elementType": "image",
  "bindings": {
    "url": "https://example.com/image.jpg"
  },
  "layout": {
    "width": {"value": 200, "unit": "dp"},
    "height": {"value": 150, "unit": "dp"}
  },
  "style": {
    "borderRadius": 12
  }
}
```

**Binding keys**: `url` or `base64`

---

### 3. BUTTON

Interactive button element.

```json
{
  "type": "element",
  "id": "myButton",
  "elementType": "button",
  "bindings": {
    "text": "Click Me"
  },
  "style": {
    "backgroundColor": "#FF5722",
    "textColor": "#FFFFFF",
    "borderRadius": 8
  },
  "actions": {
    "onClick": {
      "type": "open_url",
      "url": "https://example.com"
    }
  }
}
```

**Binding keys**: `text`

---

### 4. VIDEO

Plays video content.

```json
{
  "type": "element",
  "id": "myVideo",
  "elementType": "video",
  "bindings": {
    "url": "https://example.com/video.mp4",
    "autoPlay": "true",
    "loop": "false",
    "muted": "false"
  }
}
```

**Binding keys**: `url`, `autoPlay`, `loop`, `muted`

---

### 5. SPACER

Adds spacing (invisible element).

```json
{
  "type": "element",
  "id": "mySpacer",
  "elementType": "spacer",
  "bindings": {},
  "layout": {
    "height": {"value": 16, "unit": "dp"}
  }
}
```

**Note**: `bindings` must be present but can be empty `{}`

---

### 6. DIVIDER

Visual separator line.

```json
{
  "type": "element",
  "id": "myDivider",
  "elementType": "divider",
  "bindings": {},
  "dividerConfig": {
    "orientation": "horizontal",
    "thickness": 1,
    "color": "#E0E0E0"
  }
}
```

---

## Layout System

### Dimension Structure

```json
{
  "value": 100,           // Number (default: 0)
  "unit": "dp",           // "dp" | "sp" | "px" | "percent" (default: "dp")
  "special": null         // null | "wrap_content" | "match_parent" (default: null)
}
```

**Default Values for Backward Compatibility:**

All dimension properties have sensible defaults to ensure parsing doesn't fail if backend JSON omits certain fields:

- `value`: defaults to `0`
- `unit`: defaults to `"dp"`
- `special`: defaults to `null`

This means a minimal dimension can be:
```json
{}  // Valid! Will parse as {value: 0, unit: "dp", special: null}
```

**Implementation Notes:**
- **Android**: Uses `@Serializable` data class with default parameter values
- **iOS**: Uses custom `init(from decoder:)` with `decodeIfPresent` + `??` fallbacks for robust parsing

### Special Dimensions

```json
// Wrap content (fit to content size)
{"special": "wrap_content"}

// Match parent (fill available space)
{"special": "match_parent"}

// Fixed size
{"value": 100, "unit": "dp"}

// Percentage
{"value": 50, "unit": "percent"}
```

> **⚠️ Dashboard constraint — `percent` and `aspectRatio` only**
>
> The CleverTap dashboard generates JSON using **only** `percent` dimensions and `aspectRatio` for layout sizing. Fixed units (`dp`, `sp`, `px`) and special values (`wrap_content`, `match_parent`) are SDK-only features — they exist to support programmatic JSON creation and backward compatibility, but are **not emitted by the dashboard**.
>
> **Implication for new platform implementations**: All dimension types must still be correctly parsed and rendered (for hand-authored JSON and tests), but in production the renderer will almost exclusively receive `percent` + `aspectRatio`. Design tests accordingly and prioritise these paths.

### Layout Object

```json
{
  "width": {"value": 200, "unit": "dp"},
  "height": {"value": 100, "unit": "dp"},
  "aspectRatio": 1.5,            // Optional: width/height ratio
  "padding": {
    "all": 16,              // All sides (optional)
    // OR
    "horizontal": 16,       // Left + Right (optional)
    "vertical": 8,          // Top + Bottom (optional)
    // OR
    "top": 8,               // (optional)
    "bottom": 8,            // (optional)
    "left": 16,             // (optional)
    "right": 16,            // (optional)
    "unit": "dp"            // default: "dp"
  },
  "offset": {
    "x": 10,                // default: 0
    "y": 20,                // default: 0
    "unit": "dp"            // default: "dp"
  },
  "arrangement": {
    "spacing": 12,          // optional (used with "spaced" strategy)
    "spacingUnit": "dp",    // default: "dp"
    "strategy": "spaced"    // default: "spaced". See Arrangement Strategies
  }
}
```

### Arrangement Strategies

For `vertical` and `horizontal` containers:

- `"spaced"` - Fixed spacing between children
- `"space_between"` - Space between, not at edges
- `"space_evenly"` - Equal space everywhere
- `"space_around"` - Space around each child
- `"start"` - Align to start
- `"center"` - Center children
- `"end"` - Align to end
- `"spacing"` is needed only for `"spaced"` type of arrangement strategy, all others do not need any value for unit

---

## Aspect Ratios

### Using Aspect Ratios

Aspect ratios automatically calculate one dimension based on the other, maintaining a specific width-to-height proportion.

```json
{
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "aspectRatio": 1.5
  }
}
```

**How it works:**
- `aspectRatio` = width / height
- If `width` is **fixed (dp/sp/px)** + `aspectRatio`: height = fixedWidth / aspectRatio
- If `height` is **fixed (dp/sp/px)** + `aspectRatio`: width = fixedHeight × aspectRatio
- If `width` is **percent** + `aspectRatio`: **percent is ignored**; node uses full parent width; height = parentWidth / aspectRatio
- If no explicit dimensions + `aspectRatio`: uses full parent width; height = parentWidth / aspectRatio
- Common ratios: `1.0` (square), `1.777` (16:9), `0.75` (3:4 portrait)

### Aspect Ratio Examples

#### Square Image (1:1)
```json
{
  "type": "element",
  "id": "avatar",
  "elementType": "image",
  "bindings": {"url": "https://example.com/avatar.jpg"},
  "layout": {
    "width": {"value": 100, "unit": "dp"},
    "aspectRatio": 1.0
  }
}
```

#### 16:9 Video Container
```json
{
  "type": "container",
  "id": "videoContainer",
  "containerType": "box",
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "aspectRatio": 1.777
  }
}
```

#### Portrait Card (3:4)
```json
{
  "type": "container",
  "id": "card",
  "containerType": "vertical",
  "layout": {
    "width": {"value": 300, "unit": "dp"},
    "aspectRatio": 0.75
  }
}
```

### Aspect Ratio Sizing Resolution Priority

`aspectRatio` is applied **before** explicit width/height constraints. In priority order:

1. **Both width AND height are fixed (dp/sp/px)**: `aspectRatio` is **skipped**; explicit dimensions win.
2. **Only height is fixed (dp/sp/px)**: `aspectRatio` derives width = `fixedHeight × aspectRatio`.
3. **Only width is fixed (dp/sp/px)**: `aspectRatio` derives height = `fixedWidth / aspectRatio`.
4. **Width is percent + aspectRatio**: uses **full available parent width** (percent is ignored); height = `parentWidth / aspectRatio`.
5. **Height is percent + aspectRatio**: AR-derived height is used (percent height is ignored).
6. **No explicit width or height**: uses full parent width; height = `parentWidth / aspectRatio`.

> **⚠️ Critical**: A percent width does **not** constrain a node when `aspectRatio` is present.
> `"width": {"value": 80, "unit": "percent"}, "aspectRatio": 1.777` renders at **full parent width**, not 80%.
> This is consistent across Android, iOS, and Flutter.

---

## Percentage-Based Layouts

### How Percentages Work

Percentage dimensions are calculated relative to the **parent container's available space**.

```json
{
  "value": 50,
  "unit": "percent"
}
```

**Key Rules:**
- Percentages are calculated **after** parent's padding is applied
- For `width`, percentage is relative to parent's **content width**
- For `height`, percentage is relative to parent's **content height**
- Range: `0-100` (values outside this range may cause unexpected behavior)

### Percentage Calculation Formula

```
Child Size = (Parent Content Size × Percentage) / 100

Where Parent Content Size = Parent Size - Parent Padding
```

### Example: Percentage with Padding

```json
{
  "type": "container",
  "id": "parent",
  "containerType": "vertical",
  "layout": {
    "width": {"value": 400, "unit": "dp"},
    "padding": {"horizontal": 20}
  },
  "children": [
    {
      "type": "element",
      "id": "child",
      "elementType": "text",
      "bindings": {"text": "I'm 50% width"},
      "layout": {
        "width": {"value": 50, "unit": "percent"}
      }
    }
  ]
}
```

**Calculation:**
- Parent width: 400dp
- Parent padding: 20dp (left) + 20dp (right) = 40dp
- Parent content width: 400dp - 40dp = 360dp
- Child width: 360dp × 50% = **180dp**

### Full Width Pattern (100%)

```json
{
  "layout": {
    "width": {"value": 100, "unit": "percent"}
  }
}
```

This makes an element fill the entire width of its parent container (excluding parent padding).

### Responsive Grid with Percentages

```json
{
  "type": "container",
  "id": "grid",
  "containerType": "horizontal",
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "padding": {"all": 8}
  },
  "children": [
    {
      "type": "element",
      "id": "col1",
      "elementType": "text",
      "bindings": {"text": "Column 1"},
      "layout": {
        "width": {"value": 33.33, "unit": "percent"}
      }
    },
    {
      "type": "element",
      "id": "col2",
      "elementType": "text",
      "bindings": {"text": "Column 2"},
      "layout": {
        "width": {"value": 33.33, "unit": "percent"}
      }
    },
    {
      "type": "element",
      "id": "col3",
      "elementType": "text",
      "bindings": {"text": "Column 3"},
      "layout": {
        "width": {"value": 33.34, "unit": "percent"}
      }
    }
  ]
}
```

### Percentage + Aspect Ratio

Combine percentages with aspect ratios for responsive, proportional layouts:

```json
{
  "type": "element",
  "id": "responsiveImage",
  "elementType": "image",
  "bindings": {"url": "https://example.com/image.jpg"},
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "aspectRatio": 1.5
  }
}
```

**Result:**
- Width adapts to parent (e.g., 300dp on small screen, 600dp on large screen)
- Height automatically adjusts (e.g., 200dp and 400dp respectively)

### Percentage Limitations

**❌ Don't use percentages when:**
- Parent has `wrap_content` dimension (unpredictable results)
- Creating fixed-size elements that shouldn't scale
- Circular dependencies exist (parent depends on child, child on parent)

**✅ Do use percentages for:**
- Responsive layouts that adapt to screen size
- Proportional spacing and grids
- Full-width/height elements
- Elements that should scale with their container

### Percentage in Different Container Types

#### VERTICAL Container
```json
{
  "type": "container",
  "containerType": "vertical",
  "layout": {
    "width": {"value": 300, "unit": "dp"},
    "height": {"value": 400, "unit": "dp"}
  },
  "children": [
    {
      "layout": {
        "width": {"value": 80, "unit": "percent"},    // 80% of 300dp = 240dp
        "height": {"value": 25, "unit": "percent"}    // 25% of 400dp = 100dp
      }
    }
  ]
}
```

#### HORIZONTAL Container
```json
{
  "type": "container",
  "containerType": "horizontal",
  "layout": {
    "width": {"value": 500, "unit": "dp"}
  },
  "children": [
    {
      "layout": {
        "width": {"value": 40, "unit": "percent"}     // 40% of 500dp = 200dp
      }
    },
    {
      "layout": {
        "width": {"value": 60, "unit": "percent"}     // 60% of 500dp = 300dp
      }
    }
  ]
}
```

#### BOX Container
```json
{
  "type": "container",
  "containerType": "box",
  "layout": {
    "width": {"value": 400, "unit": "dp"},
    "height": {"value": 300, "unit": "dp"}
  },
  "children": [
    {
      "layout": {
        "width": {"value": 100, "unit": "percent"},   // Fills entire box width
        "height": {"value": 100, "unit": "percent"}   // Fills entire box height
      }
    }
  ]
}
```

### Best Practices

1. **Use percentages for responsive layouts** that need to adapt to different screen sizes
2. **Combine with aspectRatio** to maintain proportions while scaling
3. **Avoid mixing** percentage children with `match_parent` in the same container
4. **Be mindful of padding** - percentages calculate from content area, not total size
5. **Test on multiple screen sizes** to ensure responsive behavior works as expected
6. **Use fixed dimensions (dp)** for elements that should remain constant across devices

---

## Style System

### Complete Style Object

```json
{
  "textColor": "#000000",
  "fontSize": 16,
  "fontFamily": "System",
  "fontWeight": "normal",        // "normal" | "medium" | "bold" | "light"
  "lineHeight": 20,
  "textDecoration": "none",      // "none" | "underline" | "strikethrough"
  "textAlign": "left",           // "left" | "center" | "right"
  
  "background": { /* Background object */ },
  "backgroundColor": "#FFFFFF",
  
  "borderRadius": 8,
  "borderWidth": 1,
  "borderColor": "#E0E0E0",
  
  "shadowColor": "#000000",
  "shadowRadius": 4,
  "shadowOffsetX": 0,
  "shadowOffsetY": 2,
  
  "opacity": 1.0
}
```

### Color Format

Colors must be hex strings:

```json
"#RRGGBB"      // RGB
"#AARRGGBB"    // ARGB (with alpha)
```

Examples:
- `"#FF5722"` - Orange
- `"#80FF5722"` - Orange with 50% opacity

---

## Background System

### Solid Color

```json
{
  "type": "solid",
  "color": "#FF5722"
}
```

### Linear Gradient

```json
{
  "type": "linear_gradient",
  "angle": 45,
  "colors": ["#FF5722", "#FFC107"],
  "stops": [0.0, 1.0]
}
```

### Radial Gradient

```json
{
  "type": "radial_gradient",
  "center_x": 0.5,
  "center_y": 0.5,
  "radius": 1.0,
  "colors": ["#FF5722", "#FFC107"]
}
```

### Image Background

```json
{
  "type": "image",
  "url": "https://example.com/bg.jpg",
  "fit": "cover",           // "cover" | "contain" | "fill" | "tile"
  "opacity": 1.0,
  "blur": 0,
  "tint": "#000000",
  "tint_opacity": 0.3
}
```

### Animated Backgrounds

```json
{
  "type": "shimmer",
  "base_color": "#E0E0E0",
  "highlight_color": "#FFFFFF",
  "angle": 45,
  "duration": 1500,
  "loop": true
}
```

```json
{
  "type": "pulse",
  "color": "#FF5722",
  "min_opacity": 0.3,
  "max_opacity": 1.0,
  "duration": 1000,
  "loop": true
}
```

---

## Actions System

### Action Triggers

Actions are defined in the `actions` object with trigger keys:

```json
{
  "actions": {
    "onClick": { /* Action */ },
    "onLongPress": { /* Action */ },
    "onDoubleTap": { /* Action */ },
    "onAppear": { /* Action */ },
    "onDisappear": { /* Action */ }
  }
}
```

### Action Types

#### Open URL

```json
{
  "type": "open_url",
  "url": "https://example.com",
  "openInBrowser": false,
  "customTabsEnabled": true
}
```

#### Navigate

```json
{
  "type": "navigate",
  "destination": "ProfileScreen",
  "params": {
    "userId": "123"
  }
}
```

#### Track Event

```json
{
  "type": "event",
  "eventName": "ButtonClicked",
  "properties": {
    "buttonId": "myButton",
    "timestamp": "2024-01-01"
  }
}
```

#### Custom Action

```json
{
  "type": "custom",
  "key": "showDialog",
  "value": true,
  "metadata": {
    "title": "Hello"
  }
}
```

#### Composite Action

```json
{
  "type": "composite",
  "executionMode": "sequential",    // "sequential" | "parallel"
  "actions": [
    { "type": "event", "eventName": "Click" },
    { "type": "open_url", "url": "https://example.com" }
  ]
}
```

---

## Complete Examples

### Example 1: Simple Card

```json
{
  "theme": {
    "id": "default"
  },
  "root": {
    "type": "container",
    "id": "card",
    "containerType": "vertical",
    "layout": {
      "padding": {"all": 16}
    },
    "style": {
      "backgroundColor": "#FFFFFF",
      "borderRadius": 12,
      "shadowRadius": 8,
      "shadowColor": "#000000"
    },
    "children": [
      {
        "type": "element",
        "id": "title",
        "elementType": "text",
        "bindings": {
          "text": "Card Title"
        },
        "style": {
          "fontSize": 20,
          "fontWeight": "bold"
        }
      },
      {
        "type": "element",
        "id": "spacer",
        "elementType": "spacer",
        "bindings": {},
        "layout": {
          "height": {"value": 12, "unit": "dp"}
        }
      },
      {
        "type": "element",
        "id": "description",
        "elementType": "text",
        "bindings": {
          "text": "This is a description"
        },
        "style": {
          "fontSize": 14,
          "textColor": "#666666"
        }
      }
    ]
  }
}
```

### Example 2: Button Row

```json
{
  "theme": {
    "id": "default"
  },
  "root": {
    "type": "container",
    "id": "buttonRow",
    "containerType": "horizontal",
    "layout": {
      "padding": {"all": 16}
    },
    "children": [
      {
        "type": "element",
        "id": "cancelBtn",
        "elementType": "button",
        "bindings": {"text": "Cancel"},
        "layout": {
          "padding": {"horizontal": 24, "vertical": 12}
        },
        "style": {
          "backgroundColor": "#E0E0E0",
          "borderRadius": 8
        }
      },
      {
        "type": "element",
        "id": "spacer",
        "elementType": "spacer",
        "bindings": {},
        "layout": {
          "width": {"value": 12, "unit": "dp"}
        }
      },
      {
        "type": "element",
        "id": "confirmBtn",
        "elementType": "button",
        "bindings": {"text": "Confirm"},
        "layout": {
          "padding": {"horizontal": 24, "vertical": 12}
        },
        "style": {
          "backgroundColor": "#FF5722",
          "textColor": "#FFFFFF",
          "borderRadius": 8
        },
        "actions": {
          "onClick": {
            "type": "event",
            "eventName": "ConfirmClicked"
          }
        }
      }
    ]
  }
}
```

---

## Validation Checklist

### ✅ Required Fields

- [ ] Root object has `theme` with `id`
- [ ] Root object has `root` node
- [ ] Every node has `"type"` field (`"container"` or `"element"`)
- [ ] Every node has unique `"id"` field
- [ ] Containers have `"containerType"` field
- [ ] Containers have `"children"` array (can be empty)
- [ ] Elements have `"elementType"` field
- [ ] Elements have `"bindings"` object (can be empty)

### ✅ Type Values

- [ ] `containerType` is one of: `vertical`, `horizontal`, `box`, `gallery`
- [ ] `elementType` is one of: `text`, `image`, `button`, `video`, `spacer`, `divider`
- [ ] `fontWeight` (if used) is one of: `normal`, `medium`, `bold`, `light`

### ✅ Structure

- [ ] All arrays use `[]` not missing
- [ ] All objects use `{}` not missing
- [ ] No trailing commas
- [ ] Strings use double quotes `"`
- [ ] Colors are hex format `#RRGGBB` or `#RRGGBBAA`

### ✅ Dimensions

- [ ] Dimension objects have `value` and `unit`
- [ ] OR have `special` field only
- [ ] Unit is one of: `dp`, `sp`, `px`, `percent`
- [ ] Special is: `wrap_content` or `match_parent`
- [ ] Percentage values are between 0-100
- [ ] `aspectRatio` is a positive number (if used)
- [ ] When using percentages, parent has fixed or `match_parent` dimensions

### ✅ Common Mistakes

- [ ] NOT using capital letters (`VERTICAL` ❌ should be `vertical` ✅)
- [ ] NOT missing `"type"` field on nodes
- [ ] NOT forgetting `"bindings": {}` on elements
- [ ] NOT using `{"dp": 16}` format ❌ (should be `{"value": 16, "unit": "dp"}` ✅)

---

## Quick Reference

### Minimal Container

```json
{
  "type": "container",
  "id": "myId",
  "containerType": "vertical",
  "children": []
}
```

### Minimal Element

```json
{
  "type": "element",
  "id": "myId",
  "elementType": "text",
  "bindings": {"text": "Hello"}
}
```

### Common Pattern: Spacer

```json
{
  "type": "element",
  "id": "spacer",
  "elementType": "spacer",
  "bindings": {},
  "layout": {
    "height": {"value": 16, "unit": "dp"}
  }
}
```

### Common Pattern: Full Width with Aspect Ratio

```json
{
  "type": "element",
  "id": "responsiveImage",
  "elementType": "image",
  "bindings": {"url": "https://example.com/image.jpg"},
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "aspectRatio": 1.5
  }
}
```

### Common Pattern: Responsive Grid (3 columns)

```json
{
  "type": "container",
  "id": "grid",
  "containerType": "horizontal",
  "children": [
    {
      "id": "col1",
      "layout": {"width": {"value": 33.33, "unit": "percent"}}
    },
    {
      "id": "col2",
      "layout": {"width": {"value": 33.33, "unit": "percent"}}
    },
    {
      "id": "col3",
      "layout": {"width": {"value": 33.34, "unit": "percent"}}
    }
  ]
}
```

---

## Validation Tools

Use this checklist when creating JSON:

1. ✅ Valid JSON syntax (use JSON validator)
2. ✅ All required fields present
3. ✅ Correct enum values (lowercase)
4. ✅ Proper dimension format
5. ✅ No orphaned nodes (all in tree)
6. ✅ Unique IDs throughout
7. ✅ Bindings object on elements
8. ✅ Children array on containers

---

**For complete specification and advanced features, refer to the source code models.**
