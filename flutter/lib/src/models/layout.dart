import 'enums.dart';

class Dimension {
  final double value;
  final DimensionUnit unit;
  final SpecialDimension? special;

  const Dimension({
    this.value = 0,
    this.unit = DimensionUnit.dp,
    this.special,
  });

  static const wrapContent =
      Dimension(value: 0, unit: DimensionUnit.dp, special: SpecialDimension.wrapContent);
  static const matchParent =
      Dimension(value: 0, unit: DimensionUnit.dp, special: SpecialDimension.matchParent);

  factory Dimension.fromJson(Map<String, dynamic> json) {
    final special = SpecialDimension.fromJson(json['special'] as String?);
    final unit = DimensionUnit.fromJson(json['unit'] as String? ?? 'dp');
    return Dimension(
      value: (json['value'] as num?)?.toDouble() ?? 0,
      unit: unit,
      special: special,
    );
  }

  // borderRadius accepts raw number (dp) or {"value": N, "unit": "percent"}
  factory Dimension.fromJsonFlexible(dynamic json) {
    if (json == null) return const Dimension();
    if (json is num) {
      return Dimension(value: json.toDouble(), unit: DimensionUnit.dp);
    }
    if (json is Map<String, dynamic>) {
      return Dimension.fromJson(json);
    }
    return const Dimension();
  }

  @override
  String toString() => 'Dimension(value: $value, unit: $unit, special: $special)';
}

class NDOffset {
  final double x;
  final double y;
  final DimensionUnit unit;

  const NDOffset({this.x = 0, this.y = 0, this.unit = DimensionUnit.dp});

  static const zero = NDOffset();

  factory NDOffset.fromJson(Map<String, dynamic> json) => NDOffset(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        unit: DimensionUnit.fromJson(json['unit'] as String? ?? 'dp'),
      );
}

class Spacing {
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final DimensionUnit unit;

  const Spacing({
    this.all,
    this.horizontal,
    this.vertical,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.unit = DimensionUnit.dp,
  });

  double resolveTop() => top ?? vertical ?? all ?? 0.0;
  double resolveBottom() => bottom ?? vertical ?? all ?? 0.0;
  double resolveLeft() => left ?? horizontal ?? all ?? 0.0;
  double resolveRight() => right ?? horizontal ?? all ?? 0.0;

  factory Spacing.fromJson(Map<String, dynamic> json) => Spacing(
        all: (json['all'] as num?)?.toDouble(),
        horizontal: (json['horizontal'] as num?)?.toDouble(),
        vertical: (json['vertical'] as num?)?.toDouble(),
        top: (json['top'] as num?)?.toDouble(),
        bottom: (json['bottom'] as num?)?.toDouble(),
        left: (json['left'] as num?)?.toDouble(),
        right: (json['right'] as num?)?.toDouble(),
        unit: DimensionUnit.fromJson(json['unit'] as String? ?? 'dp'),
      );
}

class ChildArrangement {
  final double? spacing;
  final DimensionUnit spacingUnit;
  final ArrangementStrategy strategy;

  const ChildArrangement({
    this.spacing,
    this.spacingUnit = DimensionUnit.dp,
    this.strategy = ArrangementStrategy.spaced,
  });

  static const defaultArrangement =
      ChildArrangement(spacing: 0, strategy: ArrangementStrategy.spaced);

  factory ChildArrangement.fromJson(Map<String, dynamic> json) => ChildArrangement(
        spacing: (json['spacing'] as num?)?.toDouble(),
        spacingUnit: DimensionUnit.fromJson(json['spacingUnit'] as String? ?? 'dp'),
        strategy: ArrangementStrategy.fromJson(json['strategy'] as String? ?? 'spaced'),
      );
}

class Layout {
  final Dimension? width;
  final Dimension? height;
  final double? aspectRatio;
  final NDOffset? offset;
  final Spacing? padding;
  final ChildArrangement? arrangement;

  const Layout({
    this.width,
    this.height,
    this.aspectRatio,
    this.offset,
    this.padding,
    this.arrangement,
  });

  factory Layout.fromJson(Map<String, dynamic> json) => Layout(
        width:
            json['width'] != null ? Dimension.fromJson(json['width'] as Map<String, dynamic>) : null,
        height: json['height'] != null
            ? Dimension.fromJson(json['height'] as Map<String, dynamic>)
            : null,
        aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
        offset: json['offset'] != null
            ? NDOffset.fromJson(json['offset'] as Map<String, dynamic>)
            : null,
        padding: json['padding'] != null
            ? Spacing.fromJson(json['padding'] as Map<String, dynamic>)
            : null,
        arrangement: json['arrangement'] != null
            ? ChildArrangement.fromJson(json['arrangement'] as Map<String, dynamic>)
            : null,
      );
}
