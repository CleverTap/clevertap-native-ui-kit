# Changelog

## 1.0.0

Initial release.

- Optional `HTML` element renderer for CleverTap Native Display, backed by
  `webview_flutter`.
- Opt-in via `registerClevertapHtmlRenderer()` — the core `clevertap_native_display`
  package never imports `webview_flutter`, so apps that don't use HTML take no
  dependency on it.
- `HTML` elements require an explicit `layout.height` (a WebView cannot auto-size to
  its content).
