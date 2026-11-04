# Changelog

## 1.0.0

Initial release.

- Optional `VIDEO` element renderer for CleverTap Native Display, backed by
  `video_player`.
- Custom overlay controls: play/pause, mute, fullscreen, and open-url.
- Opt-in via `registerClevertapVideoRenderer()` — the core `clevertap_native_display`
  package never imports `video_player`, so apps that don't use VIDEO take no
  dependency on it.
