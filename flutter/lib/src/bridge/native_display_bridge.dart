import '../internal/nd_logger.dart';

/// Small Dart-only helper for configuring the Native Display SDK.
///
/// The plugin is a pure-Dart renderer with no platform channels. Attribution
/// (Notification Viewed / Clicked) is surfaced to the host through the callbacks
/// on `NativeDisplayView` (`onNotificationViewed` / `onNotificationClicked`);
/// the host forwards those to the CleverTap Core SDK via its own
/// `clevertap_plugin` Dart APIs
/// (`pushDisplayUnitViewedEvent` / `pushDisplayUnitElementClickedEvent`).
class NativeDisplayBridge {
  const NativeDisplayBridge._();

  /// Configure the SDK log level. Takes precedence over [syncLogLevelFromCore] —
  /// once set, [NDLogger.syncFromCoreSdk] will not override the client
  /// preference.
  static void setLogLevel(NDLogLevel level) => NDLogger.setLevel(level);

  /// Align the ND SDK log level with the host's CleverTap Core SDK debug level.
  ///
  /// Host-driven: the app reads its Core SDK debug level (via `clevertap_plugin`)
  /// and passes the integer here. A no-op once the client has called
  /// [setLogLevel] (client-wins) — [NDLogger.syncFromCoreSdk] enforces the
  /// guard. Safe to call repeatedly.
  static void syncLogLevelFromCore(int coreLevel) =>
      NDLogger.syncFromCoreSdk(coreLevel);
}
