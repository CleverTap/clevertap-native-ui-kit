// Example: NativeDisplayView entry point — pure-Dart renderer
//
// This mirrors the real public API. The actual widget lives at
//   flutter/lib/src/renderer/native_display_view.dart
// and is exported from package:clevertap_native_display. Read that file for the
// full constructor; the snippets below show the common host usage.
//
// Key facts (verified against source):
//   - NativeDisplayView is a StatefulWidget; styles are resolved once (initState)
//     or supplied pre-resolved via NativeDisplayConfigParser.
//   - There are NO platform channels. Attribution is surfaced via callbacks that
//     the host forwards to clevertap_plugin.

import 'dart:convert';

import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter/widgets.dart';

/// 1) Simplest usage — parse JSON, render.
Widget renderFromJson(String jsonString) {
  final config = NativeDisplayConfig.fromJson(
    jsonDecode(jsonString) as Map<String, dynamic>,
  );
  return NativeDisplayView(config: config);
}

/// 2) With CleverTap attribution. The host forwards the callbacks to
///    clevertap_plugin's event APIs — the ND plugin never talks to native.
Widget renderWithAttribution(String jsonString, String wzrkId) {
  final config = NativeDisplayConfig.fromJson(
    jsonDecode(jsonString) as Map<String, dynamic>,
  );
  return NativeDisplayView(
    config: config,
    unitId: wzrkId, // CleverTap display unit id (wzrk_id)
    onNotificationViewed: (unitId) {
      // Fired once per impression. Host: pushDisplayUnitViewedEvent(unitId).
    },
    onNotificationClicked: (unitId, elementId, extras) {
      // Fired on interactive element tap. Host:
      // pushDisplayUnitElementClickedEvent(unitId, extras).
    },
    // Optional: intercept open_url for in-app routing (return true to handle).
    onOpenUrl: (url, openInBrowser) => false,
  );
}

/// 3) Parse a raw CleverTap display-unit map and render with styles pre-resolved
///    off the UI thread. NativeDisplayConfigParser.tryParse returns a
///    NativeDisplayUnit (config + resolvedStyles + unitId); passing resolvedStyles
///    lets NativeDisplayView skip StyleResolver at build time.
Future<Widget?> renderDisplayUnit(Map<String, dynamic> rawUnit) async {
  final unit = await NativeDisplayConfigParser.tryParse(rawUnit);
  if (unit == null) return null; // malformed / no ND config
  return NativeDisplayView(
    config: unit.config,
    resolvedStyles: unit.resolvedStyles,
    unitId: unit.unitId,
  );
}
