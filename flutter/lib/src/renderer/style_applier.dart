import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/background.dart';
import '../models/enums.dart';
import '../models/layout.dart';
import '../models/style.dart';
import '../utils/color_parser.dart';

class StyleApplier {
  static Widget apply(
    Widget child,
    Style style, {
    required double rootHeight,
    Spacing? padding,
  }) {
    Widget result = child;

    final effectivePadding = _resolvePadding(padding);
    if (effectivePadding != EdgeInsets.zero) {
      result = Padding(padding: effectivePadding, child: result);
    }

    final radius = _resolveBorderRadius(style.borderRadius, rootHeight);

    if (radius != null) {
      result = ClipRRect(borderRadius: BorderRadius.circular(radius), child: result);
    }

    final decoration = _buildDecoration(style, rootHeight, radius);
    if (decoration != null) {
      result = DecoratedBox(decoration: decoration, child: result);
    }

    final opacity = style.opacity;
    if (opacity != null && opacity < 1.0) {
      result = Opacity(opacity: opacity.clamp(0.0, 1.0), child: result);
    }

    return result;
  }

  static EdgeInsets _resolvePadding(Spacing? spacing) {
    if (spacing == null) return EdgeInsets.zero;
    return EdgeInsets.only(
      top: spacing.resolveTop(),
      bottom: spacing.resolveBottom(),
      left: spacing.resolveLeft(),
      right: spacing.resolveRight(),
    );
  }

  static BoxDecoration? _buildDecoration(Style style, double rootHeight, double? radius) {
    final bgResult = _resolveBackground(style, rootHeight);
    final border = _resolveBorder(style, rootHeight);
    final shadows = _resolveShadow(style);

    Color? bgColor;
    Gradient? bgGradient;
    DecorationImage? bgImage;

    if (bgResult is Color) {
      bgColor = bgResult;
    } else if (bgResult is LinearGradient || bgResult is RadialGradient || bgResult is SweepGradient) {
      bgGradient = bgResult as Gradient;
    } else if (bgResult is DecorationImage) {
      bgImage = bgResult;
    }

    if (bgColor == null && bgGradient == null && bgImage == null && border == null && shadows == null && radius == null) {
      return null;
    }

    return BoxDecoration(
      color: bgColor,
      gradient: bgGradient,
      image: bgImage,
      border: border,
      borderRadius: radius != null ? BorderRadius.circular(radius) : null,
      boxShadow: shadows,
    );
  }

  static dynamic _resolveBackground(Style style, double rootHeight) {
    final bg = style.background;
    if (bg == null) {
      return ColorParser.parse(style.backgroundColor);
    }
    return switch (bg) {
      SolidBackground s => ColorParser.parse(s.color),
      LinearGradientBackground lg => _buildLinearGradient(lg),
      RadialGradientBackground rg => _buildRadialGradient(rg),
      SweepGradientBackground sg => _buildSweepGradient(sg),
      ImageBackground img => DecorationImage(
          image: NetworkImage(img.url),
          fit: BoxFit.cover,
          colorFilter: img.tint != null
              ? ColorFilter.mode(
                  ColorParser.parse(img.tint) ?? const Color(0x00000000),
                  BlendMode.srcOver,
                )
              : null,
        ),
      _ => () {
          debugPrint('[NativeDisplay] Animated background type deferred to v2: ${bg.runtimeType}');
          return null;
        }(),
    };
  }

  static LinearGradient _buildLinearGradient(LinearGradientBackground lg) {
    final radians = (lg.angle - 90) * pi / 180;
    final dx = cos(radians);
    final dy = sin(radians);
    final colors = lg.colors
        .map((c) => ColorParser.parse(c) ?? const Color(0x00000000))
        .toList();
    final stops = lg.stops;
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: colors,
      stops: stops,
    );
  }

  static RadialGradient _buildRadialGradient(RadialGradientBackground rg) {
    final colors = rg.colors
        .map((c) => ColorParser.parse(c) ?? const Color(0x00000000))
        .toList();
    return RadialGradient(
      center: Alignment(rg.centerX * 2 - 1, rg.centerY * 2 - 1),
      radius: rg.radius,
      colors: colors,
      stops: rg.stops,
    );
  }

  static SweepGradient _buildSweepGradient(SweepGradientBackground sg) {
    final colors = sg.colors
        .map((c) => ColorParser.parse(c) ?? const Color(0x00000000))
        .toList();
    return SweepGradient(
      center: Alignment.center,
      startAngle: sg.startAngle * pi / 180,
      endAngle: (sg.startAngle + 360) * pi / 180,
      colors: colors,
      stops: sg.stops,
    );
  }

  static Border? _resolveBorder(Style style, double rootHeight) {
    final width = style.borderWidth;
    if (width == null || width <= 0) return null;
    final resolvedWidth = rootHeight * width / 1000.0;
    if (resolvedWidth <= 0) return null;
    final color = ColorParser.parse(style.borderColor) ?? const Color(0xFF000000);
    return Border.all(color: color, width: resolvedWidth);
  }

  static List<BoxShadow>? _resolveShadow(Style style) {
    final color = ColorParser.parse(style.shadowColor);
    if (color == null) return null;
    return [
      BoxShadow(
        color: color,
        blurRadius: style.shadowRadius ?? 4.0,
        offset: Offset(style.shadowOffsetX ?? 0, style.shadowOffsetY ?? 0),
      ),
    ];
  }

  static double? _resolveBorderRadius(Dimension? borderRadius, double rootHeight) {
    if (borderRadius == null) return null;
    if (borderRadius.special != null) return null;
    return switch (borderRadius.unit) {
      DimensionUnit.percent => rootHeight * borderRadius.value / 100.0,
      _ => borderRadius.value,
    };
  }
}
