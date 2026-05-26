import 'dart:convert';
import 'dart:isolate';

import '../models/native_display_config.dart';
import '../models/native_display_unit.dart';
import '../style/style_resolver.dart';

class NativeDisplayConfigParser {
  static Future<NativeDisplayUnit?> tryParse(dynamic rawUnit) async {
    try {
      // Dart 3.4+: Isolate.run returns any type when in same isolate group
      return await Isolate.run(() => _parseSync(rawUnit));
    } catch (_) {
      // Older Dart: fall back to synchronous parse on calling thread
      return _parseSync(rawUnit);
    }
  }

  static Future<List<NativeDisplayUnit>> parseAll(List<dynamic> rawUnits) async {
    try {
      return await Isolate.run(
        () => rawUnits.map(_parseSync).whereType<NativeDisplayUnit>().toList(),
      );
    } catch (_) {
      return rawUnits.map(_parseSync).whereType<NativeDisplayUnit>().toList();
    }
  }

  // Runs inside isolate — no Flutter/platform dependencies.
  static NativeDisplayUnit? _parseSync(dynamic rawUnit) {
    if (rawUnit is! Map) return null;
    try {
      final unit = _deepCast(rawUnit);

      final unitId = unit['wzrk_id']?.toString() ?? unit['slot_id']?.toString() ?? '';
      final slotId = unit['slot_id']?.toString();

      // Retain non-system keys as custom extras for the client.
      final customExtras = Map<String, dynamic>.from(unit)
        ..removeWhere((k, _) => _kSystemKeys.contains(k));

      NativeDisplayConfig? config;

      // Strategy 1: explicit native_display_config key
      final ndRaw = unit['native_display_config'];
      if (ndRaw is Map<String, dynamic>) {
        config = NativeDisplayConfig.fromJson(ndRaw);
      }

      // Strategy 2: custom_kv.nd_config JSON string
      if (config == null) {
        final kv = unit['custom_kv'];
        if (kv is Map<String, dynamic>) {
          final ndStr = kv['nd_config'];
          if (ndStr is String && ndStr.isNotEmpty) {
            config = NativeDisplayConfig.fromJson(
              jsonDecode(ndStr) as Map<String, dynamic>,
            );
          }
        }
      }

      // Strategy 3: entire unit is the config (has a 'root' key)
      if (config == null && unit.containsKey('root')) {
        config = NativeDisplayConfig.fromJson(unit);
      }

      if (config == null) return null;

      // Pre-resolve styles once; NativeDisplayView can skip resolution when provided.
      final resolvedStyles = StyleResolver().resolveAll(
        config.root,
        config.theme ?? NDTheme.empty,
        config.styleClasses,
      );

      return NativeDisplayUnit(
        unitId: unitId,
        slotId: slotId,
        config: config,
        customExtras: customExtras,
        resolvedStyles: resolvedStyles,
      );
    } catch (_) {
      return null;
    }
  }

  static const _kSystemKeys = {
    'wzrk_id',
    'slot_id',
    'native_display_config',
    'custom_kv',
    'wzrk_ttl',
    'wzrk_acct_id',
    'wzrk_ts',
  };

  // Platform channels deliver Map<Object?, Object?> at every nesting level.
  // Recursively convert to Map<String, dynamic> so fromJson works.
  static Map<String, dynamic> _deepCast(Map<dynamic, dynamic> raw) =>
      raw.map((k, v) => MapEntry(k.toString(), _deepCastValue(v)));

  static dynamic _deepCastValue(dynamic v) {
    if (v is Map) return _deepCast(v);
    if (v is List) return v.map(_deepCastValue).toList();
    return v;
  }
}
