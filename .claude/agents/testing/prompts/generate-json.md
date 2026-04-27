# Generate Test JSON Configuration

## Task
Generate a valid JSON configuration for testing [SPECIFIC_FEATURE].

## CRITICAL: JSON Generation Rules

**ALWAYS consult before generating:**
1. `.claude/reference/JSON_STRUCTURE_REFERENCE.md` (complete rules)
2. `.claude/agents/testing/knowledge/json-generation-rules.md` (quick reference)

## Pre-Generation Checklist

- [ ] Identified what to test (container type, element type, layout scenario)
- [ ] Reviewed similar examples in `test-configs/`
- [ ] Confirmed all required fields for node type
- [ ] Verified enum values are lowercase
- [ ] Planned dimension strategy (fixed, percent, wrap, match)

## Generation Template

```json
{
  "_comment": "Test: [DESCRIBE WHAT THIS TESTS]",

  "theme": {
    "id": "test-theme",
    "defaultStyle": {
      "textColor": "#212121",
      "fontSize": 14
    }
  },

  "root": {
    "type": "container",           // ✅ REQUIRED - "container" or "element"
    "id": "test-root",             // ✅ REQUIRED - unique ID
    "containerType": "vertical",   // ✅ REQUIRED for containers
    "layout": {
      "width": {"value": 100, "unit": "percent"},
      "padding": {"all": 16}
    },
    "arrangement": {
      "spacing": 12,
      "strategy": "spaced"
    },
    "children": [                  // ✅ REQUIRED for containers
      {
        "type": "element",         // ✅ REQUIRED
        "id": "test-element",      // ✅ REQUIRED
        "elementType": "text",     // ✅ REQUIRED for elements
        "bindings": {              // ✅ REQUIRED for elements
          "text": "Test Content"
        }
      }
    ]
  }
}
```

## Common Test Scenarios

### 1. Test Container Arrangement
```json
{
  "root": {
    "type": "container",
    "id": "container-test",
    "containerType": "vertical",  // or horizontal, box, stack, gallery
    "arrangement": {
      "spacing": 12,
      "strategy": "spaced"        // or space_between, space_evenly, etc.
    },
    "children": [
      // 3+ test children with different sizes/styles
    ]
  }
}
```

### 2. Test Element Rendering
```json
{
  "root": {
    "type": "container",
    "id": "element-test",
    "containerType": "vertical",
    "children": [
      {
        "type": "element",
        "id": "test-element",
        "elementType": "text",    // or image, button, video, spacer, divider
        "bindings": {
          "text": "Test Text"     // or url, etc.
        },
        "style": {
          // Test various style properties
        }
      }
    ]
  }
}
```

### 3. Test Responsive Layout
```json
{
  "root": {
    "type": "container",
    "id": "responsive-test",
    "containerType": "vertical",
    "layout": {
      "width": {"value": 100, "unit": "percent"}
    },
    "children": [
      {
        "type": "element",
        "id": "responsive-image",
        "elementType": "image",
        "bindings": {"url": "https://via.placeholder.com/400x300"},
        "layout": {
          "width": {"value": 100, "unit": "percent"},
          "aspectRatio": 1.5
        }
      }
    ]
  }
}
```

### 4. Test Style Cascading
```json
{
  "theme": {
    "id": "cascade-test",
    "defaultStyle": {
      "textColor": "#000000",
      "fontSize": 14
    }
  },
  "styleClasses": [
    {
      "name": "highlight",
      "style": {
        "textColor": "#FF5722",
        "fontWeight": "bold"
      }
    }
  ],
  "root": {
    "type": "container",
    "id": "parent",
    "containerType": "vertical",
    "style": {
      "fontSize": 16  // Should cascade to children
    },
    "children": [
      {
        "type": "element",
        "id": "child1",
        "elementType": "text",
        "bindings": {"text": "Inherits fontSize: 16"},
        "styleClass": "highlight"  // Also applies highlight style
      },
      {
        "type": "element",
        "id": "child2",
        "elementType": "text",
        "bindings": {"text": "Overrides fontSize"},
        "style": {
          "fontSize": 20  // Overrides inherited value
        }
      }
    ]
  }
}
```

