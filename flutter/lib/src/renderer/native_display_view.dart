import 'package:flutter/widgets.dart';
import '../evaluator/variable_evaluator.dart';
import '../internal/viewed_units_tracker.dart';
import '../models/enums.dart';
import '../models/layout.dart';
import '../models/native_display_config.dart';
import '../models/style.dart';
import '../style/style_resolver.dart';
import 'native_display_renderer.dart';
import 'native_display_scope.dart';

export 'native_display_scope.dart' show NativeDisplayNotificationClicked;

typedef NativeDisplayActionListener = void Function(
    String action, String nodeId, Map<String, dynamic>? params);
typedef NativeDisplayComponentListener = bool Function(
    String event, String nodeId, Map<String, dynamic>? params);

/// Signature for the "Notification Viewed" attribution callback — fired once
/// per impression with the display unit id (`wzrk_id`). The host forwards it to
/// `clevertap_plugin.pushDisplayUnitViewedEvent(unitId)`.
typedef NativeDisplayNotificationViewed = void Function(String unitId);

class NativeDisplayView extends StatefulWidget {
  final NativeDisplayConfig config;

  /// Pre-resolved styles from [NativeDisplayConfigParser]. When provided,
  /// the view skips [StyleResolver] entirely — avoiding redundant computation.
  final Map<String, Style>? resolvedStyles;

  /// CleverTap display unit ID (`wzrk_id`). When provided, the view surfaces
  /// "Notification Viewed" once per impression via [onNotificationViewed] and
  /// "Notification Clicked" via [onNotificationClicked] when an interactive
  /// element with an onClick action is tapped. Leave `null` for previews / test
  /// fixtures.
  final String? unitId;

  /// Fired exactly once per impression (gated by [ViewedUnitsTracker]) with
  /// [unitId]. Only fires when [unitId] is non-null/non-empty. The host forwards
  /// it to `clevertap_plugin.pushDisplayUnitViewedEvent(unitId)`.
  final NativeDisplayNotificationViewed? onNotificationViewed;

  /// Fired when an interactive element (BUTTON, or IMAGE with an onClick action)
  /// is tapped and [unitId] is non-null/non-empty. Delivers the flattened,
  /// sanitized [ActionAttributionExtras] payload; the host forwards it to
  /// `clevertap_plugin.pushDisplayUnitElementClickedEvent(unitId, extras)`.
  final NativeDisplayNotificationClicked? onNotificationClicked;

  final NativeDisplayActionListener? actionListener;
  final NativeDisplayComponentListener? componentListener;

  /// The size of the placement region this view lives in — the host's available
  /// width/height. This is the exact analog of the iOS SDK's
  /// `\.nativeDisplayParentSize` environment value: it supplies the `parentWidth`
  /// / `parentHeight` that root sizing resolves against (percent dimensions, and
  /// the `rootHeight` anchor for percent fonts / borders / radii), matching the
  /// native `resolveRootHeight` cascade.
  ///
  /// When `null`, the parent dimensions come from the incoming layout constraints
  /// (an unbounded dimension counts as "no bound", exactly like Android's
  /// `BoxWithConstraints` treating `Dp.Infinity` as `0f`), and the screen height
  /// is used only as the final fallback. Pass this when the view sits in a
  /// scrollable that hands it unbounded height AND you want it anchored to the
  /// viewport (as the iOS sample does); omit it to mirror the Android sample,
  /// which does not inject a parent size.
  final Size? parentSize;

  const NativeDisplayView({
    super.key,
    required this.config,
    this.resolvedStyles,
    this.unitId,
    this.onNotificationViewed,
    this.onNotificationClicked,
    this.actionListener,
    this.componentListener,
    this.parentSize,
  });

  @override
  State<NativeDisplayView> createState() => _NativeDisplayViewState();
}

class _NativeDisplayViewState extends State<NativeDisplayView> {
  late Map<String, Style> _resolvedStyles;

  @override
  void initState() {
    super.initState();
    _resolvedStyles = _resolve();
  }

  @override
  void didUpdateWidget(NativeDisplayView old) {
    super.didUpdateWidget(old);
    if (!identical(old.config, widget.config) ||
        !identical(old.resolvedStyles, widget.resolvedStyles)) {
      _resolvedStyles = _resolve();
    }
  }

