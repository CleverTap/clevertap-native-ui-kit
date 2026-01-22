# Test Configuration Files

This folder contains JSON test configurations for the Native Display SDK testing framework.

## Purpose

These test files are used to verify the SDK's rendering capabilities across different container types, element types, and layout scenarios. They serve as both:

1. **Test Cases**: For automated visual testing and cross-platform parity verification
2. **Examples**: Reference implementations showing proper JSON structure and best practices

## File Structure

Each test file follows this naming convention:
```
test-{NNN}-{container-type}-{variation}.json
```

### Current Test Files

**Total Tests**: 90 / 130 (69% complete)

**Phase 1: Basic Container Types (5 tests)** - COMPLETE
| File | Container Type | Description |
|------|---------------|-------------|
| `test-001-vertical-simple.json` | VERTICAL | Basic vertical stacking with text and image |
| `test-002-horizontal-simple.json` | HORIZONTAL | Basic horizontal layout with text and image |
| `test-003-box-simple.json` | BOX | Absolute positioning with image and overlaid text |
| `test-004-stack-simple.json` | STACK | Layered layout with image and badge text |
| `test-005-gallery-simple.json` | GALLERY | Scrollable carousel with snapping behavior |

**Phase 2: Child Count Variations (25 tests)** - COMPLETE

*VERTICAL Container (5 tests)*
| File | Children | Description |
|------|----------|-------------|
| `test-006-vertical-empty.json` | 0 | Empty container edge case |
| `test-007-vertical-single-child.json` | 1 | Single centered text element |
| `test-008-vertical-3-children.json` | 3 | Product showcase layout |
| `test-009-vertical-5-children.json` | 5 | Feature highlights with CTA |
| `test-010-vertical-10-children.json` | 10 | News feed simulation |

*HORIZONTAL Container (5 tests)*
| File | Children | Description |
|------|----------|-------------|
| `test-011-horizontal-empty.json` | 0 | Empty horizontal container |
| `test-012-horizontal-single-child.json` | 1 | Single centered button |
| `test-013-horizontal-3-children.json` | 3 | Image gallery row |
| `test-014-horizontal-5-children.json` | 5 | Tag/chip row layout |
| `test-015-horizontal-10-children.json` | 10 | Icon row with many items |

*BOX Container (4 tests)*
| File | Children | Description |
|------|----------|-------------|
| `test-016-box-empty.json` | 0 | Empty box container |
| `test-017-box-single-child.json` | 1 | Perfect centering demo |
| `test-018-box-3-children.json` | 3 | Corner and center positioning |
| `test-019-box-5-children.json` | 5 | Complex overlay composition |

*STACK Container (4 tests)*
| File | Children | Description |
|------|----------|-------------|
| `test-020-stack-empty.json` | 0 | Empty stack container |
| `test-021-stack-single-child.json` | 1 | Single layer with opacity |
| `test-022-stack-3-children.json` | 3 | Multi-layer overlay design |
| `test-023-stack-5-children.json` | 5 | Complex multi-layer composition |

*GALLERY Container (7 tests)*
| File | Children | Mode | Description |
|------|----------|------|-------------|
| `test-024-gallery-empty.json` | 0 | snapping | Empty gallery |
| `test-025-gallery-single-child.json` | 1 | snapping | Single item with peek |
| `test-026-gallery-3-children-snapping.json` | 3 | snapping | Card carousel |
| `test-027-gallery-5-children-snapping.json` | 5 | snapping | Product carousel |
| `test-028-gallery-10-children-snapping.json` | 10 | snapping | Long scrolling gallery |
| `test-029-gallery-3-children-free-flow.json` | 3 | free_flow | Natural scrolling |
| `test-030-gallery-3-children-free-flow-grid.json` | 3 | free_flow_grid | 2-column grid layout |

**Phase 3: Layout & Spacing Variations (20 tests)** - COMPLETE

