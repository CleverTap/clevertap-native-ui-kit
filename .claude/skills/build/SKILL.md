---
name: build
description: Build the Android, iOS, or Flutter Native Display SDK
user-invocable: true
disable-model-invocation: false
---

# Build Skill

Builds a Native Display SDK target with clear error reporting. Supports Android, iOS, and Flutter.

## Usage

```bash
/build                 # build all three (sequential)
/build android         # Android SDK only
/build ios             # iOS SDK only
/build flutter         # Flutter package only
/build android --clean # clean build
/build android --release
```

## Commands per platform

> The canonical commands also live in `.claude/settings.json` (`commands.*`). Keep the two in sync.

### Android — Gradle
```bash
cd android && ./gradlew build                 # debug (default)
cd android && ./gradlew assembleRelease       # release
cd android && ./gradlew clean build           # clean build
```
- `minSdk = 23`; see `android/sdk/build.gradle.kts` + `android/gradle/libs.versions.toml` for the
  actual compileSdk / Kotlin (currently Kotlin 1.9.25 + Compose compiler ext 1.5.15, K1).

### iOS — Xcode / xcodebuild (NOT `swift build`)
The SDK is an SPM package whose `Package.swift` is at the **repo root** (target sources in
`ios/Sources/CleverTapNativeDisplay`), and it imports UIKit — so a plain `swift build` on a macOS
host won't compile. Build via the `CleverTapNativeDisplay` Xcode scheme, as CI does:
```bash
xcodebuild build -scheme CleverTapNativeDisplay \
  -project ios/CleverTapNativeDisplay.xcodeproj \
  -destination 'generic/platform=iOS'                      # debug
xcodebuild build -scheme CleverTapNativeDisplay \
  -project ios/CleverTapNativeDisplay.xcodeproj \
  -destination 'generic/platform=iOS' -configuration Release

./ios/build_xcframework.sh                                 # distributable XCFramework
```
- SPM manifest maintenance (from the repo root, where `Package.swift` lives):
  `swift package clean` / `swift package update`.
- Deployment target: iOS 15 (`Package.swift` + project.pbxproj). Zero external SPM deps.

### Flutter — flutter CLI
```bash
cd flutter && flutter pub get
cd flutter && flutter build                   # or: flutter analyze (static check)
```
- Floor: Flutter 3.24 / Dart 3.5 (`flutter/pubspec.yaml`). Pure-Dart package; `flutter analyze`
  + `flutter test` are the fast feedback loop. VIDEO/HTML add-ons build from their own package dirs.

## Reports results
- Success/failure per platform, compilation errors with `file:line`, warnings, artifact location,
  and duration.

### Artifacts
- Android: `android/sdk/build/outputs/aar/`
- iOS: `ios/build/` (xcodebuild) · XCFramework from `build_xcframework.sh` → `output/`
- Flutter: `flutter/build/`

## Common failures
- **Unresolved reference / type mismatch** → check the reported `file:line`, imports, model types.
- **iOS `swift build` fails on `import UIKit`** → expected; use `xcodebuild` with an iOS destination.
- **Android OOM** → raise `org.gradle.jvmargs=-Xmx4g` in `gradle.properties`.
- **Dependency resolution** → Android `./gradlew --refresh-dependencies`; iOS `swift package update`
  (repo root); Flutter `flutter pub get`.
- **Gradle not executable** → `cd android && chmod +x gradlew`.

## Related
- `/test` — run tests after a successful build
- `/review` — review before building
- `/commit` — commit after a green build
