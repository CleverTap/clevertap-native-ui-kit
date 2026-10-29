import 'package:flutter/widgets.dart';

/// Inherited widget that exposes the active `unitId` (`wzrk_id`) to any
/// descendant of [NativeDisplayView]. Element renderers read this scope when
/// firing attribution events ("Notification Viewed", "Notification Clicked")
/// so the host does not have to thread the id through every parameter.
///
/// Returns `null` when the view was constructed without a unitId — this is
/// the case for previews / test fixtures that render a config directly without
/// going through [NativeDisplayConfigParser].
class UnitIdScope extends InheritedWidget {
  final String? unitId;

  const UnitIdScope({
    super.key,
    required this.unitId,
    required super.child,
  });

  static String? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UnitIdScope>()?.unitId;

  @override
  bool updateShouldNotify(UnitIdScope oldWidget) => unitId != oldWidget.unitId;
}
