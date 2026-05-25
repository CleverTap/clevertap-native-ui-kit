import 'package:flutter/widgets.dart';
import '../evaluator/variable_evaluator.dart';
import '../models/native_display_node.dart';
import '../models/style.dart';
import 'resolved_styles_scope.dart';

class NativeDisplayRenderer extends StatelessWidget {
  final NativeDisplayNode node;
  final VariableEvaluator evaluator;
  final void Function(String action, String nodeId, Map<String, dynamic>? params)? actionListener;
  final bool Function(String event, String nodeId, Map<String, dynamic>? params)? componentListener;

  const NativeDisplayRenderer({
    super.key,
    required this.node,
    required this.evaluator,
    this.actionListener,
    this.componentListener,
  });

  @override
  Widget build(BuildContext context) {
    if (!evaluator.evaluateBoolean(node.visible)) return const SizedBox.shrink();

    final resolvedStyles = ResolvedStylesScope.of(context);
    final style = resolvedStyles[node.id] ?? Style.empty;

    final child = switch (node) {
      NativeDisplayContainer c => _buildContainer(context, c, style),
      NativeDisplayElement e => _buildElement(context, e, style),
    };

    return child;
  }

  Widget _buildContainer(BuildContext context, NativeDisplayContainer node, Style style) {
    // Stub — full implementation in Steps 4 and 10
    return const SizedBox.shrink();
  }

  Widget _buildElement(BuildContext context, NativeDisplayElement node, Style style) {
    // Stub — full implementation in Steps 6-12
    return const SizedBox.shrink();
  }
}
