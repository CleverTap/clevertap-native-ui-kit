# Native Display System — Claude Code Knowledge Base

Server-driven UI framework that renders native mobile interfaces from JSON. Supports Android (Kotlin/Compose), iOS (Swift/SwiftUI), and Flutter (Dart/widgets).

> **Source of truth.** This file is the canonical, in-depth agent knowledge base. [`AGENTS.md`](AGENTS.md) is the portable, tool-agnostic entry point (roster + navigation) and defers here for the detailed rules. Keep the two in sync — update `AGENTS.md` when the agent roster, skills, or workflow change.

---

## Project Structure

```
clevertap-native-ui-kit/
├── android/              # Android SDK (Kotlin + Jetpack Compose)
│   └── sdk/              # Core SDK module
├── android-sample/       # Android Compose sample app
├── android-xml-sample/   # Android XML-based sample
├── ios/                  # iOS SDK (Swift + SwiftUI)
│   └── Sources/          # Core SDK source
├── ios-sample/           # iOS sample app
├── flutter/              # Flutter plugin — pure-Dart package (no platform channels)
│   └── lib/              # Dart renderer, public API, models, Dart-only bridge
├── flutter-sample/       # Flutter sample app
├── docs/                 # Documentation
└── .claude/
    ├── agents/           # Subagent definitions
    ├── skills/           # Skill definitions
    ├── specs/            # Feature specifications
    └── reference/        # Reference documentation
```

---

## Core Concepts

**Config structure** — every UI is a `NativeDisplayConfig`:
```
theme (optional) | styleClasses (optional) | variables (optional) | root (required)
```

**Two node types:**
- **Containers** — hold children: `VERTICAL` `HORIZONTAL` `BOX` `GALLERY`
- **Elements** — leaf nodes: `TEXT` `IMAGE` `BUTTON` `VIDEO` `HTML` `SPACER` `DIVIDER`

**Layout** — every node has a `layout` object with `width`, `height`, `padding`, `offset`, `arrangement`

**Style cascading** — text properties (`textColor`, `fontSize`, `fontWeight`, etc.) cascade to children; visual properties (`backgroundColor`, `borderRadius`, `shadow*`) do not.

**Templates** — use `{{variableName}}` or `{{object.property}}` in bindings to reference `variables`

---

## Container Types

| Type | Purpose |
|------|---------|
| `VERTICAL` | Stack children vertically |
| `HORIZONTAL` | Stack children horizontally |
| `BOX` | Overlay / absolute positioning |
| `GALLERY` | Scrollable carousel — modes: `SNAPPING` `FREE_FLOW` `FREE_FLOW_GRID` |

---

## Element Types

| Type | Binding key | Notes |
|------|-------------|-------|
| `TEXT` | `text` | Supports `{{variables}}` |
| `IMAGE` | `url` | Auto-detects GIF; use `imageConfig.animated` to override |
| `BUTTON` | `text` | |
| `VIDEO` | `url` | Also: `autoPlay` `loop` `muted` `showControls` `showFullscreen` |
| `HTML` | `html` or `url` | WebView-rendered rich content; `html` binding takes priority over `url` |
| `SPACER` | — | Fixed or flexible spacing |
| `DIVIDER` | — | Visual separator |

> VIDEO requires `androidx.media3:media3-exoplayer` on Android. iOS uses built-in AVKit.
> HTML uses `android.webkit.WebView` on Android and `WKWebView` on iOS. Requires explicit `layout.height` (no `wrap_content`).
> GIF details (auto-detection rules, `imageConfig` options) → `.claude/reference/COMPONENTS_GUIDE.md`

---

## Layout System

**Dimension units**: `dp` `sp` `percent` `px` | **Special**: `wrap_content` `match_parent`

> **⚠️ Dashboard constraint — `percent` and `aspectRatio` only**: The CleverTap dashboard generates JSON using only `percent` dimensions and `aspectRatio`. Fixed units (`dp`, `sp`, `px`) and specials (`wrap_content`, `match_parent`) are SDK-only — they exist for programmatic JSON and backward compatibility but are **not emitted by the dashboard**. New platform implementations must support all types correctly, but real dashboard payloads will only ever contain `percent` + `aspectRatio`.

> **⚠️ aspectRatio overrides percent dimensions**: When `aspectRatio` is set on a node, the node uses **full available parent width** and derives height = `parentWidth / aspectRatio`. Any `width.percent` or `height.percent` value is **ignored**. `aspectRatio` is only skipped when BOTH `width` AND `height` are fixed (dp/sp/px) simultaneously. This is consistent across Android (Compose modifier ordering), iOS (SwiftUI frame), and Flutter (AspectRatio widget).

**Arrangement strategies** (all lowercase in JSON): `spaced` `space_between` `space_evenly` `space_around` `start` `center` `end`

