import 'package:flutter/widgets.dart';

import '../models/style.dart';
import 'native_display_font.dart';

/// Signature for the "Notification Clicked" attribution callback.
///
/// Fired when an interactive element (BUTTON, or IMAGE with an onClick action)
/// is tapped inside a [NativeDisplayView] that was given a `unitId`.
///
/// - [unitId] is the CleverTap display unit id (`wzrk_id`).
/// - [elementId] is the tapped node's id.
/// - [extras] is the flattened, sanitized attribution payload
///   ([ActionAttributionExtras]) — the host feeds it straight into
///   `clevertap_plugin.pushDisplayUnitElementClickedEvent(unitId, extras)`.
typedef NativeDisplayNotificationClicked = void Function(
  String unitId,
  String elementId,
  Map<String, Object?> extras,
);

/// Signature for the host open-url interceptor. Mirrors the native SDKs'
/// `onOpenUrl(url, openInBrowser) -> Bool`: called before the SDK opens an
/// `open_url` action. Return `true` to signal the host handled the URL itself
/// (e.g. in-app routing for a deeplink) — the SDK then does **not** open it.
/// Return `false` (or provide no callback) to let the SDK open it.
typedef NativeDisplayOpenUrlCallback = bool Function(
  String url,
  bool openInBrowser,
);

/// Single inherited scope carrying the per-[NativeDisplayView] render context to
/// every descendant, so renderers don't have to thread these through every
/// widget parameter:
///
/// - [rootHeight] — the root container height in logical pixels, used to resolve
///   percent-of-root text sizes, border widths/radii and HTML height.
/// - [styles] — the pre-resolved style map (node id → [Style]).
/// - [unitId] — the active `wzrk_id`; `null` for previews / test fixtures.
/// - [onClicked] — the click-attribution callback; `null` when none was given.
///
/// These four values are established once when a config is rendered and never
/// change independently during that render, so one scope is sufficient — it
/// replaces the former RootHeight/ResolvedStyles/UnitId/NotificationClick
/// scopes. Being per-[NativeDisplayView], it is unaffected by where the client
/// places the view (inside a Row/Column/List or full screen).
class NativeDisplayScope extends InheritedWidget {
  final double rootHeight;
  final Map<String, Style> styles;
  final String? unitId;
  final NativeDisplayNotificationClicked? onClicked;
  final NativeDisplayOpenUrlCallback? onOpenUrl;

  /// Per-view client default font family (overrides [NativeDisplayFont.defaultFamily]).
  final String? fontFamily;

  /// Per-view client font resolver (overrides [NativeDisplayFont.resolver]).
  final NativeDisplayFontResolver? fontResolver;

  const NativeDisplayScope({
    super.key,
    required this.rootHeight,
    required this.styles,
    required this.unitId,
    required this.onClicked,
    this.onOpenUrl,
    this.fontFamily,
    this.fontResolver,
    required super.child,
  });

  static NativeDisplayScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NativeDisplayScope>();

  /// Root container height in logical pixels (0 when no scope is present).
  static double rootHeightOf(BuildContext context) => of(context)?.rootHeight ?? 0;

  /// Pre-resolved styles (empty when no scope is present).
  static Map<String, Style> stylesOf(BuildContext context) =>
      of(context)?.styles ?? const {};

  /// Active display unit id, or `null`.
  static String? unitIdOf(BuildContext context) => of(context)?.unitId;

  /// Click-attribution callback, or `null`.
  static NativeDisplayNotificationClicked? onClickedOf(BuildContext context) =>
      of(context)?.onClicked;

  /// Host open-url interceptor, or `null`.
  static NativeDisplayOpenUrlCallback? onOpenUrlOf(BuildContext context) =>
      of(context)?.onOpenUrl;

  /// Per-view client default font family, or `null`.
  static String? fontFamilyOf(BuildContext context) => of(context)?.fontFamily;

  /// Per-view client font resolver, or `null`.
  static NativeDisplayFontResolver? fontResolverOf(BuildContext context) =>
      of(context)?.fontResolver;

  @override
  bool updateShouldNotify(NativeDisplayScope old) =>
      rootHeight != old.rootHeight ||
      !identical(styles, old.styles) ||
      unitId != old.unitId ||
      onClicked != old.onClicked ||
      onOpenUrl != old.onOpenUrl ||
      fontFamily != old.fontFamily ||
      fontResolver != old.fontResolver;
}
