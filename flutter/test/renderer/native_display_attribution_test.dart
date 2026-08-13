import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/internal/viewed_units_tracker.dart';

// SDK-6019: attribution is surfaced to the host through NativeDisplayView
// callbacks (pure Dart — no platform channel). These tests lock in the
// once-per-impression viewed gate and the click callback shape that the sample
// (SDK-6020) will consume.
NativeDisplayConfig _buttonConfig() => NativeDisplayConfig.fromJson({
      'root': {
        'type': 'element',
        'id': 'cta',
        'elementType': 'button',
        'bindings': {'text': 'Buy'},
        'layout': {
          'width': {'value': 200, 'unit': 'dp'},
          'height': {'value': 80, 'unit': 'dp'},
        },
        'actions': {
          'onClick': {
            'type': 'open_url',
            'url': 'https://example.com',
            'metadata': {'wzrk_c2a': 'Buy Now', 'wzrk_element_id': 'cta'},
          },
        },
      },
    });

NativeDisplayConfig _imageConfig() => NativeDisplayConfig.fromJson({
      'root': {
        'type': 'element',
        'id': 'hero',
        'elementType': 'image',
        'bindings': {'url': 'https://example.com/i.png'},
        'layout': {
          'width': {'value': 200, 'unit': 'dp'},
          'height': {'value': 200, 'unit': 'dp'},
        },
        'actions': {
          'onClick': {'type': 'custom', 'key': 'promo'},
        },
      },
    });

Widget _wrap(Widget w) => Directionality(textDirection: TextDirection.ltr, child: w);

void main() {
  setUp(ViewedUnitsTracker.resetForTesting);
  tearDown(ViewedUnitsTracker.resetForTesting);

  group('onNotificationViewed', () {
    testWidgets('fires exactly once per impression', (tester) async {
      final viewed = <String>[];

      await tester.pumpWidget(_wrap(NativeDisplayView(
        config: _buttonConfig(),
        unitId: 'unit-1',
        onNotificationViewed: viewed.add,
      )));
      await tester.pump(); // run the post-frame callback

      expect(viewed, ['unit-1']);

      // A rebuild while mounted must NOT re-fire (ViewedUnitsTracker gate).
      await tester.pump();
      expect(viewed, ['unit-1']);
    });

    testWidgets('does not fire when unitId is null', (tester) async {
      var fired = false;

      await tester.pumpWidget(_wrap(NativeDisplayView(
        config: _buttonConfig(),
        onNotificationViewed: (_) => fired = true,
      )));
      await tester.pump();

      expect(fired, isFalse);
    });

    testWidgets('re-fires after unmount then remount (fresh impression)', (tester) async {
      final viewed = <String>[];

      Widget view() => _wrap(NativeDisplayView(
            config: _buttonConfig(),
            unitId: 'unit-2',
            onNotificationViewed: viewed.add,
          ));

      await tester.pumpWidget(view());
      await tester.pump();
      expect(viewed, ['unit-2']);

      // Unmount → tracker clears the id.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      // Remount → counts as a fresh impression.
      await tester.pumpWidget(view());
      await tester.pump();
      expect(viewed, ['unit-2', 'unit-2']);
    });
  });

  group('onNotificationClicked', () {
    testWidgets('button tap delivers unitId, elementId and sanitized extras', (tester) async {
      String? unitId;
      String? elementId;
      Map<String, Object?>? extras;

      await tester.pumpWidget(_wrap(NativeDisplayView(
        config: _buttonConfig(),
        unitId: 'unit-3',
        onNotificationClicked: (u, e, x) {
          unitId = u;
          elementId = e;
          extras = x;
        },
      )));
      await tester.pump();

      await tester.tap(find.text('Buy'), warnIfMissed: false);
      await tester.pump();

      expect(unitId, 'unit-3');
      expect(elementId, 'cta');
      expect(extras?['action_type'], 'open_url');
      // BE-injected wzrk_* fields flow through from action.metadata.
      expect(extras?['wzrk_c2a'], 'Buy Now');
      expect(extras?['wzrk_element_id'], 'cta');
      // sanitize() stamps the ND SDK version on every payload.
      expect(extras?.containsKey('nd_lib_v_name'), isTrue);
    });

    testWidgets('image tap with onClick delivers the click callback', (tester) async {
      String? unitId;
      String? elementId;
      Map<String, Object?>? extras;

      await tester.pumpWidget(_wrap(NativeDisplayView(
        config: _imageConfig(),
        unitId: 'unit-4',
        onNotificationClicked: (u, e, x) {
          unitId = u;
          elementId = e;
          extras = x;
        },
      )));
      await tester.pump();

      await tester.tap(find.byType(GestureDetector), warnIfMissed: false);
      await tester.pump();

      expect(unitId, 'unit-4');
      expect(elementId, 'hero');
      expect(extras?['action_type'], 'custom');
      expect(extras?['action_key'], 'promo');
    });

    testWidgets('button tap does not fire click callback when unitId is null', (tester) async {
      var fired = false;

      await tester.pumpWidget(_wrap(NativeDisplayView(
        config: _buttonConfig(),
        onNotificationClicked: (_, __, ___) => fired = true,
      )));
      await tester.pump();

      await tester.tap(find.text('Buy'), warnIfMissed: false);
      await tester.pump();

      expect(fired, isFalse);
    });
  });
}
