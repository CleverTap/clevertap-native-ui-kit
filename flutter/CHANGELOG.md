# Changelog

## 1.0.0

Initial release.

- Pure-Dart renderer for CleverTap Native Display campaigns — JSON → native Flutter
  widgets, no WebViews. Works standalone (manual JSON) or wired to the CleverTap
  Core SDK.
- Containers (`VERTICAL`, `HORIZONTAL`, `BOX`, `GALLERY`) and elements (`TEXT`,
  `IMAGE`, `BUTTON`, `SPACER`, `DIVIDER`; `VIDEO` / `HTML` via optional add-ons).
- Layout system: `percent` / `dp` / `sp` / `px` / `wrap_content` / `match_parent`
  dimensions, `aspectRatio`, offsets, arrangements; theme + style classes +
  `{{variables}}` templating.
- Cross-platform rendering parity with the native Android/iOS SDKs — rootHeight
  anchor for percent sizing, line-height defaults (1.2× percent / 1.5× raw), border
  stroke, and text font-box metrics.
- Hermetic text rendering — ND text is isolated from the host app's Material theme
  (letterSpacing, font family, soft-wrap, max-lines, color).
- Client font API (`NativeDisplayFont`; `fontFamily` / `fontResolver` on
  `NativeDisplayView`) — composes with `google_fonts`, package/asset fonts, etc.
- Self-reported Notification Viewed, Notification Clicked, and element-level click
  attribution.
- `open_url` actions open via `url_launcher` (external browser / app deeplinks), with
  a host opt-out hook (`onOpenUrl`).
- Slot-based placement (`NativeDisplaySlotManager` / `NativeDisplaySlot`).
