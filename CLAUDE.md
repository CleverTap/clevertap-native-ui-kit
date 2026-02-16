# Native Display System - Claude Code Knowledge Base

**Updated**: January 2025

---

## Quick Start

The Native Display System is a server-driven UI framework that renders native mobile interfaces from JSON configurations. The SDK supports Android (Kotlin/Compose) and iOS (Swift/SwiftUI).

### What You Can Do

- Parse JSON UI configurations into typed models
- Validate and resolve styles with inheritance
- Evaluate template expressions with runtime variables
- Calculate layouts and render native components
- Support 5 container types and 6 element types
- Handle animations, backgrounds, and galleries

### Hello World Example

```json
{
  "theme": {
    "id": "default",
    "defaultStyle": { "textColor": "#000000", "fontSize": 14 }
  },
  "variables": { "name": "World" },
  "root": {
    "id": "greeting",
    "containerType": "vertical",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "padding": { "all": 16 }
    },
    "children": [
      {
        "id": "title",
        "elementType": "text",
        "bindings": { "text": "Hello {{name}}!" },
        "layout": { "width": { "value": 100, "unit": "percent" } },
        "style": { "fontSize": 24, "fontWeight": "bold" }
      }
    ]
  }
}
```

---

## Project Structure

```
clevertap-native-ui-kit/
├── android/              # Android SDK (Kotlin + Jetpack Compose)
│   └── sdk/              # Core SDK module
├── android-sample/       # Android sample app
├── android-xml-sample/   # Android XML-based sample
├── ios/                  # iOS SDK (Swift + SwiftUI)
│   └── Sources/          # Core SDK source
├── ios-sample/           # iOS sample app
├── docs/                 # Documentation
└── .claude/              # Claude Code configuration
    ├── specs/            # Development specifications
    └── reference/        # Specialized knowledge docs
```

---

## Core Concepts

### 1. Configuration Structure

Every UI is defined by a `NativeDisplayConfig`:
```
{
  theme: Theme (optional)
  styleClasses: StyleClass[] (optional)
  variables: Map<string, any> (for template expressions)
  root: NativeDisplayNode (required)
}
```

### 2. Nodes: Containers & Elements

Two types of nodes:

**Containers** - Hold and organize children:
- VERTICAL, HORIZONTAL, BOX, GALLERY

**Elements** - Display content (leaf nodes):
- TEXT, IMAGE, BUTTON, VIDEO, SPACER, DIVIDER

### 3. Layout System

Every node has a `layout` object:
```
{
  width: Dimension
  height: Dimension
  padding: Spacing
  offset: Offset (for positioning)
  arrangement: ChildArrangement (for container spacing)
}
```

### 4. Style System

Styles consist of:
- **Text properties** (inherited by children): textColor, fontSize, fontWeight, etc.
- **Visual properties** (not inherited): backgroundColor, borderRadius, shadows, etc.

**For SDK Developers:** Use property extraction methods (`extractTextProperties()`, `extractVisualProperties()`, etc.) when working on renderer code for better organization. See `.claude/reference/STYLE_THEMING_GUIDE.md` for details.

### 5. Templates & Variables

Use `{{variableName}}` in bindings to reference variables:
```json
"bindings": { "text": "Hello {{user.name}}, you have {{count}} items" }
```

---

## Container Types

| Type | Purpose | Example Use |
|------|---------|-------------|
| VERTICAL | Stack children vertically | Card layouts, lists |
| HORIZONTAL | Stack children horizontally | Button groups, tags |
| BOX | Flexible overlay layout | Complex positioning |
| GALLERY | Scrollable carousel (3 modes) | Image galleries, product lists |

---

## Element Types

| Type | Binding | Example |
|------|---------|---------|
| TEXT | `text` | "Hello {{name}}" |
| IMAGE | `src` | "https://example.com/image.jpg" |
| BUTTON | `text` | "Click Me" |
| VIDEO | `src` | "https://example.com/video.mp4" |
| SPACER | N/A | Fixed or flexible spacing |
| DIVIDER | N/A | Visual separator |

