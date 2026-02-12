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
6. [Style System](#style-system)
7. [Background System](#background-system)
8. [Actions System](#actions-system)
9. [Complete Examples](#complete-examples)
10. [Validation Checklist](#validation-checklist)

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

### 4. STACK (ZStack)

Layers children on top of each other (z-index based on order).

```json
{
  "type": "container",
  "id": "myStack",
  "containerType": "stack",
  "children": [
    { /* background layer */ },
    { /* middle layer */ },
    { /* foreground layer */ }
  ]
}
```

**Use cases**: Overlays, backgrounds with content, layered designs

---

### 5. GALLERY

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
  "value": 100,           // Number
  "unit": "dp",           // "dp" | "sp" | "px" | "percent"
  "special": null         // null | "wrap_content" | "match_parent"
}
```

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

### Layout Object

```json
{
  "width": {"value": 200, "unit": "dp"},
  "height": {"value": 100, "unit": "dp"},
  "padding": {
    "all": 16,              // All sides
    // OR
    "horizontal": 16,       // Left + Right
    "vertical": 8,          // Top + Bottom
    // OR
    "top": 8,
    "bottom": 8,
    "left": 16,
    "right": 16,
    "unit": "dp"
  },
  "offset": {
    "x": 10,
    "y": 20,
    "unit": "dp"
  },
  "arrangement": {
    "spacing": 12,
    "spacingUnit": "dp",
    "strategy": "spaced"    // See Arrangement Strategies
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

- [ ] `containerType` is one of: `vertical`, `horizontal`, `box`, `stack`, `gallery`
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
