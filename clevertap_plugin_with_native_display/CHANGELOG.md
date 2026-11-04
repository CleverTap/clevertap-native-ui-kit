# Changelog

## 1.0.0

Initial release.

- One-call `bindCleverTap()` auto-wiring that bridges `clevertap_plugin` (the
  CleverTap Core SDK) to the pure-Dart `clevertap_native_display` renderer.
- Feeds the `NativeDisplaySlotManager` from the Core SDK's display-unit delegate and
  wires attribution (Notification Viewed / Clicked) globally, so a host integrates in
  a few lines without touching each render site.
