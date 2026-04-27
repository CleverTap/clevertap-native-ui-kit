# Native Display SDK Testing Plan

**Version**: 1.0
**Last Updated**: January 21, 2026
**Progress**: 90 / 130 tests (69% complete)

---

## Overview

This testing plan outlines a comprehensive approach to validating the Native Display SDK across both Android and iOS platforms. The plan is divided into 7 phases, generating a total of 130 test configurations.

### Goals

1. **Cross-Platform Parity**: Ensure identical rendering on Android and iOS
2. **Comprehensive Coverage**: Test all container types, element types, and layout scenarios
3. **Edge Case Validation**: Handle empty containers, extreme values, and stress conditions
4. **Real-World Scenarios**: Simulate actual UI patterns and use cases
5. **Automated Testing**: Enable screenshot capture and visual comparison

---

## Testing Phases

| Phase | Focus Area | Tests | Status | Completion Date |
|-------|-----------|-------|--------|-----------------|
| 1 | Basic Container Types | 5 | COMPLETE | Jan 20, 2026 |
| 2 | Child Count Variations | 25 | COMPLETE | Jan 21, 2026 |
| 3 | Layout & Spacing | 20 | COMPLETE | Jan 21, 2026 |
| 4 | Element Type Combinations | 20 | COMPLETE | Jan 21, 2026 |
| 5 | Style Variations | 20 | COMPLETE | Jan 21, 2026 |
| 6 | Background Types | 20 | NOT STARTED | - |
| 7 | Complex Scenarios | 20 | NOT STARTED | - |
| **TOTAL** | | **130** | **90 COMPLETE** | |

---

## Phase 1: Basic Container Types - COMPLETE

**Status**: COMPLETE
**Tests**: 5 (test-001 to test-005)
**Completion Date**: January 20, 2026

### Purpose
Establish baseline tests for each of the 5 container types with simple, minimal configurations.

### Tests Generated

1. **test-001-vertical-simple.json**
   - Container: VERTICAL
   - Children: TEXT, IMAGE
   - Features: Basic stacking

2. **test-002-horizontal-simple.json**
   - Container: HORIZONTAL
   - Children: TEXT, IMAGE
   - Features: Basic horizontal layout

3. **test-003-box-simple.json**
   - Container: BOX
   - Children: IMAGE, TEXT overlay
   - Features: Absolute positioning

4. **test-004-stack-simple.json**
   - Container: STACK
   - Children: IMAGE, TEXT badge
   - Features: Layered layout

5. **test-005-gallery-simple.json**
   - Container: GALLERY
   - Children: 3 IMAGE items
   - Features: Snapping carousel

### Outcomes
- All 5 container types validated
- Basic rendering confirmed on both platforms
- Template expressions tested with variables

---

## Phase 2: Child Count Variations - COMPLETE

**Status**: COMPLETE
**Tests**: 25 (test-006 to test-030)
**Completion Date**: January 21, 2026

### Purpose
Test how each container type handles different numbers of children, from empty (0) to many (10).

### Test Distribution

| Container | Empty | Single | 3 Children | 5 Children | 10 Children | Total |
|-----------|-------|--------|-----------|-----------|------------|-------|
| VERTICAL | 1 | 1 | 1 | 1 | 1 | 5 |
| HORIZONTAL | 1 | 1 | 1 | 1 | 1 | 5 |
| BOX | 1 | 1 | 1 | 1 | - | 4 |
| STACK | 1 | 1 | 1 | 1 | - | 4 |
| GALLERY | 1 | 1 | 3 (modes) | 1 | 1 | 7 |
| **TOTAL** | | | | | | **25** |

### Key Features Tested
- Empty container edge cases
- Single child alignment
- Multiple children arrangement
- Gallery modes: snapping, free_flow, free_flow_grid
- Nested containers (up to 3 levels)
- Real-world layouts (product cards, news feeds, carousels)

### Outcomes
- All containers handle 0-10 children correctly
- Gallery modes validated (snapping, free_flow, free_flow_grid)
- Nested containers render properly
- No crashes with empty containers

---

## Phase 3: Layout & Spacing Variations - COMPLETE

**Status**: COMPLETE
**Tests**: 20 (test-031 to test-050)
**Completion Date**: January 21, 2026

### Purpose
Comprehensive testing of all arrangement strategies, spacing values, padding variations, and dimension units.

