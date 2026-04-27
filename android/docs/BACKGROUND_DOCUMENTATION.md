# 🎨 Background System - Complete API Reference

> **The definitive guide to the Native Display Kit background system.**  
> Use this as your primary reference for implementing backgrounds in your server-driven UI.

---

## 📋 Quick Reference

### Supported Background Types

The Native Display Kit supports **11 background types** that can be applied to **any container or element**:

| Type | Description | Use Case | Performance |
|------|-------------|----------|-------------|
| **Solid** | Simple color | Basic backgrounds | ✅ Excellent |
| **LinearGradient** | Straight color blend | Modern cards, buttons | ✅ Excellent |
| **RadialGradient** | Center-outward blend | Spotlights, badges | ✅ Good |
| **SweepGradient** | Circular sweep (conic) | Progress, spinners | ✅ Good |
| **Image** | Image with effects | Heroes, headers | ⚠️ Medium |
| **Shimmer** | Loading animation | Skeleton screens | ⚠️ Medium |
| **AnimatedGradient** | Animated colors | Premium features | ⚠️ Medium |
| **Pulse** | Breathing effect | Live status | ✅ Good |
| **Pattern** | Repeating designs (7 types) | Textures, decoration | ✅ Good |
| **Particles** | Moving particles | Celebrations | ⛔ Heavy |
| **Layered** | Stack multiple backgrounds | Complex designs | ⚠️ Varies |

---

## 🎯 Universal Application

**Backgrounds work on ANY node in your UI tree:**

### ✅ Containers
```json
{
  "type": "container",
  "container_type": "vertical",
  "style": {
    "background": {
      "type": "linear_gradient",
      "angle": 45,
      "colors": ["#667eea", "#764ba2"]
    }
  }
}
```

### ✅ Elements
```json
{
  "type": "element",
  "element_type": "text",
  "style": {
    "background": {
      "type": "solid",
      "color": "#FF6B6B"
    }
  }
}
```

### ✅ Nested Structures
```json
{
  "type": "container",
  "container_type": "box",
  "style": {
    "background": {
      "type": "layered",
      "layers": [
        {"type": "image", "url": "bg.jpg"},
        {
          "type": "linear_gradient",
          "colors": ["#00000000", "#000000AA"]
        }
      ]
    }
  },
  "children": [
    {
      "type": "element",
      "element_type": "text",
      "style": {
        "background": {
          "type": "shimmer",
          "base_color": "#E0E0E0"
        }
      }
    }
  ]
}
```

---

## 🚀 Key Features

### 🎨 Rich Visual Effects
- **3 gradient types** (linear, radial, sweep)
- **4 animation types** (shimmer, animated gradient, pulse, particles)
- **7 pattern types** (dots, stripes, grid, checkerboard, etc.)
- **Unlimited layering** for complex compositions

### ⚡ Performance Optimized
- **Cached patterns** for instant rendering
- **GPU-accelerated animations** on supported devices
- **Smart rendering** only when needed
- **Battery-aware** animation handling

### 🔄 Flexible & Compatible
- **Works everywhere** - containers, elements, any nesting level
- **Backward compatible** - old `backgroundColor` still works
- **JSON-driven** - configure from server without app updates
- **Type-safe** - full Kotlin model support

### 🎯 Production Ready
- **15+ sample configurations** included
- **Battle-tested** design patterns
- **Performance guidelines** for every type
- **Best practices** documented

---

## 📖 Complete Type Reference

### 1. Solid ⭐
**Simple color background**

```json
{
  "background": {
    "type": "solid",
    "color": "#FF6B6B"
  }
}
```

**Properties**:
- `color`: Hex color string (required)

**Use Cases**:
- Simple colored backgrounds
- Replacement for `backgroundColor`
- Solid button colors

**Performance**: ✅ Excellent (no overhead)

---

### 2. LinearGradient ⭐⭐⭐
**Colors blend in a straight line**

```json
{
  "background": {
    "type": "linear_gradient",
    "angle": 45,
    "colors": ["#FF6B6B", "#4ECDC4"],
    "stops": [0.0, 1.0]
  }
}
```

