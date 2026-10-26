import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

// The bridge is pure Dart now: log-level configuration only. Attribution is
// surfaced via NativeDisplayView callbacks (see native_display_attribution_test).
void main() {
  group('NativeDisplayBridge log level', () {
    setUp(NDLogger.resetForTest);
    tearDown(NDLogger.resetForTest);

    test('setLogLevel sets the level and marks it explicit', () {
      NativeDisplayBridge.setLogLevel(NDLogLevel.verbose);
      expect(NDLogger.currentLevel, NDLogLevel.verbose);
      expect(NDLogger.isExplicitlySet, isTrue);
    });

    test('syncLogLevelFromCore applies the core level when none set explicitly', () {
      NativeDisplayBridge.syncLogLevelFromCore(3); // VERBOSE
      expect(NDLogger.currentLevel, NDLogLevel.verbose);
      // Sync must not mark the level explicit — later syncs may still update it.
      expect(NDLogger.isExplicitlySet, isFalse);
    });

    test('syncLogLevelFromCore maps an unknown level to DEBUG', () {
      NativeDisplayBridge.syncLogLevelFromCore(99);
      expect(NDLogger.currentLevel, NDLogLevel.debug);
    });

    test('client setLogLevel wins over a subsequent core sync', () {
      NativeDisplayBridge.setLogLevel(NDLogLevel.off);
      NativeDisplayBridge.syncLogLevelFromCore(3); // would be VERBOSE if applied
      expect(NDLogger.currentLevel, NDLogLevel.off);
    });

    test('a later core sync re-updates the level while not explicitly set', () {
      NativeDisplayBridge.syncLogLevelFromCore(0); // INFO
      expect(NDLogger.currentLevel, NDLogLevel.info);
      NativeDisplayBridge.syncLogLevelFromCore(3); // VERBOSE
      expect(NDLogger.currentLevel, NDLogLevel.verbose);
    });
  });
}
