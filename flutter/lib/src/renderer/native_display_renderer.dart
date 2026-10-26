import 'package:flutter/widgets.dart';
import '../evaluator/variable_evaluator.dart';
import '../models/enums.dart';
import '../models/layout.dart';
import '../models/native_display_node.dart';
import '../models/style.dart';
import 'animation_modifier.dart';
import 'containers/box_container.dart';
import 'containers/gallery_renderer.dart';
import 'containers/horizontal_container.dart';
import 'containers/vertical_container.dart';
import '../internal/nd_logger.dart';
import 'nd_element_registry.dart';
import 'elements/button_element.dart';
import 'elements/divider_element.dart';
import 'elements/image_element.dart';
import 'elements/spacer_element.dart';
import 'elements/text_element.dart';
import 'native_display_scope.dart';
import 'style_applier.dart';

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

    final resolvedStyles = NativeDisplayScope.stylesOf(context);
    final style = resolvedStyles[node.id] ?? Style.empty;
    final rootHeight = NativeDisplayScope.rootHeightOf(context);

    Widget built = switch (node) {
      NativeDisplayContainer c => _buildContainer(c, style),
      NativeDisplayElement e => _buildElement(context, e, style),
    };

    // Containers apply style here; elements apply their own style internally.
    if (node is NativeDisplayContainer) {
      built = StyleApplier.apply(
        built,
        style,
        rootHeight: rootHeight,
        padding: node.layout?.padding,
      );
    }

    // Apply aspectRatio and fixed (dp/sp/px) sizing.
    // Percent sizing is handled by each parent container:
    //   BOX → Positioned(width:, height:), VERTICAL/HORIZONTAL → FractionallySizedBox.
    built = _wrapWithSizing(built, node.layout);

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
      ElementType.image => ImageElement(
          node: node,
          style: style,
          actionListener: actionListener,
        ),
      ElementType.button => ButtonElement(
          node: node,
          style: style,
          evaluator: evaluator,
          actionListener: actionListener,
        ),
      ElementType.spacer => SpacerElement(node: node, style: style),
      ElementType.divider => DividerElement(node: node, style: style),
      // VIDEO and HTML are optional: their heavy native deps live in add-on
      // packages. If the host hasn't registered a renderer, skip gracefully.
      ElementType.video => _pluggable(ElementType.video, node, style),
      ElementType.html => _pluggable(ElementType.html, node, style),
    };
  }

  /// Resolves an optional element (VIDEO/HTML) via [NativeDisplayRenderers]. When
  /// no builder is registered, logs a hint and renders nothing — so the heavy
  /// native dependency isn't forced on integrators who don't use the element.
  Widget _pluggable(ElementType type, NativeDisplayElement node, Style style) {
    final builder = NativeDisplayRenderers.builderFor(type);
    if (builder == null) {
      final pkg = type == ElementType.video
          ? 'clevertap_native_display_video'
          : 'clevertap_native_display_webview';
      NDLogger.w(
        'NativeDisplayRenderer',
        '${type.name.toUpperCase()} element skipped: no renderer registered. '
            'Add the "$pkg" package and call its register*() function at startup.',
      );
      return const SizedBox.shrink();
    }
    return builder(node, style, evaluator);
  }

  /// Wraps [child] with an [AspectRatio] or [SizedBox] for fixed/ratio sizing.
  ///
  /// Mirrors the Android/iOS rule:
  ///   - AR is applied unless BOTH width AND height are fixed (dp/sp/px).
  ///   - Percent is NOT treated as "fixed", so AR wins over percent dimensions.
  ///
  /// Percent sizing is handled by the parent container (not here) to avoid
  /// using FractionallySizedBox inside Stack/Positioned where constraints are loose.
  Widget _wrapWithSizing(Widget child, Layout? layout) {
    if (layout == null) return child;

    final w = layout.width;
    final h = layout.height;

    final wIsFixed = w != null &&
        w.special == null &&
        w.unit != DimensionUnit.percent &&
        w.value > 0;
    final hIsFixed = h != null &&
        h.special == null &&
        h.unit != DimensionUnit.percent &&
        h.value > 0;

    final ar = layout.aspectRatio;
    if (ar != null && ar > 0 && !(wIsFixed && hIsFixed)) {
      return AspectRatio(aspectRatio: ar, child: child);
    }

    if (wIsFixed || hIsFixed) {
      return SizedBox(
        width: wIsFixed ? w.value : null,
        height: hIsFixed ? h.value : null,
        child: child,
      );
    }

    return child;
  }
}