**Properties**:
- `angle`: Gradient angle in degrees (0-360)
  - `0`: Right to left
  - `90`: Bottom to top
  - `180`: Top to bottom
  - `270`: Left to right
  - `45`, `135`: Diagonals
- `colors`: Array of hex colors (minimum 2)
- `stops`: Optional array of stop positions (0.0 to 1.0)

**Common Angles**:
```kotlin
// Horizontal (left to right)
angle = 270

// Vertical (top to bottom)
angle = 180

// Diagonal (top-left to bottom-right)
angle = 135

// Diagonal (bottom-left to top-right)
angle = 45
```

**Use Cases**:
- Modern card headers
- Button backgrounds
- Hero sections
- Brand colors
- Navigation bars

**Performance**: ✅ Excellent

---

### 3. RadialGradient ⭐⭐
**Colors blend from center outward**

```json
{
  "background": {
    "type": "radial_gradient",
    "center_x": 0.5,
    "center_y": 0.5,
    "radius": 1.0,
    "colors": ["#FFFFFF", "#000000"],
    "stops": [0.0, 1.0]
  }
}
```

**Properties**:
- `center_x`: Center X position (0.0 to 1.0, default 0.5)
- `center_y`: Center Y position (0.0 to 1.0, default 0.5)
- `radius`: Radius multiplier (default 1.0)
- `colors`: Array of hex colors (minimum 2)
- `stops`: Optional stop positions (0.0 to 1.0)

**Center Positions**:
```kotlin
// Center
center_x = 0.5, center_y = 0.5

// Top-left
center_x = 0.0, center_y = 0.0

// Bottom-right
center_x = 1.0, center_y = 1.0
```

**Use Cases**:
- Spotlight effects
- Focus indicators
- Circular buttons
- Badge backgrounds
- Vignette effects

**Performance**: ✅ Good

---

### 4. SweepGradient ⭐
**Colors blend in circular sweep (conic)**

```json
{
  "background": {
    "type": "sweep_gradient",
    "center_x": 0.5,
    "center_y": 0.5,
    "start_angle": 0,
    "colors": ["#FF0000", "#00FF00", "#0000FF", "#FF0000"]
  }
}
```

**Properties**:
- `center_x`: Center X position (0.0 to 1.0, default 0.5)
- `center_y`: Center Y position (0.0 to 1.0, default 0.5)
- `start_angle`: Starting angle in degrees (default 0)
- `colors`: Array of hex colors (minimum 2)
- `stops`: Optional stop positions (0.0 to 1.0)

**Use Cases**:
- Loading spinners
- Progress indicators  
- Color pickers
- Circular UI elements
- Clock faces

**Performance**: ✅ Good

---

### 5. Image ⭐⭐⭐
**Image background with effects**

```json
{
  "background": {
    "type": "image",
    "url": "https://example.com/image.jpg",
    "fit": "cover",
    "opacity": 1.0,
    "blur": 0,
    "tint": "#000000",
    "tint_opacity": 0.4
  }
}
```

**Properties**:
- `url`: Image URL (required)
- `fit`: How image fits container
  - `cover`: Fill and crop (default)
  - `contain`: Fit within bounds
  - `fill`: Stretch to fill
  - `tile`: Repeat pattern
- `opacity`: Image opacity (0.0 to 1.0, default 1.0)
- `blur`: Blur radius in dp (0 = no blur)
- `tint`: Overlay color (hex)
- `tint_opacity`: Tint opacity (0.0 to 1.0, default 1.0)

**Common Patterns**:

**Hero Section**:
```json
{
  "url": "hero.jpg",
  "fit": "cover",
  "opacity": 0.7,
  "tint": "#000000",
  "tint_opacity": 0.5
}
```

**Blurred Background**:
```json
{
  "url": "bg.jpg",
  "fit": "cover",
  "blur": 20,
  "opacity": 0.8
}
```

**Use Cases**:
- Hero sections
- Category cards
- Profile headers
- Marketing banners
- Background imagery

**Performance**: ⚠️ Medium (network, memory, caching)

