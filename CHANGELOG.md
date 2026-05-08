# Changelog

All notable changes to the CleverTap Native UI Kit are documented here. The
format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project adheres to [Semantic Versioning](https://semver.org/).

The SDK ships with more functionality than is documented at any given version
— we document a feature only after its cross-platform behaviour is verified
to be stable. The "Documented contract" section of each release lists what is
publicly committed; the "Ships in binary" section lists features that exist
in the artifact but are not yet contracted.

## [1.0.0]

### Documented contract

- `BOX` container (z-stacked overlapping children).
- Percentage-based dimensions for `layout.width`, `layout.height`,
  `layout.padding.*`, `layout.offset.*`, `style.borderRadius`.
- Visual style properties on BOX: `backgroundColor`, `borderRadius`,
  `borderWidth`, `borderColor`, `shadow*`, `opacity`, `aspectRatio`.
- `NativeDisplayView` Compose Composable (Android) and SwiftUI `View` (iOS).
- `NativeDisplayConfigParser` — JSON → `ResolvedConfig`.
- Standalone integration and CleverTap Core SDK bridge mode.
- Variable interpolation `{{variableName}}` in string fields.
- API reference: Dokka HTML for Android, DocC static for iOS.

### Known partial coverage

- `tile` image fit mode is currently approximated as `crop`; native
  repeating-tile rendering is tracked but not yet scheduled.

See the docs site changelog for ongoing release notes.