### Tests Generated

#### Arrangement Strategies (7 tests)
1. **test-031-vertical-spaced.json** - SPACED with 12dp spacing
2. **test-032-vertical-space-between.json** - SPACE_BETWEEN strategy
3. **test-033-vertical-space-evenly.json** - SPACE_EVENLY strategy
4. **test-034-vertical-space-around.json** - SPACE_AROUND strategy
5. **test-035-horizontal-start.json** - START alignment
6. **test-036-horizontal-center.json** - CENTER alignment
7. **test-037-horizontal-end.json** - END alignment

#### Spacing Variations (4 tests)
8. **test-038-vertical-spacing-0.json** - 0dp spacing (no gaps)
9. **test-039-vertical-spacing-8.json** - 8dp spacing (compact)
10. **test-040-vertical-spacing-16.json** - 16dp spacing (standard)
11. **test-041-vertical-spacing-32.json** - 32dp spacing (large)

#### Padding Variations (4 tests)
12. **test-042-vertical-padding-uniform.json** - 16dp all sides (uniform)
13. **test-043-vertical-padding-individual.json** - Different per side
14. **test-044-horizontal-padding-asymmetric.json** - Asymmetric padding
15. **test-045-box-padding-large.json** - 32dp all sides (large)

#### Dimension Units (3 tests)
16. **test-046-vertical-wrap-content.json** - WRAP_CONTENT height
17. **test-047-horizontal-percent-width.json** - Percentage widths (30%, 50%, 20%)
18. **test-048-vertical-mixed-units.json** - Mixed DP, PERCENT, WRAP_CONTENT

#### Mixed/Complex (2 tests)
19. **test-049-nested-mixed-arrangements.json** - Different strategies in nested containers
20. **test-050-gallery-spacing-variations.json** - Gallery with 3 spacing configurations

### Outcomes
- All 7 arrangement strategies validated
- Spacing values from 0dp to 32dp tested
- Padding patterns (uniform, individual, asymmetric, large) confirmed
- Dimension units (DP, PERCENT, WRAP_CONTENT) working
- Mixed nested arrangements render correctly

---

## Phase 4: Element Type Combinations - COMPLETE

**Status**: COMPLETE
**Tests**: 20 (test-051 to test-070)
**Completion Date**: January 21, 2026

### Purpose
Test different combinations of element types within containers, both homogeneous (all same type) and heterogeneous (mixed types forming real UI patterns).

### Tests Generated

#### Homogeneous Element Tests (6 tests)
All children are the same element type:
1. **test-051-all-text-elements.json** - 5 TEXT elements with different styles
2. **test-052-all-image-elements.json** - 4 IMAGE elements in 2x2 grid
3. **test-053-all-button-elements.json** - 4 BUTTON elements (action bar variants)
4. **test-054-all-video-elements.json** - 2 VIDEO elements (main + preview)
5. **test-055-all-spacer-elements.json** - 5 SPACER elements with varied heights
6. **test-056-all-divider-elements.json** - 5 DIVIDER elements with varied styles

#### Heterogeneous Element Tests (14 tests)
Mixed element types forming real-world UI patterns:
7. **test-057-product-card.json** - IMAGE + TEXT + TEXT + BUTTON (e-commerce)
8. **test-058-login-form.json** - TEXT + DIVIDER + BUTTON + BUTTON (auth)
9. **test-059-profile-header.json** - IMAGE + TEXT + TEXT + SPACER + BUTTON (profile)
10. **test-060-media-player.json** - VIDEO + SPACER + TEXT + BUTTON + BUTTON (player)
11. **test-061-article-layout.json** - TEXT + IMAGE + TEXT + DIVIDER + TEXT (blog)
12. **test-062-action-sheet.json** - TEXT + DIVIDER + 4 BUTTON + DIVIDER (modal)
13. **test-063-stats-card.json** - TEXT + SPACER + TEXT + TEXT + TEXT (dashboard)
14. **test-064-gallery-item.json** - IMAGE + SPACER + TEXT + TEXT + BUTTON (gallery)
15. **test-065-notification.json** - IMAGE + TEXT + TEXT + SPACER + BUTTON (messages)
16. **test-066-pricing-card.json** - TEXT + DIVIDER + 3 TEXT + SPACER + BUTTON (pricing)
17. **test-067-hero-banner.json** - IMAGE + TEXT + TEXT + BUTTON in STACK (marketing)
18. **test-068-social-post.json** - IMAGE + TEXT + IMAGE + TEXT + SPACER + BUTTON (social)
19. **test-069-settings-row.json** - TEXT + SPACER + DIVIDER pattern (settings)
20. **test-070-feature-showcase.json** - IMAGE + TEXT + TEXT + DIVIDER (features)

