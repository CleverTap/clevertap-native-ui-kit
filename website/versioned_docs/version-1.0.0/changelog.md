---
title: Changelog
description: Released versions and what each one ships.
---

# Changelog

The Native Display SDK uses [Semantic Versioning](https://semver.org/) and the [Keep a Changelog](https://keepachangelog.com/) format.

## [1.0.0] — first published release

### Added

**Containers**
- `BOX` — z-stacked overlapping children. See [BOX](/components/containers/box).
- `VERTICAL` — Compose `Column` / SwiftUI `VStack`. See [VERTICAL](/components/containers/vertical).
- `HORIZONTAL` — Compose `Row` / SwiftUI `HStack`. See [HORIZONTAL](/components/containers/horizontal).
- `GALLERY` — scrolling carousel with three modes (`snapping`, `free_flow`, `free_flow_grid`). See [GALLERY](/components/containers/gallery).

**Elements**
- `TEXT` — string rendering with full text styling and `{{variable}}` interpolation.
- `IMAGE` — remote image loading with auto-GIF detection (Coil on Android, custom `GIFImage` on iOS).
- `BUTTON` — tappable styled label with action triggers.
- `VIDEO` — HTTP/HLS video streaming via ExoPlayer / AVKit.
- `HTML` — WebView / WKWebView for rich HTML content.
- `SPACER` — pure-layout invisible spacer.
- `DIVIDER` — horizontal or vertical separator line.

**Dimensions**
- Six dimension units fully documented: [`percent`](/dimensions/percent), [`dp`](/dimensions/dp), [`sp`](/dimensions/sp), [`px`](/dimensions/px), [`wrap_content`, `match_parent`](/dimensions/special).

**Layout & styling**
- Universal `layout` object — `width`, `height`, `padding`, `offset`, `aspectRatio`, `arrangement`.
- Seven [arrangement strategies](/concepts/arrangement-strategies) for VERTICAL/HORIZONTAL: `spaced`, `space_between`, `space_evenly`, `space_around`, `start`, `center`, `end`.
- Style cascade: theme → style class → inline style → parent text cascade.
- [Theme system](/concepts/theme) with `defaultStyle` and named-colour palette.
- [Style classes](/concepts/style-classes-deep) — declare reusable `Style` blocks once, reference by name.

**Behaviour**
- [Animations](/concepts/animations) — 9 entrance types, 7 easing curves, fire-once on first appearance.
- [Actions](/concepts/actions) — 5 triggers (`onClick`, `onLongPress`, `onDoubleTap`, `onAppear`, `onDisappear`) with action types `open_url`, `dismiss`, `track_event`, `custom`.
- [Templates / variables](/concepts/templates-and-variables) — `{{variableName}}` and dot-path interpolation.

**Entry points**
- `NativeDisplayView` — Compose Composable (Android) and SwiftUI View (iOS).
- `NativeDisplayConfigParser.parse(json)` — JSON → `ResolvedConfig`.
- `NativeDisplayViewGroup` (Android XML), `NativeDisplayUIView` / `NativeDisplayViewController` (iOS UIKit / Objective-C).

**Integrations**
- Standalone mode (no Core SDK dependency).
- Bridge mode for the [CleverTap Core SDK](/integrations/core-sdk) — listens for `adUnit_notifs` display units, parses embedded `native_display_config`, exposes as `NativeDisplayUnit`.
- Slot-based rendering via `NativeDisplaySlot` / `NativeDisplaySlotManager`.

**API reference**
- Dokka HTML at `/api/android/1.0.0/`.
- DocC static HTML at `/api/ios/1.0.0/`.

### Known partial coverage

- **`tile` image fit mode** is currently approximated as `crop`. Native repeating-tile rendering is planned but not yet scheduled.

### Roadmap

The next minor (`1.1.0`) and beyond are still being scoped. Specific features will be added here once committed.

What we're tracking for future work (not yet promised to any version):
- Performance refinements — measure & reduce GeometryReader cost on iOS, lazy-render off-screen children.
- Algolia DocSearch on the docs site.
- Native `tile` image rendering.

How releases land:
- **Patch releases** (`1.0.x`) overwrite the `1.0.0` docs version. Bug fixes and doc clarifications only.
- **Minor releases** (`1.x.0`) snapshot a new versioned docs entry; previous versions stay accessible via the version dropdown.
- **Major releases** (`2.0.0`+) reserved for breaking changes; deferred until a concrete need emerges.
