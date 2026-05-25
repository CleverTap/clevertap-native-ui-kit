import 'enums.dart';

class TextDimension {
  final double value;
  final TextDimensionUnit unit;

  const TextDimension({required this.value, this.unit = TextDimensionUnit.platform});

  // Resolves to actual pixel/pt value. rootHeight is the root container height in logical pixels.
  // For percent: rootHeight * value / 1000 (matches Android/iOS /1000 divisor)
  double resolve(double rootHeight) => switch (unit) {
        TextDimensionUnit.platform => value,
        TextDimensionUnit.percent => rootHeight * value / 1000.0,
      };

  // Accepts raw number (platform units) or {"value": N, "unit": "percent"}
  factory TextDimension.fromJson(dynamic json) {
    if (json == null) return const TextDimension(value: 0);
    if (json is num) {
      return TextDimension(value: json.toDouble(), unit: TextDimensionUnit.platform);
    }
    if (json is Map<String, dynamic>) {
      final value = (json['value'] as num?)?.toDouble() ?? 0;
      final unit = TextDimensionUnit.fromJson(json['unit'] as String? ?? 'platform');
      return TextDimension(value: value, unit: unit);
    }
    return const TextDimension(value: 0);
  }
}
