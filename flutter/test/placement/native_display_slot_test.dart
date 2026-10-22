import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/internal/viewed_units_tracker.dart';

NativeDisplayConfig _config(String text) => NativeDisplayConfig.fromJson({
      'root': {
        'type': 'element',
        'id': 't',
        'elementType': 'text',
        'bindings': {'text': text},
        'layout': {
          'width': {'value': 100, 'unit': 'dp'},
          'height': {'value': 40, 'unit': 'dp'},
        },
      },
    });

NativeDisplayUnit _unit(String unitId, String slotId, String text) =>
    NativeDisplayUnit(unitId: unitId, slotId: slotId, config: _config(text));

Widget _wrap(Widget w) =>
    Directionality(textDirection: TextDirection.ltr, child: w);

void main() {
  final manager = NativeDisplaySlotManager.instance;

  setUp(() {
    manager.resetForTest();
    ViewedUnitsTracker.resetForTesting();
  });
  tearDown(() {
    manager.resetForTest();
    ViewedUnitsTracker.resetForTesting();
  });

  testWidgets('shows the loading placeholder until a unit arrives',
      (tester) async {
    await tester.pumpWidget(_wrap(NativeDisplaySlot(
      slotId: 'hero',
      loadingBuilder: (_, __) => const Text('loading'),
    )));

    expect(find.text('loading'), findsOneWidget);

    manager.deliverUnits([_unit('u1', 'hero', 'Hi')]);
    await tester.pump();

    expect(find.text('loading'), findsNothing);
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('renders a cached unit immediately on mount', (tester) async {
    manager.deliverUnits([_unit('u1', 'hero', 'Cached')]);

    await tester.pumpWidget(_wrap(const NativeDisplaySlot(slotId: 'hero')));
    await tester.pump();

    expect(find.text('Cached'), findsOneWidget);
  });

  testWidgets('registers on mount and unregisters on dispose', (tester) async {
    await tester.pumpWidget(_wrap(const NativeDisplaySlot(slotId: 'hero')));
    expect(manager.getActiveSlotIds(), {'hero'});

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    expect(manager.getActiveSlotIds(), isEmpty);
  });

  testWidgets('forwards the once-per-impression viewed attribution',
      (tester) async {
    final viewed = <String>[];

    await tester.pumpWidget(_wrap(NativeDisplaySlot(
      slotId: 'hero',
      onNotificationViewed: viewed.add,
    )));

    manager.deliverUnits([_unit('u1', 'hero', 'Hi')]);
    await tester.pump(); // rebuild with the unit
    await tester.pump(); // run the post-frame viewed callback

    expect(viewed, ['u1']);
  });

  testWidgets('re-registers when the slotId changes', (tester) async {
    manager.deliverUnits([
      _unit('u1', 'hero', 'HeroUnit'),
      _unit('u2', 'footer', 'FooterUnit'),
    ]);

    await tester.pumpWidget(_wrap(const NativeDisplaySlot(slotId: 'hero')));
    await tester.pump();
    expect(find.text('HeroUnit'), findsOneWidget);
    expect(manager.getActiveSlotIds(), {'hero'});

    await tester.pumpWidget(_wrap(const NativeDisplaySlot(slotId: 'footer')));
    await tester.pump();
    expect(find.text('FooterUnit'), findsOneWidget);
    expect(manager.getActiveSlotIds(), {'footer'});
  });
}
