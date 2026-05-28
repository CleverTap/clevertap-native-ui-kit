# JSON Generation Rules

## Primary Reference
**ALWAYS refer to**: `.claude/reference/JSON_STRUCTURE_REFERENCE.md`

This is the COMPLETE specification for generating valid Native Display JSON configurations.

## Critical Rules Summary

### 1. Every Node MUST Have `type` Field
```json
{
  "type": "container"  // or "element"
}
```

**This is the #1 most common mistake - never forget the `type` field!**

### 2. Required Fields by Node Type

**Container nodes:**
```json
{
  "type": "container",           // REQUIRED
  "id": "unique_id",             // REQUIRED
  "containerType": "vertical",   // REQUIRED
  "children": []                 // REQUIRED (can be empty)
}
```

**Element nodes:**
```json
{
  "type": "element",             // REQUIRED
  "id": "unique_id",             // REQUIRED
  "elementType": "text",         // REQUIRED
  "bindings": {}                 // REQUIRED (can be empty)
}
```

### 3. Valid Enum Values (LOWERCASE!)

**Container types:**
- `"vertical"` ✅ (not `"VERTICAL"` ❌)
- `"horizontal"` ✅
- `"box"` ✅
- `"stack"` ✅
- `"gallery"` ✅

**Element types:**
- `"text"` ✅
- `"image"` ✅
- `"button"` ✅
- `"video"` ✅
- `"html"` ✅
- `"spacer"` ✅
- `"divider"` ✅

**Font weights:**
- `"normal"` ✅ (not `"NORMAL"` ❌)
- `"medium"` ✅
- `"bold"` ✅
- `"light"` ✅

### 4. Dimension Format

**Fixed dimensions:**
```json
{
  "value": 100,
  "unit": "dp"  // "dp" | "sp" | "px" | "percent"
}
```

**Special dimensions:**
```json
{"special": "wrap_content"}
{"special": "match_parent"}
```

**Common mistake:**
```json
{"dp": 16}  // ❌ WRONG!
```

**Correct:**
```json
{"value": 16, "unit": "dp"}  // ✅ RIGHT!
```

### 5. Percentage Rules

- Percentages calculate from **parent's content area** (after padding)
- Range: 0-100
- Parent must have fixed or `match_parent` dimensions
- Don't use with `wrap_content` parent

**Example:**
```json
{
  "layout": {
    "width": {"value": 100, "unit": "percent"}  // Full width
  }
}
```

### 6. Aspect Ratio

Automatically calculates one dimension from the other:

```json
{
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "aspectRatio": 1.5  // width / height
  }
}
```

**Common ratios:**
- `1.0` - Square (1:1)
- `1.777` - Widescreen (16:9)
- `0.75` - Portrait (3:4)

### 7. Color Format

```json
"#RRGGBB"      // RGB (e.g., "#FF5722")
"#RRGGBBAA"    // RGBA with alpha (e.g., "#FF572280")
```

### 8. Arrangement Strategies

For `vertical` and `horizontal` containers:

```json
{
  "arrangement": {
    "spacing": 12,           // Only for "spaced" strategy
    "spacingUnit": "dp",
    "strategy": "spaced"     // See options below
  }
}
```

**Strategies:**
- `"spaced"` - Fixed spacing (needs `spacing` value)
- `"space_between"` - Space between items, not at edges
- `"space_evenly"` - Equal space everywhere
- `"space_around"` - Space around each item
- `"start"` - Align to start
- `"center"` - Center items
- `"end"` - Align to end

### 9. Bindings

**Elements MUST have bindings object:**

```json
// Text/Button
{"bindings": {"text": "Hello"}}

// Image/Video
{"bindings": {"url": "https://..."}}

// HTML (inline html or url, html takes priority)
{"bindings": {"html": "<div>Content</div>"}}
{"bindings": {"url": "https://example.com/page.html"}}

// Spacer/Divider (empty but required!)
{"bindings": {}}
```

### 10. Common Mistakes Checklist

- [ ] ❌ Missing `"type"` field on nodes
- [ ] ❌ Using uppercase enums (`"VERTICAL"` instead of `"vertical"`)
- [ ] ❌ Wrong dimension format (`{"dp": 16}` instead of `{"value": 16, "unit": "dp"}`)
- [ ] ❌ Missing `"children": []` on containers
- [ ] ❌ Missing `"bindings": {}` on elements
- [ ] ❌ Trailing commas in JSON
- [ ] ❌ Single quotes instead of double quotes
- [ ] ❌ Percentages with `wrap_content` parent

## Test JSON Generation Workflow

### 1. Choose Test Scenario
Identify what you're testing:
- Container type + arrangement strategy
- Element type + style properties
- Layout combinations
- Responsive behavior

### 2. Start from Template
Use templates from `.claude/agents/testing/templates/`

### 3. Apply Variations
Systematically vary the test dimensions:
```bash
./scripts/generate-tests.sh
```

### 4. Validate Each Generated File
```bash
for file in test-configs/generated/*.json; do
    jq empty "$file" || echo "Invalid: $file"
done
```

### 5. Verify Against Rules
Check each file against the checklist in `JSON_STRUCTURE_REFERENCE.md`

## Quick Reference Patterns

### Minimal Valid Container
```json
{
  "type": "container",
  "id": "test",
  "containerType": "vertical",
  "children": []
}
```

### Minimal Valid Element
```json
{
  "type": "element",
  "id": "test",
  "elementType": "text",
  "bindings": {"text": "Test"}
}
```

### Full-Width Responsive Image
```json
{
  "type": "element",
  "id": "image",
  "elementType": "image",
  "bindings": {"url": "https://example.com/image.jpg"},
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "aspectRatio": 1.5
  }
}
```

### Vertical Container with Spacing
```json
{
  "type": "container",
  "id": "list",
  "containerType": "vertical",
  "layout": {
    "width": {"value": 100, "unit": "percent"},
    "padding": {"all": 16}
  },
  "arrangement": {
    "spacing": 12,
    "strategy": "spaced"
  },
  "children": [...]
}
```

### Three-Column Grid
```json
{
  "type": "container",
  "id": "grid",
  "containerType": "horizontal",
  "children": [
    {
      "type": "element",
      "id": "col1",
      "elementType": "text",
      "bindings": {"text": "Column 1"},
      "layout": {"width": {"value": 33.33, "unit": "percent"}}
    },
    {
      "type": "element",
      "id": "col2",
      "elementType": "text",
      "bindings": {"text": "Column 2"},
      "layout": {"width": {"value": 33.33, "unit": "percent"}}
    },
    {
      "type": "element",
      "id": "col3",
      "elementType": "text",
      "bindings": {"text": "Column 3"},
      "layout": {"width": {"value": 33.34, "unit": "percent"}}
    }
  ]
}
```

## Validation Command

Always validate generated JSON:
```bash
jq empty your-test-file.json && echo "Valid ✅" || echo "Invalid ❌"
```

## Testing Agent Responsibilities

1. **Generate comprehensive test variations** covering all containers, elements, and layout combinations
2. **Validate all JSON** against the rules in `JSON_STRUCTURE_REFERENCE.md`
3. **Ensure cross-platform parity** by generating identical JSON for Android and iOS testing
4. **Maintain test templates** that follow the latest specification
5. **Document test coverage** with clear naming and organization

## Key Principle

**EVERY JSON file generated for testing MUST be validated against `JSON_STRUCTURE_REFERENCE.md`**

When in doubt, ALWAYS refer to the complete specification document.
