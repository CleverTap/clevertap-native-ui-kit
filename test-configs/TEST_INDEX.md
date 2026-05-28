# Test Configuration Index

Complete catalog of all test configuration files for the Native Display SDK.

**Last Updated**: January 21, 2026
**Total Tests**: 90 / 130 (69% complete)

---

## Test Progress by Phase

| Phase | Description | Tests | Status |
|-------|-------------|-------|--------|
| Phase 1 | Basic Container Types | 5 | COMPLETE |
| Phase 2 | Child Count Variations | 25 | COMPLETE |
| Phase 3 | Layout & Spacing | 20 | COMPLETE |
| Phase 4 | Element Type Combinations | 20 | COMPLETE |
| Phase 5 | Style Variations | 20 | COMPLETE |
| Phase 6 | Background Types | 20 | NOT STARTED |
| Phase 7 | Complex Scenarios | 20 | NOT STARTED |
| **TOTAL** | | **130** | **90 COMPLETE** |

---

## Phase 1: Basic Container Types (5 tests) - COMPLETE

### test-001-vertical-simple.json
- **Container**: VERTICAL
- **Children**: 2 (TEXT, IMAGE)
- **Features**: Basic vertical stacking, arrangement strategy, padding
- **Variables**: title, imageUrl

### test-002-horizontal-simple.json
- **Container**: HORIZONTAL
- **Children**: 2 (TEXT, IMAGE)
- **Features**: Basic horizontal layout, space-between arrangement
- **Variables**: label, iconUrl

### test-003-box-simple.json
- **Container**: BOX
- **Children**: 2 (IMAGE, TEXT overlay)
- **Features**: Absolute positioning with offsets, centered text
- **Variables**: backgroundUrl, overlayText

### test-004-stack-simple.json
- **Container**: STACK
- **Children**: 2 (IMAGE, TEXT badge)
- **Features**: Layered layout, corner positioning
- **Variables**: heroImage, badgeText

### test-005-gallery-simple.json
- **Container**: GALLERY
- **Children**: 3 (IMAGE cards)
- **Features**: Snapping mode, peek configuration, horizontal scrolling
- **Variables**: image1, image2, image3

---

## Phase 2: Child Count Variations (25 tests) - COMPLETE

### VERTICAL Container (5 tests)

#### test-006-vertical-empty.json
- **Children**: 0
- **Purpose**: Empty container edge case
- **Style**: Solid background with border

#### test-007-vertical-single-child.json
- **Children**: 1 (TEXT)
- **Purpose**: Single child with center alignment
- **Style**: Linear gradient background

#### test-008-vertical-3-children.json
- **Children**: 3 (TEXT header, IMAGE, TEXT description)
- **Purpose**: Product showcase layout
- **Style**: Solid color background with space-between arrangement

#### test-009-vertical-5-children.json
- **Children**: 5 (TEXT title, 2x TEXT features, IMAGE, BUTTON)
- **Purpose**: Feature highlights with CTA
- **Style**: Radial gradient background with spaced arrangement

#### test-010-vertical-10-children.json
- **Children**: 10 (TEXT header, alternating TEXT/IMAGE news items)
- **Purpose**: News feed simulation
- **Style**: Light background with consistent spacing

---

### HORIZONTAL Container (5 tests)

#### test-011-horizontal-empty.json
- **Children**: 0
- **Purpose**: Empty horizontal container
- **Style**: Linear gradient background

#### test-012-horizontal-single-child.json
- **Children**: 1 (BUTTON)
- **Purpose**: Single centered button
- **Style**: Solid background with center alignment

#### test-013-horizontal-3-children.json
- **Children**: 3 (IMAGE cards)
- **Purpose**: Image gallery row
- **Style**: Space-evenly arrangement with border radius

#### test-014-horizontal-5-children.json
- **Children**: 5 (TEXT tags)
- **Purpose**: Tag/chip row layout
- **Style**: Gradient background with space-between arrangement

#### test-015-horizontal-10-children.json
- **Children**: 10 (IMAGE icons)
- **Purpose**: Icon row with many items
- **Style**: Light background with circular images

