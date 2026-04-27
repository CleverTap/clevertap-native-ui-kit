# Architecture Overview

## System Architecture

The Native Display System is a server-driven UI framework that renders native mobile interfaces from JSON configurations.

---

## 🏗️ High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        BACKEND SERVER                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  UI Logic  │  │   Theme    │  │  Variables │             │
│  │  Builder   │  │  Manager   │  │   Store    │             │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘             │
│         │                │                │                    │
│         └────────────────┴────────────────┘                    │
│                          │                                     │
│                          ▼                                     │
│                  ┌────────────────┐                           │
│                  │  JSON Generator│                           │
│                  └────────┬───────┘                           │
└───────────────────────────┼───────────────────────────────────┘
                            │ HTTP/HTTPS
                            │ JSON Payload
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                      MOBILE CLIENT                            │
│  ┌──────────────────────────────────────────────────────────┐│
│  │                    NATIVE DISPLAY SDK                     ││
│  │                                                            ││
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐ ││
│  │  │   Parser    │─▶│   Validator  │─▶│  Model Builder  │ ││
│  │  │  (JSON→Obj) │  │ (Type Check) │  │  (ResolvedCfg)  │ ││
│  │  └─────────────┘  └──────────────┘  └────────┬────────┘ ││
│  │                                                │          ││
│  │  ┌─────────────┐  ┌──────────────┐           │          ││
│  │  │   Style     │  │   Variable   │           │          ││
│  │  │  Resolver   │  │  Evaluator   │           │          ││
│  │  └──────┬──────┘  └──────┬───────┘           │          ││
│  │         │                 │                   │          ││
│  │         └────────┬────────┘                   │          ││
│  │                  │                            │          ││
│  │                  ▼                            ▼          ││
│  │         ┌────────────────────────────────────────┐      ││
│  │         │           RENDERER                     │      ││
│  │         │  ┌──────────────┐  ┌──────────────┐   │      ││
│  │         │  │  Container   │  │   Element    │   │      ││
│  │         │  │   Renderer   │  │   Renderer   │   │      ││
│  │         │  └──────────────┘  └──────────────┘   │      ││
│  │         └────────────────┬───────────────────────┘      ││
│  │                          │                              ││
│  └──────────────────────────┼──────────────────────────────┘│
│                             │                               │
│                             ▼                               │
│                   ┌──────────────────┐                      │
│                   │   Native UI      │                      │
│                   │  (Compose/SwiftUI│                      │
│                   │   /Flutter/RN)   │                      │
│                   └──────────────────┘                      │
└──────────────────────────────────────────────────────────────┘
```

---

## 📦 Core Components

### 1. Parser
**Purpose:** Convert JSON string to typed objects

**Input:** JSON string
**Output:** `ResolvedConfig` object

```kotlin
JSON String → kotlinx.serialization → ResolvedConfig
```

**Responsibilities:**
- Deserialize JSON
- Validate structure
- Handle malformed JSON
- Return typed model

---

### 2. Style Resolver
**Purpose:** Apply style inheritance and resolve final styles

**Input:** Node + Parent Style
**Output:** Resolved Style

```
Theme Styles
     ↓
Style Classes
     ↓
Node Style    →  [ Style Resolver ]  →  Final Resolved Style
     ↓
Parent Style (inherited)
```

**Resolution Order:**
1. Start with theme defaults
2. Apply style class if present
3. Apply node-level style
4. Inherit from parent (if applicable)
5. Resolve color values

---

### 3. Variable Evaluator
**Purpose:** Evaluate template expressions with runtime data

**Input:** Template string + Variables map
**Output:** Evaluated value

```
Template: "Hello {{name}}"
Variables: {"name": "World"}
          ↓
Output: "Hello World"
```

**Supported Expressions:**
- Simple: `{{variable}}`
- Nested: `{{user.name}}`
- Boolean: `{{isVisible}}`

---

### 4. Renderer
**Purpose:** Convert display nodes to native UI components

**Input:** Display Node + Resolved Style
**Output:** Native UI Component

```
NativeDisplayNode
       ↓
  [Renderer]
       ↓
┌──────┴───────┐
│              │
Container    Element
   ↓            ↓
Column/Row   Text/Image
```

**Process:**
1. Check visibility
2. Resolve style
3. Apply layout
4. Apply decorations
5. Render children (if container)

---

## 🔄 Request Flow

### Complete Flow Diagram

```
┌────────┐
│ Start  │
└───┬────┘
    │
    ▼
┌───────────────┐
│ 1. Fetch JSON │
│   from Server │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ 2. Parse JSON │
│   to Models   │
└───────┬───────┘
        │
        ▼
