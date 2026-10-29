import 'dart:ui';

// Flutter 3.27+ has Color.withValues; older only withOpacity. Probe once.
final bool _supportsWithValues = () {
  try {
    // ignore: avoid_dynamic_calls
    (const Color(0xFF000000) as dynamic).withValues(alpha: 1.0);
    return true;
  } catch (_) {
    return false;
  }
}();

class ColorParser {
  // SDK stores RGBA (#RRGGBBAA), Flutter Color is ARGB (0xAARRGGBB)
  // #FF0000   → Color(0xFFFF0000)  (opaque red — implicit AA=FF)
  // #FF000080 → Color(0x80FF0000)  (red at 50% opacity — AA bytes swapped)
  static Color? parse(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return switch (cleaned.length) {
      6 => Color(0xFF000000 | value),
      8 => Color(((value & 0xFF) << 24) | (value >> 8)), // RGBA → ARGB
      _ => null,
    };
  }

  static Color parseWithDefault(String? hex, Color defaultColor) =>
      parse(hex) ?? defaultColor;

  /// Applies [opacity] (clamped to 0..1) to [color]. Uses `withValues` on
  /// Flutter 3.27+ (sidestepping the deprecated `withOpacity`) and falls back
  /// to `withOpacity` on older SDKs — probed once via [_supportsWithValues].
  static Color applyOpacity(Color color, double opacity) {
    final a = opacity.clamp(0.0, 1.0);
    if (_supportsWithValues) {
      // ignore: avoid_dynamic_calls
      return (color as dynamic).withValues(alpha: a) as Color;
    }
    // ignore: deprecated_member_use
    return color.withOpacity(a);
  }
}