### Key Features Tested
- All 6 element types: TEXT, IMAGE, BUTTON, VIDEO, SPACER, DIVIDER
- Homogeneous containers (all same type)
- Heterogeneous containers (mixed types)
- Real-world UI patterns (14 different patterns)
- Proper element combinations and hierarchy
- Spacing with SPACER elements
- Visual separation with DIVIDER elements

### Outcomes
- Element type coverage: TEXT (100%), IMAGE (45%), BUTTON (55%), VIDEO (10%), SPACER (35%), DIVIDER (30%)
- 14 unique real-world UI patterns validated
- Container types used: VERTICAL (18), HORIZONTAL (3), STACK (1)
- All tests render correctly with proper element combinations

---

## Phase 5: Style Variations - COMPLETE

**Status**: COMPLETE
**Tests**: 20 (test-071 to test-090)
**Completion Date**: January 21, 2026

### Purpose
Test all style properties and visual treatments, including text properties, visual properties, style cascading, inheritance, and complex styled combinations.

### Tests Generated

#### Text Style Variations (7 tests)
1. **test-071-text-colors.json** - textColor with various colors and alpha values
2. **test-072-font-sizes.json** - fontSize from 12sp to 48sp
3. **test-073-font-weights.json** - fontWeight (normal, medium, semibold, bold)
4. **test-074-text-alignment.json** - textAlign (start, center, end)
5. **test-075-text-decoration.json** - textDecoration (none, underline, line-through)
6. **test-076-line-height.json** - lineHeight (1.0, 1.2, 1.5, 2.0)
7. **test-077-font-families.json** - fontFamily (system, monospace, serif)

#### Visual Style Variations (7 tests)
8. **test-078-border-radius.json** - borderRadius from 0 to 50 (pill shape)
9. **test-079-border-width-color.json** - borderWidth (1-8dp) with different colors
10. **test-080-shadows-light.json** - Light shadows (opacity 0.1-0.2, radius 2-6)
11. **test-081-shadows-medium.json** - Medium shadows (opacity 0.25-0.35, radius 8-16)
12. **test-082-shadows-heavy.json** - Heavy shadows (opacity 0.4-0.6, radius 20-32)
13. **test-083-opacity-variations.json** - opacity from 1.0 to 0.2
14. **test-084-combined-visual-styles.json** - Multiple visual properties combined

#### Style Cascading & Inheritance (4 tests)
15. **test-085-text-style-inheritance.json** - Text property inheritance through nested containers
16. **test-086-style-class-usage.json** - Reusable styleClasses (7 classes defined)
17. **test-087-inline-vs-inherited.json** - Inline styles overriding inheritance
18. **test-088-theme-default-styles.json** - Theme defaultStyle affecting all elements

#### Complex Style Combinations (2 tests)
19. **test-089-styled-product-card.json** - E-commerce card with complex styling
20. **test-090-styled-profile-card.json** - Profile card with gradients, shadows, overlays

### Key Features Tested
- **Text Properties** (inherited by children):
  - textColor (including alpha channel)
  - fontSize (12sp - 48sp range)
  - fontWeight (4 variations)
  - fontFamily (3 types)
  - lineHeight (4 variations)
  - textDecoration (3 types)
  - textAlign (3 alignments)
  - opacity (5 variations)

- **Visual Properties** (not inherited):
  - backgroundColor (solid colors)
  - borderRadius (0 - 50dp)
  - borderWidth (1 - 8dp)
  - borderColor (various colors)
  - shadowColor, shadowOpacity, shadowRadius, shadowOffset (3 elevation levels)

- **Style Resolution**:
  - Theme defaultStyle → StyleClass → Inline Style → Parent Inherited
  - Demonstrated in 4 dedicated tests
  - 7 reusable styleClasses defined and used

- **Complex Styling**:
  - Product card: badges, overlays, multiple shadows, gradient-like effects
  - Profile card: STACK layers, gradient overlays, circular avatar, stats grid

