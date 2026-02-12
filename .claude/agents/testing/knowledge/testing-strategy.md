# Testing Strategy

## Overview
Ensure visual parity between Android and iOS implementations through automated testing.

## JSON Generation
**CRITICAL**: All test JSON configurations MUST follow the rules in:
- `.claude/reference/JSON_STRUCTURE_REFERENCE.md` (complete specification)
- `json-generation-rules.md` (this agent's quick reference)

**Never generate JSON without consulting these references!**

## Testing Levels

### 1. Unit Tests
Test individual components in isolation:
- Model parsing (JSON → Objects)
- Style resolution logic
- Template evaluation
- Dimension calculations

### 2. Screenshot Tests
Capture and compare visual output:
- Container rendering
- Element rendering
- Style cascading
- Arrangement strategies
- Gallery modes

### 3. Visual Parity Tests
Compare Android vs iOS screenshots:
- Same JSON configuration
- Same screen size
- Pixel-perfect comparison
- Automated diff reports

## Test Organization

```
test-configs/
├── containers/
│   ├── vertical_spaced.json
│   ├── horizontal_space_between.json
│   └── gallery_snapping.json
├── elements/
│   ├── text_styled.json
│   ├── image_fit.json
│   └── button_rounded.json
└── complex/
    ├── product_card.json
    └── login_form.json
```

## Screenshot Workflow

1. **Generate Test JSON** - Create comprehensive test configurations
2. **Capture Android** - Run Android app, capture screenshots
3. **Capture iOS** - Run iOS app, capture screenshots
4. **Compare** - Pixel-by-pixel comparison
5. **Report** - Generate visual diff report with highlighted differences

## Tools
- Android: Compose screenshot testing
- iOS: XCTest UI snapshot testing
- Comparison: ImageMagick, pixelmatch
- CI/CD: GitHub Actions for automated runs
