import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/internal/viewed_units_tracker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The process-wide NativeDisplayAttribution sink is the fallback used when a
// NativeDisplayView/Slot has no per-widget onNotificationViewed/onNotification
// clicked. This is what lets the add-on's bindCleverTap() attribute every unit
// without the host wiring each render site.
NativeDisplayConfig _buttonConfig() => NativeDisplayConfig.fromJson(const {
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
            'metadata': {'wzrk_element_id': 'cta'},
          },
        },
      },
    });

Widget _wrap(Widget w) =>
    Directionality(textDirection: TextDirection.ltr, child: w);

void main() {
  setUp(ViewedUnitsTracker.resetForTesting);
  tearDown(() {
    ViewedUnitsTracker.resetForTesting();
    NativeDisplayAttribution.instance.clear();
  });

  testWidgets('global sink receives viewed when no per-widget callback',
      (tester) async {
    final viewed = <String>[];
    NativeDisplayAttribution.instance.onViewed = viewed.add;

    await tester.pumpWidget(_wrap(NativeDisplayView(
      config: _buttonConfig(),
      unitId: 'unit-g1',
    )));
    await tester.pump(); // post-frame viewed callback

    expect(viewed, ['unit-g1']);
  });

  testWidgets('global sink receives click when no per-widget callback',
      (tester) async {
    String? unitId;
    String? elementId;
    Map<String, Object?>? extras;
    NativeDisplayAttribution.instance.onClicked = (u, e, x) {
      unitId = u;
      elementId = e;
      extras = x;
    };

    await tester.pumpWidget(_wrap(NativeDisplayView(
      config: _buttonConfig(),
      unitId: 'unit-g2',
    )));
    await tester.pump();

    await tester.tap(find.text('Buy'), warnIfMissed: false);
    await tester.pump();

    expect(unitId, 'unit-g2');
    expect(elementId, 'cta');
    expect(extras?['action_type'], 'open_url');
    expect(extras?['wzrk_element_id'], 'cta');
  });

  testWidgets('per-widget callback takes precedence over the global sink',
      (tester) async {
    final global = <String>[];
    final perWidget = <String>[];
    NativeDisplayAttribution.instance.onViewed = global.add;

    await tester.pumpWidget(_wrap(NativeDisplayView(
      config: _buttonConfig(),
      unitId: 'unit-g3',
      onNotificationViewed: perWidget.add,
    )));
    await tester.pump();

    expect(perWidget, ['unit-g3']);
    expect(global, isEmpty, reason: 'global sink must not also fire');
  });
}
