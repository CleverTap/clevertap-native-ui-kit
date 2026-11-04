import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../evaluator/variable_evaluator.dart';
import '../../handler/action_attribution_extras.dart';
import '../../handler/action_handler.dart';
import '../../models/action.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../../utils/color_parser.dart';
import '../native_display_font.dart';
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
    final onOpenUrl = NativeDisplayScope.onOpenUrlOf(context);

    return GestureDetector(
      onTap: () => _handleClick(unitId, onNotificationClicked, onOpenUrl),
      child: StyleApplier.apply(
        Center(
          child: Text(
            text,
            style: _buildTextStyle(context, rootHeight),
            maxLines: style.maxLines,
            overflow: _resolveOverflow(style.overflow),
            softWrap: style.maxLines == null,
            // Match Android's includeFontPadding=false / iOS: drop the extra
            // leading above the first line and below the last so the button text
            // box matches the natives for a given lineHeight.
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
        style,
        rootHeight: rootHeight,
        padding: node.layout?.padding,
      ),
    );
  }

  TextStyle _buildTextStyle(BuildContext context, double rootHeight) {
    // Default button font size 16 matches the native SDKs' BUTTON defaultFontSize
    // (TEXT defaults to 14). Only used when a config omits fontSize.
    final fontSize = style.fontSize?.resolve(rootHeight) ?? 16.0;
    final lineHeight = style.lineHeight?.resolve(rootHeight);
    final fontWeight = _resolveFontWeight(style.fontWeight);
    final fontStyle =
        style.fontStyle == NDFontStyle.italic ? FontStyle.italic : FontStyle.normal;
    // Client font resolution (resolver → default family → JSON family → system),
    // matching the native SDKs. Returns only font-identity fields.
    final fontOverride = resolveNativeDisplayFont(
      ctx: NativeDisplayFontContext(
        jsonFontFamily: style.fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      ),
      scopeFamily: NativeDisplayScope.fontFamilyOf(context),
      scopeResolver: NativeDisplayScope.fontResolverOf(context),
    );
    return TextStyle(
      // Default to white (native BUTTON defaultColor) when the config/theme omits
      // a color, rather than inheriting the host DefaultTextStyle's color.
      color: ColorParser.parse(style.textColor) ?? const Color(0xFFFFFFFF),
      fontSize: fontSize,
      fontFamily: fontOverride?.fontFamily,
      fontFamilyFallback: fontOverride?.fontFamilyFallback,
      fontFeatures: fontOverride?.fontFeatures,
      fontVariations: fontOverride?.fontVariations,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: _lineHeightMultiple(fontSize, lineHeight),
      // Center text in its line box, matching Android Compose
      // LineHeightStyle(alignment=Center) and iOS. Pairs with textHeightBehavior
      // on the Text widget.
      leadingDistribution: TextLeadingDistribution.even,
      // Explicit 0 (not null) so button text never inherits the host app's
      // DefaultTextStyle letterSpacing (e.g. Material's 0.25). Native ND uses 0.
      letterSpacing: style.letterSpacing ?? 0,
    );
  }

  // Default line height matches the native SDKs when the config omits it: a
  // percent-unit fontSize anchors to 1.2×, a raw (sp) fontSize to 1.5× — same as
  // Android's ElementRenderer and iOS's renderText. letterSpacing already matches
  // (both platforms default to 0).
  double? _lineHeightMultiple(double fontSize, double? lineHeight) {
    if (fontSize <= 0) return null;
    if (lineHeight != null) return lineHeight / fontSize;
    return style.fontSize?.unit == TextDimensionUnit.percent ? 1.2 : 1.5;
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

  void _handleClick(
    String? unitId,
    NativeDisplayNotificationClicked? onNotificationClicked,
    NativeDisplayOpenUrlCallback? onOpenUrl,
  ) {
    final action = node.actions?[ActionTriggers.onClick];
    if (action == null) return;
    // Execute the action — opens URLs via url_launcher (open_url), and dispatches
    // custom/navigate/track_event/composite — and surfaces it to the host
    // listener. The host can intercept open_url via onOpenUrl. Previously this
    // only notified the listener, so configured URLs never opened.
    unawaited(ActionHandler(listener: actionListener, onOpenUrl: onOpenUrl)
        .handle(action, node.id));
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
}
