import 'package:flutter/foundation.dart';

import 'model_hash.dart';
import 'native_display_config.dart';
import 'style.dart';

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
        ndMapHash(customExtras),
        ndMapHash(resolvedStyles),
      );
}
