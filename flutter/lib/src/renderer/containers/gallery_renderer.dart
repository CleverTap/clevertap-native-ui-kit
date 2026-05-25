import 'package:flutter/widgets.dart';
import '../../evaluator/variable_evaluator.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';

// v1 stub — full GALLERY implementation in Step 9
class GalleryRenderer extends StatelessWidget {
  final NativeDisplayContainer node;
  final Style style;
  final VariableEvaluator evaluator;
  final void Function(String, String, Map<String, dynamic>?)? actionListener;
  final bool Function(String, String, Map<String, dynamic>?)? componentListener;

  const GalleryRenderer({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
    this.actionListener,
    this.componentListener,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[NativeDisplay] GalleryRenderer: full implementation in Step 9 — rendering stub');
    return const SizedBox.shrink();
  }
}
