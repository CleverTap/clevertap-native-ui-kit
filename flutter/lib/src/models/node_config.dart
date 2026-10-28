import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class ImageConfig {
  final ImageFit fit;
  // null = auto-detect, true = force animated, false = disable animated
  final bool? animated;

  const ImageConfig({this.fit = ImageFit.crop, this.animated});

  factory ImageConfig.fromJson(Map<String, dynamic> json) => ImageConfig(
        fit: ImageFit.fromJson(json['fit'] as String? ?? 'crop'),
        animated: json['animated'] as bool?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageConfig && other.fit == fit && other.animated == animated;

  @override
  int get hashCode => Object.hash(fit, animated);
}

@immutable
class HtmlConfig {
  final bool javascriptEnabled;
  final bool scrollEnabled;
  final String? baseUrl;
  final bool transparentBackground;

  const HtmlConfig({
    this.javascriptEnabled = false,
    this.scrollEnabled = false,
    this.baseUrl,
    this.transparentBackground = true,
  });

  factory HtmlConfig.fromJson(Map<String, dynamic> json) => HtmlConfig(
        javascriptEnabled: json['javascriptEnabled'] as bool? ?? false,
        scrollEnabled: json['scrollEnabled'] as bool? ?? false,
        baseUrl: json['baseUrl'] as String?,
        transparentBackground: json['transparentBackground'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HtmlConfig &&
          other.javascriptEnabled == javascriptEnabled &&
          other.scrollEnabled == scrollEnabled &&
          other.baseUrl == baseUrl &&
          other.transparentBackground == transparentBackground;

  @override
  int get hashCode =>
      Object.hash(javascriptEnabled, scrollEnabled, baseUrl, transparentBackground);
}

@immutable
class DividerConfig {
  final Orientation orientation;
  final double thickness;
  final String color;

  const DividerConfig({
    this.orientation = Orientation.horizontal,
    this.thickness = 1,
    this.color = '#E0E0E0',
  });

  factory DividerConfig.fromJson(Map<String, dynamic> json) => DividerConfig(
        orientation: Orientation.fromJson(json['orientation'] as String? ?? 'horizontal'),
        thickness: (json['thickness'] as num?)?.toDouble() ?? 1,
        color: json['color'] as String? ?? '#E0E0E0',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DividerConfig &&
          other.orientation == orientation &&
          other.thickness == thickness &&
          other.color == color;

  @override
  int get hashCode => Object.hash(orientation, thickness, color);
}

@immutable
class NDAnimation {
  final AnimationType type;
  final int duration;
  final int delay;
  final Easing easing;

  const NDAnimation({
    this.type = AnimationType.none,
    this.duration = 300,
    this.delay = 0,
    this.easing = Easing.easeOut,
  });

  factory NDAnimation.fromJson(Map<String, dynamic> json) => NDAnimation(
        type: AnimationType.fromJson(json['type'] as String? ?? 'none'),
        duration: (json['duration'] as num?)?.toInt() ?? 300,
        delay: (json['delay'] as num?)?.toInt() ?? 0,
        easing: Easing.fromJson(json['easing'] as String? ?? 'ease_out'),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NDAnimation &&
          other.type == type &&
          other.duration == duration &&
          other.delay == delay &&
          other.easing == easing;

  @override
  int get hashCode => Object.hash(type, duration, delay, easing);
}