---

## Development Approach

**Spec-Driven Development**: Every feature starts with a specification before implementation.

### Workflow
1. Define spec in `.claude/specs/`
2. Implement Android version
3. Implement iOS version (maintain parity)
4. Update sample apps
5. Document changes

---

## Documentation Files

### Reference Documentation (in `.claude/reference/`)
- **CLAUDE_CODE_REFERENCE_ACTUAL.md** - **PRIMARY** - Complete specification verified against actual Kotlin code
- **CLAUDE_CODE_PATTERNS.md** - Copy-paste ready Kotlin implementations
- **CLAUDE_CODE_MODELS.md** - Type definitions for Kotlin, Swift, TypeScript
- **COMPONENTS_GUIDE.md** - Examples for each container and element type
- **STYLE_THEMING_GUIDE.md** - How to use styles, themes, and styling system

### Architecture Documentation
- `ARCHITECTURE_DOCS_INDEX.md` - Main documentation index
- `LAYOUT_CONTENT_SEPARATION.md` - Layout system design
- `docs/VISUAL_STRATEGY_GUIDE.md` - Visual rendering approach

---

## Common Tasks with Claude Code

### Task 1: Parse JSON to Models
```
"Parse this JSON and create typed NativeDisplayConfig model"
Reference: CLAUDE_CODE_MODELS.md
```

### Task 2: Validate Configuration
```
"Validate this configuration JSON against the schema"
Reference: CLAUDE_CODE_REFERENCE_ACTUAL.md
```

### Task 3: Resolve Styles
```
"Apply style cascading and resolve final styles for each node"
Reference: CLAUDE_CODE_PATTERNS.md → StyleResolver
```

### Task 4: Evaluate Templates
```
"Evaluate {{variable}} expressions in this configuration"
Reference: CLAUDE_CODE_PATTERNS.md → VariableEvaluator
```

### Task 5: Generate Sample Data
```
"Generate sample JSON configuration for a product card"
Reference: COMPONENTS_GUIDE.md
```

---

## Workflows with Skills

Skills are one-command workflows that streamline development. Invoke with `/skill-name`.

### Available Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| `/commit` | `/commit` | Create git commit with proper message |
| `/generate-json` | `/generate-json [type]` | Generate test JSON configs |
| `/test` | `/test [platform]` | Run Android/iOS tests |
| `/build` | `/build [platform]` | Build Android/iOS SDK |
| `/review` | `/review` | Review code changes |
| `/statusline` | `/statusline` | Show project status |

### Workflow 1: Making Changes

Standard development workflow:
```
1. Edit code
2. /build android      → Verify compilation
3. /test android       → Run tests
4. /review             → Check standards
5. /commit             → Commit with proper message
```

### Workflow 2: Generating Test Configurations

Create valid test JSON configs:
```
1. /generate-json product-card
   → Generates valid JSON following JSON_STRUCTURE_REFERENCE.md
   → Uses ARGB color format (#AARRGGBB)
   → Ensures layout definitions on all nodes
   → Validates with jq

2. Saved to: test-configs/generated/product-card-test.json

3. /test               → Verify it works
```

### Workflow 3: Cross-Platform Development

Maintain parity across platforms:
```
1. Implement Android feature
2. /build android
3. /test android
4. Implement iOS equivalent
5. /build ios
6. /test ios
7. /review             → Check parity
8. /commit
```

### Workflow 4: Quick Status Check

Check project state before starting work:
```
/statusline
  → Git status (branch, changes)
  → Build status (last build results)
  → Test status (last test results)
  → Phase progress (current development phase)
```

### Workflow 5: Creating Demos

Sample app development:
```
1. Design demo UI
2. /generate-json demo-scenario
3. Integrate in sample app
4. /build android
5. /review
6. /commit
```

### Skills Benefits

- ✅ **Consistency** - Same workflow every time
- ✅ **Validation** - Built-in checks (JSON validation, code review)
- ✅ **Speed** - One command instead of multiple steps
- ✅ **Discoverability** - Easy to remember `/skill-name` pattern
- ✅ **Quality** - Automated standards enforcement