---

### BOX Container (4 tests)

#### test-016-box-empty.json
- **Children**: 0
- **Purpose**: Empty box container
- **Style**: Radial gradient with border

#### test-017-box-single-child.json
- **Children**: 1 (TEXT centered)
- **Purpose**: Perfect centering demonstration
- **Style**: Dark background with centered text

#### test-018-box-3-children.json
- **Children**: 3 (TEXT top-left, IMAGE center, TEXT bottom-right)
- **Purpose**: Corner and center positioning
- **Style**: Linear gradient with positioned elements

#### test-019-box-5-children.json
- **Children**: 5 (IMAGE background, TEXT badge, TEXT title, TEXT subtitle, BUTTON)
- **Purpose**: Complex overlay layout
- **Style**: Multiple layers with overlay positioning

---

### STACK Container (4 tests)

#### test-020-stack-empty.json
- **Children**: 0
- **Purpose**: Empty stack container
- **Style**: Linear gradient background

#### test-021-stack-single-child.json
- **Children**: 1 (IMAGE base layer)
- **Purpose**: Single layer with opacity
- **Style**: Light background with semi-transparent image

#### test-022-stack-3-children.json
- **Children**: 3 (IMAGE, VERTICAL container overlay, TEXT badge)
- **Purpose**: Layered design with multiple overlays
- **Style**: Multiple layers with different z-indices

#### test-023-stack-5-children.json
- **Children**: 5 (IMAGE, gradient overlay, badge, content container, button)
- **Purpose**: Complex multi-layer composition
- **Style**: Full-featured stack with all layer types

---

### GALLERY Container (7 tests)

#### test-024-gallery-empty.json
- **Children**: 0
- **Mode**: snapping
- **Purpose**: Empty gallery container
- **Style**: Light background

#### test-025-gallery-single-child.json
- **Children**: 1 (IMAGE)
- **Mode**: snapping
- **Purpose**: Single item gallery with peek
- **Style**: Peek before/after configuration

#### test-026-gallery-3-children-snapping.json
- **Children**: 3 (VERTICAL card containers)
- **Mode**: snapping
- **Purpose**: Card-based gallery with snapping
- **Style**: Shadowed cards with peek and spacing

#### test-027-gallery-5-children-snapping.json
- **Children**: 5 (IMAGE items)
- **Mode**: snapping
- **Purpose**: Product carousel
- **Style**: Bordered images with large peek

#### test-028-gallery-10-children-snapping.json
- **Children**: 10 (IMAGE items)
- **Mode**: snapping
- **Purpose**: Long scrolling gallery
- **Style**: Compact images with minimal spacing

#### test-029-gallery-3-children-free-flow.json
- **Children**: 3 (VERTICAL card containers)
- **Mode**: free_flow
- **Purpose**: Free-scrolling without snapping
- **Style**: Card layout with natural scrolling

#### test-030-gallery-3-children-free-flow-grid.json
- **Children**: 3 (VERTICAL grid items)
- **Mode**: free_flow_grid
- **Purpose**: Grid layout with 2 columns
- **Style**: Grid items with variable heights

---

## Phase 3: Layout & Spacing Variations (20 tests) - COMPLETE

### Arrangement Strategies (7 tests)

#### test-031-vertical-spaced.json
- **Strategy**: SPACED with 12dp spacing
- **Children**: 5 (header, description, 3 cards)
- **Purpose**: Fixed spacing between each element

#### test-032-vertical-space-between.json
- **Strategy**: SPACE_BETWEEN
- **Children**: 5 (header, description, 3 images)
- **Purpose**: Equal space between items, no space at edges

#### test-033-vertical-space-evenly.json
- **Strategy**: SPACE_EVENLY
- **Children**: 5 (header, description, 3 boxes)
- **Purpose**: Equal space including edges

#### test-034-vertical-space-around.json
- **Strategy**: SPACE_AROUND
- **Children**: 5 (header, description, 3 circular images)
- **Purpose**: Half space at edges, full space between