---

### 6. Shimmer ⭐⭐⭐
**Animated shimmer effect (loading)**

```json
{
  "background": {
    "type": "shimmer",
    "base_color": "#E0E0E0",
    "highlight_color": "#F5F5F5",
    "angle": 45,
    "duration": 1500,
    "loop": true
  }
}
```

**Properties**:
- `base_color`: Base background color (hex, required)
- `highlight_color`: Shimmer highlight color (hex, required)
- `angle`: Shimmer angle in degrees (default 45)
- `duration`: Animation duration in ms (default 1500)
- `loop`: Loop animation continuously (default true)

**Common Configurations**:

**Light Theme**:
```json
{
  "base_color": "#E0E0E0",
  "highlight_color": "#F5F5F5",
  "duration": 1500
}
```

**Dark Theme**:
```json
{
  "base_color": "#2A2A2A",
  "highlight_color": "#3A3A3A",
  "duration": 1500
}
```

**Use Cases**:
- Skeleton screens (industry standard)
- Loading placeholders
- Content loading states
- Empty state animations

**Performance**: ⚠️ Medium (animated, but optimized)

---

### 7. AnimatedGradient ⭐⭐
**Gradient with animated colors**

```json
{
  "background": {
    "type": "animated_gradient",
    "gradient_type": "linear",
    "angle": 45,
    "colors": ["#FFD700", "#FFA500", "#FFD700"],
    "duration": 3000,
    "loop": true,
    "animation_style": "smooth"
  }
}
```

**Properties**:
- `gradient_type`: `linear`, `radial`, or `sweep`
- `angle`: For linear gradients (degrees)
- `colors`: Array of colors to animate (3+ recommended)
- `duration`: Animation duration in ms
- `loop`: Loop animation (default true)
- `animation_style`:
  - `smooth`: Colors blend smoothly
  - `shift`: Colors shift positions
  - `pulse`: Colors pulse intensity

**Use Cases**:
- Premium badges
- Special features
- Attention-grabbing elements
- Limited-time offers
- VIP sections

**Performance**: ⚠️ Medium (animated, CPU usage)

---

### 8. Pulse ⭐⭐
**Pulsing opacity effect**

```json
{
  "background": {
    "type": "pulse",
    "color": "#FF6B6B",
    "min_opacity": 0.3,
    "max_opacity": 1.0,
    "duration": 1000,
    "loop": true
  }
}
```

**Properties**:
- `color`: Background color (hex, required)
- `min_opacity`: Minimum opacity (0.0 to 1.0, default 0.3)
- `max_opacity`: Maximum opacity (0.0 to 1.0, default 1.0)
- `duration`: Pulse duration in ms (default 1000)
- `loop`: Loop animation (default true)

**Use Cases**:
- Live indicators
- Recording states
- Active status
- Notifications
- Breathing effects

**Performance**: ✅ Good (simple animation)

---

### 9. Pattern ⭐⭐
**Repeating visual patterns**

```json
{
  "background": {
    "type": "pattern",
    "pattern_type": "dots",
    "primary_color": "#F0F0F0",
    "secondary_color": "#E0E0E0",
    "size": 20,
    "spacing": 30,
    "opacity": 1.0
  }
}
```

**Properties**:
- `pattern_type`:
  - `dots`: Small dots
  - `stripes_horizontal`: Horizontal lines
  - `stripes_vertical`: Vertical lines
  - `stripes_diagonal`: Diagonal lines
  - `grid`: Grid lines
  - `checkerboard`: Checker pattern
  - `polka_dots`: Larger dots
- `primary_color`: Base color (hex, required)
- `secondary_color`: Pattern color (hex, required)
- `size`: Pattern element size in dp
- `spacing`: Space between elements in dp
- `opacity`: Pattern opacity (0.0 to 1.0, default 1.0)

**Common Patterns**:

**Subtle Dots**:
```json
{
  "pattern_type": "dots",
  "primary_color": "#FAFAFA",
  "secondary_color": "#E0E0E0",
  "size": 4,
  "spacing": 20,
  "opacity": 0.5
}
```

