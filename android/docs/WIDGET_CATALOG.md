# Widget Catalog

Complete reference for all Native Display widgets, their properties, and usage examples.

---

## 📦 Containers

Containers hold and layout child elements.

### 1. VERTICAL Container

**Purpose:** Stack children vertically (column layout)

**Container Type:** `vertical`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `containerType` | string | `"vertical"` | Container type |
| `children` | array | `[]` | Child nodes |
| `layout.spacing` | number | `0` | Gap between children (dp) |
| `layout.padding` | object | `{all: 0}` | Internal padding |
| `style` | object | `{}` | Visual styling |

**Example:**

```json
{
  "type": "container",
  "id": "vertical_list",
  "containerType": "vertical",
  "layout": {
    "spacing": 12,
    "padding": {"all": 16}
  },
  "children": [
    {"type": "element", "elementType": "text", "bindings": {"text": "Item 1"}},
    {"type": "element", "elementType": "text", "bindings": {"text": "Item 2"}},
    {"type": "element", "elementType": "text", "bindings": {"text": "Item 3"}}
  ]
}
```

**Visual:**
```
┌───────────────┐
│  Item 1       │
│               │ spacing: 12dp
│  Item 2       │
│               │ spacing: 12dp
│  Item 3       │
└───────────────┘
```

---

### 2. HORIZONTAL Container

**Purpose:** Arrange children horizontally (row layout)

**Container Type:** `horizontal`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `containerType` | string | `"horizontal"` | Container type |
| `children` | array | `[]` | Child nodes |
| `layout.spacing` | number | `0` | Gap between children (dp) |
| `layout.padding` | object | `{all: 0}` | Internal padding |
| `style` | object | `{}` | Visual styling |

**Example:**

```json
{
  "type": "container",
  "id": "button_row",
  "containerType": "horizontal",
  "layout": {
    "spacing": 8,
    "padding": {"horizontal": 16, "vertical": 12}
  },
  "children": [
    {"type": "element", "elementType": "button", "bindings": {"text": "Cancel"}},
    {"type": "element", "elementType": "button", "bindings": {"text": "OK"}}
  ]
}
```

**Visual:**
```
┌────────────────────────┐
│  [Cancel]  [OK]        │
│     ↑         ↑        │
│     └─spacing:8dp─┘    │
└────────────────────────┘
```

---

### 3. BOX Container

**Purpose:** Single child with alignment control

**Container Type:** `box`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `containerType` | string | `"box"` | Container type |
| `children` | array | `[1 child]` | Single child (first one used) |
| `layout.alignment` | string | `"center"` | Child alignment |
| `layout.padding` | object | `{all: 0}` | Internal padding |
| `style` | object | `{}` | Visual styling |

**Alignment Values:**
- `"topStart"`, `"topCenter"`, `"topEnd"`
- `"centerStart"`, `"center"`, `"centerEnd"`
- `"bottomStart"`, `"bottomCenter"`, `"bottomEnd"`

**Example:**

```json
{
  "type": "container",
  "id": "centered_box",
  "containerType": "box",
  "layout": {
    "height": {"value": 200, "unit": "dp"},
    "padding": {"all": 20}
  },
  "style": {
    "backgroundColor": "#F5F5F5",
    "borderRadius": 12
  },
  "children": [
    {
      "type": "element",
      "elementType": "text",
      "bindings": {"text": "Centered Content"}
    }
  ]
}
```

**Visual:**
```
┌──────────────────────┐
│                      │
│                      │
│  Centered Content    │
│                      │
│                      │
└──────────────────────┘
```

---

### 4. STACK Container

**Purpose:** Layer children with z-index control

**Container Type:** `stack`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `containerType` | string | `"stack"` | Container type |
| `children` | array | `[]` | Layered children (first = bottom) |
| `layout.padding` | object | `{all: 0}` | Internal padding |
| `style` | object | `{}` | Visual styling |

**Child Positioning:**
- Use `layout.margin` for absolute positioning
- Negative margins for overlapping

**Example:**

```json
{
  "type": "container",
  "id": "overlapping_cards",
  "containerType": "stack",
  "style": {"backgroundColor": "#FFFFFF"},
  "children": [
    {
      "type": "container",
      "id": "card_1",
      "containerType": "box",
      "layout": {
        "width": {"value": 200, "unit": "dp"},
        "height": {"value": 100, "unit": "dp"}
      },
      "style": {"backgroundColor": "#FF0000"}
    },
    {
      "type": "container",
      "id": "card_2",
      "containerType": "box",
      "layout": {
        "width": {"value": 200, "unit": "dp"},
        "height": {"value": 100, "unit": "dp"},
        "margin": {"left": 20, "top": 20}
      },
      "style": {"backgroundColor": "#00FF00"}
    }
  ]
}
```

