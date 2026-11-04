// iOS screenshot fallback for the ND cross-platform capture.
//
// integration_test's in-process `binding.takeScreenshot()` hangs on the iOS
// simulator (the `captureScreenshot` method channel never returns). This variant
// does NOT take screenshots — it only DRIVES the Events screen (fires each event
// through the UI, waits for the unit to land via the batch handshake, lets images
// decode) and prints a sync marker per event:
//
//   ND-SHOT-READY:<event>
//
// An external watcher captures the simulator screen with
// `xcrun simctl io <udid> screenshot` when it sees the marker, writing
// flutter-events-<event>.png — the same filenames capture_flutter.sh produces, so
// the segregate step works unchanged. Android keeps using the normal in-test path.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clevertap_native_display_sample/main.dart' as app;

import 'automation_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('events — fire all, external screenshot sync', (tester) async {
    app.main();
    await settle(tester, const Duration(seconds: 2));
    await switchToTab(tester, 'Events');
    await hideEventLog(tester);

    for (final event in eventsToFire) {
      await fireEventThroughScreen(tester, event);
      // Let images decode/paint before signalling (cold-cache first pass).
      await settle(tester, const Duration(seconds: 4));
      debugPrint('ND-SHOT-READY:$event');
      // Hold the frame so the external capturer has a window to screenshot.
      await settle(tester, const Duration(seconds: 3));
    }
    debugPrint('ND-SHOT-DONE');
  });
}
