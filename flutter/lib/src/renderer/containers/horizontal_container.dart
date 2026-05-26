import 'package:flutter/widgets.dart';
import '../../evaluator/variable_evaluator.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../native_display_renderer.dart';

class HorizontalContainer extends StatelessWidget {
  final NativeDisplayContainer node;
  final Style style;
  final VariableEvaluator evaluator;
  final void Function(String, String, Map<String, dynamic>?)? actionListener;
  final bool Function(String, String, Map<String, dynamic>?)? componentListener;

  const HorizontalContainer({
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
      (c) => c.layout?.width?.special == SpecialDimension.matchParent,
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

      // Percent height relative to the row height — FractionallySizedBox works
      // here because Row provides tight height constraints to its children.
      final h = child.layout?.height;
      if (h != null && h.special == null && h.unit == DimensionUnit.percent) {
        renderer = FractionallySizedBox(
          heightFactor: h.value / 100.0,
          alignment: Alignment.topLeft,
          child: renderer,
        );
      }

      // match_parent width fills remaining Row space via Expanded.
      final w = child.layout?.width;
      if (w?.special == SpecialDimension.matchParent) {
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
        if (i < widgets.length - 1) spaced.add(SizedBox(width: spacing));
      }
    } else {
      spaced.addAll(widgets);
    }

    return Row(
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
