// Flutter counterpart of Android's SlotsScreenshotsTest.kt and iOS's
// SlotsScreenshotsTests.swift.
//
// Stays on the Slots tab. Flow:
//   1. Open the Slots tab, screenshot the empty (dashed placeholder) state.
//   2. Tap "Fetch Slot Data" — fires the canonical slot-fetch events
//      (Footer1, Footer5, Header1, Header2, Header4, lalit); see
//      slot_demo_screen.dart. The returned campaigns route to their slots.
//   3. Wait `fetchSlotWait`, screenshot `after_fetch`.
//   4. Fling to the bottom of the feed, screenshot `at_bottom`.
//   5. Fling back to the top, screenshot `back_at_top`.
//
// Run:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/slots_screenshots_test.dart -d <deviceId>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clevertap_native_display_sample/main.dart' as app;

import 'automation_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('slots screen — fetch and scroll, screenshot', (tester) async {
    app.main();
    await settle(tester, const Duration(seconds: 2));
    await prepareForScreenshots(binding);

    await switchToTab(tester, 'Slots');
    await binding.takeScreenshot('flutter-slots-initial');

    await tester.tap(find.byKey(const Key('fetch-slot-data-btn')));
    await settle(tester, fetchSlotWait);
    await binding.takeScreenshot('flutter-slots-after_fetch');

    final feed = find.byKey(const Key('slot-demo-feed'));
    expect(feed, findsOneWidget);

    // Scroll to the bottom of the ~19-row feed, then screenshot.
    await tester.fling(feed, const Offset(0, -1600), 3000);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('flutter-slots-at_bottom');

    // Scroll back to the top.
    await tester.fling(feed, const Offset(0, 1600), 3000);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('flutter-slots-back_at_top');
  });
}