**Visual:**
```
┌─────────────────┐
│ Red Card        │
│  ┌──────────────┼──┐
│  │ Green Card   │  │
└──┼──────────────┘  │
   └──────────────────┘
```

---

### 5. GALLERY Container

**Purpose:** Scrolling container with 3 modes

**Container Type:** `gallery`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `containerType` | string | `"gallery"` | Container type |
| `children` | array | `[]` | Scrollable items |
| `galleryConfig` | object | required | Gallery configuration |

**Gallery Config:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `mode` | string | `"snapping"` | `"snapping"`, `"free_flow"`, `"free_flow_grid"` |
| `orientation` | string | `"horizontal"` | `"horizontal"` or `"vertical"` |
| `spacing` | number | `8` | Gap between items (dp) |
| `peek` | object | `{}` | `{"before": dp, "after": dp}` — adjacent card reveal (snapping mode only) |
| `itemsPerView` | number | `1` | Items visible (free_flow_grid mode only) |
| `columns` | number | `null` | Override itemsPerView with integer column count (free_flow_grid mode only) |
| `showIndicators` | boolean | `false` | Show page indicators |
| `autoScrollInterval` | number | `0` | Auto-scroll ms (0 = off) |

**Mode 1: SNAPPING (Carousel)**

```json
{
  "type": "container",
  "id": "image_carousel",
  "containerType": "gallery",
  "layout": {"height": {"value": 200, "unit": "dp"}},
  "galleryConfig": {
    "mode": "snapping",
    "orientation": "horizontal",
    "peek": {"before": 15, "after": 15},
    "showIndicators": true,
    "autoScrollInterval": 3000
  },
  "children": [
    {"type": "element", "elementType": "image", "bindings": {"url": "image1.jpg"}},
    {"type": "element", "elementType": "image", "bindings": {"url": "image2.jpg"}},
    {"type": "element", "elementType": "image", "bindings": {"url": "image3.jpg"}}
  ]
}
```

**Visual:**
```
┌────────────────────────────┐
│  [▓▓▓Image 1▓▓▓] [I] [I3]  │
│         ◄─────────►         │
│      Peek 15% each side     │
│         ● ○ ○               │
└────────────────────────────┘
```

**Mode 2: FREE_FLOW (Tags)**

```json
{
  "type": "container",
  "id": "tag_list",
  "containerType": "gallery",
  "galleryConfig": {
    "mode": "free_flow",
    "orientation": "horizontal",
    "spacing": 8
  },
  "children": [
    {"type": "element", "elementType": "text", "bindings": {"text": "Design"}},
    {"type": "element", "elementType": "text", "bindings": {"text": "Development"}},
    {"type": "element", "elementType": "text", "bindings": {"text": "UI"}}
  ]
}
```

**Visual:**
```
┌────────────────────────────┐
│ [Design] [Development] [UI]│
│   ↑          ↑          ↑  │
│   └─Self-sized by content──┘│
└────────────────────────────┘
```

**Mode 3: FREE_FLOW_GRID (Products)**

```json
{
  "type": "container",
  "id": "product_grid",
  "containerType": "gallery",
  "layout": {"height": {"value": 150, "unit": "dp"}},
  "galleryConfig": {
    "mode": "free_flow_grid",
    "orientation": "horizontal",
    "itemsPerView": 2.5,
    "spacing": 12
  },
  "children": [
    {"type": "container", "containerType": "box", "children": [...]},
    {"type": "container", "containerType": "box", "children": [...]},
    {"type": "container", "containerType": "box", "children": [...]}
  ]
}
```

**Visual:**
```
┌────────────────────────────┐
│ [═Product 1═][═Product 2═][═│
│      ↑            ↑        ↑ │
│      └─2.5 items visible───┘ │
└────────────────────────────┘
```

---

## 🎨 Elements

Elements are leaf nodes that display content.

### 1. TEXT Element

**Purpose:** Display text with typography

**Element Type:** `text`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `elementType` | string | `"text"` | Element type |
| `bindings.text` | string | required | Text to display |
| `style.textColor` | string | `"#000000"` | Text color (hex) |
| `style.fontSize` | number | `14` | Font size (sp) |
| `style.fontWeight` | string | `"normal"` | Weight: `"normal"`, `"bold"` |
| `style.textAlign` | string | `"start"` | Alignment: `"start"`, `"center"`, `"end"` |
| `style.lineHeight` | number | `null` | Line height multiplier |

