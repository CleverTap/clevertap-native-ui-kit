import 'package:flutter/widgets.dart';
import '../models/style.dart';

class ResolvedStylesScope extends InheritedWidget {
  final Map<String, Style> styles;

  const ResolvedStylesScope({
    super.key,
    required this.styles,
    required super.child,
  });

  static Map<String, Style> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ResolvedStylesScope>()?.styles ?? const {};

  @override
  bool updateShouldNotify(ResolvedStylesScope oldWidget) => styles != oldWidget.styles;
}
