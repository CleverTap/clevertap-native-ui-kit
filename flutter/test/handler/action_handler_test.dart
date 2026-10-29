import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

void main() {
  group('ActionHandler listener dispatch', () {
    test('custom action calls listener with key', () async {
      String? capturedAction;
      String? capturedNodeId;
      Map<String, dynamic>? capturedParams;

      final handler = ActionHandler(
        listener: (action, nodeId, params) {
          capturedAction = action;
          capturedNodeId = nodeId;
          capturedParams = params;
        },
      );

      final action = NDAction.fromJson({'type': 'custom', 'key': 'promo_click'});
      await handler.handle(action, 'btn1');

      expect(capturedAction, 'custom');
      expect(capturedNodeId, 'btn1');
      expect(capturedParams?['key'], 'promo_click');
    });

    test('navigate action calls listener with destination', () async {
      String? capturedAction;
      Map<String, dynamic>? capturedParams;

      final handler = ActionHandler(
        listener: (action, nodeId, params) {
          capturedAction = action;
          capturedParams = params;
        },
      );

      final action = NDAction.fromJson({
        'type': 'navigate',
        'destination': 'product_detail',
        'params': {'id': '42'},
      });
      await handler.handle(action, 'card1');

      expect(capturedAction, 'navigate');
      expect(capturedParams?['destination'], 'product_detail');
      expect(capturedParams?['id'], '42');
    });

    test('track event action calls listener with eventName', () async {
      String? capturedAction;
      Map<String, dynamic>? capturedParams;

      final handler = ActionHandler(
        listener: (action, nodeId, params) {
          capturedAction = action;
          capturedParams = params;
        },
      );

      final action = NDAction.fromJson({
        'type': 'event',
        'eventName': 'Banner Viewed',
        'properties': {'campaign': 'summer'},
      });
      await handler.handle(action, 'banner');

      expect(capturedAction, 'event');
      expect(capturedParams?['eventName'], 'Banner Viewed');
      expect(capturedParams?['campaign'], 'summer');
    });

    test('composite sequential action calls listener for each sub-action', () async {
      final captured = <String>[];

      final handler = ActionHandler(
        listener: (action, nodeId, params) {
          captured.add(action);
        },
      );

      final action = NDAction.fromJson({
        'type': 'composite',
        'executionMode': 'sequential',
        'actions': [
          {'type': 'custom', 'key': 'first'},
          {'type': 'custom', 'key': 'second'},
        ],
      });
      await handler.handle(action, 'node');

      expect(captured, ['custom', 'custom']);
    });

    test('no listener — no crash on custom action', () async {
      final handler = ActionHandler();
      final action = NDAction.fromJson({'type': 'custom', 'key': 'x'});
      await expectLater(handler.handle(action, 'n'), completes);
    });

    test('no listener — no crash on navigate action', () async {
      final handler = ActionHandler();
      final action = NDAction.fromJson({'type': 'navigate', 'destination': 'home'});
      await expectLater(handler.handle(action, 'n'), completes);
    });
  });
}
