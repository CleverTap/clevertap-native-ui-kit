import 'dart:convert';

import 'package:flutter/services.dart';

import '../handler/action_attribution_extras.dart';
import '../internal/nd_logger.dart';
import '../models/native_display_config.dart';

class NativeDisplayBridge {
  static const String _tag = 'NativeDisplayBridge';
  static const _channel = MethodChannel('com.clevertap.flutter.nativedisplay');
  static const _events = EventChannel('com.clevertap.flutter/native_display_events');
  static const _sampleChannel = MethodChannel('com.clevertap.flutter/native_display');

  /// Configure the SDK log level. Takes precedence over the auto-sync from
  /// Core SDK debug level — once set, [NDLogger.syncFromCoreSdk] will not
  /// override the client preference.
  static void setLogLevel(NDLogLevel level) => NDLogger.setLevel(level);

  // Fetch a display unit config JSON from the native CleverTap Core SDK by unitId.
  // Returns null when the unit is not found or an error occurs.
  static Future<NativeDisplayConfig?> fetchConfig(String unitId) async {
    try {
      final result = await _channel.invokeMethod<String>('fetchDisplayUnit', {'unitId': unitId});
      if (result == null) return null;
      final json = jsonDecode(result) as Map<String, dynamic>;
      return NativeDisplayConfig.fromJson(json);
    } on PlatformException catch (e) {
      NDLogger.w(_tag, 'fetchConfig failed for $unitId: ${e.message}');
      return null;
    }
  }

  // Report a viewed event for the given display unit to the CleverTap Core SDK.
  // Impressions are unit-level (no caller extras), but still carry the ND SDK
  // version stamp as `additionalProperties` for parity with the clicked path
  // and with the shipped Android/iOS SDKs.
  static Future<void> pushViewedEvent(String unitId) async {
    try {
      await _channel.invokeMethod<void>('pushViewedEvent', {
        'unitId': unitId,
        'additionalProperties': ActionAttributionExtras.versionStamp(),
      });
    } on PlatformException catch (e) {
      NDLogger.w(_tag, 'pushViewedEvent failed for $unitId: ${e.message}');
    }
  }

  // Report a clicked event for the given display unit and element to the CleverTap Core SDK.
  // [extras] carries the clicked action's attribution properties (action_type,
  // custom KVs, and BE-injected wzrk_* fields from action.metadata); when
  // non-empty it is forwarded to Core SDK as `additionalProperties`.
  static Future<void> pushClickedEvent(
    String unitId, {
    String? elementId,
    Map<String, Object?>? extras,
  }) async {
    try {
      await _channel.invokeMethod<void>('pushClickedEvent', {
        'unitId': unitId,
        if (elementId != null) 'elementId': elementId,
        if (extras != null && extras.isNotEmpty) 'additionalProperties': extras,
      });
    } on PlatformException catch (e) {
      NDLogger.w(_tag, 'pushClickedEvent failed for $unitId: ${e.message}');
    }
  }

  // Stream of events pushed from the native side (e.g. units_updated).
  // Each event is a Map<String, dynamic> with at minimum a 'type' key.
  static Stream<Map<String, dynamic>> get eventStream => _events
      .receiveBroadcastStream()
      .where((e) => e is Map)
      .map((e) => (e as Map).cast<String, dynamic>());

  // Fire a CleverTap event by name via the native Core SDK.
  // Used by the sample app's integration screen to send user-defined events.
  static Future<void> pushEvent(String eventName) async {
    try {
      await _sampleChannel.invokeMethod<void>('pushEvent', {'eventName': eventName});
    } on PlatformException catch (e) {
      NDLogger.w(_tag, 'pushEvent failed for $eventName: ${e.message}');
    } catch (_) {
      // Channel may not be set up in all host apps — silently ignore
    }
  }
}
