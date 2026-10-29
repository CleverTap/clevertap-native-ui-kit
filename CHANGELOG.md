# Changelog

All notable changes to the CleverTap Native Display SDK are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This is a multi-platform monorepo. Each platform SDK versions and releases on its
own line, so the same number can appear for different platforms. Entry headings
name the platform. Git tags follow the per-platform convention: iOS and Android
use a bare semver tag (e.g. `1.0.0`); React Native and Flutter use a prefixed tag
(e.g. `react-native-v1.0.0`).

## [React Native 1.0.0] - 2026-10-29

Initial release.

### Added

- React Native SDK (`@clevertap/native-display-sdk`, package version 1.0.0).
  Renders CleverTap Native Display campaigns as native React Native components
  from JSON, with no WebViews. Works with both bare React Native and Expo (via
  `expo prebuild` or EAS Build, not Expo Go). Pure TypeScript - it adds no native
  module of its own.
  - Public API: `NativeDisplayBridge`, `NativeDisplayView`,
    `NativeDisplaySlotManager`, `NativeDisplaySlot`, `wireCleverTap`, `NDLogLevel`.
  - Optional UI features through `registerComponents` - linear gradient, SVG,
    Reanimated, WebView, video, masked view, blur, and fast image (or
    `expo-image` under Expo). The SDK never imports these itself, so a feature
    whose library is not registered degrades gracefully.
  - Console log levels through `NDLogger` / `NDLogLevel`.
  - Self-reported Notification Viewed and Notification Clicked events, so host
    apps do not double-report.
  - Element-level click attribution (`action_type`, `action_url`, `wzrk_*`).
  - Requires React Native 0.73+, React 18+, `clevertap-react-native` 4.1+.
  - Full setup: [react-native/README.md](react-native/README.md).

## [iOS & Android 1.0.0] - 2026-06-25

Initial release.

### Added

- Server-driven Native Display rendering for Android and iOS. Draws CleverTap
  Native Display campaigns (banners, cards, carousels, and more) from a JSON
  config delivered by the CleverTap Core SDK, as fully native UI. No WebViews.
- Android renderer built on Jetpack Compose, with XML / View wrappers that host a
  `ComposeView`. Requires API 23+ and Kotlin 1.9+.
- iOS renderer built on SwiftUI, with UIKit and Objective-C wrappers that host a
  `UIHostingController`. Requires iOS 15+ and Swift 5.5+.
- Containers: `VERTICAL`, `HORIZONTAL`, `BOX`, `GALLERY`. Elements: `TEXT`,
  `IMAGE`, `BUTTON`, `VIDEO`, `HTML`, `SPACER`, `DIVIDER`.
- Theming, style classes, variables, and `{{variable}}` template bindings, all
  controlled server-side without app updates.
- Two integration paths on each platform: slot-based rendering (recommended) and
  custom / standalone rendering where you feed JSON yourself.

[React Native 1.0.0]: https://github.com/CleverTap/clevertap-native-ui-kit/releases/tag/react-native-v1.0.0
[iOS & Android 1.0.0]: https://github.com/CleverTap/clevertap-native-ui-kit/releases/tag/1.0.0