### Outcomes
- All text style properties validated (8 properties)
- All visual style properties tested (borders, shadows, opacity)
- Style inheritance working correctly (text properties cascade)
- Visual properties correctly NOT inheriting
- StyleClasses enable reusable styling
- Inline styles properly override inherited/class styles
- Theme defaultStyle provides global baseline
- Complex real-world styling scenarios render correctly

---

## Phase 6: Background Types - NOT STARTED

**Status**: NOT STARTED
**Tests**: 20 (test-091 to test-110)

### Purpose
Test all 10+ background types and variations.

### Coverage Plan

#### Background Types (10+)
1. **solid**: Solid color
2. **linear_gradient**: Linear gradient with angle
3. **radial_gradient**: Radial gradient with center/radius
4. **sweep_gradient**: Sweep gradient
5. **pattern_stripes**: Striped pattern
6. **pattern_checkerboard**: Checkerboard pattern
7. **pattern_dots**: Dotted pattern
8. **animated_gradient**: Animated gradient
9. **animated_shimmer**: Shimmer effect
10. **animated_pulse**: Pulsing effect

#### Test Breakdown
- **Solid colors**: 2 tests (with opacity variations)
- **Linear gradients**: 4 tests (angles: 0, 45, 90, 180, multiple colors)
- **Radial gradients**: 3 tests (center positions, radius variations)
- **Sweep gradient**: 2 tests
- **Patterns**: 3 tests (stripes, checkerboard, dots)
- **Animated backgrounds**: 6 tests (2 per animation type)

---

## Phase 7: Complex Scenarios - NOT STARTED

**Status**: NOT STARTED
**Tests**: 20 (test-111 to test-130)

### Purpose
Real-world UI patterns and stress tests.

### Coverage Plan

#### Real-World Patterns (10 tests)
1. **Product Card**: Image, title, price, rating, button
2. **Login Form**: Logo, inputs, button, links
3. **Profile Screen**: Avatar, name, bio, stats grid
4. **Settings Page**: List of settings with icons and switches
5. **Chat Bubble**: Avatar, message, timestamp
6. **Dashboard Widget**: Header, chart, footer
7. **Article Card**: Featured image, category tag, title, excerpt
8. **Pricing Card**: Icon, price, features list, CTA
9. **Notification Item**: Icon, title, description, timestamp
10. **Media Player**: Image, title, controls, progress bar

#### Stress Tests (5 tests)
1. **Deep nesting**: 5 levels of nested containers
2. **Many children**: 50+ children in container
3. **Large content**: Very long text, huge images
4. **Mixed complexity**: All element types in one screen
5. **Dynamic sizing**: Many wrap_content elements

#### Edge Cases (5 tests)
1. **Empty nested**: Empty containers within containers
2. **Zero dimensions**: 0dp width/height elements
3. **Extreme values**: 9999dp, 1dp sizes
4. **No style**: Elements with minimal styling
5. **Overlay stress**: 10+ layers in STACK

---

## Test File Standards

All test files must adhere to these standards:

### Required Structure
```json
{
  "theme": {
    "id": "test-theme",
    "defaultStyle": { ... }
  },
  "root": {
    "id": "unique-id",
    "containerType": "...",
    "layout": {
      "width": { "value": X, "unit": "..." },
      "height": { "value": Y, "unit": "..." }
    },
    "children": [ ... ]
  }
}
```

### Layout Requirements
1. Every node MUST have `width` AND `height`
2. All dimension values must include `value` and `unit`
3. Use proper dimension units (dp, sp, percent, px, wrap_content, match_parent)

### Content Requirements
1. NO `variables` key (all values inline)
2. Use realistic content (real text, image URLs)
3. Use picsum.photos for placeholder images
4. Vary visual styling across tests

### Style Requirements
1. Use diverse backgrounds (solid, gradients, patterns)
2. Vary color schemes across tests
3. Include borders, shadows, and other visual treatments
4. Test opacity and transparency

---

## Testing Methodology

### 1. Test Generation
- Generate JSON test files according to phase specifications
- Validate JSON syntax and structure
- Verify all required fields present
- Ensure unique test IDs

### 2. Visual Testing
- Load test in Android sample apps (Compose and XML)
- Load test in iOS sample apps (SwiftUI and UIKit)
- Capture screenshots for each platform
- Compare visual output

