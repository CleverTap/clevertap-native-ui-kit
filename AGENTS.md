# AGENTS.md — CleverTap Native Display UI Kit

Portable, tool-agnostic entry point for AI coding agents working in this repo. It is the
**map**; the **territory** (detailed rules, schema, patterns) lives in
[`CLAUDE.md`](CLAUDE.md) and [`.claude/`](.claude/).

> **Source of truth.** [`CLAUDE.md`](CLAUDE.md) is the canonical, in-depth knowledge base
> (core concepts, layout/style system, schema rules, conventions). This file mirrors only
> the **roster + navigation** and defers there for everything else. If the two ever
> disagree, `CLAUDE.md` wins — then fix this file.

---

## What this project is

A **server-driven UI framework** that renders native mobile interfaces from JSON, with
cross-platform parity across three implementations:

| Platform | Stack | SDK path | Sample |
|----------|-------|----------|--------|
| Android  | Kotlin + Jetpack Compose | `android/sdk/` | `android-sample/`, `android-xml-sample/` |
| iOS      | Swift + SwiftUI | `ios/Sources/` | `ios-sample/` |
| Flutter  | Dart + Flutter widgets (pure-Dart renderer) | `flutter/lib/` | `flutter-sample/` |

**Android is the behavioural source of truth**; iOS and Flutter match it. A React Native
example also exists under `react-native/example/` (screenshot automation only).

Every UI is a `NativeDisplayConfig`: `theme?` · `styleClasses?` · `variables?` · `root`.
Containers (`VERTICAL` `HORIZONTAL` `BOX` `GALLERY`) hold children; elements (`TEXT`
`IMAGE` `BUTTON` `VIDEO` `HTML` `SPACER` `DIVIDER`) are leaves. Full concept reference →
[`CLAUDE.md`](CLAUDE.md).

---

## Agent roster

Specialized subagents live in [`.claude/agents/`](.claude/agents/). Each has frontmatter
(`name`, `description`) and a system prompt, and **reads its own architecture knowledge
file on demand** (`.claude/agents/<name>/knowledge/architecture.md`) — so a feature can be
built across platforms **in parallel** against one shared spec.

| Agent | Scope | Reads its own arch at |
|-------|-------|-----------------------|
| `android-sdk` | `android/sdk/` — Kotlin/Compose SDK | `.claude/agents/android-sdk/knowledge/` |
| `ios-sdk` | `ios/Sources/` — Swift/SwiftUI SDK | `.claude/agents/ios-sdk/knowledge/` |
| `flutter-sdk` | `flutter/lib/` — pure-Dart renderer (no platform channels) | `.claude/agents/flutter-sdk/knowledge/` |
| `android-sample` | `android-sample/` + `android-xml-sample/` | `.claude/agents/android-sample/knowledge/` |
| `ios-sample` | `ios-sample/` | `.claude/agents/ios-sample/knowledge/` |
| `flutter-sample` | `flutter-sample/` | `.claude/agents/flutter-sample/knowledge/` |
| `testing` | all platforms — **the test & automation + screenshot expert**: JSON test generation, build/run apps, drive integration/instrumentation tests, deterministic capture, and comparable cross-platform screenshot bundles | `.claude/agents/testing/knowledge/` |

**Invoke explicitly**, e.g.:
```
"Using the flutter-sdk agent, implement the GALLERY container in Dart per spec 013"
"Using the testing agent, capture and compare screenshots across Flutter/native on Android + iOS"
```

### Routing defaults

When a task matches a platform or domain, **delegate to its agent by default** — don't hand-do it in the main loop:

- Touches `android/` SDK → `android-sdk` · `ios/` SDK → `ios-sdk` · `flutter/lib/` → `flutter-sdk`.
- Touches a sample app → that platform's `*-sample` agent.
- **A change to rendering / layout / style / schema behaviour is cross-platform by default** —
  fan out to `android-sdk`, `ios-sdk`, **and** `flutter-sdk` in parallel (Android is the
  reference). Scope to a single platform only when the request says so explicitly.
- Test generation, running apps, screenshot capture/compare → `testing`.
- For any rendering change, `/review` + `/nd-screenshot-compare` are the gate before `/commit`.

