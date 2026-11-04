# Flutter Client Font API for Native Display — Spec

**Status**: Spec for implementation
**Audience**: Native Display SDK team (Flutter), consumers of the Flutter plugin
**Related**: Jira `SDK-6296` (epic `SDK-5820`); builds on hermetic text rendering (`SDK-6246`, commit `eea677b`)
**Scope**: Flutter plugin only (`flutter/lib`) — pure Dart, no platform-channel / native changes

---

## TL;DR

The native ND SDKs let a client app provide its own font for ND content (a default font + a resolver for JSON font names). The **Flutter plugin has no equivalent** — it only passes the JSON `fontFamily` string straight to `TextStyle.fontFamily`, which resolves only if the app registered that exact family in `pubspec.yaml`. This is a cross-platform parity gap.

The API must compose **effortlessly** with how Flutter apps actually ship fonts:
- **`google_fonts`** (dynamic, runtime-loaded) — the common case,
- **pubspec-declared asset fonts** (incl. fonts from a package),
- **any custom `TextStyle` source**.

Because `google_fonts` hands back a **`TextStyle`** (whose family is registered at runtime, e.g. `GoogleFonts.inter()`), the resolver returns a **`TextStyle`**, not a family string — the SDK adopts the font-identifying fields and keeps its own size/color/weight/line-height from the JSON config.

This is also the sanctioned fix for the iOS wrapping difference in `SDK-6246`: that only occurred with the **system font** (SF optical tracking that Flutter's engine doesn't replicate). With one explicit client font on both platforms, Flutter-iOS and Flutter-Android render through the same engine and wrap identically.

---

## 1. What native already has

- **Android** (`NativeDisplayLocals.kt`): `LocalFontFamily` (client default) + `LocalFontFamilyResolver: (String) -> FontFamily?`; resolved in `resolveEffectiveFontFamily` — *client default → JSON-via-resolver → system*.
- **iOS** (`NativeDisplayRenderer.swift`): `\.nativeDisplayFontFamily` + `\.nativeDisplayFontResolver: (String, CGFloat, Font.Weight) -> Font`; same order.
- **Flutter today**: `fontFamily: style.fontFamily` only. No client default, no resolver. **Gap.**

---

## 2. Proposed Flutter API

Mirror native's two layers, but **`TextStyle`-returning** for google_fonts composability. Follows the existing `onOpenUrl` plumbing pattern (per-widget param + process-wide default via a singleton, surfaced to elements through `NativeDisplayScope`).

### 2.1 Public types (exported from `clevertap_native_display.dart`)
```dart
/// Context describing the text the SDK is about to render, so a resolver can pick
/// the right font / weight / optical variant.
class NativeDisplayFontContext {
  final String? jsonFontFamily; // fontFamily from the ND JSON (may be null)
  final double fontSize;        // resolved px/logical size
  final FontWeight fontWeight;  // resolved weight
  final FontStyle fontStyle;    // normal / italic
  const NativeDisplayFontContext({...});
}

/// Returns a TextStyle whose FONT-identifying fields (fontFamily,
/// fontFamilyFallback, package, fontFeatures, fontVariations) the SDK adopts.
/// Size / color / weight / line-height stay owned by the SDK (from the JSON).
/// Return null to fall through to the next layer.
typedef NativeDisplayFontResolver = TextStyle? Function(NativeDisplayFontContext ctx);
```
Returning a full `TextStyle` (rather than a family string) is what makes `google_fonts` a one-liner — `GoogleFonts.inter()` *is* a `TextStyle`.

### 2.2 `NativeDisplayView` constructor params
```dart
/// Convenience: a single default family for ALL ND text (e.g. a pubspec font).
final String? fontFamily;
/// Full control: pick a font per JSON-name / size / weight. Composes with
/// google_fonts, package fonts, fallbacks, etc. Wins over [fontFamily].
final NativeDisplayFontResolver? fontResolver;
```

### 2.3 Process-wide default (one-time global setup)
A singleton (mirroring `NativeDisplayAttribution.instance`) so a single wiring covers every render site — ideal for the add-on `bindCleverTap()`:
```dart
NativeDisplayFont.instance
  ..defaultFamily = 'Inter'
  ..resolver = (ctx) => GoogleFonts.inter(fontWeight: ctx.fontWeight);
```
Per-widget params override the global default.

### 2.4 Resolution order (shared helper used by `text_element` + `button_element`)
```
1. fontResolver(ctx)            — if it returns non-null  (HIGHEST; this is where google_fonts plugs in)
2. fontFamily (client default)  — simple single-family override
3. JSON fontFamily string       — current behaviour (pubspec-registered family)
4. null → system font           — hermetic baseline
```
Matches native precedence (client default/ resolver highest → JSON → system).

