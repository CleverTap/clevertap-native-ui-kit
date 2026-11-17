---
name: test
description: Run tests for the Android, iOS, or Flutter Native Display SDK
user-invocable: true
disable-model-invocation: false
---

# Test Skill

Runs unit/widget tests for a Native Display SDK target with clear result reporting. Supports
Android, iOS, and Flutter.

## Usage

```bash
/test                              # all three (sequential)
/test android                      # Android only
/test ios                          # iOS only
/test flutter                      # Flutter only
/test android VariableEvaluatorTest     # one Android class
/test ios VariableEvaluatorTests        # one iOS suite
```

## Commands per platform

> The canonical commands also live in `.claude/settings.json` (`commands.*`). Keep in sync.

### Android — Gradle
```bash
cd android && ./gradlew test                              # all unit tests
cd android && ./gradlew :sdk:test                         # SDK module only
cd android && ./gradlew test --tests VariableEvaluatorTest  # one class
cd android && ./gradlew test --info                       # detailed output
```
- Instrumented/screenshot suites run via connected-device tasks (see the `testing` agent +
  `nd-screenshot-compare` skill), not `./gradlew test`.

### iOS — xcodebuild (NOT `swift test`)
The SDK imports UIKit, so a host `swift test` won't compile — run the test target in a simulator,
as CI does. `Package.swift` is at the **repo root**; the test target is `CleverTapNativeDisplayTests`.
```bash
xcodebuild test -scheme CleverTapNativeDisplay \
  -project ios/CleverTapNativeDisplay.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 15'
# one suite / case:  add  -only-testing:CleverTapNativeDisplayTests/VariableEvaluatorTests
```
- Get a booted simulator with `xcrun simctl list devices booted`; adjust the `name=` accordingly.

### Flutter — flutter CLI
```bash
cd flutter && flutter test                                # all tests
cd flutter && flutter test test/renderer/text_test.dart   # one file
cd flutter && flutter analyze                             # static analysis (run alongside tests)
```
- Pure-Dart package: unit + widget tests. Add-on packages (`clevertap_native_display_video`/`_webview`)
  have their own `test/` run from their package dir.

## Reports results
- Pass/fail counts per platform, failed tests with error + `file:line`, and duration.

## Common failures
- **Serialization** → check models vs `.claude/reference/JSON_STRUCTURE_REFERENCE.md` (@Serializable /
  Codable / fromJson).
- **Variable evaluation** → `VariableEvaluator` (all platforms; not "TemplateEvaluator").
- **Style resolution** → `StyleResolver` cascade (Android `mergeWith`; resolve-time on all platforms).
- **iOS `swift test` fails on `import UIKit`** → expected; use the `xcodebuild test` simulator command.
- **Flaky/hanging** → await async completion; disable emulator animations for instrumented runs.

## Environment
- Android: JDK 11+, Kotlin 1.9.25. iOS: Xcode 15+, iOS 15 sim. Flutter: 3.24 / Dart 3.5.

## Related
- `/build` — build before testing
- `/nd-screenshot-compare` — cross-platform visual parity (device/simulator)
- `/review` → `/commit` after green