#### test-035-horizontal-start.json
- **Strategy**: START alignment
- **Children**: 3 (nested vertical containers)
- **Purpose**: Items aligned to start (left) with no spacing

#### test-036-horizontal-center.json
- **Strategy**: CENTER alignment
- **Children**: 3 (nested vertical containers)
- **Purpose**: Items grouped and centered horizontally

#### test-037-horizontal-end.json
- **Strategy**: END alignment
- **Children**: 3 (nested vertical containers)
- **Purpose**: Items aligned to end (right) with no spacing

---

### Spacing Variations (4 tests)

#### test-038-vertical-spacing-0.json
- **Spacing**: 0dp (no spacing)
- **Children**: 6 (header, description, 4 items)
- **Purpose**: Elements touch with no gaps

#### test-039-vertical-spacing-8.json
- **Spacing**: 8dp (compact)
- **Children**: 5 (header, description, 3 images)
- **Purpose**: Minimal spacing for compact layouts

#### test-040-vertical-spacing-16.json
- **Spacing**: 16dp (standard/comfortable)
- **Children**: 5 (header, description, 3 sections)
- **Purpose**: Most common comfortable spacing

#### test-041-vertical-spacing-32.json
- **Spacing**: 32dp (large/premium)
- **Children**: 5 (header, description, 3 feature cards)
- **Purpose**: Generous spacing for premium feel

---

### Padding Variations (4 tests)

#### test-042-vertical-padding-uniform.json
- **Padding**: 16dp all sides (uniform)
- **Children**: 5 (header, description, 3 content boxes)
- **Purpose**: Equal padding creating balanced frame

#### test-043-vertical-padding-individual.json
- **Padding**: top:8dp, right:16dp, bottom:8dp, left:16dp
- **Children**: 5 (header, description, 3 images)
- **Purpose**: Different padding per side

#### test-044-horizontal-padding-asymmetric.json
- **Padding**: top:24dp, right:8dp, bottom:8dp, left:24dp (asymmetric)
- **Children**: 3 (nested vertical containers)
- **Purpose**: Asymmetric padding for unique effects

#### test-045-box-padding-large.json
- **Padding**: 32dp all sides (large)
- **Children**: 1 (nested vertical container with content)
- **Purpose**: Large padding creates dramatic framing

---

### Dimension Units (3 tests)

#### test-046-vertical-wrap-content.json
- **Unit**: WRAP_CONTENT for height
- **Children**: 5 (header, description, 3 cards with varied text)
- **Purpose**: Container adjusts to fit content automatically

#### test-047-horizontal-percent-width.json
- **Units**: PERCENT for widths (30%, 50%, 20%)
- **Children**: 3 (columns with different percentage widths)
- **Purpose**: Responsive layouts with percentage-based sizing

#### test-048-vertical-mixed-units.json
- **Units**: Mixed (DP, PERCENT, WRAP_CONTENT)
- **Children**: 6 (header, description, fixed height, wrap content, percentage row, footer)
- **Purpose**: Combining different unit types for flexible layouts

---

### Mixed/Complex Arrangements (2 tests)

#### test-049-nested-mixed-arrangements.json
- **Complexity**: Multiple nested containers with different strategies
- **Parent**: VERTICAL with SPACE_BETWEEN
- **Children**: 3 sections, each using different arrangement strategies
- **Purpose**: Demonstrate mixing strategies in nested layouts

#### test-050-gallery-spacing-variations.json
- **Complexity**: 3 galleries with different spacing configurations
- **Variations**: Tight (4dp spacing, 8dp peek), Comfortable (16dp spacing, 24dp peek), Spacious (24dp spacing, 40dp peek)
- **Purpose**: Compare gallery spacing options side-by-side

---

## Phase 4: Element Type Combinations (20 tests) - COMPLETE

### Homogeneous Element Tests (6 tests)

#### test-051-all-text-elements.json
- **Elements**: 5 TEXT elements (all same type)
- **Variation**: Different text styles, sizes, weights, alignments
- **Purpose**: Typography showcase demonstrating text hierarchy
- **Style**: Linear gradient background, varied text properties