**Graph Paper**:
```json
{
  "pattern_type": "grid",
  "primary_color": "#FFFFFF",
  "secondary_color": "#DDDDDD",
  "size": 1,
  "spacing": 20
}
```

**Use Cases**:
- Subtle textures
- Empty states
- Background decoration
- Professional layouts
- Branded patterns

**Performance**: ✅ Good (cached patterns)

---

### 10. Particles ⭐
**Moving particles effect**

```json
{
  "background": {
    "type": "particles",
    "particle_color": "#FFD700",
    "particle_count": 50,
    "particle_size": 4,
    "speed": 2,
    "direction": "up",
    "opacity": 0.7
  }
}
```

**Properties**:
- `particle_color`: Particle color (hex, required)
- `particle_count`: Number of particles (10-100, default 30)
- `particle_size`: Particle size in dp (default 4)
- `speed`: Movement speed (0.5 to 5.0, default 1.5)
- `direction`: `up`, `down`, `left`, `right`, `random`
- `opacity`: Particle opacity (0.0 to 1.0, default 0.8)

**Use Cases**:
- Celebration screens
- Success animations
- Special events
- Premium features
- Confetti effects

**Performance**: ⛔ Heavy (use sparingly, test on device)

---

### 11. Layered ⭐⭐
**Stack multiple backgrounds**

```json
{
  "background": {
    "type": "layered",
    "layers": [
      {
        "type": "image",
        "url": "hero.jpg",
        "opacity": 0.7
      },
      {
        "type": "linear_gradient",
        "angle": 180,
        "colors": ["#00000000", "#000000AA"]
      },
      {
        "type": "pattern",
        "pattern_type": "dots",
        "primary_color": "#00000000",
        "secondary_color": "#FFFFFF20",
        "size": 6,
        "spacing": 15
      }
    ]
  }
}
```

**Properties**:
- `layers`: Array of Background objects (applied bottom-to-top)

**Common Combinations**:

**Image + Dark Overlay**:
```json
{
  "layers": [
    {"type": "image", "url": "bg.jpg"},
    {
      "type": "linear_gradient",
      "angle": 180,
      "colors": ["#00000000", "#000000CC"]
    }
  ]
}
```

**Gradient + Pattern**:
```json
{
  "layers": [
    {
      "type": "linear_gradient",
      "angle": 45,
      "colors": ["#667eea", "#764ba2"]
    },
    {
      "type": "pattern",
      "pattern_type": "dots",
      "primary_color": "#00000000",
      "secondary_color": "#FFFFFF20"
    }
  ]
}
```

**Use Cases**:
- Complex hero sections
- Rich card designs
- Premium layouts
- Marketing materials
- Advanced compositions

**Performance**: ⚠️ Depends on layers (2-3 layers = good, 4+ = test carefully)

---

## 🎨 Common Design Patterns

### Modern Card
```json
{
  "style": {
    "background": {
      "type": "linear_gradient",
      "angle": 135,
      "colors": ["#667eea", "#764ba2"]
    },
    "border_radius": 16,
    "shadow_radius": 8
  }
}
```

### Loading Placeholder
```json
{
  "style": {
    "background": {
      "type": "shimmer",
      "base_color": "#E0E0E0",
      "highlight_color": "#F5F5F5",
      "duration": 1500
    },
    "border_radius": 8
  }
}
```

### Hero Section
```json
{
  "style": {
    "background": {
      "type": "layered",
      "layers": [
        {
          "type": "image",
          "url": "hero.jpg",
          "blur": 3
        },
        {
          "type": "linear_gradient",
          "angle": 180,
          "colors": ["#00000066", "#000000CC"]
        }
      ]
    }
  }
}
```

### Premium Badge
```json
{
  "style": {
    "background": {
      "type": "animated_gradient",
      "gradient_type": "linear",
      "angle": 45,
      "colors": ["#FFD700", "#FFA500", "#FFD700"],
      "duration": 2000
    },
    "border_radius": 20
  }
}
```

