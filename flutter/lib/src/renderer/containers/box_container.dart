import 'package:flutter/widgets.dart';
import '../../evaluator/variable_evaluator.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../native_display_renderer.dart';

class BoxContainer extends StatelessWidget {
  final NativeDisplayContainer node;
  final Style style;
  final VariableEvaluator evaluator;
  final void Function(String, String, Map<String, dynamic>?)? actionListener;
  final bool Function(String, String, Map<String, dynamic>?)? componentListener;

  const BoxContainer({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
    this.actionListener,
    this.componentListener,
  });

  @override
  Widget build(BuildContext context) {
    final children = node.children;
    final hasPercentOffsets = children.any(
      (c) => c.layout?.offset?.unit == DimensionUnit.percent,
    );

    if (hasPercentOffsets) {
      return LayoutBuilder(
        builder: (ctx, constraints) =>
            _buildStack(constraints.maxWidth, constraints.maxHeight),
      );
    }
    return _buildStack(0, 0);
  }

  Widget _buildStack(double parentWidth, double parentHeight) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: node.children.map((child) {
        final offset = child.layout?.offset;
        final renderer = NativeDisplayRenderer(
          node: child,
          evaluator: evaluator,
          actionListener: actionListener,
          componentListener: componentListener,
        );
        if (offset == null) return renderer;
        final x = offset.unit == DimensionUnit.percent
            ? parentWidth * offset.x / 100.0
            : offset.x;
        final y = offset.unit == DimensionUnit.percent
            ? parentHeight * offset.y / 100.0
            : offset.y;
        return Positioned(left: x, top: y, child: renderer);
      }).toList(),
    );
  }
}
