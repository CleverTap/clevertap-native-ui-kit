# Reference Documentation Index

This folder contains specialized knowledge for Claude Code to understand and implement the Native Display System.

## Quick Start

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **CLAUDE_CODE_REFERENCE_ACTUAL.md** | Verified spec from actual Kotlin code | Primary reference for all implementations |
| **CLIENT_USAGE_MODEL.md** | **How clients use the SDK** | Understanding JSON-driven usage model |
| **JSON_STRUCTURE_REFERENCE.md** | Complete JSON configuration rules | **Generating JSON configs and test files** |
| **CLAUDE_CODE_PATTERNS.md** | Copy-paste ready code examples | When implementing features |
| **COMPONENTS_GUIDE.md** | All container and element types | Understanding component structure |
| **STYLE_THEMING_GUIDE.md** | Style system and theming | Implementing styles and themes |
| **CLAUDE_CODE_MODELS.md** | Type definitions (Kotlin/Swift/TS) | Creating data models |
| **ARCHITECTURE_INDEX.md** | Architecture documentation index | Finding architecture docs |
| **LAYOUT_SEPARATION.md** | Layout system design decisions | Understanding layout architecture |
| **ADAPTIVE_ARCHITECTURE.md** | Adaptive architecture patterns | Architectural decision making |
| **PLATFORM_ARRANGEMENT_COMPARISON.md** | Cross-platform arrangement comparison | Ensuring iOS/Android parity |

## Files

### Core Reference (Read First)
- `CLAUDE_CODE_REFERENCE_ACTUAL.md` - **Verified against actual Kotlin code** - the authoritative reference
- `CLIENT_USAGE_MODEL.md` - **JSON-driven SDK usage model** - How clients use the SDK (NO custom Composables!)
- `JSON_STRUCTURE_REFERENCE.md` - **Complete JSON configuration rules** - MUST use when generating JSON

### Implementation Patterns
- `CLAUDE_CODE_PATTERNS.md` - Parser, StyleResolver, VariableEvaluator, LayoutCalculator implementations

### Component Documentation
- `COMPONENTS_GUIDE.md` - Container types (VERTICAL, HORIZONTAL, BOX, STACK, GALLERY) and Element types (TEXT, IMAGE, BUTTON, etc.)

### Style System
- `STYLE_THEMING_GUIDE.md` - Theme, StyleClasses, Style resolution, Colors, Backgrounds

### Architecture Documentation
- `ARCHITECTURE_INDEX.md` - Main architecture documentation index
- `LAYOUT_SEPARATION.md` - Layout and content separation design
- `ADAPTIVE_ARCHITECTURE.md` - Adaptive architecture patterns and decisions

### Cross-Platform Reference
- `PLATFORM_ARRANGEMENT_COMPARISON.md` - iOS vs Android arrangement implementation comparison

## Usage Priority

1. **For understanding the system**: Start with `CLAUDE_CODE_REFERENCE_ACTUAL.md`
2. **For implementation**: Use `CLAUDE_CODE_PATTERNS.md` code examples
3. **For component details**: Refer to `COMPONENTS_GUIDE.md`
4. **For styling**: Check `STYLE_THEMING_GUIDE.md`

## Key Concepts

### Container Types
- VERTICAL, HORIZONTAL, BOX, STACK, GALLERY

### Element Types  
- TEXT, IMAGE, BUTTON, VIDEO, SPACER, DIVIDER

### Layout System
- Dimension (DP, PERCENT, WRAP, FILL)
- Spacing (padding, margin)
- Arrangement (spacing strategy)

### Style System
- Theme defaults → Style class → Inline style
- Text properties cascade to children
- Visual properties don't cascade

---

**Updated**: January 2025
