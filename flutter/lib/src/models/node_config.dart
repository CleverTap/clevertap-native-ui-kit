import 'enums.dart';

class ImageConfig {
  final ImageFit fit;
  // null = auto-detect, true = force animated, false = disable animated
  final bool? animated;

  const ImageConfig({this.fit = ImageFit.crop, this.animated});

  factory ImageConfig.fromJson(Map<String, dynamic> json) => ImageConfig(
        fit: ImageFit.fromJson(json['fit'] as String? ?? 'crop'),
        animated: json['animated'] as bool?,
      );
}

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
}

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
}

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
        duration: json['duration'] as int? ?? 300,
        delay: json['delay'] as int? ?? 0,
        easing: Easing.fromJson(json['easing'] as String? ?? 'ease_out'),
      );
}