> Only `spaced` uses a `spacing` field. All other strategies have no spacing fields.

**Default values** (safe to omit in JSON — parsing never fails):
- Dimension: `value=0, unit=dp, special=null`
- Offset: `x=0, y=0, unit=dp`
- ChildArrangement: `strategy=spaced, spacingUnit=dp`

---

## Style System

**Resolution order**:
```
Theme default → Style class → Inline node style → Parent style (text properties only)
```

**Color format**: `#RRGGBB` (opaque) or `#RRGGBBAA` (with alpha, RGBA web standard)

**⚠️ Always specify `lineHeight`** for cross-platform consistency — Android default is `fontSize × 1.5`, iOS is `fontSize × 1.176`.

**TextDimension** — `fontSize` and `lineHeight` support two JSON formats: raw number (platform units: SP/points) or `{"value": N, "unit": "percent"}` which resolves as `rootContainerHeight × value / 1000`. The `/1000` divisor matches FE/dashboard behavior.

**Font family resolution** — 3-layer priority at render time (parity across all platforms):
1. Client-provided font — Android `LocalFontFamily`, iOS `\.nativeDisplayFontFamily`, Flutter `NativeDisplayFont.instance.defaultFamily` / per-view `fontFamily` — HIGHEST
2. JSON `fontFamily` string resolved via a client resolver — Android `LocalFontFamilyResolver`, iOS `\.nativeDisplayFontResolver`, Flutter `NativeDisplayFont.instance.resolver` / per-view `fontResolver` (returns a `TextStyle`, composes with `google_fonts`)
3. Platform system default (Roboto / San Francisco) — respects Android FontManager user settings

---

## Development Workflow

Spec-driven: every feature starts with a spec before implementation.

```
1. Write spec → .claude/specs/
2. Implement Android (android-sdk agent)
3. Implement iOS (ios-sdk agent, maintain parity)
4. Implement Flutter (flutter-sdk agent, maintain parity)
5. Update sample apps (android-sample + ios-sample + flutter-sample agents)
6. /build → /test → /review → /commit
```

Cross-platform features fan out in parallel: `android-sdk`, `ios-sdk`, and `flutter-sdk` each read their own architecture knowledge file and implement against the shared spec, with Android as the behavioural source of truth.

---

## Skills

Invoke with `/skill-name`:

| Skill | Purpose |
|-------|---------|
| `/build [android\|ios\|flutter]` | Build SDK or sample apps |
| `/test [android\|ios\|flutter]` | Run tests |
| `/generate-json [type]` | Generate valid JSON test configs |
| `/nd-screenshot-compare` | Capture & segregate comparable cross-platform screenshots (Flutter/native/RN × Android/iOS) |
| `/review` | Review code against project standards |
| `/commit` | Create a properly formatted git commit |
| `/ship-jira` | Create/transition the Jira ticket for committed work |
| `/statusline` | Show git, build, and test status |

Full skill documentation → `.claude/skills/`

---

## Agent Teams

Specialized subagents for domain-focused work:

| Agent | Domain |
|-------|--------|
| `android-sdk` | Android SDK — Kotlin/Compose implementation |
| `ios-sdk` | iOS SDK — Swift/SwiftUI implementation |
| `flutter-sdk` | Flutter plugin — pure-Dart renderer (no platform channels) |
| `android-sample` | Android demo apps (Compose + XML) |
| `ios-sample` | iOS demo app (SwiftUI) |
| `flutter-sample` | Flutter demo app |
| `testing` | Test JSON generation, Roborazzi screenshots, visual comparison |

**Invoking agents explicitly:**
```
"Using the android-sdk agent, implement the GRID container from spec 013"
"Using the flutter-sdk agent, implement the GALLERY container in Dart"
"Using the testing agent, generate 25 GALLERY container test variations"
```

**Routing defaults** — when a task matches a platform or domain, delegate to its agent by default; don't hand-do it in the main loop:
- Task touches `android/` SDK → `android-sdk`; `ios/` SDK → `ios-sdk`; `flutter/lib/` → `flutter-sdk`.
- Task touches a sample app → that platform's `*-sample` agent.
- **Any change to rendering, layout, style, or schema behaviour is cross-platform by default** — fan out to `android-sdk`, `ios-sdk`, AND `flutter-sdk` in parallel (Android is the reference). Scope to one platform only when explicitly stated.
- Test generation, running apps, screenshot capture/compare → `testing`.
- For any rendering change, run `/review` + `/nd-screenshot-compare` as a gate before `/commit`.

