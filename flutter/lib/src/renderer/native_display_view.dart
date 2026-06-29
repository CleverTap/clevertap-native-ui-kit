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

class NativeDisplayView extends StatefulWidget {
  final NativeDisplayConfig config;

  /// Pre-resolved styles from [NativeDisplayConfigParser]. When provided,
  /// the view skips [StyleResolver] entirely — avoiding redundant computation.
  final Map<String, Style>? resolvedStyles;

  final NativeDisplayActionListener? actionListener;
  final NativeDisplayComponentListener? componentListener;

  const NativeDisplayView({
    super.key,
    required this.config,
    this.resolvedStyles,
    this.actionListener,
    this.componentListener,
  });

  @override
  State<NativeDisplayView> createState() => _NativeDisplayViewState();
}

class _NativeDisplayViewState extends State<NativeDisplayView> {
  late Map<String, Style> _resolvedStyles;

  @override
  void initState() {
    super.initState();
    _resolvedStyles = _resolve();
  }

  @override
  void didUpdateWidget(NativeDisplayView old) {
    super.didUpdateWidget(old);
    if (!identical(old.config, widget.config) ||
        !identical(old.resolvedStyles, widget.resolvedStyles)) {
      _resolvedStyles = _resolve();
    }
  }

  Map<String, Style> _resolve() =>
      widget.resolvedStyles ??
      StyleResolver().resolveAll(
        widget.config.root,
        widget.config.theme ?? NDTheme.empty,
        widget.config.styleClasses,
      );

  @override
  Widget build(BuildContext context) {
    final root = widget.config.root;
    if (root == null) return const SizedBox.shrink();

    final evaluator = VariableEvaluator(widget.config.variables);
    final layout = root.layout;

    // Optimization: when root has only fixed (dp) dimensions and no aspectRatio,
    // skip LayoutBuilder — constraints are already known from the JSON values.
    if (_hasOnlyFixedDimensions(layout)) {
      final fixedWidth = layout!.width!.value;
      final fixedHeight = layout.height!.value;
      return SizedBox(
        width: fixedWidth,
        height: fixedHeight,
        child: RootHeightScope(
          rootHeight: fixedHeight,
          child: ResolvedStylesScope(
            styles: _resolvedStyles,
            child: NativeDisplayRenderer(
              node: root,
              evaluator: evaluator,
              actionListener: widget.actionListener,
              componentListener: widget.componentListener,
            ),
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layouterWidth =
            constraints.maxWidth.isInfinite ? screenHeight : constraints.maxWidth;

        final effectiveRootWidth = _effectiveWidth(layout, layouterWidth);
        final rootHeight =
            _computeRootHeight(layout, effectiveRootWidth, constraints, screenHeight);

        Widget child = RootHeightScope(
          rootHeight: rootHeight,
          child: ResolvedStylesScope(
            styles: _resolvedStyles,
            child: NativeDisplayRenderer(
              node: root,
              evaluator: evaluator,
              actionListener: widget.actionListener,
              componentListener: widget.componentListener,
            ),
          ),
        );

        child = _applyRootSizing(child, layout, effectiveRootWidth, rootHeight, screenHeight);

        return child;
      },
    );
  }

  bool _hasOnlyFixedDimensions(Layout? layout) {
    if (layout == null) return false;
    final ar = layout.aspectRatio;
    if (ar != null && ar > 0) return false;
    final w = layout.width;
    final h = layout.height;
    if (w == null || h == null) return false;
    if (w.special != null || h.special != null) return false;
    if (w.unit == DimensionUnit.percent || h.unit == DimensionUnit.percent) return false;
    return w.value > 0 && h.value > 0;
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