### Live Indicator
```json
{
  "style": {
    "background": {
      "type": "pulse",
      "color": "#FF6B6B",
      "min_opacity": 0.3,
      "max_opacity": 1.0,
      "duration": 1000
    },
    "border_radius": 4
  }
}
```

---

## ⚡ Performance Guide

### Excellent Performance ✅
**Use freely in production**
- Solid colors
- Linear gradients
- Radial gradients
- Sweep gradients
- Pattern backgrounds (cached)
- Pulse animations

### Good Performance ✅
**Safe for most use cases**
- Static images (cached)
- Shimmer effects
- Simple layered (2-3 layers)
- Single animated elements

### Use With Caution ⚠️
**Test on target devices**
- Animated gradients
- Complex layered (4+ layers)
- Image backgrounds (uncached)
- Many simultaneous animations
- Multiple shimmer effects

### Heavy Performance ⛔
**Use sparingly, only for special moments**
- Particle effects
- Multiple particle systems
- Complex animations on low-end devices
- Layered animations

---

## 🎯 Best Practices

### DO ✅
- **Use linear gradients** for 90% of gradient needs
- **Cache images** aggressively at the network level
- **Limit animated backgrounds** to key UI elements
- **Test on real devices** before shipping
- **Provide fallbacks** for low-end devices
- **Use shimmer** for loading states (industry standard)
- **Keep layers under 3** for best performance
- **Profile animations** to check battery impact

### DON'T ❌
- **Overuse animations** - respect battery life
- **Layer 5+ backgrounds** - severe performance impact
- **Use particles everywhere** - they're CPU-intensive
- **Animate on low-end devices** without performance checks
- **Forget about accessibility** - ensure contrast ratios
- **Ignore caching** - images should be cached
- **Skip real device testing** - emulators don't show true performance

---

## 🔄 Backward Compatibility

### Old API Still Works
```json
{
  "style": {
    "backgroundColor": "#FF0000"
  }
}
```

### New API Takes Priority
```json
{
  "style": {
    "background": {
      "type": "linear_gradient",
      "angle": 45,
      "colors": ["#FF0000", "#00FF00"]
    },
    "backgroundColor": "#0000FF"  // ❌ Ignored when background is present
  }
}
```

### Migration Strategy
1. New configs use `background`
2. Old configs continue using `backgroundColor`
3. Gradual migration as needed
4. No breaking changes

---

## 📦 Implementation

### Kotlin Models
All background types are defined as a sealed class hierarchy:

```kotlin
sealed class Background {
    data class Solid(val color: String) : Background()
    data class LinearGradient(...) : Background()
    data class RadialGradient(...) : Background()
    // ... etc
}
```

### JSON Serialization
Fully serializable with kotlinx.serialization:

```kotlin
@Serializable
@SerialName("background")
val background: Background?
```

### Renderer Integration
Single extension function applies all types:

```kotlin
@Composable
fun Modifier.applyBackground(background: Background?): Modifier
```

---

## 🚀 Getting Started

### 1. Use Existing Samples
Check out `BackgroundSamples.kt` for 15+ ready-to-use configurations.

### 2. Test in Sample App
Run the sample app and navigate to tabs 9-13 to see all backgrounds in action.

### 3. Create Your Own
Copy any example and modify properties to match your design.

### 4. Apply to Any Node
Add the `background` field to any container or element's `style` object.

---

## 📚 Additional Resources

- **Implementation**: See `BackgroundRenderer.kt` for rendering logic
- **Models**: See `Background.kt` for complete type definitions
- **Samples**: See `BackgroundSamples.kt` for 15 examples
- **Integration**: See `BACKGROUND_QUICK_START.md` for setup guide
- **Examples**: Run sample app tabs 9-13

---

## 🎉 Summary

You now have access to **11 powerful background types** that can be applied to **any element or container** in your server-driven UI:

✅ Simple colors to complex gradients  
✅ Static images to animated effects  
✅ Subtle patterns to eye-catching particles  
✅ Single backgrounds to rich layered compositions  

**All configurable via JSON, all performant, all production-ready.**

---

**Ready to create stunning UIs?** Start with the design patterns above and experiment! 🎨
