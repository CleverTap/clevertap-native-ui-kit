# 🎨 New UI Elements: Divider & Gallery

## ✅ Added Features

### 1. **Divider Element** 
Simple separator for visual organization

### 2. **Gallery Container**
Full-featured carousel/slider with extensive configuration

---

## 📐 Divider Element

### Overview
A divider is a visual separator that helps organize content. Supports both horizontal and vertical orientations.

### Configuration

```kotlin
NativeDisplayElement(
    id = "my-divider",
    elementType = ElementType.DIVIDER,
    dividerConfig = DividerConfig(
        orientation = Orientation.HORIZONTAL,  // or VERTICAL
        thickness = 1f,                        // in dp
        color = "#DDDDDD"                      // hex color
    ),
    layout = Layout(
        margin = Spacing(top = 12f, bottom = 12f)
    )
)
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `orientation` | `Orientation` | `HORIZONTAL` | Direction of the divider |
| `thickness` | `Float` | `1f` | Thickness in dp |
| `color` | `String` | `"#DDDDDD"` | Hex color |

### Examples

**Horizontal Divider (Default)**
```kotlin
NativeDisplayElement(
    elementType = ElementType.DIVIDER,
    dividerConfig = DividerConfig(
        orientation = Orientation.HORIZONTAL,
        thickness = 1f,
        color = "#E0E0E0"
    )
)
```

**Thick Colored Divider**
```kotlin
NativeDisplayElement(
    elementType = ElementType.DIVIDER,
    dividerConfig = DividerConfig(
        thickness = 4f,
        color = "#007AFF"
    )
)
```

**Vertical Divider**
```kotlin
NativeDisplayElement(
    elementType = ElementType.DIVIDER,
    layout = Layout(
        width = Dimension.dp(1f),
        height = Dimension.dp(40f)
    ),
    dividerConfig = DividerConfig(
        orientation = Orientation.VERTICAL,
        color = "#999999"
    )
)
```

---

## 🎠 Gallery Container

### Overview
A powerful carousel/slider component with full configurability including:
- Multiple snap behaviors (free flow, center, start, end)
- Peek percentage (show parts of adjacent items)
- Navigation arrows
- Page indicators (dots)
- Auto-scroll
- Infinite scroll
- Horizontal/vertical orientation

### Basic Configuration

```kotlin
NativeDisplayContainer(
    id = "my-gallery",
    containerType = ContainerType.GALLERY,
    layout = Layout(
        width = Dimension.MATCH_PARENT,
        height = Dimension.dp(250f)
    ),
    galleryConfig = GalleryConfig(
        snapBehavior = SnapBehavior.CENTER,
        peekPercentage = 20f,
        showIndicators = true,
        showArrows = true
    ),
    children = listOf(/* your items */)
)
```

### Gallery Configuration Properties

#### Core Behavior

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `snapBehavior` | `SnapBehavior` | `CENTER` | How items snap: NONE, START, CENTER, END |
| `peekPercentage` | `Float` | `0f` | % of adjacent items visible (0-100) |
| `orientation` | `Orientation` | `HORIZONTAL` | Scroll direction |
| `initialPage` | `Int` | `0` | Starting page index |

#### Features

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `showArrows` | `Boolean` | `false` | Show navigation arrows |
| `showIndicators` | `Boolean` | `true` | Show page dots |
| `infiniteScroll` | `Boolean` | `false` | Enable loop scrolling |
| `autoScrollInterval` | `Long` | `0` | Auto-scroll delay in ms (0=disabled) |

#### Styling

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `arrowStyle` | `ArrowStyle?` | `null` | Arrow appearance config |
| `indicatorStyle` | `IndicatorStyle?` | `null` | Indicator appearance config |

### Snap Behaviors

**NONE** - Free scrolling
```kotlin
galleryConfig = GalleryConfig(
    snapBehavior = SnapBehavior.NONE,
    peekPercentage = 30f  // Show 30% of adjacent items
)
```

**CENTER** - One item centered (classic carousel)
```kotlin
galleryConfig = GalleryConfig(
    snapBehavior = SnapBehavior.CENTER,
    peekPercentage = 15f  // Show 15% on each side
)
```

**START** - Items snap to start
```kotlin
galleryConfig = GalleryConfig(
    snapBehavior = SnapBehavior.START
)
```

**END** - Items snap to end
```kotlin
galleryConfig = GalleryConfig(
    snapBehavior = SnapBehavior.END
)
```

### Arrow Configuration

```kotlin
ArrowStyle(
    size = 32f,                    // Size in dp
    color = "#FFFFFF",             // Arrow icon color
    backgroundColor = "#007AFF",   // Background circle color
    borderRadius = 20f,            // Corner radius
    padding = 8f,                  // Inner padding
    position = "inside"            // "inside" or "outside"
)
```

### Indicator Configuration

```kotlin
IndicatorStyle(
    size = 10f,                    // Dot size in dp
    activeColor = "#007AFF",       // Active page color
    inactiveColor = "#CCCCCC",     // Inactive pages color
    spacing = 8f,                  // Space between dots
    position = "bottom",           // "top", "bottom", "left", "right"
    shape = "circle"               // "circle" or "line"
)
```

### Complete Examples

#### Simple Gallery
```kotlin
NativeDisplayContainer(
    containerType = ContainerType.GALLERY,
    layout = Layout(
        width = Dimension.MATCH_PARENT,
        height = Dimension.dp(200f)
    ),
    galleryConfig = GalleryConfig(
        snapBehavior = SnapBehavior.CENTER,
        showIndicators = true,
        peekPercentage = 15f
    ),
    children = createItems()
)
```

#### Full-Featured Gallery
```kotlin
NativeDisplayContainer(
    containerType = ContainerType.GALLERY,
    layout = Layout(
        width = Dimension.MATCH_PARENT,
        height = Dimension.dp(250f)
    ),
    galleryConfig = GalleryConfig(
        snapBehavior = SnapBehavior.CENTER,
        showIndicators = true,
        showArrows = true,
        peekPercentage = 20f,
        autoScrollInterval = 3000,    // Auto-scroll every 3s
        infiniteScroll = true,
        arrowStyle = ArrowStyle(
            size = 32f,
            color = "#FFFFFF",
            backgroundColor = "#007AFF",
            borderRadius = 20f,
            padding = 8f
        ),
        indicatorStyle = IndicatorStyle(
            size = 10f,
            activeColor = "#007AFF",
            inactiveColor = "#CCCCCC",
            spacing = 8f,
            position = "bottom",
            shape = "circle"
        )
    ),
    children = createItems()
)
```

#### Free-Flow Gallery (No Snapping)
```kotlin
NativeDisplayContainer(
    containerType = ContainerType.GALLERY,
    galleryConfig = GalleryConfig(
        snapBehavior = SnapBehavior.NONE,
        showIndicators = false,
        showArrows = false,
        peekPercentage = 30f
    ),
    children = createItems()
)
```

#### Vertical Gallery
```kotlin
NativeDisplayContainer(
    containerType = ContainerType.GALLERY,
    layout = Layout(
        width = Dimension.dp(200f),
        height = Dimension.MATCH_PARENT
    ),
    galleryConfig = GalleryConfig(
        orientation = Orientation.VERTICAL,
        snapBehavior = SnapBehavior.CENTER,
        showIndicators = true
    ),
    children = createItems()
)
```

---

## 🎯 Use Cases

### Divider Use Cases
1. **Section Separator** - Between content sections
2. **List Divider** - Between list items
3. **Column Separator** - Vertical dividers in multi-column layouts
4. **Visual Break** - Create visual hierarchy

### Gallery Use Cases
1. **Product Carousel** - E-commerce product display
2. **Image Gallery** - Photo viewer
3. **Feature Showcase** - App features walkthrough
4. **Testimonial Slider** - Customer reviews
5. **Banner Carousel** - Promotional banners with auto-scroll
6. **Story Cards** - Instagram-style story viewer

---

## 📊 JSON Schema Examples

### Divider JSON
```json
{
  "type": "element",
  "id": "divider-1",
  "element_type": "divider",
  "divider_config": {
    "orientation": "horizontal",
    "thickness": 1.0,
    "color": "#DDDDDD"
  },
  "layout": {
    "margin": {
      "top": 12,
      "bottom": 12
    }
  }
}
```

### Gallery JSON
```json
{
  "type": "container",
  "id": "gallery-1",
  "container_type": "gallery",
  "gallery_config": {
    "snap_behavior": "center",
    "peek_percentage": 20.0,
    "show_arrows": true,
    "show_indicators": true,
    "infinite_scroll": true,
    "auto_scroll_interval": 3000,
    "arrow_style": {
      "size": 32.0,
      "color": "#FFFFFF",
      "background_color": "#007AFF",
      "border_radius": 20.0,
      "padding": 8.0,
      "position": "inside"
    },
    "indicator_style": {
      "size": 10.0,
      "active_color": "#007AFF",
      "inactive_color": "#CCCCCC",
      "spacing": 8.0,
      "position": "bottom",
      "shape": "circle"
    }
  },
  "layout": {
    "width": {"special": "match_parent"},
    "height": {"value": 250, "unit": "dp"}
  },
  "children": [
    // ... gallery items
  ]
}
```

---

## ✅ Testing

Sample configurations are provided in `NewElementsSamples.kt`:

```kotlin
// Test dividers
NewElementsSamples.dividerDemo()

