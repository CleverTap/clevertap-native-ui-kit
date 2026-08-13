import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

class JsonLoader {
  static Future<NativeDisplayConfig?> loadFromAsset(String assetPath) async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return NativeDisplayConfig.fromJson(json);
    } catch (e) {
      debugPrint('[JsonLoader] Failed to load $assetPath: $e');
      return null;
    }
  }

  static Future<String?> loadStringFromAsset(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      debugPrint('[JsonLoader] Failed to load string from $assetPath: $e');
      return null;
    }
  }
}
