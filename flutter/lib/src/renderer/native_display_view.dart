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

    Widget buildContent(double availableWidth, double availableHeight) {
      return RootHeightScope(
        rootHeight: availableHeight,
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
    }

    final needsLayout = _needsLayoutBuilder(root.layout);

    if (needsLayout) {
      return LayoutBuilder(
        builder: (context, constraints) => buildContent(
          constraints.maxWidth,
          constraints.maxHeight.isInfinite ? 0 : constraints.maxHeight,
        ),
      );
    }

    final w = _fixedSize(root.layout?.width);
    final h = _fixedSize(root.layout?.height);
    return SizedBox(
      width: w,
      height: h,
      child: buildContent(w ?? double.infinity, h ?? 0),
    );
  }

  bool _needsLayoutBuilder(Layout? layout) {
    if (layout == null) return false;
    if (_isPercent(layout.width) || _isPercent(layout.height)) return true;
    if (layout.aspectRatio != null) return true;
    return false;
  }

  bool _isPercent(Dimension? dim) =>
      dim != null && dim.special == null && dim.unit == DimensionUnit.percent;

  double? _fixedSize(Dimension? dim) {
    if (dim == null || dim.special != null || dim.unit == DimensionUnit.percent) return null;
    return dim.value;
  }
}
