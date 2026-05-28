# Specifications Directory

This directory contains specifications for **new features** (Phase 9+).

Phases 1-8 are already implemented and documented in `../reference/`.

---

## 📋 When to Create a Spec

Create a specification BEFORE implementing:
- New container types
- New element types
- New background types
- Platform support (React Native, Web, Flutter)
- Major architectural changes
- Breaking changes

---

## 📝 How to Write a Spec

1. **Copy the template**: Use `TEMPLATE.md` as your starting point
2. **Fill in all sections**: Don't skip any section
3. **Be specific**: Use concrete examples and measurements
4. **Include both platforms**: Document Android AND iOS approach
5. **List test cases**: What needs to be tested?
6. **Define acceptance criteria**: How do you know it's done?

---

## 📂 Files

| File | Purpose | Status |
|------|---------|--------|
| `TEMPLATE.md` | Template for new specs | ✅ Use this |
| `001-core-data-models.md` | Example spec | ✅ Reference only |

---

## 🔢 Naming Convention

Specs should be named: `NNN-feature-name.md`

Where:
- `NNN` = Three-digit sequential number (002, 003, 004...)
- `feature-name` = Kebab-case descriptive name

**Examples:**
- `009-react-native-support.md`
- `010-web-renderer.md`
- `011-enhanced-animations.md`
- `012-custom-fonts.md`

---

## ✅ Spec Lifecycle

```
1. Draft          Write spec, mark [x] Spec Draft
2. Review         Team reviews, provides feedback
3. Approved       Mark [x] Spec Approved
4. Implement      Build according to spec
5. Test           Verify acceptance criteria
6. Complete       Mark all checkboxes complete
7. Learnings      Update spec with "Gotchas" section
```

---

## 📚 For Existing Features

**Don't create retroactive specs.** 

Phases 1-8 are already documented in `../reference/`:
- `CLAUDE_CODE_REFERENCE_ACTUAL.md` - Complete feature list
- `CLAUDE_CODE_PATTERNS.md` - Code examples
- `COMPONENTS_GUIDE.md` - Container & element details
- `STYLE_THEMING_GUIDE.md` - Style system
- `CLAUDE_CODE_MODELS.md` - Data models

---

## 🎯 Example: Adding a New Container Type

Let's say you want to add a "GRID" container:

1. **Create spec**: `012-grid-container.md`
2. **Define requirements**:
   - Grid layout with configurable columns
   - Responsive sizing
   - Gap between items
3. **Design data model**:
   ```kotlin
   data class GridConfig(
       val columns: Int,
       val gap: Float
   )
   ```
4. **List test cases**:
   - 2 columns with 16dp gap
   - 3 columns with wrap content
   - Responsive column count
5. **Get approved**
6. **Implement** on Android and iOS
7. **Test** against acceptance criteria
8. **Update spec** with learnings

---

## 💡 Tips

**Good specs:**
- Are specific and measurable
- Include code examples
- List all edge cases
- Have clear acceptance criteria
- Document both platforms

**Bad specs:**
- Vague requirements ("should be fast")
- No examples
- Missing edge cases
- No acceptance criteria
- Platform assumptions

---

**Last Updated**: January 20, 2026
