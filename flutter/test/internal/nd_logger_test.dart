import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors the shipped Android/iOS CleverTapAutoWire log-sync semantics:
// client-wins, unknown-level fallback = DEBUG, re-sync updates level without
// setting explicitlySet.
void main() {
  setUp(NDLogger.resetForTest);
  tearDown(NDLogger.resetForTest);

  group('NDLogLevel.fromInt', () {
    test('maps known Core SDK debug levels', () {
      expect(NDLogLevel.fromInt(-1), NDLogLevel.off);
      expect(NDLogLevel.fromInt(0), NDLogLevel.info);
      expect(NDLogLevel.fromInt(2), NDLogLevel.debug);
      expect(NDLogLevel.fromInt(3), NDLogLevel.verbose);
    });

    test('unknown level falls back to INFO', () {
      // Unknown Core debug levels must not silently enable verbose/debug
      // logging — they fall back to the safe INFO default.
      expect(NDLogLevel.fromInt(1), NDLogLevel.info);
      expect(NDLogLevel.fromInt(99), NDLogLevel.info);
      expect(NDLogLevel.fromInt(-5), NDLogLevel.info);
    });
  });

  group('NDLogger.syncFromCoreSdk', () {
    test('applies core level when client has not set one explicitly', () {
      NDLogger.syncFromCoreSdk(3);
      expect(NDLogger.currentLevel, NDLogLevel.verbose);
      // Sync must NOT mark the level as explicitly set — later syncs may update.
      expect(NDLogger.isExplicitlySet, isFalse);
    });

    test('client setLogLevel wins over a subsequent core sync', () {
      NativeDisplayBridge.setLogLevel(NDLogLevel.off);
      expect(NDLogger.isExplicitlySet, isTrue);

      NDLogger.syncFromCoreSdk(3); // would be VERBOSE if it applied
      expect(NDLogger.currentLevel, NDLogLevel.off);
    });

    test('a later sync re-updates level while not explicitly set', () {
      NDLogger.syncFromCoreSdk(0);
      expect(NDLogger.currentLevel, NDLogLevel.info);
      NDLogger.syncFromCoreSdk(3);
      expect(NDLogger.currentLevel, NDLogLevel.verbose);
    });
  });
}