#### test-052-all-image-elements.json
- **Elements**: 4 IMAGE elements in 2x2 grid
- **Variation**: Different image sources from picsum.photos
- **Purpose**: Image gallery grid layout
- **Style**: Dark background with rounded images

#### test-053-all-button-elements.json
- **Elements**: 4 BUTTON elements (action bar)
- **Variation**: Primary, secondary, tertiary, danger buttons
- **Purpose**: Button group showing different button states
- **Style**: Gradient background, varied button styles

#### test-054-all-video-elements.json
- **Elements**: 2 VIDEO elements
- **Variation**: Main video and preview video with different opacity
- **Purpose**: Video player interface
- **Style**: Dark background with rounded video players

#### test-055-all-spacer-elements.json
- **Elements**: 5 SPACER elements
- **Variation**: Fixed spacers (24dp, 48dp, 72dp, 96dp) + flexible spacer
- **Purpose**: Demonstrate spacing control with visible spacers
- **Style**: Gradient background, colored spacers with varying opacity

#### test-056-all-divider-elements.json
- **Elements**: 5 DIVIDER elements
- **Variation**: Different heights (1dp, 2dp, 3dp, 4dp) and colors
- **Purpose**: Visual separation techniques
- **Style**: Light background, varied divider styles including gradient

---

### Heterogeneous Element Tests - Real UI Patterns (14 tests)

#### test-057-product-card.json
- **Elements**: IMAGE + TEXT + TEXT + BUTTON
- **Pattern**: E-commerce product card
- **Purpose**: Standard product display with image, name, price, CTA
- **Style**: White card on gray background with shadow

#### test-058-login-form.json
- **Elements**: TEXT + DIVIDER + BUTTON + BUTTON
- **Pattern**: Login UI
- **Purpose**: Authentication interface with sign in and forgot password
- **Style**: White card on gradient background with center alignment

#### test-059-profile-header.json
- **Elements**: IMAGE + TEXT + TEXT + SPACER + BUTTON
- **Pattern**: User profile header
- **Purpose**: Profile display with avatar, name, bio, edit button
- **Style**: Gradient background with circular avatar

#### test-060-media-player.json
- **Elements**: VIDEO + SPACER + TEXT + BUTTON + BUTTON
- **Pattern**: Video player with controls
- **Purpose**: Media playback interface with title and control buttons
- **Style**: Dark theme with video and controls

#### test-061-article-layout.json
- **Elements**: TEXT + IMAGE + TEXT + DIVIDER + TEXT
- **Pattern**: Blog post/article
- **Purpose**: Content layout with title, hero image, and body text
- **Style**: Clean white background with typography hierarchy

#### test-062-action-sheet.json
- **Elements**: TEXT + DIVIDER + BUTTON + BUTTON + BUTTON + DIVIDER + BUTTON
- **Pattern**: iOS-style action sheet modal
- **Purpose**: Action menu with multiple options and cancel
- **Style**: White sheet on dark overlay background

#### test-063-stats-card.json
- **Elements**: TEXT + SPACER + TEXT + TEXT + TEXT (in horizontal layout)
- **Pattern**: Dashboard metrics card
- **Purpose**: Display multiple statistics side by side
- **Style**: White card with colored metric values and dividers

#### test-064-gallery-item.json
- **Elements**: IMAGE + SPACER + TEXT + TEXT + BUTTON
- **Pattern**: Gallery card
- **Purpose**: Photo gallery item with title, description, and action
- **Style**: White card with image and content section

#### test-065-notification.json
- **Elements**: IMAGE + TEXT + TEXT + SPACER + BUTTON
- **Pattern**: Notification card
- **Purpose**: Message notification with avatar, content, and reply
- **Style**: White card with horizontal layout

#### test-066-pricing-card.json
- **Elements**: TEXT + DIVIDER + TEXT + TEXT + TEXT + SPACER + BUTTON
- **Pattern**: Pricing table
- **Purpose**: Subscription plan display with features and CTA
- **Style**: Premium card with border and shadow