*Arrangement Strategies (7 tests)*
| File | Strategy | Description |
|------|----------|-------------|
| `test-031-vertical-spaced.json` | SPACED | Fixed 12dp spacing |
| `test-032-vertical-space-between.json` | SPACE_BETWEEN | Equal space between, no edges |
| `test-033-vertical-space-evenly.json` | SPACE_EVENLY | Equal space including edges |
| `test-034-vertical-space-around.json` | SPACE_AROUND | Half space at edges |
| `test-035-horizontal-start.json` | START | Align to start (left) |
| `test-036-horizontal-center.json` | CENTER | Center alignment |
| `test-037-horizontal-end.json` | END | Align to end (right) |

*Spacing Variations (4 tests)*
| File | Spacing | Description |
|------|---------|-------------|
| `test-038-vertical-spacing-0.json` | 0dp | No gaps between elements |
| `test-039-vertical-spacing-8.json` | 8dp | Compact spacing |
| `test-040-vertical-spacing-16.json` | 16dp | Standard spacing |
| `test-041-vertical-spacing-32.json` | 32dp | Large/premium spacing |

*Padding Variations (4 tests)*
| File | Padding Type | Description |
|------|-------------|-------------|
| `test-042-vertical-padding-uniform.json` | Uniform (16dp all) | Balanced frame |
| `test-043-vertical-padding-individual.json` | Individual sides | Different per side |
| `test-044-horizontal-padding-asymmetric.json` | Asymmetric | Unique combinations |
| `test-045-box-padding-large.json` | Large (32dp all) | Dramatic framing |

*Dimension Units (3 tests)*
| File | Units | Description |
|------|-------|-------------|
| `test-046-vertical-wrap-content.json` | WRAP_CONTENT | Auto-size to content |
| `test-047-horizontal-percent-width.json` | PERCENT | Responsive columns (30%, 50%, 20%) |
| `test-048-vertical-mixed-units.json` | Mixed | DP + PERCENT + WRAP_CONTENT |

*Mixed/Complex (2 tests)*
| File | Complexity | Description |
|------|-----------|-------------|
| `test-049-nested-mixed-arrangements.json` | Nested strategies | Different strategies in nested containers |
| `test-050-gallery-spacing-variations.json` | Gallery spacing | 3 galleries with different spacing configs |

**Phase 4: Element Type Combinations (20 tests)** - COMPLETE

*Homogeneous Element Tests (6 tests)*
| File | Element Type | Description |
|------|-------------|-------------|
| `test-051-all-text-elements.json` | TEXT (5) | Typography showcase with hierarchy |
| `test-052-all-image-elements.json` | IMAGE (4) | Image gallery 2x2 grid |
| `test-053-all-button-elements.json` | BUTTON (4) | Action bar with button variants |
| `test-054-all-video-elements.json` | VIDEO (2) | Video player interface |
| `test-055-all-spacer-elements.json` | SPACER (5) | Spacing control with varied heights |
| `test-056-all-divider-elements.json` | DIVIDER (5) | Visual separation techniques |

*Heterogeneous Element Tests - Real UI Patterns (14 tests)*
| File | Pattern | Elements | Description |
|------|---------|----------|-------------|
| `test-057-product-card.json` | E-commerce | IMAGE + 2 TEXT + BUTTON | Product display |
| `test-058-login-form.json` | Auth | TEXT + DIVIDER + 2 BUTTON | Login interface |
| `test-059-profile-header.json` | Profile | IMAGE + 2 TEXT + SPACER + BUTTON | User profile |
| `test-060-media-player.json` | Player | VIDEO + SPACER + TEXT + 2 BUTTON | Video controls |
| `test-061-article-layout.json` | Blog | TEXT + IMAGE + TEXT + DIVIDER + TEXT | Article content |
| `test-062-action-sheet.json` | Modal | TEXT + DIVIDER + 4 BUTTON + DIVIDER | Action menu |
| `test-063-stats-card.json` | Dashboard | TEXT + SPACER + 3 TEXT | Metrics display |
| `test-064-gallery-item.json` | Gallery | IMAGE + SPACER + 2 TEXT + BUTTON | Photo card |
| `test-065-notification.json` | Messages | IMAGE + 2 TEXT + SPACER + BUTTON | Notification |
| `test-066-pricing-card.json` | Pricing | TEXT + DIVIDER + 3 TEXT + SPACER + BUTTON | Subscription |
| `test-067-hero-banner.json` | Marketing | IMAGE + 2 TEXT + BUTTON (STACK) | Landing page |
| `test-068-social-post.json` | Social | IMAGE + TEXT + IMAGE + TEXT + SPACER + BUTTON | User post |
| `test-069-settings-row.json` | Settings | TEXT + SPACER + DIVIDER (pattern) | Settings list |
| `test-070-feature-showcase.json` | Features | IMAGE + 2 TEXT + DIVIDER | Feature highlight |

