import 'package:clevertap_plugin_with_native_display/clevertap_plugin_with_native_display.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// bindCleverTap() is the one-call integration. These tests mock the
// clevertap_plugin method channel so we can assert it wires:
//   - the global attribution sink (viewed / clicked / element-clicked)
//   - slot-sync out (onSlotSync -> recordEvent)
//   - the cached-units pull (getAllDisplayUnits)
// without a real native CleverTap SDK.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('clevertap_plugin/dart_to_native');
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getAllDisplayUnits') return <dynamic>[];
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    NativeDisplaySlotManager.instance.resetForTest();
    NativeDisplayAttribution.instance.clear();
  });

  test('bindCleverTap wires slot-sync + attribution sinks', () async {
    final manager = NativeDisplaySlotManager.instance;
    expect(manager.onSlotSync, isNull);
    expect(NativeDisplayAttribution.instance.onViewed, isNull);
    expect(NativeDisplayAttribution.instance.onClicked, isNull);

    // Completes without throwing. (The getAllDisplayUnits pull is guarded by
    // Platform.isAndroid/isIOS inside clevertap_plugin, so it no-ops on the test
    // host VM — exercised on-device, not here.)
    await manager.bindCleverTap();

    expect(manager.onSlotSync, isNotNull);
    expect(NativeDisplayAttribution.instance.onViewed, isNotNull);
    expect(NativeDisplayAttribution.instance.onClicked, isNotNull);
  });

  test('viewed sink -> pushDisplayUnitViewedEvent', () async {
    await NativeDisplaySlotManager.instance.bindCleverTap();
    calls.clear();

    NativeDisplayAttribution.instance.onViewed!('unit-x');
    await pumpEventQueue();

    expect(calls.single.method, 'pushDisplayUnitViewedEvent');
    expect((calls.single.arguments as Map)['unitId'], 'unit-x');
  });

  test('element click -> pushDisplayUnitElementClickedEvent', () async {
    await NativeDisplaySlotManager.instance.bindCleverTap();
    calls.clear();

    NativeDisplayAttribution.instance.onClicked!(
        'unit-x', 'cta', {'wzrk_c2a': 'Buy'});
    await pumpEventQueue();

    expect(calls.single.method, 'pushDisplayUnitElementClickedEvent');
    final args = calls.single.arguments as Map;
    expect(args['unitId'], 'unit-x');
    expect((args['additionalProperties'] as Map)['wzrk_c2a'], 'Buy');
  });

  test('unit click (empty elementId) -> pushDisplayUnitClickedEvent', () async {
    await NativeDisplaySlotManager.instance.bindCleverTap();
    calls.clear();

    NativeDisplayAttribution.instance.onClicked!('unit-x', '', const {});
    await pumpEventQueue();

    expect(calls.single.method, 'pushDisplayUnitClickedEvent');
  });

  test('onSlotSync -> recordEvent', () async {
    final manager = NativeDisplaySlotManager.instance;
    await manager.bindCleverTap();
    calls.clear();

    manager.onSlotSync!('wzrk_nd_slot_sync', {
      'slots': ['hero'],
    });
    await pumpEventQueue();

    expect(calls.single.method, 'recordEvent');
    expect((calls.single.arguments as Map)['eventName'], 'wzrk_nd_slot_sync');
  });

  test('unbindCleverTap clears the sinks', () async {
    final manager = NativeDisplaySlotManager.instance;
    await manager.bindCleverTap();

    manager.unbindCleverTap();

    expect(manager.onSlotSync, isNull);
    expect(NativeDisplayAttribution.instance.onViewed, isNull);
    expect(NativeDisplayAttribution.instance.onClicked, isNull);
  });
}
