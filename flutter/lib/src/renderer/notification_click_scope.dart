import 'package:flutter/widgets.dart';

/// Signature for the "Notification Clicked" attribution callback.
///
/// Fired when an interactive element (BUTTON, or IMAGE with an onClick action)
/// is tapped inside a [NativeDisplayView] that was given a `unitId`.
///
/// - [unitId] is the CleverTap display unit id (`wzrk_id`).
/// - [elementId] is the tapped node's id.
/// - [extras] is the flattened, sanitized attribution payload
///   ([ActionAttributionExtras]) — the host feeds it straight into
///   `clevertap_plugin.pushDisplayUnitElementClickedEvent(unitId, extras)`.
typedef NativeDisplayNotificationClicked = void Function(
  String unitId,
  String elementId,
  Map<String, Object?> extras,
);

/// Inherited widget that exposes the active [NativeDisplayNotificationClicked]
/// callback to element renderers, so they need not thread it through every
/// container parameter. Mirrors `UnitIdScope`.
///
/// Returns `null` when the view was constructed without an
/// `onNotificationClicked` callback (previews / test fixtures).
class NotificationClickScope extends InheritedWidget {
  final NativeDisplayNotificationClicked? onClicked;

  const NotificationClickScope({
    super.key,
    required this.onClicked,
    required super.child,
  });

  static NativeDisplayNotificationClicked? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NotificationClickScope>()?.onClicked;

  @override
  bool updateShouldNotify(NotificationClickScope oldWidget) =>
      onClicked != oldWidget.onClicked;
}
