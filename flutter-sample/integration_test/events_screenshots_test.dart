// Flutter counterpart of Android's EventsScreenshotsTest.kt and iOS's
// EventsScreenshotsTests.swift.
//
// Stays on the Events tab and fires every event in [eventsToFire] through the
// on-screen input UI (type into `ct-event-input`, tap `ct-send-event-btn`),
// capturing a screenshot after each so a human can compare the rendered
// native-display campaigns against Android and iOS.
//
// Run:
//   cd flutter-sample && ./run_automation.sh <deviceId>
// or directly:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/events_screenshots_test.dart -d <deviceId>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clevertap_native_display_sample/main.dart' as app;

import 'automation_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('events screen — fire all events, screenshot each', (tester) async {
    app.main();
    // Give the app, CleverTap SDK init, and the first frame time to settle.
    await settle(tester, const Duration(seconds: 2));
    await prepareForScreenshots(binding);

    // Events is the default tab; tap explicitly for resilience.
    await switchToTab(tester, 'Events');
    await hideEventLog(tester);

    for (final event in eventsToFire) {
      await fireEventThroughScreen(tester, event);
      await binding.takeScreenshot('flutter-events-$event');
    }
  });
}
