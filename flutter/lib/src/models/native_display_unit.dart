import 'package:flutter/foundation.dart';

import 'native_display_config.dart';
import 'style.dart';

// Order-independent hash for a nullable map — pairs with mapEquals.
int _mapHash(Map<Object?, Object?>? map) {
  if (map == null) return null.hashCode;
  var h = 0;
  for (final e in map.entries) {
    h ^= Object.hash(e.key, e.value);
  }
  return Object.hash(map.length, h);
}

@immutable
class NativeDisplayUnit {
  final String unitId;
  final String? slotId;
  final NativeDisplayConfig config;
  final Map<String, dynamic> customExtras;
  final Map<String, Style> resolvedStyles;

  const NativeDisplayUnit({
    required this.unitId,
    this.slotId,
    required this.config,
    this.customExtras = const {},
    this.resolvedStyles = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeDisplayUnit &&
          other.unitId == unitId &&
          other.slotId == slotId &&
          other.config == config &&
          mapEquals(other.customExtras, customExtras) &&
          mapEquals(other.resolvedStyles, resolvedStyles);

  @override
  int get hashCode => Object.hash(
        unitId,
        slotId,
        config,
        _mapHash(customExtras),
        _mapHash(resolvedStyles),
      );
}