**See**: `.claude/skills/` directory for detailed documentation on each skill

---

## Key Features

### ✅ Supported

- **4 Container Types**: VERTICAL, HORIZONTAL, BOX, GALLERY
- **6 Element Types**: TEXT, IMAGE, BUTTON, VIDEO, SPACER, DIVIDER
- **Rich Styling**: 15+ style properties with cascading
- **Backgrounds**: 10+ background types (solid, gradients, patterns, animations)
- **Animations**: 8+ animation types with easing functions
- **Gallery Modes**: SNAPPING, FREE_FLOW, FREE_FLOW_GRID
- **Template Expressions**: Variable interpolation with nesting support
- **Style Classes**: Reusable style definitions
- **Themes**: Global default styles

### Layout Features

- **Dimensions**: DP, SP, PERCENT, PX, WRAP_CONTENT, MATCH_PARENT
- **Spacing**: Padding with individual side control
- **Arrangement**: 7 strategies (SPACED, SPACE_BETWEEN, SPACE_EVENLY, SPACE_AROUND, START, CENTER, END)
- **Positioning**: Offset for absolute positioning in BOX/STACK

---

## Style Resolution Order

```
1. Theme Default Style
   ↓
2. Style Class
   ↓
3. Inline Node Style
   ↓
4. Parent Style (text properties only)
```

---

## Color Format

```
#RRGGBB        // Hex RGB (e.g., #FF0000 = red)
#AARRGGBB      // Hex ARGB with alpha (e.g., #80FF0000 = red 50% opacity)
```

---

## Code Conventions

### Android (Kotlin)
- Use `@Serializable` for JSON models
- Jetpack Compose for UI rendering
- Follow existing package structure in `android/sdk/`

### iOS (Swift)
- Use `Codable` for JSON models
- SwiftUI for UI rendering
- Follow existing module structure in `ios/Sources/`

---

## Commands Reference

When working on this project:
- Android build: `cd android && ./gradlew build`
- Android test: `cd android && ./gradlew test`
- iOS build: `cd ios && swift build`
- iOS test: `cd ios && swift test`

---

## Quick Reference

### Containers
```
VERTICAL | HORIZONTAL | BOX | GALLERY
```

### Elements
```
TEXT | IMAGE | BUTTON | VIDEO | SPACER | DIVIDER
```

### Layout
```
Dimension: DP, SP, PERCENT, PX, WRAP_CONTENT, MATCH_PARENT
Arrangement: SPACED, SPACE_BETWEEN, SPACE_EVENLY, SPACE_AROUND, START, CENTER, END
```

### Styles
```
Text: textColor, fontSize, fontFamily, fontWeight, fontStyle, lineHeight, letterSpacing,
      textDecoration, textAlign, maxLines, overflow, textShadow, textGradient, opacity
Visual: backgroundColor, borderRadius, borderWidth, borderColor, shadow*, background
```

### Bindings
```
TEXT: "text"
IMAGE/VIDEO: "src"
```

---

## Best Practices

1. **Always define layout** for every node (container and element)
2. **Use arrangement strategies** for container spacing instead of manual gaps
3. **Define theme** for consistent styling across your app
4. **Create style classes** for reusable component styles
5. **Use template expressions** for dynamic content
6. **Keep inline styles** minimal - prefer classes
7. **Test responsive** behavior on multiple screen sizes

---

## Next Steps

1. **Reference `.claude/reference/CLAUDE_CODE_REFERENCE_ACTUAL.md`** for complete specification
2. **Check `.claude/reference/COMPONENTS_GUIDE.md`** for container and element examples
3. **Review `.claude/reference/CLAUDE_CODE_PATTERNS.md`** for implementation patterns
4. **Use `.claude/reference/STYLE_THEMING_GUIDE.md`** for styling system details
5. **Check `.claude/specs/`** for current development specifications

---

**Ready to use with Claude Code**  
All documentation is structured for easy integration with Claude Code's knowledge base system.
