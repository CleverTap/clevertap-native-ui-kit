import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/bridge/native_display_bridge.dart';

const _channel = MethodChannel('com.clevertap.flutter.nativedisplay');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeDisplayBridge', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('fetchConfig returns null when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        if (call.method == 'fetchDisplayUnit') return null;
        return null;
      });

      final result = await NativeDisplayBridge.fetchConfig('unit-1');
      expect(result, isNull);
    });

    test('fetchConfig parses returned JSON into NativeDisplayConfig', () async {
      final configJson = jsonEncode({
        'root': {
          'type': 'container',
          'id': 'root',
          'containerType': 'vertical',
          'children': [],
        },
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        if (call.method == 'fetchDisplayUnit') return configJson;
        return null;
      });

      final result = await NativeDisplayBridge.fetchConfig('unit-1');
      expect(result, isNotNull);
      expect(result!.root, isNotNull);
    });

    test('pushViewedEvent sends correct method and unitId', () async {
      String? capturedMethod;
      String? capturedUnitId;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        capturedMethod = call.method;
        capturedUnitId = (call.arguments as Map)['unitId'] as String?;
        return null;
      });

      await NativeDisplayBridge.pushViewedEvent('unit-42');

      expect(capturedMethod, 'pushViewedEvent');
      expect(capturedUnitId, 'unit-42');
    });

    test('pushClickedEvent sends correct method, unitId, and elementId', () async {
      String? capturedMethod;
      Map<dynamic, dynamic>? capturedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        capturedMethod = call.method;
        capturedArgs = call.arguments as Map;
        return null;
      });

      await NativeDisplayBridge.pushClickedEvent('unit-7', elementId: 'btn-ok');

      expect(capturedMethod, 'pushClickedEvent');
      expect(capturedArgs?['unitId'], 'unit-7');
      expect(capturedArgs?['elementId'], 'btn-ok');
    });

    test('pushClickedEvent without elementId omits elementId from args', () async {
      Map<dynamic, dynamic>? capturedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        capturedArgs = call.arguments as Map;
        return null;
      });

      await NativeDisplayBridge.pushClickedEvent('unit-8');

      expect(capturedArgs?.containsKey('elementId'), false);
    });

    test('fetchConfig returns null and does not throw on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        throw PlatformException(code: 'NOT_FOUND', message: 'Unit not found');
      });

      final result = await NativeDisplayBridge.fetchConfig('missing');
      expect(result, isNull);
    });
  });
}