### 2.5 Merge semantics (critical for correctness)
```dart
final clientStyle = resolver?.call(ctx);               // e.g. GoogleFonts.inter(fontWeight: w)
var textStyle = _hermeticBase                            // inherit:false, letterSpacing 0, …
    .merge(clientStyle)                                  // adopt font family / fallback / features
    .copyWith(                                           // SDK ALWAYS owns these (from JSON)
      fontSize: fontSize, color: color, fontWeight: weight,
      fontStyle: fontStyle, height: heightMultiplier,
      letterSpacing: style.letterSpacing ?? 0,
    );
```
So the client controls *which font*, the SDK controls *how it's sized/coloured* — no surprises, and a client can't accidentally break percent sizing or the hermetic guarantees.

---

## 3. Client usage — ergonomics (the whole point)

**google_fonts — default font for all ND (most common):**
```dart
// one-time, global:
NativeDisplayFont.instance.resolver =
    (ctx) => GoogleFonts.inter(fontWeight: ctx.fontWeight, fontStyle: ctx.fontStyle);
// or per render site:
NativeDisplayView(config: cfg,
  fontResolver: (ctx) => GoogleFonts.inter(fontWeight: ctx.fontWeight));
```

**google_fonts — honour the JSON font name, fall back to a default:**
```dart
fontResolver: (ctx) => GoogleFonts.getFont(
    ctx.jsonFontFamily ?? 'Inter', fontWeight: ctx.fontWeight);
```

**pubspec-declared asset font (simplest):**
```dart
NativeDisplayView(config: cfg, fontFamily: 'MyBrandFont');
```

**asset font shipped in a package:**
```dart
fontResolver: (ctx) => const TextStyle(fontFamily: 'Brand', package: 'brand_kit');
```

**weight/size-aware selection (e.g. different file per weight):**
```dart
fontResolver: (ctx) => TextStyle(
    fontFamily: ctx.fontWeight.index >= FontWeight.w600.index ? 'Brand-Bold' : 'Brand-Regular');
```

Add-on convenience (so the ~1-line setup covers the whole app):
```dart
bindCleverTap(fontResolver: (ctx) => GoogleFonts.inter(fontWeight: ctx.fontWeight));
```

---

## 4. Touchpoints & size

Pure Dart, no native bridge. Mechanical plumbing mirroring the already-shipped `onOpenUrl` feature.

| File | Change |
|------|--------|
| `clevertap_native_display.dart` | export `NativeDisplayFontResolver`, `NativeDisplayFontContext` |
| `src/renderer/native_display_scope.dart` | fields + accessors (default family + resolver) |
| `src/renderer/native_display_view.dart` | `fontFamily` + `fontResolver` params + global fallback + thread into scope (both branches) |
| `src/renderer/elements/text_element.dart` | call shared font-resolution helper (merge semantics) |
| `src/renderer/elements/button_element.dart` | same |
| new: `src/renderer/native_display_font.dart` | `NativeDisplayFont` singleton + `NativeDisplayFontContext` + resolution helper |
| `clevertap_plugin_with_native_display` (add-on) | optional `bindCleverTap(fontFamily:, fontResolver:)` |
| `test/` | resolution-order + merge unit tests; widget test with a fake resolver |

**Estimate: small-to-medium (~1 day incl. tests).** No platform channels, no model/schema changes, no cross-platform coordination. `google_fonts` is a *client* dependency — the SDK takes **no** dependency on it (the resolver just returns a `TextStyle`), so there's zero coupling.

---

## 5. Testing
- Unit: resolution order (resolver → default family → JSON string → system); merge keeps SDK size/color/weight/height while adopting the resolver's family/fallback; null-safety per layer.
- Widget: `NativeDisplayView(fontResolver: …)` → rendered `TextStyle.fontFamily` matches the resolver's; per-widget overrides global; a fake `google_fonts`-shaped resolver (returns a `TextStyle(fontFamily:'X')`) is honoured.
- Manual: with a shared font (e.g. `GoogleFonts.inter()`) set on both platforms, the `SDK-6246` "aspect ratio 5:8" config wraps identically (3 lines) on Flutter-iOS and Flutter-Android.

---

## 6. Non-goals
- Taking an SDK dependency on `google_fonts` or bundling a font (fonts stay the client's choice — the resolver keeps the SDK decoupled).
- Fixing Flutter-vs-native-SDK sub-pixel shaping at zero-margin boxes (inherent cross-engine; a shared font makes it a non-issue in practice).
- Changing percent sizing / line-height / the hermetic baseline (shipped in `SDK-6246`) — the merge semantics explicitly protect these.