// Test simple gallery
NewElementsSamples.simpleGallery()

// Test full-featured gallery
NewElementsSamples.fullFeaturedGallery()

// Test free-flow gallery
NewElementsSamples.freeFlowGallery()

// Test combined (dividers + gallery)
NewElementsSamples.combinedDemo()
```

---

## 🎨 Best Practices

### Divider
1. Use consistent thickness across your app
2. Use subtle colors (#E0E0E0, #DDDDDD) for non-intrusive separation
3. Add margin for proper spacing
4. Use thicker dividers (2-4dp) to emphasize major sections

### Gallery
1. **Peek Percentage**: 10-20% works well for most cases
2. **Auto-scroll**: 3-5 seconds is ideal for readability
3. **Indicators**: Keep them small (8-12dp) and subtle
4. **Arrows**: Use contrasting colors for visibility
5. **Height**: Ensure sufficient height for content (200dp+)
6. **Children**: 3-10 items work best for performance

---

## 🚀 Summary

### What Was Added

**Files Created:**
1. `GalleryConfig.kt` - Gallery configuration models
2. `NewElementsSamples.kt` - Sample demonstrations

**Files Updated:**
1. `Enums.kt` - Added DIVIDER, GALLERY, Orientation, SnapBehavior
2. `NativeDisplayNode.kt` - Added galleryConfig and dividerConfig
3. `NativeDisplayRenderer.kt` - Added rendering logic

**Features:**
- ✅ Divider element (horizontal/vertical)
- ✅ Gallery container with center snap
- ✅ Gallery with free-flow scrolling
- ✅ Gallery with peek percentage
- ✅ Navigation arrows (customizable)
- ✅ Page indicators (customizable)
- ✅ Auto-scroll capability
- ✅ Infinite scroll
- ✅ Vertical/horizontal orientation

---

**Your UI Kit is now even more powerful!** 🎉
