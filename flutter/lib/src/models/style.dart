import 'package:flutter/foundation.dart';

import 'background.dart';
import 'enums.dart';
import 'layout.dart';
import 'text_dimension.dart';

@immutable
class TextShadow {
  final String color;
  final double offsetX;
  final double offsetY;
  final double blur;

  const TextShadow({
    required this.color,
    this.offsetX = 0,
    this.offsetY = 0,
    this.blur = 0,
  });

  factory TextShadow.fromJson(Map<String, dynamic> json) => TextShadow(
        color: json['color'] as String? ?? '#00000040',
        offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
        offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
        blur: (json['blur'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextShadow &&
          other.color == color &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.blur == blur;

  @override
  int get hashCode => Object.hash(color, offsetX, offsetY, blur);
}

@immutable
class TextGradient {
  final String type;
  final List<String> colors;
  final double angle;
  final List<double>? stops;

  const TextGradient({
    this.type = 'linear',
    required this.colors,
    this.angle = 0,
    this.stops,
  });

  factory TextGradient.fromJson(Map<String, dynamic> json) => TextGradient(
        type: json['type'] as String? ?? 'linear',
        colors: (json['colors'] as List?)
                ?.map((e) => e?.toString())
                .whereType<String>()
                .toList() ??
            const [],
        angle: (json['angle'] as num?)?.toDouble() ?? 0,
        stops: (json['stops'] as List?)
            ?.map((e) => e is num ? e.toDouble() : null)
            .whereType<double>()
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextGradient &&
          other.type == type &&
          listEquals(other.colors, colors) &&
          other.angle == angle &&
          listEquals(other.stops, stops);

  @override
  int get hashCode =>
      Object.hash(type, Object.hashAll(colors), angle,
          stops == null ? null : Object.hashAll(stops!));
}

@immutable
class Style {
  // Text properties (cascade to children)
  final String? textColor;
  final TextDimension? fontSize;
  final String? fontFamily;
  final NDFontWeight? fontWeight;
  final NDFontStyle? fontStyle;
  final TextDimension? lineHeight;
  final double? letterSpacing;
  final NDTextDecoration? textDecoration;
  final String? textAlign;
  final int? maxLines;
  final NDTextOverflow? overflow;
  final TextShadow? textShadow;
  final TextGradient? textGradient;

  // Visual properties (do NOT cascade)
  final Background? background;
  final String? backgroundColor;

  // Border properties (do NOT cascade)
  final Dimension? borderRadius;
  final double? borderWidth;
  final String? borderColor;

  // Shadow properties (do NOT cascade)
  final String? shadowColor;
  final double? shadowRadius;
  final double? shadowOffsetX;
  final double? shadowOffsetY;

  // Universal (cascades to children)
  final double? opacity;

  const Style({
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.fontStyle,
    this.lineHeight,
    this.letterSpacing,
    this.textDecoration,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textShadow,
    this.textGradient,
    this.background,
    this.backgroundColor,
    this.borderRadius,
    this.borderWidth,
    this.borderColor,
    this.shadowColor,
    this.shadowRadius,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.opacity,
  });

  static const empty = Style();

  // this takes priority; fallback to other per field
  Style merge(Style? other) {
    if (other == null) return this;
    return Style(
      textColor: textColor ?? other.textColor,
      fontSize: fontSize ?? other.fontSize,
      fontFamily: fontFamily ?? other.fontFamily,
      fontWeight: fontWeight ?? other.fontWeight,
      fontStyle: fontStyle ?? other.fontStyle,
      lineHeight: lineHeight ?? other.lineHeight,
      letterSpacing: letterSpacing ?? other.letterSpacing,
      textDecoration: textDecoration ?? other.textDecoration,
      textAlign: textAlign ?? other.textAlign,
      maxLines: maxLines ?? other.maxLines,
      overflow: overflow ?? other.overflow,
      textShadow: textShadow ?? other.textShadow,
      textGradient: textGradient ?? other.textGradient,
      background: background ?? other.background,
      backgroundColor: backgroundColor ?? other.backgroundColor,
      borderRadius: borderRadius ?? other.borderRadius,
      borderWidth: borderWidth ?? other.borderWidth,
      borderColor: borderColor ?? other.borderColor,
      shadowColor: shadowColor ?? other.shadowColor,
      shadowRadius: shadowRadius ?? other.shadowRadius,
      shadowOffsetX: shadowOffsetX ?? other.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? other.shadowOffsetY,
      opacity: opacity ?? other.opacity,
    );
  }

  // Returns only text properties + opacity (for cascading to children)
  Style cascadingOnly() => Style(
        textColor: textColor,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        lineHeight: lineHeight,
        letterSpacing: letterSpacing,
        textDecoration: textDecoration,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textShadow: textShadow,
        textGradient: textGradient,
        opacity: opacity,
      );

  factory Style.fromJson(Map<String, dynamic> json) => Style(
        textColor: json['textColor'] as String?,
        fontSize: json['fontSize'] != null ? TextDimension.fromJson(json['fontSize']) : null,
        fontFamily: json['fontFamily'] as String?,
        fontWeight: json['fontWeight'] != null
            ? NDFontWeight.fromJson(json['fontWeight'].toString())
            : null,
        fontStyle: json['fontStyle'] != null
            ? NDFontStyle.fromJson(json['fontStyle'].toString())
            : null,
        lineHeight: json['lineHeight'] != null ? TextDimension.fromJson(json['lineHeight']) : null,
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
        textDecoration: json['textDecoration'] != null
            ? NDTextDecoration.fromJson(json['textDecoration'].toString())
            : null,
        textAlign: json['textAlign'] as String?,
        maxLines: (json['maxLines'] as num?)?.toInt(),
        overflow: json['overflow'] != null
            ? NDTextOverflow.fromJson(json['overflow'].toString())
            : null,
        textShadow: json['textShadow'] != null
            ? TextShadow.fromJson(json['textShadow'] as Map<String, dynamic>)
            : null,
        textGradient: json['textGradient'] != null
            ? TextGradient.fromJson(json['textGradient'] as Map<String, dynamic>)
            : null,
        background: json['background'] != null
            ? Background.fromJson(json['background'] as Map<String, dynamic>)
            : null,
        backgroundColor: json['backgroundColor'] as String?,
        borderRadius: json['borderRadius'] != null
            ? Dimension.fromJsonFlexible(json['borderRadius'])
            : null,
        borderWidth: (json['borderWidth'] as num?)?.toDouble(),
        borderColor: json['borderColor'] as String?,
        shadowColor: json['shadowColor'] as String?,
        shadowRadius: (json['shadowRadius'] as num?)?.toDouble(),
        shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble(),
        shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble(),
        opacity: (json['opacity'] as num?)?.toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Style &&
          other.textColor == textColor &&
          other.fontSize == fontSize &&
          other.fontFamily == fontFamily &&
          other.fontWeight == fontWeight &&
          other.fontStyle == fontStyle &&
          other.lineHeight == lineHeight &&
          other.letterSpacing == letterSpacing &&
          other.textDecoration == textDecoration &&
          other.textAlign == textAlign &&
          other.maxLines == maxLines &&
          other.overflow == overflow &&
          other.textShadow == textShadow &&
          other.textGradient == textGradient &&
          other.background == background &&
          other.backgroundColor == backgroundColor &&
          other.borderRadius == borderRadius &&
          other.borderWidth == borderWidth &&
          other.borderColor == borderColor &&
          other.shadowColor == shadowColor &&
          other.shadowRadius == shadowRadius &&
          other.shadowOffsetX == shadowOffsetX &&
          other.shadowOffsetY == shadowOffsetY &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hashAll([
        textColor,
        fontSize,
        fontFamily,
        fontWeight,
        fontStyle,
        lineHeight,
        letterSpacing,
        textDecoration,
        textAlign,
        maxLines,
        overflow,
        textShadow,
        textGradient,
        background,
        backgroundColor,
        borderRadius,
        borderWidth,
        borderColor,
        shadowColor,
        shadowRadius,
        shadowOffsetX,
        shadowOffsetY,
        opacity,
      ]);
}
