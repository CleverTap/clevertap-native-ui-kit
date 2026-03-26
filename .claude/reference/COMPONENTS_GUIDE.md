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
    "peek": {"before": 20, "after": 20},
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

**Bindings**: `url`

```json
{
  "id": "product-image",
  "elementType": "image",
  "bindings": { "url": "{{imageUrl}}" },
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 300, "unit": "dp" }
  },
  "style": { "borderRadius": 12 }
}
```

#### GIF / Animated Image Support

GIF animation is **auto-detected** from the URL in most cases (`.gif` extension, Giphy/Tenor/Gfycat/Imgur domains, paths containing `/gif/` or `/media/`). Use `imageConfig.animated` only when auto-detection cannot work:

```json
{
  "elementType": "image",
  "bindings": { "url": "https://api.example.com/image/123" },
  "imageConfig": {
    "fit": "crop",
    "animated": true
  }
}
```

| `imageConfig.animated` | Behaviour |
|---|---|
| `null` (default) | Auto-detect from URL |
| `true` | Force animation — use for API endpoints or CDN URLs without `.gif` extension |
| `false` | Show first frame only — disable animation |

**Platform**: Android uses `coil-gif`; iOS uses a custom GIF decoder with static-image fallback.

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

**Bindings**: `url` (required), `autoPlay`, `loop`, `muted`, `showControls`, `showFullscreen`

**Custom Controls**: The VIDEO element includes custom player controls (not platform default UI):
- **Play/Pause** - Toggle playback
- **Mute/Unmute** - Toggle audio
- **Fullscreen** - Enter/exit fullscreen mode (optional)
- **Tap to show/hide** - Controls auto-hide after 3 seconds
- **Configurable** - Use `showControls` to hide all controls, `showFullscreen` to hide fullscreen button

**Platform Requirements**:
- **Android**: Host app must add `androidx.media3:media3-exoplayer` dependency
- **iOS**: Built-in AVKit framework (no additional dependencies)

```json
{
  "id": "video-player",
  "elementType": "video",
  "bindings": {
    "url": "{{videoUrl}}",
    "autoPlay": "false",
    "loop": "true",
    "muted": "false",
    "showControls": "true",
    "showFullscreen": "true"
  },
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "height": { "value": 300, "unit": "dp" }
  },
  "style": {
    "borderRadius": 12,
    "backgroundColor": "#000000"
  }
}
```

---

### 5. HTML

**Bindings**: `html` (inline HTML string, primary) or `url` (load a URL). If both present, `html` wins.

**Platform Requirements**:
- **Android**: Uses `android.webkit.WebView` (built-in, no extra dependencies)
- **iOS**: Uses `WKWebView` (iOS only — tvOS gets a placeholder fallback)

**Performance Warning**: WebView is heavyweight. Avoid placing many HTML elements in scrollable containers (e.g., GALLERY). Each creates a separate WebView instance.

**Sizing**: HTML element requires explicit `layout.width`/`height` — no `wrap_content` auto-sizing (WebView content size is unknowable without JS measurement).

```json
{
  "id": "rich-content",
  "elementType": "html",
  "bindings": {
    "html": "<div style='color:white; padding:16px;'><h2>Welcome</h2><p>Rich HTML content here.</p></div>"
  },
  "htmlConfig": {
    "javascriptEnabled": false,
    "scrollEnabled": false,
    "baseUrl": "https://cdn.example.com",
    "transparentBackground": true
  },
  "layout": {
    "width": { "special": "match_parent" },
    "height": { "value": 200, "unit": "dp" }
  }
}
```

#### htmlConfig Options

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `javascriptEnabled` | boolean | `false` | Enable JavaScript execution |
| `scrollEnabled` | boolean | `false` | Allow scrolling within WebView |
| `baseUrl` | string | `null` | Base URL for resolving relative paths in inline HTML |
| `transparentBackground` | boolean | `true` | Transparent WebView background (allows container bg to show through) |

#### Hardcoded Behavior (not configurable)
- **No in-view navigation**: Link taps open in external browser
- **No file/universal access**: Security hardening
- **No zoom**: Pinch-to-zoom disabled
- **No text zoom scaling**: System font size changes don't affect HTML layout
- **Inline media playback**: On iOS (no fullscreen takeover)
- **CleverTap JS Bridge**: Injected automatically via reflection when CleverTap Core SDK is present at runtime. When absent, HTML renders without bridge — pure HTML still works.

---

### 6. SPACER

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

### 7. DIVIDER

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