┌───────────────┐     ❌ Invalid
│ 3. Validate   │────────────┐
│   Structure   │             │
└───────┬───────┘             │
        │ ✅ Valid            │
        ▼                     ▼
┌───────────────┐     ┌──────────────┐
│ 4. Build      │     │ Show Error   │
│  ResolvedCfg  │     │   Message    │
└───────┬───────┘     └──────────────┘
        │
        ▼
┌───────────────┐
│ 5. Resolve    │
│   All Styles  │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ 6. Evaluate   │
│   Variables   │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ 7. Render     │
│   Root Node   │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ 8. Display UI │
└───────────────┘
```

---

## 🌲 Node Rendering Flow

```
RenderNode(node)
      │
      ▼
┌─────────────────┐
│ Check Visible?  │
└────┬─────┬──────┘
     │ Yes │ No → Return (skip rendering)
     ▼     
┌─────────────────┐
│ Resolve Style   │
│ (with parent)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Apply Layout    │
│ (width/height/  │
│  padding)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Apply Offset    │
│ (x/y position)  │
└────────┬────────┘
         │
         ▼
     Is Container?
    ┌────┴────┐
   Yes       No
    │          │
    ▼          ▼
┌────────┐  ┌────────┐
│Render  │  │Render  │
│Contain-│  │Element │
│er      │  │        │
└───┬────┘  └───┬────┘
    │           │
    ▼           ▼
┌────────┐  ┌────────┐
│Apply   │  │Apply   │
│Decor-  │  │Decor-  │
│ations │  │ations  │
└───┬────┘  └───┬────┘
    │           │
    ▼           ▼
┌────────┐  ┌────────┐
│Render  │  │Render  │
│Children│  │Content │
└────────┘  └────────┘
```

---

## 📐 Layout System

### Layout Application Order

```
1. Base Modifier
        ↓
2. Layout Properties
   - width
   - height  
   - padding
        ↓
3. Offset (x, y)
        ↓
4. Visual Decorations
   - shadow
   - border
   - background
   - opacity
        ↓
5. Final UI Component
```

### Container Layout Types

```
┌─────────────────────────────────────┐
│           VERTICAL                  │
│  ┌─────────────────────────────┐   │
│  │ Child 1                     │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Child 2                     │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Child 3                     │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│          HORIZONTAL                 │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│  │Ch 1 │ │Ch 2 │ │Ch 3 │ │Ch 4 │  │
│  └─────┘ └─────┘ └─────┘ └─────┘  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│              BOX                    │
│     (single child, centered)        │
│                                     │
│         ┌──────────────┐            │
│         │   Child 1    │            │
│         └──────────────┘            │
│                                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│            STACK                    │
│     (layered, z-index)              │
│  ┌─────────────────────────────┐   │
│  │ Child 1 (bottom)            │   │
│  │   ┌─────────────────────┐   │   │
│  │   │ Child 2 (middle)    │   │   │
│  │   │   ┌─────────────┐   │   │   │
│  │   │   │ Child 3     │   │   │   │
│  │   │   │ (top)       │   │   │   │
│  │   │   └─────────────┘   │   │   │
│  │   └─────────────────────┘   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 🎨 Style Resolution

### Style Inheritance Chain

```
Theme Default Style
        ↓
Style Class (optional)
        ↓
Node Style
        ↓
Parent Style (inherited properties)
        ↓
Final Resolved Style
```

### Example

```json
Theme: {
  "defaultStyle": {
    "textColor": "#000000",
    "fontSize": 14
  }
}

StyleClass "title": {
  "fontSize": 24,
  "fontWeight": "bold"
}

Node: {
  "styleClass": "title",
  "style": {
    "textColor": "#FF0000"
  }
}

Parent: {
  "style": {
    "textColor": "#0000FF"  // Overridden by node
  }
}

↓

Final: {
  "textColor": "#FF0000",    // From node
  "fontSize": 24,             // From style class
  "fontWeight": "bold"        // From style class
}
```

---

## 🔍 Variable Evaluation

### Evaluation Flow

```
Template String: "Hello {{user.name}}, you have {{count}} messages"
       ↓
Parse Expressions: ["{{user.name}}", "{{count}}"]
       ↓
Variables Map: {
  "user": {"name": "Alice"},
  "count": 5
}
       ↓
Evaluate Each:
  {{user.name}} → "Alice"
  {{count}} → "5"
       ↓
Replace in Template
       ↓
Result: "Hello Alice, you have 5 messages"
```

### Supported Types

```
String:  {{name}}           → "John"
Number:  {{age}}            → 25
Boolean: {{isActive}}       → true
Nested:  {{user.profile.name}} → "Alice"
```

---

## 🎭 Gallery Modes

### Three Rendering Strategies

