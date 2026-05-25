import 'package:flutter/widgets.dart';
import '../../evaluator/variable_evaluator.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../native_display_renderer.dart';

// v1 stub — full arrangement logic deferred to v2
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: node.children
          .map((c) => NativeDisplayRenderer(
                node: c,
                evaluator: evaluator,
                actionListener: actionListener,
                componentListener: componentListener,
              ))
          .toList(),
    );
  }
}
