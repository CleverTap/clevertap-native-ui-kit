import '../models/layout.dart';
import '../models/enums.dart';

class DimensionCalculator {
  // Returns null for wrap_content (intrinsic) and match_parent (caller uses infinity).
  // percent: parentSize * value / 100
  // dp/sp/px: value as logical pixels
  // aspectRatio: handled at render site, not here
  static double? resolve(
    Dimension? dim, {
    required double parentSize,
    double rootHeight = 0,
  }) {
    if (dim == null) return null;
    if (dim.special != null) return null; // wrap_content or match_parent
    return switch (dim.unit) {
      DimensionUnit.percent => parentSize * dim.value / 100.0,
      DimensionUnit.dp => dim.value,
      DimensionUnit.sp => dim.value,
      DimensionUnit.px => dim.value,
    };
  }
}
