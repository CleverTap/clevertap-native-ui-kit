import 'enums.dart';

sealed class Background {
  const Background();

  factory Background.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'solid' => SolidBackground.fromJson(json),
      'linear_gradient' => LinearGradientBackground.fromJson(json),
      'radial_gradient' => RadialGradientBackground.fromJson(json),
      'sweep_gradient' => SweepGradientBackground.fromJson(json),
      'image' => ImageBackground.fromJson(json),
      'shimmer' => ShimmerBackground.fromJson(json),
      'animated_gradient' => AnimatedGradientBackground.fromJson(json),
      'pulse' => PulseBackground.fromJson(json),
      'pattern' => PatternBackground.fromJson(json),
      'particles' => ParticlesBackground.fromJson(json),
      'layered' => LayeredBackground.fromJson(json),
      _ => SolidBackground(color: '#00000000'),
    };
  }
}

class SolidBackground extends Background {
  final String color;

  const SolidBackground({required this.color});

  factory SolidBackground.fromJson(Map<String, dynamic> json) =>
      SolidBackground(color: json['color'] as String? ?? '#000000');
}

class LinearGradientBackground extends Background {
  final double angle;
  final List<String> colors;
  final List<double>? stops;

  const LinearGradientBackground({
    required this.angle,
    required this.colors,
    this.stops,
  });