**Example:**

```json
{
  "type": "element",
  "id": "title",
  "elementType": "text",
  "bindings": {
    "text": "Hello World"
  },
  "style": {
    "textColor": "#FF5722",
    "fontSize": 24,
    "fontWeight": "bold",
    "textAlign": "center"
  }
}
```

**Template Support:**

```json
{
  "bindings": {
    "text": "Welcome, {{user.name}}!"
  }
}
```

**Visual:**
```
┌──────────────────┐
│  Hello World     │
│  24sp, bold, red │
└──────────────────┘
```

---

### 2. IMAGE Element

**Purpose:** Display images from URL or base64

**Element Type:** `image`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `elementType` | string | `"image"` | Element type |
| `bindings.url` | string | required | Image URL or base64 |
| `layout.width` | dimension | required | Image width |
| `layout.height` | dimension | required | Image height |
| `style.borderRadius` | number | `0` | Corner radius (dp) |

**Example (URL):**

```json
{
  "type": "element",
  "id": "profile_image",
  "elementType": "image",
  "bindings": {
    "url": "https://example.com/avatar.jpg"
  },
  "layout": {
    "width": {"value": 100, "unit": "dp"},
    "height": {"value": 100, "unit": "dp"}
  },
  "style": {
    "borderRadius": 50
  }
}
```

**Example (Base64):**

```json
{
  "bindings": {
    "url": "data:image/png;base64,iVBORw0KGgoAAAANS..."
  }
}
```

**Visual:**
```
  ┌────────┐
  │  ╔══╗  │
  │  ║🖼 ║  │  100x100dp
  │  ╚══╝  │  Circular
  └────────┘
```

---

### 3. VIDEO Element

**Purpose:** Display and play videos

**Element Type:** `video`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `elementType` | string | `"video"` | Element type |
| `bindings.url` | string | required | Video URL |
| `bindings.autoPlay` | boolean | `false` | Auto-play on load |
| `bindings.loop` | boolean | `false` | Loop playback |
| `bindings.muted` | boolean | `false` | Mute audio |
| `layout.width` | dimension | required | Video width |
| `layout.height` | dimension | required | Video height |

**Example:**

```json
{
  "type": "element",
  "id": "promo_video",
  "elementType": "video",
  "bindings": {
    "url": "https://example.com/promo.mp4",
    "autoPlay": true,
    "loop": true,
    "muted": true
  },
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "height": {"value": 200, "unit": "dp"}
  },
  "style": {
    "borderRadius": 12
  }
}
```

**Visual:**
```
┌──────────────────────┐
│  ▶ ────○───── 🔇     │
│  [    Video         ]│
│  [    Content       ]│
│  [                  ]│
└──────────────────────┘
```

---

### 4. SPACER Element

**Purpose:** Add empty space

**Element Type:** `spacer`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `elementType` | string | `"spacer"` | Element type |
| `layout.width` | dimension | `0` | Spacer width |
| `layout.height` | dimension | `0` | Spacer height |

**Example (Fixed):**

```json
{
  "type": "element",
  "id": "gap",
  "elementType": "spacer",
  "layout": {
    "height": {"value": 24, "unit": "dp"}
  }
}
```

**Example (Flexible):**

```json
{
  "type": "element",
  "id": "flex_space",
  "elementType": "spacer",
  "layout": {
    "height": {"value": 1, "unit": "fill"}
  }
}
```

**Visual:**
```
Text Above
          } 24dp gap
Text Below
```

---

### 5. BUTTON Element

**Purpose:** Interactive clickable element

**Element Type:** `button`

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | string | required | Unique identifier |
| `elementType` | string | `"button"` | Element type |
| `bindings.text` | string | required | Button label |
| `actions.onClick` | action | `null` | Click action |
| `style` | object | `{}` | Visual styling |

**Example:**

```json
{
  "type": "element",
  "id": "submit_btn",
  "elementType": "button",
  "bindings": {
    "text": "Submit"
  },
  "style": {
    "backgroundColor": "#2196F3",
    "textColor": "#FFFFFF",
    "borderRadius": 8,
    "padding": {"horizontal": 24, "vertical": 12}
  },
  "actions": {
    "onClick": {
      "type": "openUrl",
      "data": {"url": "https://example.com/submit"}
    }
  }
}
```

