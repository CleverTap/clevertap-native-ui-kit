import 'package:flutter/widgets.dart';

import '../../evaluator/variable_evaluator.dart';
import '../../handler/action_attribution_extras.dart';
import '../../models/action.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../../utils/color_parser.dart';
import '../native_display_scope.dart';
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
    final rootHeight = NativeDisplayScope.rootHeightOf(context);
    final text = evaluator.evaluateString(node.bindings['text'] ?? '');
    final unitId = NativeDisplayScope.unitIdOf(context);
    final onNotificationClicked = NativeDisplayScope.onClickedOf(context);

    return GestureDetector(
      onTap: () => _handleClick(unitId, onNotificationClicked),
      child: StyleApplier.apply(
        Center(
          child: Text(
            text,
            style: _buildTextStyle(rootHeight),
            maxLines: style.maxLines,
            overflow: _resolveOverflow(style.overflow),
            softWrap: style.maxLines == null,
          ),
        ),
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
      letterSpacing: style.letterSpacing,
    );
  }

  TextOverflow? _resolveOverflow(NDTextOverflow? overflow) => switch (overflow) {
        NDTextOverflow.clip => TextOverflow.clip,
        NDTextOverflow.ellipsis => TextOverflow.ellipsis,
        NDTextOverflow.visible => null,
        null => null,
      };

  FontWeight _resolveFontWeight(NDFontWeight? w) => switch (w) {
        NDFontWeight.light => FontWeight.w300,
        NDFontWeight.normal => FontWeight.w400,
        NDFontWeight.medium => FontWeight.w500,
        NDFontWeight.bold => FontWeight.w700,
        null => FontWeight.w400,
      };

  void _handleClick(String? unitId, NativeDisplayNotificationClicked? onNotificationClicked) {
    final action = node.actions?[ActionTriggers.onClick];
    if (action == null) return;
    actionListener?.call('action', node.id, _payload(action));
    if (onNotificationClicked != null && unitId != null && unitId.isNotEmpty) {
      // Flatten the clicked action into attribution extras (action_type, custom
      // KVs, and BE-injected wzrk_* fields from action.metadata). The host feeds
      // these into clevertap_plugin.pushDisplayUnitElementClickedEvent.
      final extras = ActionAttributionExtras.sanitize(
        ActionAttributionExtras.from(action),
      );
      onNotificationClicked(unitId, node.id, extras);
    }
  }

  Map<String, dynamic>? _payload(NDAction action) {
    if (action is OpenUrlAction && action.metadata != null) return {...action.metadata!};
    if (action is CustomAction && action.metadata != null) return {...action.metadata!};
    return null;
  }
}
