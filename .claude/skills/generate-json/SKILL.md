---
name: generate-json
description: Generate test JSON configurations following JSON_STRUCTURE_REFERENCE.md rules
user-invocable: true
disable-model-invocation: false
---

# Generate JSON Skill

Generates valid Native Display JSON configurations for testing purposes, strictly following the JSON_STRUCTURE_REFERENCE.md specification.

## Usage

```bash
# Interactive mode - asks what to generate
/generate-json

# Specify what to generate
/generate-json product-card
/generate-json vertical-container-arrangement-test
/generate-json gallery-snapping-mode
```

## What This Skill Does

1. **References Specification**
   - Always reads `.claude/reference/JSON_STRUCTURE_REFERENCE.md`
   - Validates against proper JSON structure rules
   - Ensures ARGB color format (#AARRGGBB)
   - Follows proper dimension/spacing conventions

2. **Generates Valid JSON**
   - Creates complete `NativeDisplayConfig` structure
   - Includes required fields (theme, variables, root)
   - Uses proper container/element types
   - Applies correct layout definitions

3. **Validates Output**
   - Checks JSON syntax with `jq`
   - Verifies color format (ARGB)
   - Ensures layout completeness
   - Validates bindings and expressions

4. **Saves to Test Directory**
   - Saves to `test-configs/generated/`
   - Names files descriptively (e.g., `product-card-test.json`)
   - Creates variations when requested

## Key Rules (from JSON_STRUCTURE_REFERENCE.md)

### ✅ DO
- Use ARGB color format: `#AARRGGBB` or `#RRGGBB`
- Define layout for ALL nodes (containers and elements)
- Use proper dimension units: `DP`, `SP`, `PERCENT`, `PX`, `WRAP_CONTENT`, `MATCH_PARENT`
- Include theme with defaultStyle
- Define variables for template expressions
- Use proper containerType/elementType values

### ❌ DON'T
- Use RGB format for colors - always ARGB
- Skip layout definitions
- Use invalid dimension units
- Mix up container vs element types
- Forget to define bindings for dynamic content

## Generation Templates

### Minimal Example
```json
{
  "theme": {
    "id": "default",
    "defaultStyle": { "textColor": "#FF000000", "fontSize": 14 }
  },
  "variables": {},
  "root": {
    "id": "root",
    "containerType": "vertical",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "padding": { "all": 16 }
    },
    "children": []
  }
}
```

### Product Card Example
```json
{
  "theme": {
    "id": "product-theme",
    "defaultStyle": {
      "textColor": "#FF000000",
      "fontSize": 14,
      "fontFamily": "System"
    }
  },
  "variables": {
    "productName": "Product Name",
    "price": "$99.99",
    "imageUrl": "https://example.com/product.jpg"
  },
  "root": {
    "id": "product-card",
    "containerType": "vertical",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "padding": { "all": 16 }
    },
    "children": [
      {
        "id": "product-image",
        "elementType": "image",
        "bindings": { "src": "{{imageUrl}}" },
        "layout": {
          "width": { "value": 100, "unit": "percent" },
          "height": { "value": 200, "unit": "dp" }
        }
      },
      {
        "id": "product-name",
        "elementType": "text",
        "bindings": { "text": "{{productName}}" },
        "layout": {
          "width": { "value": 100, "unit": "percent" }
        },
        "style": {
          "fontSize": 18,
          "fontWeight": "bold"
        }
      },
      {
        "id": "product-price",
        "elementType": "text",
        "bindings": { "text": "{{price}}" },
        "layout": {
          "width": { "value": 100, "unit": "percent" }
        },
        "style": {
          "fontSize": 16,
          "textColor": "#FF0066CC"
        }
      }
    ]
  }
}
```

## Use Cases

1. **Container Testing**
   - Generate VERTICAL, HORIZONTAL, BOX, STACK, GALLERY examples
   - Test arrangement strategies (SPACED, SPACE_BETWEEN, etc.)
   - Test nesting scenarios

2. **Element Testing**
   - Generate TEXT, IMAGE, BUTTON, VIDEO examples
   - Test bindings and template expressions
   - Test styling variations

3. **Layout Testing**
   - Test different dimension units
   - Test padding/spacing combinations
   - Test responsive behaviors

4. **Style Testing**
   - Test style cascading
   - Test theme inheritance
   - Test style classes

5. **Gallery Testing**
   - Test SNAPPING mode
   - Test FREE_FLOW mode
   - Test FREE_FLOW_GRID mode

## Validation Steps

After generation, this skill:

1. ✅ Runs `jq` to validate JSON syntax
2. ✅ Checks all colors are ARGB format
3. ✅ Verifies all nodes have layout definitions
4. ✅ Validates dimension units are correct
5. ✅ Ensures containerType/elementType values are valid
6. ✅ Checks bindings reference defined variables

## Output Location

Generated files saved to:
```
test-configs/generated/
├── product-card-test.json
├── vertical-arrangement-test.json
├── gallery-snapping-test.json
└── ...
```

## Integration with Testing Agent

This skill works seamlessly with the `testing` agent:
- Testing agent can invoke `/generate-json` to create test cases
- Generated JSONs are automatically placed in test directories
- Can be used in automated test suites

## Best Practices

1. **Always validate** generated JSON with `jq`
2. **Use descriptive names** for test files
3. **Include comments** in generated JSON (if supported)
4. **Create variations** for different test scenarios
5. **Reference specification** before generating

## Error Prevention

Common mistakes this skill prevents:
- ❌ RGB colors → Converts to ARGB
- ❌ Missing layouts → Adds default layouts
- ❌ Invalid units → Uses valid dimension units
- ❌ Wrong types → Uses correct container/element types
- ❌ Missing bindings → Ensures bindings for dynamic content

## Related Documentation

- `.claude/reference/JSON_STRUCTURE_REFERENCE.md` - Complete JSON spec
- `.claude/reference/COMPONENTS_GUIDE.md` - Component examples
- `.claude/agents/testing/templates/` - JSON templates