**Visual:**
```
┌──────────────┐
│   Submit     │  Blue background
└──────────────┘  White text, rounded
```

---

## 📐 Layout Properties

Common to all widgets.

### Dimensions

```json
{
  "layout": {
    "width": {"value": 100, "unit": "dp"},
    "height": {"value": 200, "unit": "percent"}
  }
}
```

**Units:**
- `"dp"` - Density-independent pixels
- `"percent"` - Percentage of parent
- `"wrap"` - Fit content
- `"fill"` - Fill available space

### Spacing

```json
{
  "layout": {
    "padding": {
      "all": 16,
      "horizontal": 12,
      "vertical": 8,
      "left": 10,
      "top": 5,
      "right": 10,
      "bottom": 5
    },
    "margin": {
      "all": 16,
      "left": 20,
      "top": -10
    },
    "spacing": 12
  }
}
```

---

## 🎨 Style Properties

Visual appearance properties.

### Colors

```json
{
  "style": {
    "textColor": "#FF5722",
    "backgroundColor": "#F5F5F5",
    "borderColor": "#E0E0E0",
    "shadowColor": "#00000040"
  }
}
```

### Typography

```json
{
  "style": {
    "fontSize": 16,
    "fontWeight": "bold",
    "textAlign": "center",
    "lineHeight": 1.5
  }
}
```

**Font Weights:**
- `"normal"` - Regular (400)
- `"bold"` - Bold (700)

**Text Align:**
- `"start"` - Left (LTR), Right (RTL)
- `"center"` - Center
- `"end"` - Right (LTR), Left (RTL)

### Borders

```json
{
  "style": {
    "borderRadius": 12,
    "borderWidth": 2,
    "borderColor": "#2196F3"
  }
}
```

### Shadows

```json
{
  "style": {
    "shadowRadius": 4,
    "shadowColor": "#00000040",
    "shadowOffset": {"x": 0, "y": 2}
  }
}
```

### Effects

```json
{
  "style": {
    "opacity": 0.8
  }
}
```

---

## 🎭 Background Types

See [`BACKGROUND_SYSTEM.md`](./BACKGROUND_SYSTEM.md) for complete reference.

### Quick Reference

```json
{
  "style": {
    "background": {
      "type": "linear_gradient",
      "angle": 135,
      "colors": ["#667eea", "#764ba2"]
    }
  }
}
```

**Types:**
- `solid` - Single color
- `linear_gradient` - Linear gradient
- `radial_gradient` - Radial gradient
- `grid` - Grid pattern
- `dots` - Dot pattern
- `waves` - Wave pattern
- `pulse` - Animated pulse
- `shimmer` - Animated shimmer
- `smooth` - Smooth transitions
- `particle` - Floating particles
- `breathing` - Breathing animation

---

## 🔍 Visibility & Conditionals

```json
{
  "visible": "{{isLoggedIn}}",
  "children": [...]
}
```

When `isLoggedIn = false`, the node is not rendered.

---

## 🎯 Complete Example

E-commerce product card combining multiple widgets:

```json
{
  "type": "container",
  "id": "product_card",
  "containerType": "vertical",
  "layout": {
    "padding": {"all": 16},
    "spacing": 12
  },
  "style": {
    "backgroundColor": "#FFFFFF",
    "borderRadius": 12,
    "shadowRadius": 4,
    "shadowColor": "#00000015"
  },
  "children": [
    {
      "type": "element",
      "id": "product_image",
      "elementType": "image",
      "bindings": {"url": "{{product.imageUrl}}"},
      "layout": {
        "width": {"value": 100, "unit": "fill"},
        "height": {"value": 200, "unit": "dp"}
      },
      "style": {"borderRadius": 8}
    },
    {
      "type": "element",
      "id": "product_name",
      "elementType": "text",
      "bindings": {"text": "{{product.name}}"},
      "style": {
        "fontSize": 18,
        "fontWeight": "bold"
      }
    },
    {
      "type": "element",
      "id": "product_price",
      "elementType": "text",
      "bindings": {"text": "${{product.price}}"},
      "style": {
        "fontSize": 16,
        "textColor": "#2196F3",
        "fontWeight": "bold"
      }
    },
    {
      "type": "element",
      "id": "add_to_cart",
      "elementType": "button",
      "bindings": {"text": "Add to Cart"},
      "style": {
        "backgroundColor": "#4CAF50",
        "textColor": "#FFFFFF",
        "borderRadius": 8
      }
    }
  ]
}
```

---