  Map<String, Style> _resolve() =>
      widget.resolvedStyles ??
      StyleResolver().resolveAll(
        widget.config.root,
        widget.config.theme ?? NDTheme.empty,
        widget.config.styleClasses,
      );

  @override
  Widget build(BuildContext context) {
    final root = widget.config.root;
    if (root == null) return const SizedBox.shrink();

    final evaluator = VariableEvaluator(widget.config.variables);
    final layout = root.layout;

    // Optimization: when root has only fixed (dp) dimensions and no aspectRatio,
    // skip LayoutBuilder — constraints are already known from the JSON values.
    if (_hasOnlyFixedDimensions(layout)) {
      final fixedWidth = layout!.width!.value;
      final fixedHeight = layout.height!.value;
      return SizedBox(
        width: fixedWidth,
        height: fixedHeight,
        child: NativeDisplayScope(
          rootHeight: fixedHeight,
          styles: _resolvedStyles,
          unitId: widget.unitId,
          onClicked: widget.onNotificationClicked,
          child: _TrackNotificationViewed(
            unitId: widget.unitId,
            onViewed: widget.onNotificationViewed,
            child: NativeDisplayRenderer(
              node: root,
              evaluator: evaluator,
              actionListener: widget.actionListener,
              componentListener: widget.componentListener,
            ),
          ),
        ),
      );
    }

    // Final fallback only — the real device screen height. Matches native's last
    // resort (`displayMetrics.heightPixels` / `UIScreen.main.bounds.height`).
    final screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mirror native's parent derivation. Android reads BoxWithConstraints and
        // treats an unbounded dimension as 0f ("no parent bound"); iOS takes an
        // injected parentSize. So: prefer the host-provided [parentSize] (the iOS
        // environment analog), else the incoming constraints, else 0 when
        // unbounded — never the screen here (screen is only the final fallback
        // inside _computeRootHeight).
        final parentWidth = widget.parentSize?.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0);
        final parentHeight = widget.parentSize?.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0);

        final rootWidth = _resolveRootWidth(layout, parentWidth);
        final rootHeight = _computeRootHeight(layout, parentWidth, parentHeight, screenHeight);

        Widget child = NativeDisplayScope(
          rootHeight: rootHeight,
          styles: _resolvedStyles,
          unitId: widget.unitId,
          onClicked: widget.onNotificationClicked,
          child: _TrackNotificationViewed(
            unitId: widget.unitId,
            onViewed: widget.onNotificationViewed,
            child: NativeDisplayRenderer(
              node: root,
              evaluator: evaluator,
              actionListener: widget.actionListener,
              componentListener: widget.componentListener,
            ),
          ),
        );

        child = _applyRootSizing(child, layout, rootWidth, rootHeight, parentHeight);

        return child;
      },
    );
  }

  bool _hasOnlyFixedDimensions(Layout? layout) {
    if (layout == null) return false;
    final ar = layout.aspectRatio;
    if (ar != null && ar > 0) return false;
    final w = layout.width;
    final h = layout.height;
    if (w == null || h == null) return false;
    if (w.special != null || h.special != null) return false;
    if (w.unit == DimensionUnit.percent || h.unit == DimensionUnit.percent) return false;
    return w.value > 0 && h.value > 0;
  }

  /// Visual box sizing for the root. Faithful to native: AR is handled by the
  /// AspectRatio widget (in NativeDisplayRenderer._wrapWithSizing), percent width
  /// constrains the box to [rootWidth], and percent height uses the resolved
  /// [rootHeight]. A root with no explicit dimensions wraps its content.
  Widget _applyRootSizing(
    Widget child,
    Layout? layout,
    double rootWidth,
    double rootHeight,
    double parentHeight,
  ) {
    if (layout == null) return child;

    final rw = layout.width;
    final rh = layout.height;
    final ar = layout.aspectRatio;
    final hasAR = ar != null && ar > 0;

    // AR takes precedence; the AspectRatio widget applies the visual constraint.
    if (hasAR) return child;

    final hasPercentWidth =
        rw != null && rw.special == null && rw.unit == DimensionUnit.percent && rw.value > 0;
    // Percent height only yields a concrete box when the parent is bounded
    // (parentHeight > 0) — mirrors native, which skips percent-height when the
    // parent height is unknown.
    final hasPercentHeight = rh != null &&
        rh.special == null &&
        rh.unit == DimensionUnit.percent &&
        rh.value > 0 &&
        parentHeight > 0;

    if (hasPercentWidth) {
      final explicitHeight = hasPercentHeight ? parentHeight * rh.value / 100.0 : null;
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: rootWidth, height: explicitHeight, child: child),
      );
    }

    if (hasPercentHeight) {
      return SizedBox(height: parentHeight * rh.value / 100.0, child: child);
    }

    return child;
  }

  /// Faithful port of native `resolveRootWidthPx`: null/special width → parent
  /// width; dp/sp/px → value; percent → parentWidth × value/100 (0 if the parent
  /// width is unknown).
  double _resolveRootWidth(Layout? layout, double parentWidth) {
    final w = layout?.width;
    if (w == null || w.special != null) return parentWidth;
    return switch (w.unit) {
      DimensionUnit.percent => parentWidth > 0 ? parentWidth * w.value / 100.0 : 0.0,
      _ => w.value, // dp/sp/px as logical pixels
    };
  }

  /// Faithful port of native `resolveRootHeightPx` (NativeDisplayRenderer.kt:411
  /// / NativeDisplayRenderer.swift:207). The cascade — and therefore the anchor
  /// every percent font / border / radius resolves against — matches native
  /// exactly so cross-platform sizing agrees:
  ///   1. fixed height (dp/sp/px) → value
  ///   2. aspectRatio → rootWidth / aspectRatio
  ///   3. percent height, bounded parent → parentHeight × value/100
  ///   4. bounded parent → parentHeight
  ///   5. fallback → screen height
  double _computeRootHeight(
    Layout? layout,
    double parentWidth,
    double parentHeight,
    double screenHeight,
  ) {
    final h = layout?.height;

    // 1. Fixed height.
    if (h != null && h.special == null && h.unit != DimensionUnit.percent && h.value > 0) {
      return h.value;
    }

    // 2. Aspect ratio + known width.
    final ar = layout?.aspectRatio;
    if (ar != null && ar > 0) {
      final rootWidth = _resolveRootWidth(layout, parentWidth);
      if (rootWidth > 0) return rootWidth / ar;
    }

    // 3. Percent height against a bounded parent.
    if (h != null && h.special == null && h.unit == DimensionUnit.percent && parentHeight > 0) {
      return parentHeight * h.value / 100.0;
    }

    // 4. Bounded parent height.
    if (parentHeight > 0) return parentHeight;

    // 5. Final fallback: screen height.
    return screenHeight;
  }
}