#### test-067-hero-banner.json
- **Elements**: IMAGE + TEXT + TEXT + BUTTON (in STACK container)
- **Pattern**: Marketing hero banner
- **Purpose**: Landing page hero with overlay content
- **Style**: Image background with dark overlay and centered content

#### test-068-social-post.json
- **Elements**: IMAGE + TEXT + IMAGE + TEXT + SPACER + BUTTON
- **Pattern**: Social media post
- **Purpose**: User post with avatar, content, image, engagement
- **Style**: Card layout with header and content sections

#### test-069-settings-row.json
- **Elements**: TEXT + SPACER + DIVIDER (repeated pattern)
- **Pattern**: Settings list items
- **Purpose**: iOS-style settings rows with labels and arrows
- **Style**: White rows on light background with dividers

#### test-070-feature-showcase.json
- **Elements**: IMAGE + TEXT + TEXT + DIVIDER
- **Pattern**: Feature highlight
- **Purpose**: Product feature display with icon, title, description
- **Style**: White card on gradient background

---

## Phase 5: Style Variations (20 tests) - COMPLETE

### Text Style Variations (7 tests)

#### test-071-text-colors.json
- **Variations**: 9 color examples (solid + with alpha)
- **Colors**: Black, red, green, blue, purple, with 80%, 50%, 20% opacity
- **Purpose**: Demonstrate textColor property with full and partial opacity

#### test-072-font-sizes.json
- **Sizes**: 12sp, 14sp, 16sp, 20sp, 24sp, 32sp, 48sp
- **Purpose**: Typography scale from caption to display sizes
- **Style**: Clean white background showing size progression

#### test-073-font-weights.json
- **Weights**: normal, medium, semibold, bold
- **Purpose**: Font weight variations for hierarchy
- **Features**: Side-by-side comparison showing weight differences

#### test-074-text-alignment.json
- **Alignments**: start, center, end
- **Purpose**: Demonstrate textAlign property
- **Features**: Multiline text examples, practical use cases

#### test-075-text-decoration.json
- **Decorations**: none, underline, line-through
- **Purpose**: Text decoration examples
- **Features**: Practical examples (old/new prices, links)

#### test-076-line-height.json
- **Line Heights**: 1.0, 1.2, 1.5, 2.0
- **Purpose**: Demonstrate line spacing for readability
- **Features**: Paragraphs showing tight to loose spacing

#### test-077-font-families.json
- **Families**: system, monospace, serif
- **Purpose**: Font family variations
- **Features**: Side-by-side comparison, code example with monospace

---

### Visual Style Variations (7 tests)

#### test-078-border-radius.json
- **Radii**: 0, 4, 8, 16, 24, 50
- **Purpose**: Border radius from sharp to pill shape
- **Features**: Colored containers showing rounding progression

#### test-079-border-width-color.json
- **Widths**: 1dp, 2dp, 4dp, 8dp
- **Colors**: Blue, green, orange, red borders
- **Purpose**: Border width and color combinations
- **Features**: Multiple color squares demonstrating borders

#### test-080-shadows-light.json
- **Shadows**: Subtle, light, moderate elevations
- **Opacity**: 0.1 - 0.2
- **Radius**: 2 - 6
- **Purpose**: Light shadows for cards and buttons
- **Features**: Colored shadows (blue, green, purple)

#### test-081-shadows-medium.json
- **Shadows**: Medium, raised, high elevations
- **Opacity**: 0.25 - 0.35
- **Radius**: 8 - 16
- **Purpose**: Medium shadows for raised content
- **Features**: Product card example with medium shadow

#### test-082-shadows-heavy.json
- **Shadows**: Heavy, dramatic, extreme elevations
- **Opacity**: 0.4 - 0.6
- **Radius**: 20 - 32
- **Purpose**: Heavy shadows for modals and floating elements
- **Features**: Modal dialog and FAB examples

