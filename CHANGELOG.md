# Changelog

All notable changes to the CleverTap Native Display SDK are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This is a multi-platform monorepo. Each platform SDK versions and releases on its
own line, so the same number can appear for different platforms. Entry headings
name the platform. Git tags follow the per-platform convention: iOS and Android
use a bare semver tag (e.g. `1.0.0`); React Native and Flutter use a prefixed tag
(e.g. `react-native-v1.0.0`).

## [Flutter 1.0.0] - 2026-11-04

Initial release.

### Added

- Flutter plugin (`clevertap_native_display`, package version 1.0.0). Renders
  CleverTap Native Display campaigns as native Flutter widgets from JSON, with no
  WebViews. Pure Dart — it adds no native module of its own and works standalone
  (manual JSON) or wired to the CleverTap Core SDK.
  - Public API: `NativeDisplayBridge`, `NativeDisplayView`, `NativeDisplaySlotManager`,
    `NativeDisplaySlot`, `NativeDisplayConfigParser`, `NativeDisplayAttribution`,
    `NDLogger` / `NDLogLevel`.
  - Containers (`VERTICAL`, `HORIZONTAL`, `BOX`, `GALLERY`) and elements (`TEXT`,
    `IMAGE`, `BUTTON`, `SPACER`, `DIVIDER`; `VIDEO` / `HTML` via optional add-ons).
  - Full layout system — `percent` / `dp` / `sp` / `px` / `wrap_content` /
    `match_parent` dimensions, `aspectRatio`, offsets, arrangements; theme +
    style classes + `{{variables}}` templating.
  - Cross-platform rendering parity with the native Android/iOS SDKs: rootHeight
    anchor for percent sizing, line-height defaults (1.2× percent / 1.5× raw),
    border stroke, and text font-box metrics.
  - Hermetic text rendering — ND text is isolated from the host app's Material
    theme (letterSpacing, font family, soft-wrap, max-lines, color), matching the
    self-contained native SDKs.
  - Client font API (`NativeDisplayFont`; `fontFamily` / `fontResolver` on
    `NativeDisplayView`) — set a default font / resolver for all ND text; composes
    with `google_fonts`, package/asset fonts, etc. Parity with native
    `LocalFontFamily` / `nativeDisplayFontResolver`.
  - Self-reported Notification Viewed, Notification Clicked, and element-level
    click attribution (flattened `action_type` / custom KVs / `wzrk_*`).
  - `open_url` actions open via `url_launcher` (external browser / app deeplinks),
    with a host opt-out hook (`onOpenUrl`) mirroring the native `onOpenUrl -> Bool`.
  - Slot-based placement (`NativeDisplaySlotManager` / `NativeDisplaySlot`) for
    server-driven feed/slot layouts.
  - Requires Flutter 3.x / Dart 3.x. Full setup:
    [docs/INTEGRATION_FLUTTER.md](docs/INTEGRATION_FLUTTER.md).

- Optional add-on packages (each opt-in; the core never imports them, so a feature
  whose library is not registered degrades gracefully):
  - `clevertap_native_display_video` (1.0.0) — `VIDEO` element via `video_player`,
    with a custom overlay control set (play/pause, mute, fullscreen, open-url).
  - `clevertap_native_display_webview` (1.0.0) — `HTML` element via `webview_flutter`.
  - `clevertap_plugin_with_native_display` (1.0.0) — one-call `bindCleverTap()`
    auto-wiring that bridges `clevertap_plugin` (Core SDK) to the pure-Dart renderer
    and feeds the slot manager.

## [React Native 1.0.0] - 2026-11-03

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
  - Requires React Native 0.73+, React 18+, `clevertap-react-native` 4.5+.
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