/// Surfaces "Notification Viewed" exactly once per impression via the
/// [ViewedUnitsTracker] gate, calling [onViewed]. A no-op when [unitId] is null
/// or [onViewed] is null.
///
/// Mirrors Android `TrackNotificationViewed` (Compose) — the gate suppresses
/// repeat-fires from rebuilds while allowing genuine scroll-out → scroll-in
/// to re-fire once the widget unmounts.
class _TrackNotificationViewed extends StatefulWidget {
  final String? unitId;
  final NativeDisplayNotificationViewed? onViewed;
  final Widget child;

  const _TrackNotificationViewed({
    required this.unitId,
    required this.onViewed,
    required this.child,
  });

  @override
  State<_TrackNotificationViewed> createState() => _TrackNotificationViewedState();
}

class _TrackNotificationViewedState extends State<_TrackNotificationViewed> {
  @override
  void initState() {
    super.initState();
    _fireIfFirstImpression();
  }

  @override
  void didUpdateWidget(_TrackNotificationViewed old) {
    super.didUpdateWidget(old);
    if (old.unitId != widget.unitId) {
      if (old.unitId != null) ViewedUnitsTracker.remove(old.unitId!);
      _fireIfFirstImpression();
    }
  }

  void _fireIfFirstImpression() {
    final id = widget.unitId;
    if (id == null || id.isEmpty) return;
    if (ViewedUnitsTracker.addIfNew(id)) {
      // Defer past the first frame so the impression coincides with the
      // canvas actually being on-screen (matches LaunchedEffect cadence
      // on Android).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onViewed?.call(id);
      });
    }
  }

  @override
  void dispose() {
    final id = widget.unitId;
    if (id != null && id.isNotEmpty) {
      ViewedUnitsTracker.remove(id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
