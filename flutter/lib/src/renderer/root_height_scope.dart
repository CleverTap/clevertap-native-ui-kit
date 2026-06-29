import 'package:flutter/widgets.dart';

class RootHeightScope extends InheritedWidget {
  final double rootHeight;

  const RootHeightScope({
    super.key,
    required this.rootHeight,
    required super.child,
  });

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootHeightScope>()?.rootHeight ?? 0;

  @override
  bool updateShouldNotify(RootHeightScope oldWidget) => rootHeight != oldWidget.rootHeight;
}
