/// Process-wide default attribution sink.
///
/// [NativeDisplayView] (and therefore [NativeDisplaySlot]) fall back to these
/// when their per-widget `onNotificationViewed` / `onNotificationClicked` are
/// null. This lets a single global wiring — e.g. the
/// `clevertap_plugin_with_native_display` add-on's `bindCleverTap()` — attribute
/// every rendered unit without the host wiring each render site.
///
/// Per-widget callbacks always take precedence; the global sink is only consulted
/// when a widget supplies none. The core SDK never populates these (it has no
/// `clevertap_plugin` dependency) — an integration layer or the host does.
///
/// The field types mirror the `NativeDisplayNotificationViewed` /
/// `NativeDisplayNotificationClicked` typedefs structurally, so they're
/// interchangeable without importing (and coupling to) the view/scope libraries.
class NativeDisplayAttribution {
  NativeDisplayAttribution._();

  /// Process-wide singleton.
  static final NativeDisplayAttribution instance = NativeDisplayAttribution._();

  /// Fallback for "Notification Viewed" — `(unitId)`.
  void Function(String unitId)? onViewed;

  /// Fallback for "Notification Clicked" — `(unitId, elementId, extras)`.
  void Function(String unitId, String elementId, Map<String, Object?> extras)?
      onClicked;

  /// Clear both sinks. Used by `unbindCleverTap()` and tests.
  void clear() {
    onViewed = null;
    onClicked = null;
  }
}
