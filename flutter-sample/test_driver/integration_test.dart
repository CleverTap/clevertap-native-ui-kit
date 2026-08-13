// Driver for the events/slots screenshot automation suite.
//
// Runs on the HOST during `flutter drive` and receives each
// `binding.takeScreenshot(name)` call from the device via [onScreenshot],
// writing the PNG bytes to disk. Output lands in ND_SCREENSHOT_DIR (set by
// run_automation.sh) or, by default, ~/Desktop/nd-automation-output/flutter/ —
// the same place the Android Gradle task and iOS xcparse drop their PNGs, so
// all three platforms' screenshots sit side by side for comparison.

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final home = Platform.environment['HOME'] ?? '.';
  final outDir = Platform.environment['ND_SCREENSHOT_DIR'] ??
      '$home/Desktop/nd-automation-output/flutter';

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final dir = Directory(outDir)..createSync(recursive: true);
      final file = File('${dir.path}/$name.png');
      file.writeAsBytesSync(bytes);
      stdout.writeln('Captured: ${file.path}');
      return true;
    },
  );
}
