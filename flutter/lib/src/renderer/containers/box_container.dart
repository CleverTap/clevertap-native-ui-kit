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
    final needsParentSize = node.children.any((c) {
      final layout = c.layout;
      if (layout == null) return false;
      final offset = layout.offset;
      final w = layout.width;
      final h = layout.height;
      return (offset != null && offset.unit == DimensionUnit.percent) ||
          (w != null && w.special == null && w.unit == DimensionUnit.percent) ||
          (h != null && h.special == null && h.unit == DimensionUnit.percent);
    });

    if (needsParentSize) {
      return LayoutBuilder(
        builder: (ctx, constraints) => _buildStack(
          constraints.maxWidth,
          constraints.maxHeight.isInfinite ? 0 : constraints.maxHeight,
        ),
      );
    }
    return _buildStack(0, 0);
  }

  Widget _buildStack(double parentWidth, double parentHeight) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: node.children
          .map((child) => _buildChild(child, parentWidth, parentHeight))
          .toList(),
    );
  }

  Widget _buildChild(NativeDisplayNode child, double parentWidth, double parentHeight) {
    final renderer = NativeDisplayRenderer(
      node: child,
      evaluator: evaluator,
      actionListener: actionListener,
      componentListener: componentListener,
    );

    final layout = child.layout;
    final offset = layout?.offset;

    double? left, top;
    if (offset != null) {
      left = offset.unit == DimensionUnit.percent
          ? parentWidth * offset.x / 100.0
          : offset.x;
      top = offset.unit == DimensionUnit.percent
          ? parentHeight * offset.y / 100.0
          : offset.y;
    }

    final hasAspectRatio = (layout?.aspectRatio ?? 0) > 0;
    double? posWidth, posHeight;
    final w = layout?.width;
    final h = layout?.height;
    if (w != null && w.special == null && w.unit == DimensionUnit.percent && parentWidth > 0) {
      posWidth = parentWidth * w.value / 100.0;
    }
    if (!hasAspectRatio && h != null && h.special == null && h.unit == DimensionUnit.percent && parentHeight > 0) {
      posHeight = parentHeight * h.value / 100.0;
    }

    if (left == null && top == null && posWidth == null && posHeight == null) {
      return renderer;
    }

    if (left == null && top == null) {
      return SizedBox(width: posWidth, height: posHeight, child: renderer);
    }

    return Positioned(
      left: left,
      top: top,
      width: posWidth,
      height: posHeight,
      child: renderer,
    );
  }
}