### 3. Cross-Platform Validation
- Compare Android vs iOS screenshots
- Calculate pixel difference percentage
- Generate diff images highlighting differences
- Create HTML comparison report

### 4. Regression Testing
- Maintain baseline screenshots
- Re-run tests after SDK changes
- Identify visual regressions
- Track cross-platform parity percentage

---

## Success Metrics

### Coverage Metrics
- **Container Types**: 5/5 tested (100%)
- **Element Types**: 6/6 tested (TEXT, IMAGE, BUTTON, VIDEO, SPACER, DIVIDER) - COMPLETE
- **Arrangement Strategies**: 7/7 tested (100%) - COMPLETE
- **Background Types**: 10+/10+ tested (target by Phase 6)

### Quality Metrics
- **Cross-Platform Parity**: >95% visual similarity target
- **Test Pass Rate**: >98% pass rate target
- **Crash Rate**: 0% (no crashes on any test)
- **Performance**: <1s render time for 95% of tests

### Progress Metrics
- **Phase Completion**: 5/7 phases complete (71%)
- **Test Completion**: 90/130 tests complete (69%)
- **Documentation**: 100% of completed phases documented

---

## Timeline

| Phase | Start Date | End Date | Duration | Status |
|-------|-----------|----------|----------|--------|
| Phase 1 | Jan 19, 2026 | Jan 20, 2026 | 1 day | COMPLETE |
| Phase 2 | Jan 20, 2026 | Jan 21, 2026 | 1 day | COMPLETE |
| Phase 3 | Jan 21, 2026 | Jan 21, 2026 | 1 day | COMPLETE |
| Phase 4 | Jan 21, 2026 | Jan 21, 2026 | 1 day | COMPLETE |
| Phase 5 | Jan 21, 2026 | Jan 21, 2026 | 1 day | COMPLETE |
| Phase 6 | Jan 22, 2026 | Jan 23, 2026 | 2 days | NOT STARTED |
| Phase 7 | Jan 24, 2026 | Jan 26, 2026 | 3 days | NOT STARTED |
| **Total** | | | **10 days** | **71% COMPLETE** |

---

## Tools & Scripts

### Test Generation
- Manual generation via Testing Agent
- Validate with JSON linter
- Automated test numbering

### Screenshot Capture
- `capture-android.sh`: Capture Android screenshots
- `capture-ios.sh`: Capture iOS screenshots
- Device/simulator automation

### Visual Comparison
- `compare-screenshots.sh`: Compare cross-platform
- `generate-report.sh`: Create HTML comparison report
- Pixel-by-pixel difference calculation

---

## Documentation

### Per Phase
- **PHASE_N_SUMMARY.md**: Detailed phase documentation
- Test file descriptions
- Use cases and scenarios
- Visual variety notes

### Overall
- **TEST_INDEX.md**: Complete test catalog
- **TESTING_PLAN.md**: This document
- **README.md**: General test file documentation

---

## Next Steps

### Immediate (Phase 6)
1. Generate 20 background type tests
2. Test solid colors with opacity
3. Test linear gradients (various angles and colors)
4. Test radial and sweep gradients
5. Test pattern backgrounds (stripes, checkerboard, dots)
6. Test animated backgrounds (shimmer, pulse, gradient animation)
7. Update documentation

### Short Term (Phase 7)
1. Generate background type tests
2. Test all gradient types (linear, radial, sweep)
3. Test pattern backgrounds (stripes, checkerboard, dots)
4. Test animated backgrounds (shimmer, pulse)
5. Begin cross-platform screenshot capture

### Long Term (Phase 7)
1. Generate complex scenario tests
2. Complete all 130 tests
3. Achieve >95% cross-platform parity
4. Automate regression testing

---

## Related Resources

- **Test Files**: `/Users/lalitkumar/StudioProjects/clevertap-native-ui-kit/test-configs/`
- **SDK Reference**: `/.claude/reference/CLAUDE_CODE_REFERENCE_ACTUAL.md`
- **Components Guide**: `/.claude/reference/COMPONENTS_GUIDE.md`
- **Testing Agent**: `/.claude/agents/testing/AGENT.md`

---

**Current Status**: 90 / 130 tests complete (69%)
**Next Milestone**: Phase 6 completion (110 / 130 tests)
**Target Completion**: January 26, 2026
