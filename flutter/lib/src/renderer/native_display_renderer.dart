import 'package:flutter/widgets.dart';
import '../evaluator/variable_evaluator.dart';
import '../models/enums.dart';
import '../models/native_display_node.dart';
import '../models/style.dart';
import 'containers/box_container.dart';
import 'containers/gallery_renderer.dart';
import 'containers/horizontal_container.dart';
import 'containers/vertical_container.dart';
import 'elements/image_element.dart';
import 'elements/text_element.dart';
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

    return switch (node) {
      NativeDisplayContainer c => _buildContainer(c, style),
      NativeDisplayElement e => _buildElement(context, e, style),
    };
  }

  Widget _buildContainer(NativeDisplayContainer node, Style style) {
    return switch (node.containerType) {
      ContainerType.box => BoxContainer(
          node: node,
          style: style,
          evaluator: evaluator,
          actionListener: actionListener,
          componentListener: componentListener,
        ),
      ContainerType.vertical => VerticalContainer(
          node: node,
          style: style,
          evaluator: evaluator,
          actionListener: actionListener,
          componentListener: componentListener,
        ),
      ContainerType.horizontal => HorizontalContainer(
          node: node,
          style: style,
          evaluator: evaluator,
          actionListener: actionListener,
          componentListener: componentListener,
        ),
      ContainerType.gallery => GalleryRenderer(
          node: node,
          style: style,
          evaluator: evaluator,
          actionListener: actionListener,
          componentListener: componentListener,
        ),
    };
  }

  Widget _buildElement(BuildContext context, NativeDisplayElement node, Style style) {
    return switch (node.elementType) {
      ElementType.text => TextElement(node: node, style: style, evaluator: evaluator),
      ElementType.image => ImageElement(node: node, style: style),
      _ => const SizedBox.shrink(),
    };
  }
}
