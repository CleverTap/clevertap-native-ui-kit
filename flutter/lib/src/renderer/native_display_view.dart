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

  const NativeDisplayView({
    super.key,
    required this.config,
    this.resolvedStyles,
    this.unitId,
    this.onNotificationViewed,
    this.onNotificationClicked,
    this.actionListener,
    this.componentListener,
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

    final screenHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layouterWidth =
            constraints.maxWidth.isInfinite ? screenHeight : constraints.maxWidth;

        final effectiveRootWidth = _effectiveWidth(layout, layouterWidth);
        final rootHeight =
            _computeRootHeight(layout, effectiveRootWidth, constraints, screenHeight);

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

        child = _applyRootSizing(child, layout, effectiveRootWidth, rootHeight, screenHeight);

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

  Widget _applyRootSizing(
    Widget child,
    Layout? layout,
    double effectiveRootWidth,
    double rootHeight,
    double screenHeight,
  ) {
    if (layout == null) return child;

    final rw = layout.width;
    final rh = layout.height;
    final ar = layout.aspectRatio;
    final hasAR = ar != null && ar > 0;

    // AR takes precedence over all percent dimensions — it uses full available width
    // and derives height. The AspectRatio widget in _wrapWithSizing handles the
    // visual constraint; no additional sizing wrapper is needed here.
    if (hasAR) return child;

    final hasPercentWidth =
        rw != null && rw.special == null && rw.unit == DimensionUnit.percent && rw.value > 0;

    if (hasPercentWidth) {
      double? explicitHeight;
      if (rh != null && rh.special == null && rh.unit == DimensionUnit.percent && rh.value > 0) {
        explicitHeight = screenHeight * rh.value / 100.0;
      }
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: effectiveRootWidth, height: explicitHeight, child: child),
      );
    }

    if (rh != null && rh.special == null && rh.unit == DimensionUnit.percent && rh.value > 0) {
      return SizedBox(height: screenHeight * rh.value / 100.0, child: child);
    }

    return child;
  }

  double _effectiveWidth(Layout? layout, double availableWidth) {
    // AR present → use full available width; percent is irrelevant.
    final ar = layout?.aspectRatio;
    if (ar != null && ar > 0) return availableWidth;

    final w = layout?.width;
    if (w != null && w.special == null && w.unit == DimensionUnit.percent && w.value > 0) {
      return availableWidth * w.value / 100.0;
    }
    return availableWidth;
  }

  double _computeRootHeight(
    Layout? layout,
    double effectiveRootWidth,
    BoxConstraints constraints,
    double screenHeight,
  ) {
    if (layout == null) return screenHeight;

    final ar = layout.aspectRatio;
    if (ar != null && ar > 0) return effectiveRootWidth / ar;

    final h = layout.height;
    if (h != null && h.special == null && h.value > 0) {
      if (h.unit == DimensionUnit.percent) return screenHeight * h.value / 100.0;
      return h.value;
    }

    if (!constraints.maxHeight.isInfinite) return constraints.maxHeight;

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
