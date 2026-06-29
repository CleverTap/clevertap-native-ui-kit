import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/native_display_config.dart';

class NativeDisplayBridge {
  static const _channel = MethodChannel('com.clevertap.flutter.nativedisplay');
  static const _events = EventChannel('com.clevertap.flutter/native_display_events');
  static const _sampleChannel = MethodChannel('com.clevertap.flutter/native_display');

  // Fetch a display unit config JSON from the native CleverTap Core SDK by unitId.
  // Returns null when the unit is not found or an error occurs.
  static Future<NativeDisplayConfig?> fetchConfig(String unitId) async {
    try {
      final result = await _channel.invokeMethod<String>('fetchDisplayUnit', {'unitId': unitId});
      if (result == null) return null;
      final json = jsonDecode(result) as Map<String, dynamic>;
      return NativeDisplayConfig.fromJson(json);
    } on PlatformException catch (e) {
      debugPrint('[NativeDisplay] fetchConfig failed for $unitId: ${e.message}');
      return null;
    }
  }

  // Report a viewed event for the given display unit to the CleverTap Core SDK.
  static Future<void> pushViewedEvent(String unitId) async {
    try {
      await _channel.invokeMethod<void>('pushViewedEvent', {'unitId': unitId});
    } on PlatformException catch (e) {
      debugPrint('[NativeDisplay] pushViewedEvent failed for $unitId: ${e.message}');
    }
  }

  // Report a clicked event for the given display unit and element to the CleverTap Core SDK.
  static Future<void> pushClickedEvent(String unitId, {String? elementId}) async {
    try {
      await _channel.invokeMethod<void>('pushClickedEvent', {
        'unitId': unitId,
        if (elementId != null) 'elementId': elementId,
      });
    } on PlatformException catch (e) {
      debugPrint('[NativeDisplay] pushClickedEvent failed for $unitId: ${e.message}');
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
      debugPrint('[NativeDisplay] pushEvent failed for $eventName: ${e.message}');
    } catch (_) {
      // Channel may not be set up in all host apps — silently ignore
    }
  }
}