See **TEST_INDEX.md** for complete test catalog.

## Test File Requirements

All test configuration files MUST adhere to these requirements:

### 1. Complete Layout Definitions
Every node (container or element) MUST have both `width` AND `height` defined in the `layout` object.

```json
"layout": {
  "width": { "value": 100, "unit": "percent" },
  "height": { "value": 0, "unit": "wrap_content" }
}
```

### 2. Valid Dimension Units
- `dp` - Density-independent pixels
- `sp` - Scale-independent pixels (for text)
- `percent` - Percentage of parent
- `px` - Raw pixels
- `wrap_content` - Fit to content (use value: 0)
- `match_parent` - Match parent size (use value: 100 with percent)

### 3. Required Structure
Each test file must include:
- `theme` (optional but recommended)
- `root` (required - the top-level container)

**Note**: Phase 2+ tests do NOT include `variables` key. All values are inline.

## Usage

### For Android Sample Apps
1. Place JSON file in the app's assets or use the file picker
2. Load via `NativeDisplayView` or XML integration

### For iOS Sample Apps
1. Include JSON in bundle or load from URL
2. Render using `NativeDisplayView`

### For Automated Testing
1. Use screenshot capture scripts in `.claude/agents/testing/scripts/`
2. Generate visual comparison reports
3. Track cross-platform parity

## Adding New Test Files

When creating new test configurations:

1. Follow the naming convention
2. Ensure ALL elements have width AND height
3. Include descriptive variables for dynamic content
4. Add metadata comments explaining the test purpose
5. Update this README with the new test entry

## Validation

Before using a test file, validate it has:
- [ ] Valid JSON syntax
- [ ] All required fields (theme, variables, root)
- [ ] Width and height on every element
- [ ] Proper dimension units
- [ ] Valid container and element types
- [ ] Correct binding syntax for dynamic content

## Test Phases

This folder follows a 7-phase testing plan:

1. **Phase 1** (5 tests): Basic container types - COMPLETE
2. **Phase 2** (25 tests): Child count variations - COMPLETE
3. **Phase 3** (20 tests): Layout & spacing variations - COMPLETE
4. **Phase 4** (20 tests): Element type combinations - COMPLETE
5. **Phase 5** (20 tests): Style variations - COMPLETE
6. **Phase 6** (20 tests): Background types - NOT STARTED
7. **Phase 7** (20 tests): Complex scenarios - NOT STARTED

See **TESTING_PLAN.md** for complete phase details and timeline.

## Related Documentation

- **TEST_INDEX.md**: Complete test catalog with descriptions
- **TESTING_PLAN.md**: Comprehensive testing strategy and timeline
- **PHASE_2_SUMMARY.md**: Detailed Phase 2 documentation
- **PHASE_3_SUMMARY.md**: Detailed Phase 3 documentation
- **PHASE_4_SUMMARY.md**: Detailed Phase 4 documentation
- **PHASE_5_SUMMARY.md**: Detailed Phase 5 documentation
- SDK Reference: `/.claude/reference/CLAUDE_CODE_REFERENCE_ACTUAL.md`
- Components Guide: `/.claude/reference/COMPONENTS_GUIDE.md`
- Testing Agent: `/.claude/agents/testing/AGENT.md`

---

**Last Updated**: January 21, 2026
**Progress**: 90 / 130 tests complete (69%)
