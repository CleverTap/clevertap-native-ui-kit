# Native Display System - Components Guide

## Container Components

### 1. VERTICAL Container

**Purpose**: Stack child elements vertically (top to bottom)

**Example**:
```json
{
  "id": "user-profile",
  "containerType": "vertical",
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "padding": { "all": 16 },
    "arrangement": { "spacing": 12, "strategy": "spaced" }
  },
  "children": [...]
}
```

---

### 2. HORIZONTAL Container

**Purpose**: Stack child elements horizontally (left to right)

**Example**:
```json
{
  "id": "action-buttons",
  "containerType": "horizontal",
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 56, "unit": "dp" },
    "arrangement": { "spacing": 8, "strategy": "spaced" }
  },
  "children": [...]
}
```

---

### 3. BOX Container

**Purpose**: Layout container for flexible child arrangement

**Example**:
```json
{
  "id": "card-with-badge",
  "containerType": "box",
  "layout": {
    "width": { "value": 200, "unit": "dp" },
    "height": { "value": 200, "unit": "dp" }
  },
  "children": [...]
}
```

---

### 4. GALLERY Container

**Purpose**: Scrollable carousel with multiple layout modes

**Modes**:
- **SNAPPING**: Full-size items with snap behavior
- **FREE_FLOW**: Items define their own size
- **FREE_FLOW_GRID**: Fixed items per view

**Example**:
```json
{
  "id": "product-carousel",
  "containerType": "gallery",
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 300, "unit": "dp" }
  },
  "galleryConfig": {
    "mode": "snapping",
    "orientation": "horizontal",
    "snapBehavior": "center",
    "peekPercentage": 20,
    "spacing": 16,
    "showIndicators": true
  },
  "children": [...]
}
```

---

## Element Components

### 1. TEXT

**Bindings**: `text`

```json
{
  "id": "title",
  "elementType": "text",
  "bindings": { "text": "{{title}}" },
  "style": {
    "fontSize": 24,
    "fontWeight": "bold",
    "textColor": "#212121"
  }
}
```

---

### 2. IMAGE

**Bindings**: `src`

```json
{
  "id": "product-image",
  "elementType": "image",
  "bindings": { "src": "{{imageUrl}}" },
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 300, "unit": "dp" }
  },
  "style": { "borderRadius": 12 }
}
```

---

### 3. BUTTON

**Bindings**: `text`

```json
{
  "id": "submit-btn",
  "elementType": "button",
  "bindings": { "text": "{{buttonLabel}}" },
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 48, "unit": "dp" }
  },
  "style": {
    "backgroundColor": "#007AFF",
    "textColor": "#FFFFFF",
    "borderRadius": 8
  },
  "actions": {
    "onClick": {
      "type": "deeplink",
      "url": "app://action/submit"
    }
  }
}
```

---

### 4. VIDEO

**Bindings**: `src`

```json
{
  "id": "video-player",
  "elementType": "video",
  "bindings": { "src": "{{videoUrl}}" },
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 300, "unit": "dp" }
  }
}
```

---

### 5. SPACER

**Purpose**: Add spacing between elements

```json
{
  "id": "vertical-space",
  "elementType": "spacer",
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 16, "unit": "dp" }
  }
}
```

---

### 6. DIVIDER

**Purpose**: Visual divider/separator

```json
{
  "id": "divider",
  "elementType": "divider",
  "layout": {
    "width": { "value": 100, "unit": "percent" }
  },
  "dividerConfig": {
    "orientation": "horizontal",
    "thickness": 1,
    "color": "#E0E0E0"
  }
}
```

---

## Component Layout Best Practices

1. **Always define layout** for both containers and elements
2. **Use arrangement strategies** for container spacing
3. **Set explicit dimensions** when possible
4. **Use offsets** for absolute positioning in BOX containers
5. **Respect padding** for internal spacing
