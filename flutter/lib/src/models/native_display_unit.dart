import 'native_display_config.dart';
import 'style.dart';

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
}