## Post-Generation Validation

### 1. JSON Syntax Validation
```bash
jq empty your-test.json && echo "Valid JSON ✅" || echo "Invalid JSON ❌"
```

### 2. Required Fields Check
- [ ] Every node has `"type"` field
- [ ] Every node has unique `"id"` field
- [ ] Containers have `"containerType"` and `"children": []`
- [ ] Elements have `"elementType"` and `"bindings": {}`

### 3. Enum Values Check
- [ ] All enum values are lowercase
- [ ] `containerType` is one of: vertical, horizontal, box, stack, gallery
- [ ] `elementType` is one of: text, image, button, video, spacer, divider
- [ ] `fontWeight` (if used) is one of: normal, medium, bold, light
- [ ] `strategy` (if used) is valid arrangement strategy

### 4. Dimension Format Check
- [ ] Fixed dimensions: `{"value": N, "unit": "dp|sp|px|percent"}`
- [ ] Special dimensions: `{"special": "wrap_content|match_parent"}`
- [ ] NOT using wrong format like `{"dp": 16}`

### 5. Structure Check
- [ ] No trailing commas
- [ ] Double quotes (not single quotes)
- [ ] Colors in hex format `#RRGGBB` or `#AARRGGBB`
- [ ] Percentage values between 0-100

## Naming Convention

Test files should be named descriptively:

```
test-configs/generated/
├── container_vertical_spaced.json
├── container_horizontal_space_between.json
├── element_text_styled.json
├── element_image_aspectratio.json
├── layout_responsive_percentage.json
└── style_cascading_inheritance.json
```

Format: `[category]_[type]_[feature].json`

## Example: Complete Test Generation

**Scenario**: Test vertical container with SPACE_BETWEEN arrangement

```json
{
  "_comment": "Test: Vertical container with SPACE_BETWEEN arrangement",
  "_expected": "Children should have space between them, but not at top/bottom edges",

  "theme": {
    "id": "test"
  },

  "root": {
    "type": "container",
    "id": "vertical-space-between",
    "containerType": "vertical",
    "layout": {
      "width": {"value": 300, "unit": "dp"},
      "height": {"value": 400, "unit": "dp"},
      "padding": {"all": 16}
    },
    "style": {
      "backgroundColor": "#F5F5F5"
    },
    "arrangement": {
      "strategy": "space_between"
    },
    "children": [
      {
        "type": "element",
        "id": "child-1",
        "elementType": "text",
        "bindings": {"text": "First (top edge)"},
        "layout": {
          "width": {"value": 100, "unit": "percent"},
          "height": {"value": 50, "unit": "dp"}
        },
        "style": {
          "backgroundColor": "#E3F2FD",
          "textAlign": "center"
        }
      },
      {
        "type": "element",
        "id": "child-2",
        "elementType": "text",
        "bindings": {"text": "Middle (space above and below)"},
        "layout": {
          "width": {"value": 100, "unit": "percent"},
          "height": {"value": 50, "unit": "dp"}
        },
        "style": {
          "backgroundColor": "#FFEBEE",
          "textAlign": "center"
        }
      },
      {
        "type": "element",
        "id": "child-3",
        "elementType": "text",
        "bindings": {"text": "Last (bottom edge)"},
        "layout": {
          "width": {"value": 100, "unit": "percent"},
          "height": {"value": 50, "unit": "dp"}
        },
        "style": {
          "backgroundColor": "#E8F5E9",
          "textAlign": "center"
        }
      }
    ]
  }
}
```

## Final Checklist

Before considering JSON generation complete:

- [ ] Validated with `jq empty`
- [ ] All required fields present
- [ ] All enum values lowercase
- [ ] Correct dimension format
- [ ] Unique IDs throughout
- [ ] Bindings present on all elements
- [ ] Children array present on all containers
- [ ] Comments explain what is being tested
- [ ] File named according to convention
- [ ] Added to test index/manifest

## References

- **Complete Rules**: `.claude/reference/JSON_STRUCTURE_REFERENCE.md`
- **Quick Reference**: `json-generation-rules.md`
- **Templates**: `.claude/agents/testing/templates/`
- **Examples**: `test-configs/`
