import 'package:flutter/widgets.dart';

import '../../evaluator/variable_evaluator.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../../utils/color_parser.dart';
import '../root_height_scope.dart';
import '../style_applier.dart';

class ButtonElement extends StatelessWidget {
  final NativeDisplayElement node;
  final Style style;
  final VariableEvaluator evaluator;
  final void Function(String, String, Map<String, dynamic>?)? actionListener;

  const ButtonElement({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
    this.actionListener,
  });

  @override
  Widget build(BuildContext context) {
    final rootHeight = RootHeightScope.of(context);
    final text = evaluator.evaluateString(node.bindings['text'] ?? '');

    return GestureDetector(
      onTap: _handleClick,
      child: StyleApplier.apply(
        Center(child: Text(text, style: _buildTextStyle(rootHeight))),
        style,
        rootHeight: rootHeight,
        padding: node.layout?.padding,
      ),
    );
  }

  TextStyle _buildTextStyle(double rootHeight) {
    final fontSize = style.fontSize?.resolve(rootHeight) ?? 14.0;
    final lineHeight = style.lineHeight?.resolve(rootHeight);
    return TextStyle(
      color: ColorParser.parse(style.textColor),
      fontSize: fontSize,
      fontFamily: style.fontFamily,
      fontWeight: _resolveFontWeight(style.fontWeight),
      fontStyle: style.fontStyle == NDFontStyle.italic ? FontStyle.italic : FontStyle.normal,
      height: lineHeight != null ? lineHeight / fontSize : null,
    );
  }

  FontWeight _resolveFontWeight(NDFontWeight? w) => switch (w) {
        NDFontWeight.light => FontWeight.w300,
        NDFontWeight.normal => FontWeight.w400,
        NDFontWeight.medium => FontWeight.w500,
        NDFontWeight.bold => FontWeight.w700,
        null => FontWeight.w400,
      };

  void _handleClick() {
    final action = node.actions?['onClick'];
    if (action != null) {
      actionListener?.call('action', node.id, null);
    }
  }
}