```
MODE 1: SNAPPING
┌──────────────────────────────────────┐
│   [═══ Item 1 ═══] [It] [Item 3]    │
│    ◄────────────►                    │
│    Peek 20%                          │
└──────────────────────────────────────┘

MODE 2: FREE_FLOW
┌──────────────────────────────────────┐
│ [Tag1] [Tag2] [LongerTag3] [T4]     │
│  ◄──►  ◄──►   ◄─────────►  ◄►       │
│  Self-sized items                    │
└──────────────────────────────────────┘

MODE 3: FREE_FLOW_GRID
┌──────────────────────────────────────┐
│ [═ Item 1 ═] [═ Item 2 ═] [═ I]     │
│  ◄────────►   ◄────────►   ◄──       │
│  Fixed: 2.5 items per view           │
└──────────────────────────────────────┘
```

---

## 🎨 Background System

### Background Rendering Flow

```
Background Config
       ↓
Is Animated?
   ┌───┴───┐
  Yes     No
   │       │
   ▼       ▼
Composable  Modifier
Animation   Extension
   │       │
   └───┬───┘
       ↓
Native Background
```

### Background Types

```
STATIC (6):
├─ Solid Color
├─ Linear Gradient
├─ Radial Gradient
├─ Grid Pattern
├─ Dots Pattern
└─ Waves Pattern

ANIMATED (5):
├─ Pulse (opacity)
├─ Shimmer (sweep)
├─ Smooth (slow transitions)
├─ Particle (floating)
└─ Breathing (scale)
```

---

## 🚀 Performance Considerations

### Optimization Strategies

```
1. Lazy Loading
   ┌──────────────┐
   │ Only render  │
   │ visible items│
   └──────────────┘

2. Memoization
   ┌──────────────┐
   │ Cache styled │
   │ components   │
   └──────────────┘

3. Efficient Re-renders
   ┌──────────────┐
   │ Only update  │
   │ changed nodes│
   └──────────────┘

4. Background Pooling
   ┌──────────────┐
   │ Reuse        │
   │ brushes      │
   └──────────────┘
```

---

## 🔐 Error Handling

### Error Flow

```
JSON Parsing Error
       ↓
┌──────────────┐
│ Show Error   │
│ Message      │
└──────────────┘

Style Resolution Error
       ↓
┌──────────────┐
│ Use Default  │
│ Style        │
└──────────────┘

Variable Not Found
       ↓
┌──────────────┐
│ Show         │
│ Template     │
└──────────────┘

Rendering Error
       ↓
┌──────────────┐
│ Show Error   │
│ Placeholder  │
└──────────────┘
```

---

## 📊 Data Models

### Core Model Hierarchy

```
ResolvedConfig
├─ theme: Theme
├─ styleClasses: List<StyleClass>
├─ variables: Map<String, Any>
└─ root: NativeDisplayNode

NativeDisplayNode (sealed)
├─ NativeDisplayContainer
│  ├─ containerType: ContainerType
│  ├─ children: List<NativeDisplayNode>
│  ├─ galleryConfig?: GalleryConfig
│  └─ dividerConfig?: DividerConfig
└─ NativeDisplayElement
   ├─ elementType: ElementType
   ├─ bindings: Map<String, String>
   └─ ... (common properties)

Common Properties:
├─ id: String
├─ layout?: Layout
├─ style?: Style
├─ styleClass?: String
├─ visible?: String
├─ actions?: Map<String, Action>
└─ animation?: Animation
```

---

## 🎯 Key Design Decisions

### 1. Sealed Classes for Type Safety
```kotlin
sealed class NativeDisplayNode
- Compile-time exhaustive checking
- Type-safe pattern matching
```

### 2. Nullable Optional Config
```kotlin
val galleryConfig: GalleryConfig? = null
- Only present when needed
- Keeps JSON lean
```

### 3. String-based Templates
```kotlin
val visible: String? = "{{isVisible}}"
- Flexible evaluation
- Backend-controlled logic
```

### 4. Modifier Chain Pattern
```kotlin
modifier
  .applyLayout()
  .applyOffset()
  .applyDecorations()
- Composable transformations
- Clear order of operations
```

---

## 📈 Scalability

### Horizontal Scaling
```
Backend: Generate JSON → Cache → CDN → Clients
```

### Vertical Scaling
```
Client: Parse → Cache → Reuse → Efficient Render
```

---

## 🔄 Update Flow

```
User Action → Server
       ↓
New JSON Generated
       ↓
Push to Client
       ↓
Parse & Validate
       ↓
Diff with Current
       ↓
Update Changed Nodes
       ↓
Re-render UI
```

---

**Last Updated:** December 2025
**Version:** 1.0