### Collaboration rules
- SDK agents never touch sample apps; sample agents never touch SDK code — delegate across.
- The `testing` agent never fixes SDK bugs — it reproduces, then hands off to the SDK agent.
- Cross-platform features need `android-sdk` **and** `ios-sdk` **and** `flutter-sdk`.
- `flutter-sdk` owns `flutter/lib/` — a **pure-Dart package, no platform channels**. CleverTap
  attribution flows through host callbacks forwarded to `clevertap_plugin`, not a native bridge.

---

## Skills — one-command workflows

Invoke with `/skill-name`. Definitions in [`.claude/skills/`](.claude/skills/).

| Skill | Purpose |
|-------|---------|
| `/build [android\|ios\|flutter]` | Build SDK or sample apps |
| `/test [android\|ios\|flutter]` | Run tests |
| `/generate-json [type]` | Generate valid JSON test configs |
| `/nd-screenshot-compare` | Capture & segregate comparable cross-platform screenshots (Flutter/native/RN × Android/iOS) into `~/Desktop/nd-screenshots-review/<os>/<event>/<framework>.png` |
| `/review` | Review code against project standards |
| `/commit` | Create a properly formatted git commit |
| `/ship-jira` | Create/transition the Jira ticket for committed work |
| `/statusline` | Show git, build, and test status |

---

## Build & test commands

```
Android build:  cd android && ./gradlew build        Android test:  cd android && ./gradlew test
Flutter build:  cd flutter && flutter build          Flutter test:  cd flutter && flutter test
iOS build:      xcodebuild build -scheme CleverTapNativeDisplay -project ios/CleverTapNativeDisplay.xcodeproj -destination 'generic/platform=iOS'
iOS test:       xcodebuild test  -scheme CleverTapNativeDisplay -project ios/CleverTapNativeDisplay.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15'
```
> iOS: `Package.swift` is at the **repo root** (sources in `ios/Sources/`), not `ios/`. The SDK
> imports UIKit, so a host `swift build` won't compile — use the `CleverTapNativeDisplay` Xcode
> scheme / `xcodebuild` (as CI does), or `ios/build_xcframework.sh` for the XCFramework.

---

## Development workflow (spec-driven)

1. Write a spec → [`.claude/specs/`](.claude/specs/) (`TEMPLATE.md`).
2. Implement **Android** (`android-sdk`) — the reference behaviour.
3. Implement **iOS** (`ios-sdk`) and **Flutter** (`flutter-sdk`) to parity — in parallel.
4. Update sample apps (`android-sample` / `ios-sample` / `flutter-sample`).
5. `/build` → `/test` → `/review` → `/commit`.
6. Validate visual parity with `/nd-screenshot-compare`.

---

## Reference docs (read on demand, not upfront)

Deep references live in [`.claude/reference/`](.claude/reference/). Pick by task:

| Need | File |
|------|------|
| Type definitions / schema rules | `CLAUDE_CODE_REFERENCE_ACTUAL.md` |
| JSON for containers/elements, GIF/VIDEO behaviour | `COMPONENTS_GUIDE.md` |
| Generating/validating test JSON | `JSON_STRUCTURE_REFERENCE.md` |
| Styles, themes, backgrounds, cross-platform consistency | `STYLE_THEMING_GUIDE.md` |
| Parser / StyleResolver / VariableEvaluator / layout calculation | `CLAUDE_CODE_PATTERNS.md` |
| Data model types (Kotlin / Swift / Dart) | `CLAUDE_CODE_MODELS.md` |
| SDK vs client-app responsibility | `CLIENT_USAGE_MODEL.md` |
| Arrangement parity between platforms | `PLATFORM_ARRANGEMENT_COMPARISON.md` |

---

## House rules

- **Cross-platform parity is non-negotiable.** A rendering change on one platform must be
  mirrored on the others (or explicitly scoped). Android is the reference.
- **Dashboard payloads only ever use `percent` + `aspectRatio`.** Other dimension units
  exist for hand-authored JSON/back-compat — support them, but optimise for the fast path.
- **Always set `lineHeight`** for cross-platform text consistency.
- **Staging credentials never get committed** — account/token/region live only in local
  working copies of the sample manifests / `Info.plist` files (see the
  `nd-screenshot-compare` skill).
- Keep this file and `CLAUDE.md` in sync when the roster, skills, or workflow change.
