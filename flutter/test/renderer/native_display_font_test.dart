// Internal helper under test (not part of the public surface).
import 'package:clevertap_native_display/src/renderer/native_display_font.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ctxWithJson = NativeDisplayFontContext(
    jsonFontFamily: 'JsonFont',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
  );
  const ctxNoJson = NativeDisplayFontContext(
    jsonFontFamily: null,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.normal,
  );

  tearDown(() {
    // Reset the global singleton between tests.
    NativeDisplayFont.instance
      ..defaultFamily = null
      ..resolver = null;
  });

  group('resolution order', () {
    test('resolver (per-view) wins over everything', () {
      final s = resolveNativeDisplayFont(
        ctx: ctxWithJson,
        scopeFamily: 'ScopeDefault',
        scopeResolver: (ctx) => const TextStyle(fontFamily: 'Resolved'),
      );
      expect(s?.fontFamily, 'Resolved');
    });

    test('per-view default family wins over JSON when no resolver', () {
      final s = resolveNativeDisplayFont(ctx: ctxWithJson, scopeFamily: 'ScopeDefault');
      expect(s?.fontFamily, 'ScopeDefault');
    });

    test('JSON family used when no resolver / default', () {
      final s = resolveNativeDisplayFont(ctx: ctxWithJson);
      expect(s?.fontFamily, 'JsonFont');
    });

    test('null (system font) when nothing provided', () {
      final s = resolveNativeDisplayFont(ctx: ctxNoJson);
      expect(s, isNull);
    });
  });

  group('global singleton fallback', () {
    test('global resolver used when no per-view resolver', () {
      NativeDisplayFont.instance.resolver =
          (ctx) => const TextStyle(fontFamily: 'GlobalResolved');
      final s = resolveNativeDisplayFont(ctx: ctxWithJson);
      expect(s?.fontFamily, 'GlobalResolved');
    });

    test('per-view resolver overrides global resolver', () {
      NativeDisplayFont.instance.resolver =
          (ctx) => const TextStyle(fontFamily: 'GlobalResolved');
      final s = resolveNativeDisplayFont(
        ctx: ctxWithJson,
        scopeResolver: (ctx) => const TextStyle(fontFamily: 'ViewResolved'),
      );
      expect(s?.fontFamily, 'ViewResolved');
    });

    test('global default family used when no resolver / per-view default', () {
      NativeDisplayFont.instance.defaultFamily = 'GlobalDefault';
      final s = resolveNativeDisplayFont(ctx: ctxWithJson);
      expect(s?.fontFamily, 'GlobalDefault');
    });
  });

  group('resolver fall-through + field adoption', () {
    test('resolver returning null falls through to default family', () {
      final s = resolveNativeDisplayFont(
        ctx: ctxWithJson,
        scopeFamily: 'ScopeDefault',
        scopeResolver: (ctx) => null,
      );
      expect(s?.fontFamily, 'ScopeDefault');
    });

    test('adopts fontFamily + fallback from the resolver result (google_fonts-shaped)',
        () {
      final s = resolveNativeDisplayFont(
        ctx: ctxWithJson,
        scopeResolver: (ctx) => const TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto'],
        ),
      );
      expect(s?.fontFamily, 'Inter');
      expect(s?.fontFamilyFallback, ['Roboto']);
      // Carries only font identity — no size/color leaks from the resolver.
      expect(s?.fontSize, isNull);
      expect(s?.color, isNull);
    });

    test('resolver receives the render context (weight/size)', () {
      late NativeDisplayFontContext seen;
      resolveNativeDisplayFont(
        ctx: ctxNoJson,
        scopeResolver: (ctx) {
          seen = ctx;
          return const TextStyle(fontFamily: 'X');
        },
      );
      expect(seen.fontWeight, FontWeight.w700);
      expect(seen.fontSize, 20);
    });
  });
}
