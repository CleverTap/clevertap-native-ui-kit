import 'package:flutter/widgets.dart';

/// Describes the text the SDK is about to render, so a [NativeDisplayFontResolver]
/// can pick the right font / weight / optical variant.
class NativeDisplayFontContext {
  /// `fontFamily` from the ND JSON config for this node (may be null/empty).
  final String? jsonFontFamily;

  /// Resolved font size (logical px) the SDK will render at.
  final double fontSize;

  /// Resolved font weight.
  final FontWeight fontWeight;

  /// Resolved font style (normal / italic).
  final FontStyle fontStyle;

  const NativeDisplayFontContext({
    required this.jsonFontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.fontStyle,
  });
}

/// Client hook that returns a [TextStyle] whose FONT-identifying fields
/// (`fontFamily`, `fontFamilyFallback`, `fontFeatures`, `fontVariations`) the SDK
/// adopts for ND text. Size / colour / weight / line-height stay owned by the SDK
/// (derived from the JSON config), so a resolver can never break percent sizing or
/// the hermetic text guarantees.
///
/// Return `null` to fall through to the next resolution layer.
///
/// Because it returns a [TextStyle], it composes directly with `google_fonts`
/// (`GoogleFonts.inter()` *is* a [TextStyle]), package/asset fonts, fallbacks and
/// per-weight font files — the SDK takes no dependency on any font package.
///
/// ```dart
/// NativeDisplayFont.instance.resolver =
///     (ctx) => GoogleFonts.inter(fontWeight: ctx.fontWeight, fontStyle: ctx.fontStyle);
/// ```
typedef NativeDisplayFontResolver = TextStyle? Function(
    NativeDisplayFontContext ctx);

/// Process-wide default font configuration for ND text — the analog of Android's
/// `LocalFontFamily` / iOS's `\.nativeDisplayFontFamily`. Set it once (e.g. in the
/// add-on's `bindCleverTap`) so every rendered unit picks up the client's font
/// without wiring each render site. Per-[NativeDisplayView] params override this.
class NativeDisplayFont {
  NativeDisplayFont._();
  static final NativeDisplayFont instance = NativeDisplayFont._();

  /// A single default family for ALL ND text (e.g. a pubspec-declared font).
  String? defaultFamily;

  /// Full control: pick the font per JSON-name / size / weight. Wins over
  /// [defaultFamily]. Composes with `google_fonts` and any [TextStyle] source.
  NativeDisplayFontResolver? resolver;
}

/// Resolves the font-identifying [TextStyle] to apply on top of the SDK's computed
/// text style, honouring the native precedence:
///
/// 1. [scopeResolver] (per-view) → else [NativeDisplayFont.instance.resolver]  — HIGHEST
/// 2. [scopeFamily] (per-view default) → else [NativeDisplayFont.instance.defaultFamily]
/// 3. JSON `fontFamily` ([NativeDisplayFontContext.jsonFontFamily])  — current behaviour
/// 4. `null` → platform system font (the hermetic baseline)
///
/// Returns only font-identity fields so the caller merges it without disturbing
/// size / colour / weight / line-height.
TextStyle? resolveNativeDisplayFont({
  required NativeDisplayFontContext ctx,
  String? scopeFamily,
  NativeDisplayFontResolver? scopeResolver,
}) {
  // 1. Resolver (per-view, else global).
  final resolver = scopeResolver ?? NativeDisplayFont.instance.resolver;
  if (resolver != null) {
    final resolved = resolver(ctx);
    if (resolved != null) {
      return TextStyle(
        fontFamily: resolved.fontFamily,
        fontFamilyFallback: resolved.fontFamilyFallback,
        fontFeatures: resolved.fontFeatures,
        fontVariations: resolved.fontVariations,
      );
    }
  }

  // 2. Client default family (per-view, else global).
  final family = scopeFamily ?? NativeDisplayFont.instance.defaultFamily;
  if (family != null && family.isNotEmpty) {
    return TextStyle(fontFamily: family);
  }

  // 3. JSON fontFamily (unchanged behaviour).
  final json = ctx.jsonFontFamily;
  if (json != null && json.isNotEmpty) {
    return TextStyle(fontFamily: json);
  }

  // 4. System font.
  return null;
}
