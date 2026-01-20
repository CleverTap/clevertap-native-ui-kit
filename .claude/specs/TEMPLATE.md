# [Feature Name]

**Spec Number**: [NNN]  
**Status**: Draft  
**Last Updated**: [Date]

---

## Status Checklist

- [ ] Spec Draft
- [ ] Spec Approved
- [ ] Android Implementation
- [ ] iOS Implementation  
- [ ] Sample App Integration
- [ ] Documentation

---

## Overview

[2-3 paragraphs describing:
- What problem does this solve?
- How does it fit into the system?
- Who uses this feature?]

---

## Requirements

### Functional Requirements
1. [Specific, measurable requirement]
2. [Another requirement]
3. [Edge case requirement]

### Non-Functional Requirements
- **Performance**: [Specific targets, e.g., "< 100ms", "60fps"]
- **Memory**: [Memory constraints]
- **Error Handling**: [How errors are managed]
- **Compatibility**: [Platform/version requirements]

---

## Data Models

### Kotlin (Android)
```kotlin
@Serializable
data class Example(
    val id: String,
    val required: String,
    val optional: String? = null
)
```

### Swift (iOS)
```swift
struct Example: Codable {
    let id: String
    let required: String
    let optional: String?
}
```

### TypeScript (Web/RN - if applicable)
```typescript
interface Example {
  id: string;
  required: string;
  optional?: string;
}
```

---

## JSON Schema & Examples

### Schema
```json
{
  "type": "object",
  "required": ["id", "required"],
  "properties": {
    "id": { "type": "string" },
    "required": { "type": "string" },
    "optional": { "type": "string" }
  }
}
```

### Example Usage
```json
{
  "id": "example_1",
  "required": "value",
  "optional": "optional value"
}
```

### Edge Cases
```json
// Document edge cases with examples
```

---

## Implementation Plan

### Android
**Approach**: [Describe implementation strategy]

**Key Files**:
- `models/Example.kt` - Data model
- `renderer/ExampleRenderer.kt` - Rendering logic
- `parser/ExampleParser.kt` - JSON parsing

**Dependencies**:
```gradle
// List any new dependencies needed
```

**Code Example**:
```kotlin
// Show key implementation pattern
@Composable
fun RenderExample(example: Example) {
    // Implementation
}
```

### iOS  
**Approach**: [Describe implementation strategy]

**Key Files**:
- `Models/Example.swift` - Data model
- `Renderer/ExampleRenderer.swift` - Rendering logic
- `Parser/ExampleParser.swift` - JSON parsing

**Dependencies**:
```swift
// List any new dependencies needed
```

**Code Example**:
```swift
// Show key implementation pattern
struct ExampleView: View {
    let example: Example
    var body: some View {
        // Implementation
    }
}
```

---

## Test Cases

### Unit Tests
- [ ] Valid input with all fields
- [ ] Valid input with only required fields
- [ ] Missing required field returns error
- [ ] Invalid type returns error
- [ ] Edge case: [specific edge case]

### Integration Tests
- [ ] JSON → Parse → Render → UI displays correctly
- [ ] Works with existing features
- [ ] Error scenarios handled gracefully

### Visual Tests
- [ ] Android renders correctly
- [ ] iOS renders correctly
- [ ] Cross-platform visual parity
- [ ] Dark mode support
- [ ] RTL layout support

### Performance Tests
- [ ] Meets performance target: [specify]
- [ ] No memory leaks
- [ ] Handles large payloads

---

## Acceptance Criteria

### Functional
- [ ] Parses valid JSON correctly
- [ ] Handles all required fields
- [ ] Uses defaults for optional fields
- [ ] Returns descriptive errors for invalid input
- [ ] Renders correctly on Android
- [ ] Renders correctly on iOS

### Non-Functional
- [ ] Performance target met: [specify]
- [ ] Memory usage within budget
- [ ] No crashes or exceptions
- [ ] Error messages are user-friendly

### Documentation
- [ ] Reference docs updated
- [ ] Sample app includes example
- [ ] API documentation generated

---

## Known Issues / Gotchas

[Fill this section after implementation]

**Edge Cases Discovered**:
- [Edge case 1 and how it's handled]
- [Edge case 2 and how it's handled]

**Platform Differences**:
- [Difference 1 between Android and iOS]
- [Why it exists and if it's acceptable]

**Performance Considerations**:
- [What to watch out for]
- [Optimization techniques used]

---

## Open Questions

[Questions to be resolved before/during implementation]

- [ ] Question 1?
- [ ] Question 2?

---

## Related Documents

**Dependencies**:
- [Link to specs this depends on]

**Referenced By**:
- [Link to specs that use this]

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | YYYY-MM-DD | Initial spec |

---

**Author**: [Name]  
**Reviewers**: [Names]
