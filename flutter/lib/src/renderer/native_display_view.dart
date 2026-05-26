import 'package:flutter/widgets.dart';
import '../evaluator/variable_evaluator.dart';
import '../models/enums.dart';
import '../models/layout.dart';
import '../models/native_display_config.dart';
import '../models/style.dart';
import '../style/style_resolver.dart';
import 'native_display_renderer.dart';
import 'root_height_scope.dart';
import 'resolved_styles_scope.dart';

typedef NativeDisplayActionListener = void Function(
    String action, String nodeId, Map<String, dynamic>? params);
typedef NativeDisplayComponentListener = bool Function(
    String event, String nodeId, Map<String, dynamic>? params);

class NativeDisplayView extends StatelessWidget {
  final NativeDisplayConfig config;
  final NativeDisplayActionListener? actionListener;
  final NativeDisplayComponentListener? componentListener;
  final Map<String, Style> _resolvedStyles;

  NativeDisplayView({
    super.key,
    required this.config,
    this.actionListener,
    this.componentListener,
  }) : _resolvedStyles = StyleResolver().resolveAll(
          config.root,
          config.theme ?? NDTheme.empty,
          config.styleClasses,
        );

  @override
  Widget build(BuildContext context) {
    final root = config.root;
    if (root == null) return const SizedBox.shrink();

    final evaluator = VariableEvaluator(config.variables);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layouterWidth =
            constraints.maxWidth.isInfinite ? screenHeight : constraints.maxWidth;

        final effectiveRootWidth = _effectiveWidth(root.layout, layouterWidth);
        final rootHeight =
            _computeRootHeight(root.layout, effectiveRootWidth, constraints, screenHeight);

        Widget child = RootHeightScope(
          rootHeight: rootHeight,
          child: ResolvedStylesScope(
            styles: _resolvedStyles,
            child: NativeDisplayRenderer(
              node: root,
              evaluator: evaluator,
              actionListener: actionListener,
              componentListener: componentListener,
            ),
          ),
        );

        child = _applyRootSizing(child, root.layout, effectiveRootWidth, rootHeight, screenHeight);

        return child;
      },
    );
  }

  Widget _applyRootSizing(
    Widget child,
    Layout? layout,
    double effectiveRootWidth,
    double rootHeight,
    double screenHeight,
  ) {
    if (layout == null) return child;

    final rw = layout.width;
    final rh = layout.height;
    final ar = layout.aspectRatio;
    final hasAR = ar != null && ar > 0;

    // AR takes precedence over all percent dimensions — it uses full available width
    // and derives height. The AspectRatio widget in _wrapWithSizing handles the
    // visual constraint; no additional sizing wrapper is needed here.
    if (hasAR) return child;

    final hasPercentWidth =
        rw != null && rw.special == null && rw.unit == DimensionUnit.percent && rw.value > 0;

    if (hasPercentWidth) {
      double? explicitHeight;
      if (rh != null && rh.special == null && rh.unit == DimensionUnit.percent && rh.value > 0) {
        explicitHeight = screenHeight * rh.value / 100.0;
      }
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: effectiveRootWidth, height: explicitHeight, child: child),
      );
    }

    if (rh != null && rh.special == null && rh.unit == DimensionUnit.percent && rh.value > 0) {
      return SizedBox(height: screenHeight * rh.value / 100.0, child: child);
    }

    return child;
  }

  double _effectiveWidth(Layout? layout, double availableWidth) {
    // AR present → use full available width; percent is irrelevant.
    final ar = layout?.aspectRatio;
    if (ar != null && ar > 0) return availableWidth;

    final w = layout?.width;
    if (w != null && w.special == null && w.unit == DimensionUnit.percent && w.value > 0) {
      return availableWidth * w.value / 100.0;
    }
    return availableWidth;
  }

  double _computeRootHeight(
    Layout? layout,
    double effectiveRootWidth,
    BoxConstraints constraints,
    double screenHeight,
  ) {
    if (layout == null) return screenHeight;

    final ar = layout.aspectRatio;
    if (ar != null && ar > 0) return effectiveRootWidth / ar;

    final h = layout.height;
    if (h != null && h.special == null && h.value > 0) {
      if (h.unit == DimensionUnit.percent) return screenHeight * h.value / 100.0;
      return h.value;
    }

    if (!constraints.maxHeight.isInfinite) return constraints.maxHeight;

    return screenHeight;
  }
}