**Collaboration rules:**
- SDK agents do not touch sample apps — delegate to sample agents
- Sample agents do not touch SDK code — delegate to SDK agents
- Testing agent does not fix bugs — hands issues to SDK agents
- Cross-platform features need `android-sdk`, `ios-sdk`, AND `flutter-sdk`
- `flutter-sdk` owns `flutter/lib/` — a **pure-Dart package with no platform channels**. CleverTap attribution flows through host callbacks forwarded to `clevertap_plugin`, not a native bridge. VIDEO/HTML ship as optional add-on packages via the renderer registry.

Agent workflows and examples → `.claude/agents/` and `.claude/AGENTS_QUICK_REFERENCE.md`

---

## Code Conventions

**Android**: `@Serializable` data classes · Jetpack Compose rendering · `android/sdk/` package structure

**iOS**: `Codable` structs · SwiftUI rendering · `ios/Sources/` module structure

**Flutter**: `fromJson`/`toJson` Dart models · Flutter widget rendering · `flutter/lib/` package structure

**Commands**:
```
Android build:  cd android && ./gradlew build
Android test:   cd android && ./gradlew test
iOS build:      xcodebuild build -scheme CleverTapNativeDisplay -project ios/CleverTapNativeDisplay.xcodeproj -destination 'generic/platform=iOS'
iOS test:       xcodebuild test  -scheme CleverTapNativeDisplay -project ios/CleverTapNativeDisplay.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15'
Flutter build:  cd flutter && flutter build
Flutter test:   cd flutter && flutter test
```

> **iOS build note:** the SPM manifest (`Package.swift`) is at the **repo root** (sources in `ios/Sources/`), not in `ios/`. The SDK imports UIKit, so a plain `swift build` on a macOS host won't compile — build via the `CleverTapNativeDisplay` Xcode scheme / `xcodebuild` (as CI does), or `ios/build_xcframework.sh` for the distributable XCFramework.

---

## Quick Reference

**Containers**: `VERTICAL` `HORIZONTAL` `BOX` `GALLERY`

**Elements**: `TEXT` `IMAGE` `BUTTON` `VIDEO` `HTML` `SPACER` `DIVIDER`

**Dimensions**: `dp` `sp` `percent` `px` `wrap_content` `match_parent`

**Arrangement**: `spaced` `space_between` `space_evenly` `space_around` `start` `center` `end`

**Text styles**: `textColor` `fontSize` (TextDimension) `fontFamily` `fontWeight` `fontStyle` `lineHeight` (TextDimension) `letterSpacing` `textDecoration` `textAlign` `maxLines` `overflow` `textShadow` `textGradient` `opacity`

**TextDimension**: `fontSize` and `lineHeight` accept raw number (platform units) or `{"value": N, "unit": "percent"}` (rootContainerHeight × N / 1000)

**Visual styles**: `backgroundColor` `borderRadius` (Dimension: number dp or `{"value","unit":"percent"}` → rootContainerHeight×value/100) `borderWidth` (rendered as rootContainerHeight×value/1000) `borderColor` `shadow*` `background`

---

## Best Practices

1. Define `layout` on every node — containers and elements
2. Use `arrangement` strategies for spacing, not manual gaps
3. Define a `theme` for consistent global styles
4. Use `styleClasses` for reusable styles; keep inline styles minimal
5. Use `{{variables}}` for dynamic content
6. Always specify `lineHeight` to avoid cross-platform differences
7. Test on multiple screen sizes
8. If cross-platform font parity matters, enforce a shared font via the client font API — Roboto and San Francisco have different character widths and will wrap text differently

---

## Reference Documentation

Read these files on-demand — only when your task requires the detail. Do not load them upfront.

| File | Read when… |
|------|-----------|
| `.claude/reference/CLAUDE_CODE_REFERENCE_ACTUAL.md` | Implementing any feature; verifying type definitions or schema rules |
| `.claude/reference/COMPONENTS_GUIDE.md` | Writing JSON for containers/elements; GIF or VIDEO-specific behaviour |
| `.claude/reference/JSON_STRUCTURE_REFERENCE.md` | Generating or validating test JSON; unsure about schema rules |
| `.claude/reference/STYLE_THEMING_GUIDE.md` | Working on styles, themes, backgrounds, or cross-platform consistency |
| `.claude/reference/CLAUDE_CODE_PATTERNS.md` | Implementing parser, StyleResolver, VariableEvaluator, or layout calculation |
| `.claude/reference/CLAUDE_CODE_MODELS.md` | Creating or auditing data model types (Kotlin / Swift / TypeScript) |
| `.claude/reference/CLIENT_USAGE_MODEL.md` | Checking whether a feature belongs in the SDK vs the client app |
| `.claude/reference/PLATFORM_ARRANGEMENT_COMPARISON.md` | Ensuring arrangement strategy parity between Android and iOS |
| `.claude/specs/` | Starting a new feature — read the relevant spec first |
