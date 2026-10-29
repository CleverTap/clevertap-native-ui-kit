import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../evaluator/variable_evaluator.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../../models/text_dimension.dart';
import '../../utils/color_parser.dart';
import '../root_height_scope.dart';
import '../style_applier.dart';

class TextElement extends StatelessWidget {
  final NativeDisplayElement node;
  final Style style;
  final VariableEvaluator evaluator;

  const TextElement({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
  });

  @override
  Widget build(BuildContext context) {
    final rootHeight = RootHeightScope.of(context);
    final rawText = node.bindings['text'] ?? '';
    final text = evaluator.evaluateString(rawText);

    final fontSize = _resolveTextDimension(style.fontSize, rootHeight) ?? 14.0;
    final lineHeight = _resolveTextDimension(style.lineHeight, rootHeight);
    final heightMultiplier = lineHeight != null ? lineHeight / fontSize : null;

    final textStyle = TextStyle(
      color: ColorParser.parse(style.textColor),
      fontSize: fontSize,
      fontFamily: style.fontFamily,
      fontWeight: _resolveFontWeight(style.fontWeight),
      fontStyle: style.fontStyle == NDFontStyle.italic ? FontStyle.italic : FontStyle.normal,
      height: heightMultiplier,
      letterSpacing: style.letterSpacing,
      decoration: _resolveDecoration(style.textDecoration),
      shadows: _resolveShadows(style),
    );

    Widget textWidget = Text(
      text,
      style: textStyle,
      textAlign: _resolveTextAlign(style.textAlign),
      maxLines: style.maxLines,
      overflow: _resolveOverflow(style.overflow),
    );

    if (style.textGradient != null) {
      textWidget = ShaderMask(
        shaderCallback: (bounds) => _buildGradient(style.textGradient!).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: textWidget,
      );
    }

    return StyleApplier.apply(
      textWidget,
      style,
      rootHeight: rootHeight,
      padding: node.layout?.padding,
    );
  }

  double? _resolveTextDimension(TextDimension? dim, double rootHeight) {
    if (dim == null) return null;
    return dim.resolve(rootHeight);
  }

  FontWeight _resolveFontWeight(NDFontWeight? w) => switch (w) {
        NDFontWeight.light => FontWeight.w300,
        NDFontWeight.normal => FontWeight.w400,
        NDFontWeight.medium => FontWeight.w500,
        NDFontWeight.bold => FontWeight.w700,
        null => FontWeight.w400,
      };

  TextDecoration _resolveDecoration(NDTextDecoration? d) => switch (d) {
        NDTextDecoration.underline => TextDecoration.underline,
        NDTextDecoration.strikethrough => TextDecoration.lineThrough,
        _ => TextDecoration.none,
      };

  TextAlign _resolveTextAlign(String? align) => switch (align) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        'justify' => TextAlign.justify,
        _ => TextAlign.left,
      };

  TextOverflow? _resolveOverflow(NDTextOverflow? overflow) => switch (overflow) {
        NDTextOverflow.clip => TextOverflow.clip,
        NDTextOverflow.ellipsis => TextOverflow.ellipsis,
        NDTextOverflow.visible => null,
        null => null,
      };

  List<Shadow>? _resolveShadows(Style style) {
    if (style.textShadow == null) return null;
    final ts = style.textShadow!;
    return [
      Shadow(
        color: ColorParser.parse(ts.color) ?? const Color(0xFF000000),
        offset: Offset(ts.offsetX, ts.offsetY),
        blurRadius: ts.blur,
      )
    ];
  }

  Gradient _buildGradient(TextGradient tg) {
    final colors = tg.colors
        .map((c) => ColorParser.parse(c) ?? const Color(0xFF000000))
        .toList();
    final stops = tg.stops;
    if (tg.type == 'radial') {
      return RadialGradient(colors: colors, stops: stops);
    }
    // Default: linear
    final radians = (tg.angle - 90) * pi / 180;
    final dx = cos(radians);
    final dy = sin(radians);
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: colors,
      stops: stops,
    );
  }
}
