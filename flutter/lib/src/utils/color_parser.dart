import 'dart:ui';

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
}
