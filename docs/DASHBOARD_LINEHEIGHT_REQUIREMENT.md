# Dashboard Requirement: lineHeight Support

**Date**: February 2025
**Priority**: High
**Impact**: Cross-platform rendering consistency

---

## Problem

Text elements render differently on Android and iOS when `lineHeight` is not explicitly specified:

| Platform | Default Calculation | fontSize: 16 Result | Visual Impact |
|----------|---------------------|---------------------|---------------|
| Android  | `fontSize × 1.5`    | 24sp per text       | Shows ~7 texts in 160dp container |
| iOS      | `fontSize × 1.176`  | 18.8pt per text     | Shows ~9 texts in 160dp container |

This causes **preview-to-device mismatch** and **Android-iOS inconsistency**.

---

## Solution

### 1. Always Include lineHeight in Generated JSON

When generating Native Display JSON configurations:

```json
{
  "elementType": "text",
  "style": {
    "fontSize": 16,
    "lineHeight": 20  // ✅ Always include this
  }
}
```

### 2. Calculation Formula

Use this formula when `lineHeight` is not explicitly set by user:

```typescript
lineHeight = fontSize * 1.4  // Recommended default
```

**Alternative factors:**
- `1.4` - Balanced (recommended for cross-platform)
- `1.5` - More spacing (matches Android native default)
- Custom - Allow designers to override

### 3. Dashboard Preview Rendering

Apply the same `lineHeight` logic in web preview:

```typescript
// Read from JSON
const fontSize = style.fontSize || 14;
const lineHeight = style.lineHeight || (fontSize * 1.4);

// Apply to CSS
element.style.fontSize = `${fontSize}px`;
element.style.lineHeight = `${lineHeight}px`;
```

---

## Implementation Checklist

- [ ] Update JSON generation to include `lineHeight` field
- [ ] Calculate `lineHeight = fontSize × 1.4` as default
- [ ] Add optional UI control for custom lineHeight
- [ ] Update web preview renderer to respect `lineHeight`
- [ ] Test Android and iOS preview consistency
- [ ] Validate against actual device rendering

---

## Technical Details

### SDK Support

✅ Both Android and iOS SDKs fully support `lineHeight` property:
- Parsed from JSON
- Applied during text rendering
- Cascades to child elements

### JSON Property

`fontSize` and `lineHeight` now use the `TextDimension` type, which supports two formats:

**Format 1 — Platform units (backward compatible):**
```json
{
  "style": {
    "fontSize": 16,
    "lineHeight": 20
  }
}
```

**Format 2 — Percentage of container height (matches FE behavior):**
```json
{
  "style": {
    "fontSize": { "value": 40, "unit": "percent" },
    "lineHeight": { "value": 56, "unit": "percent" }
  }
}
```

Percentage formula: `rootContainerHeight × value / 1000` (divisor = 1000, matching FE). Always relative to the root container height, regardless of nesting depth.

### Platform Behavior

**With explicit lineHeight:**
- Android uses specified value
- iOS uses specified value
- ✅ Consistent rendering

**Without lineHeight:**
- Android calculates `fontSize × 1.5`
- iOS calculates `fontSize × 1.176`
- ❌ Inconsistent rendering

---

## Expected Outcome

After implementation:
1. ✅ Dashboard preview matches actual device rendering
2. ✅ Android and iOS render identically
3. ✅ WYSIWYG behavior for designers
4. ✅ No need for platform-specific configurations

---

## Contact

For questions or clarifications, contact the SDK team.
