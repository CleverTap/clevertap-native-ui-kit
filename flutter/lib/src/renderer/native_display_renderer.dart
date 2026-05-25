import 'package:flutter/widgets.dart';
import '../evaluator/variable_evaluator.dart';
import '../models/enums.dart';
import '../models/native_display_node.dart';
import '../models/style.dart';
import 'animation_modifier.dart';
import 'containers/box_container.dart';
import 'containers/gallery_renderer.dart';
import 'containers/horizontal_container.dart';
import 'containers/vertical_container.dart';
import 'elements/button_element.dart';
import 'elements/divider_element.dart';
import 'elements/html_element.dart';
import 'elements/image_element.dart';
import 'elements/spacer_element.dart';
import 'elements/text_element.dart';
import 'elements/video_element.dart';
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

    Widget built = switch (node) {
      NativeDisplayContainer c => _buildContainer(c, style),
      NativeDisplayElement e => _buildElement(context, e, style),
    };

    final anim = node.animation;
    if (anim != null && anim.type != AnimationType.none) {
      built = AnimationModifier(animation: anim, child: built);
    }
    return built;
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
      ElementType.button => ButtonElement(
          node: node,
          style: style,
          evaluator: evaluator,
          actionListener: actionListener,
        ),
      ElementType.spacer => SpacerElement(node: node, style: style),
      ElementType.divider => DividerElement(node: node, style: style),
      ElementType.video => VideoElement(node: node, style: style, evaluator: evaluator),
      ElementType.html => HtmlElement(node: node, style: style, evaluator: evaluator),
    };
  }
}