#### test-083-opacity-variations.json
- **Opacities**: 1.0, 0.8, 0.6, 0.4, 0.2
- **Purpose**: Opacity for transparency effects
- **Features**: Overlay example with image + dark overlay + text

#### test-084-combined-visual-styles.json
- **Combinations**: Border + Shadow + Opacity + Background
- **Purpose**: Multiple visual properties working together
- **Features**: Styled cards, buttons, and badges with combined effects

---

### Style Cascading & Inheritance (4 tests)

#### test-085-text-style-inheritance.json
- **Purpose**: Demonstrate text property inheritance down the tree
- **Features**: 3-level nested containers with inherited text styles
- **Properties**: textColor, fontSize, fontWeight, lineHeight, fontFamily cascade

#### test-086-style-class-usage.json
- **Purpose**: Demonstrate reusable styleClasses
- **Classes**: 7 defined style classes (buttons, cards, badges, text styles)
- **Features**: Multiple elements using same styleClass, inline overrides

#### test-087-inline-vs-inherited.json
- **Purpose**: Show inline styles overriding inherited styles
- **Features**: Style resolution order demonstration
- **Hierarchy**: Theme → StyleClass → Inline → Parent Inherited

#### test-088-theme-default-styles.json
- **Purpose**: Show theme defaultStyle affecting all elements
- **Features**: Elements using theme defaults, selective overrides
- **Benefits**: Consistency, efficiency, maintainability demonstration

---

### Complex Style Combinations (2 tests)

#### test-089-styled-product-card.json
- **Pattern**: E-commerce product card
- **Styles**: Shadows, badges, rounded corners, overlays
- **Features**: Image, sale badge, favorite button, ratings, prices, CTA buttons
- **Complexity**: Multiple styleClasses, complex visual hierarchy

#### test-090-styled-profile-card.json
- **Pattern**: Social media profile card
- **Styles**: Gradients, shadows, borders, badges, overlays
- **Features**: Header image with overlay, circular avatar, stats grid, action buttons
- **Complexity**: Multi-layer STACK, gradient overlays, verified badge

---

## Phase 6: Background Types (NOT STARTED)

20 tests covering:
- Solid colors
- Linear gradients (various angles)
- Radial gradients
- Sweep gradients
- Pattern backgrounds
- Animated backgrounds

---

## Phase 7: Complex Scenarios (NOT STARTED)

20 tests covering:
- Real-world UI patterns
- Nested containers (3-5 levels)
- Mixed element types
- Complex layouts
- Edge cases and stress tests

---

## Test File Requirements

All test files must adhere to:

1. **Complete Layout**: Every node has `width` AND `height`
2. **No Variables Key**: All values are inline (no template expressions)
3. **Valid JSON**: Proper syntax and structure
4. **Realistic Content**: Real text and image URLs
5. **Varied Styles**: Different backgrounds, colors, and visual treatments

---

## Usage

### Android Sample Apps
```kotlin
val config = parseNativeDisplayConfig(jsonString)
NativeDisplayView(config = config)
```

### iOS Sample Apps
```swift
let config = try JSONDecoder().decode(NativeDisplayConfig.self, from: jsonData)
NativeDisplayView(config: config)
```

### Testing Agent
```bash
# Load test configuration
./load-test.sh test-006-vertical-empty.json

# Capture screenshot
./capture-screenshot.sh android test-006
./capture-screenshot.sh ios test-006

# Compare cross-platform
./compare-screenshots.sh test-006
```

---

## Related Documentation

- **Testing Plan**: `TESTING_PLAN.md`
- **Phase 2 Summary**: `PHASE_2_SUMMARY.md`
- **Phase 3 Summary**: `PHASE_3_SUMMARY.md`
- **Phase 4 Summary**: `PHASE_4_SUMMARY.md`
- **Phase 5 Summary**: `PHASE_5_SUMMARY.md`
- **General README**: `README.md`
- **SDK Reference**: `/.claude/reference/CLAUDE_CODE_REFERENCE_ACTUAL.md`

---

**Progress**: 90 / 130 tests complete (69%)
**Next Phase**: Phase 6 - Background Types