  factory LinearGradientBackground.fromJson(Map<String, dynamic> json) =>
      LinearGradientBackground(
        angle: (json['angle'] as num?)?.toDouble() ?? 0,
        colors: (json['colors'] as List?)?.map((e) => e as String).toList() ?? const [],
        stops: (json['stops'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      );
}

class RadialGradientBackground extends Background {
  final double centerX;
  final double centerY;
  final double radius;
  final List<String> colors;
  final List<double>? stops;

  const RadialGradientBackground({
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.radius = 1.0,
    required this.colors,
    this.stops,
  });

  factory RadialGradientBackground.fromJson(Map<String, dynamic> json) =>
      RadialGradientBackground(
        centerX: (json['center_x'] as num?)?.toDouble() ?? 0.5,
        centerY: (json['center_y'] as num?)?.toDouble() ?? 0.5,
        radius: (json['radius'] as num?)?.toDouble() ?? 1.0,
        colors: (json['colors'] as List?)?.map((e) => e as String).toList() ?? const [],
        stops: (json['stops'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      );
}

class SweepGradientBackground extends Background {
  final double centerX;
  final double centerY;
  final double startAngle;
  final List<String> colors;
  final List<double>? stops;

  const SweepGradientBackground({
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.startAngle = 0,
    required this.colors,
    this.stops,
  });

  factory SweepGradientBackground.fromJson(Map<String, dynamic> json) =>
      SweepGradientBackground(
        centerX: (json['center_x'] as num?)?.toDouble() ?? 0.5,
        centerY: (json['center_y'] as num?)?.toDouble() ?? 0.5,
        startAngle: (json['start_angle'] as num?)?.toDouble() ?? 0,
        colors: (json['colors'] as List?)?.map((e) => e as String).toList() ?? const [],
        stops: (json['stops'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      );
}

class ImageBackground extends Background {
  final String url;
  final ImageFit fit;
  final double opacity;
  final double blur;
  final String? tint;
  final double tintOpacity;

  const ImageBackground({
    required this.url,
    this.fit = ImageFit.crop,
    this.opacity = 1.0,
    this.blur = 0,
    this.tint,
    this.tintOpacity = 0,
  });

  factory ImageBackground.fromJson(Map<String, dynamic> json) => ImageBackground(
        url: json['url'] as String? ?? '',
        fit: ImageFit.fromJson(json['fit'] as String? ?? 'crop'),
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        blur: (json['blur'] as num?)?.toDouble() ?? 0,
        tint: json['tint'] as String?,
        tintOpacity: (json['tint_opacity'] as num?)?.toDouble() ?? 0,
      );
}

// Deferred to v2 — parsed but rendered as transparent with warning
class ShimmerBackground extends Background {
  final String baseColor;
  final String highlightColor;
  final double angle;
  final int duration;
  final bool loop;

  const ShimmerBackground({
    required this.baseColor,
    required this.highlightColor,
    this.angle = 45,
    this.duration = 1500,
    this.loop = true,
  });

  factory ShimmerBackground.fromJson(Map<String, dynamic> json) => ShimmerBackground(
        baseColor: json['base_color'] as String? ?? '#E0E0E0',
        highlightColor: json['highlight_color'] as String? ?? '#F5F5F5',
        angle: (json['angle'] as num?)?.toDouble() ?? 45,
        duration: json['duration'] as int? ?? 1500,
        loop: json['loop'] as bool? ?? true,
      );
}

// Deferred to v2 — parsed but rendered as transparent with warning
class AnimatedGradientBackground extends Background {
  final GradientType gradientType;
  final double angle;
  final List<String> colors;
  final int duration;
  final bool loop;
  final AnimationStyle animationStyle;

  const AnimatedGradientBackground({
    required this.gradientType,
    this.angle = 0,
    required this.colors,
    this.duration = 3000,
    this.loop = true,
    this.animationStyle = AnimationStyle.smooth,
  });

  factory AnimatedGradientBackground.fromJson(Map<String, dynamic> json) =>
      AnimatedGradientBackground(
        gradientType: GradientType.fromJson(json['gradient_type'] as String? ?? 'linear'),
        angle: (json['angle'] as num?)?.toDouble() ?? 0,
        colors: (json['colors'] as List?)?.map((e) => e as String).toList() ?? const [],
        duration: json['duration'] as int? ?? 3000,
        loop: json['loop'] as bool? ?? true,
        animationStyle: AnimationStyle.fromJson(json['animation_style'] as String? ?? 'smooth'),
      );
}

// Deferred to v2 — parsed but rendered as transparent with warning
class PulseBackground extends Background {
  final String color;
  final double minOpacity;
  final double maxOpacity;
  final int duration;
  final bool loop;

  const PulseBackground({
    required this.color,
    this.minOpacity = 0.3,
    this.maxOpacity = 1.0,
    this.duration = 1000,
    this.loop = true,
  });

  factory PulseBackground.fromJson(Map<String, dynamic> json) => PulseBackground(
        color: json['color'] as String? ?? '#000000',
        minOpacity: (json['min_opacity'] as num?)?.toDouble() ?? 0.3,
        maxOpacity: (json['max_opacity'] as num?)?.toDouble() ?? 1.0,
        duration: json['duration'] as int? ?? 1000,
        loop: json['loop'] as bool? ?? true,
      );
}

// Deferred to v2 — parsed but rendered as transparent with warning
class PatternBackground extends Background {
  final PatternType patternType;
  final String primaryColor;
  final String secondaryColor;
  final double size;
  final double spacing;
  final double opacity;

  const PatternBackground({
    required this.patternType,
    required this.primaryColor,
    required this.secondaryColor,
    this.size = 20,
    this.spacing = 30,
    this.opacity = 1.0,
  });

  factory PatternBackground.fromJson(Map<String, dynamic> json) => PatternBackground(
        patternType: PatternType.fromJson(json['pattern_type'] as String? ?? 'dots'),
        primaryColor: json['primary_color'] as String? ?? '#000000',
        secondaryColor: json['secondary_color'] as String? ?? '#FFFFFF',
        size: (json['size'] as num?)?.toDouble() ?? 20,
        spacing: (json['spacing'] as num?)?.toDouble() ?? 30,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      );
}

// Deferred to v2 — parsed but rendered as transparent with warning
class ParticlesBackground extends Background {
  final String particleColor;
  final int particleCount;
  final double particleSize;
  final double speed;
  final ParticleDirection direction;
  final double opacity;

  const ParticlesBackground({
    required this.particleColor,
    this.particleCount = 50,
    this.particleSize = 4,
    this.speed = 2,
    this.direction = ParticleDirection.up,
    this.opacity = 0.7,
  });

  factory ParticlesBackground.fromJson(Map<String, dynamic> json) => ParticlesBackground(
        particleColor: json['particle_color'] as String? ?? '#000000',
        particleCount: json['particle_count'] as int? ?? 50,
        particleSize: (json['particle_size'] as num?)?.toDouble() ?? 4,
        speed: (json['speed'] as num?)?.toDouble() ?? 2,
        direction: ParticleDirection.fromJson(json['direction'] as String? ?? 'up'),
        opacity: (json['opacity'] as num?)?.toDouble() ?? 0.7,
      );
}

// Deferred to v2 — parsed but rendered as transparent with warning
class LayeredBackground extends Background {
  final List<Background> layers;

  const LayeredBackground({required this.layers});

  factory LayeredBackground.fromJson(Map<String, dynamic> json) => LayeredBackground(
        layers: (json['layers'] as List?)
                ?.map((e) => Background.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
