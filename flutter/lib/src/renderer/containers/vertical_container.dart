import 'package:flutter/widgets.dart';
import '../../evaluator/variable_evaluator.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../native_display_renderer.dart';

class VerticalContainer extends StatelessWidget {
  final NativeDisplayContainer node;
  final Style style;
  final VariableEvaluator evaluator;
  final void Function(String, String, Map<String, dynamic>?)? actionListener;
  final bool Function(String, String, Map<String, dynamic>?)? componentListener;

  const VerticalContainer({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
    this.actionListener,
    this.componentListener,
  });

  @override
  Widget build(BuildContext context) {
    final arrangement = node.layout?.arrangement;
    final strategy = arrangement?.strategy ?? ArrangementStrategy.spaced;
    final spacing = arrangement?.spacing ?? 0.0;
    final children = node.children;

    final hasMatchParent = children.any(
      (c) => c.layout?.height?.special == SpecialDimension.matchParent,
    );
    final needsMaxSize = hasMatchParent ||
        strategy == ArrangementStrategy.spaceBetween ||
        strategy == ArrangementStrategy.spaceEvenly ||
        strategy == ArrangementStrategy.spaceAround ||
        strategy == ArrangementStrategy.center ||
        strategy == ArrangementStrategy.end;

    final List<Widget> widgets = [];
    for (final child in children) {
      Widget renderer = NativeDisplayRenderer(
        node: child,
        evaluator: evaluator,
        actionListener: actionListener,
        componentListener: componentListener,
      );

      // Percent width relative to the column width — FractionallySizedBox works
      // here because Column provides tight width constraints to its children.
      final w = child.layout?.width;
      if (w != null && w.special == null && w.unit == DimensionUnit.percent) {
        renderer = FractionallySizedBox(
          widthFactor: w.value / 100.0,
          alignment: Alignment.topLeft,
          child: renderer,
        );
      }

      // match_parent height fills remaining Column space via Expanded.
      final h = child.layout?.height;
      if (h?.special == SpecialDimension.matchParent) {
        widgets.add(Expanded(child: renderer));
        continue;
      }

      widgets.add(renderer);
    }

    // 'spaced' strategy inserts a fixed gap between siblings.
    final List<Widget> spaced = [];
    if (strategy == ArrangementStrategy.spaced && spacing > 0) {
      for (int i = 0; i < widgets.length; i++) {
        spaced.add(widgets[i]);
        if (i < widgets.length - 1) spaced.add(SizedBox(height: spacing));
      }
    } else {
      spaced.addAll(widgets);
    }

    return Column(
      mainAxisSize: needsMaxSize ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: _mainAxis(strategy),
      children: spaced,
    );
  }

  MainAxisAlignment _mainAxis(ArrangementStrategy s) => switch (s) {
        ArrangementStrategy.spaced => MainAxisAlignment.start,
        ArrangementStrategy.spaceBetween => MainAxisAlignment.spaceBetween,
        ArrangementStrategy.spaceEvenly => MainAxisAlignment.spaceEvenly,
        ArrangementStrategy.spaceAround => MainAxisAlignment.spaceAround,
        ArrangementStrategy.start => MainAxisAlignment.start,
        ArrangementStrategy.center => MainAxisAlignment.center,
        ArrangementStrategy.end => MainAxisAlignment.end,
      };
}
