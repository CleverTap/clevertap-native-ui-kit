import 'package:flutter/widgets.dart';

import '../models/native_display_unit.dart';
import '../renderer/native_display_view.dart';
import 'native_display_slot_manager.dart';

/// Builds the placeholder shown while no unit is available for the slot.
typedef NativeDisplaySlotLoadingBuilder = Widget Function(
  BuildContext context,
  String slotId,
);

/// Renders the Native Display unit routed to [slotId] by
/// [NativeDisplaySlotManager].
///
/// Registers as an observer for [slotId] on mount and renders the delivered
/// unit via [NativeDisplayView] (reusing the unit's pre-resolved styles). While
/// no unit is available it shows [loadingBuilder] (an empty box by default).
/// Unregisters automatically on dispose.
///
/// Attribution stays host-mediated: [onNotificationViewed] /
/// [onNotificationClicked] are forwarded straight to [NativeDisplayView], which
/// the host wires to `clevertap_plugin`.
///
/// Mirrors Android `NativeDisplaySlot` (Composable) and iOS `NativeDisplaySlot`
/// (SwiftUI).
///
/// **Usage:**
/// ```dart
/// NativeDisplaySlot(
///   slotId: 'hero_banner',
///   loadingBuilder: (context, slotId) => const SizedBox(height: 120),
///   onNotificationViewed: (id) => CleverTapPlugin.pushDisplayUnitViewedEvent(id),
///   onNotificationClicked: (id, elementId, extras) =>
///       CleverTapPlugin.pushDisplayUnitElementClickedEvent(id, extras),
/// )
/// ```
class NativeDisplaySlot extends StatefulWidget {
  /// The slot id to observe for display units.
  final String slotId;

  final NativeDisplayActionListener? actionListener;
  final NativeDisplayComponentListener? componentListener;

  /// Forwarded to [NativeDisplayView.onNotificationViewed].
  final NativeDisplayNotificationViewed? onNotificationViewed;

  /// Forwarded to [NativeDisplayView.onNotificationClicked].
  final NativeDisplayNotificationClicked? onNotificationClicked;

  /// Placeholder shown while no unit is available. Defaults to
  /// [SizedBox.shrink].
  final NativeDisplaySlotLoadingBuilder? loadingBuilder;

  /// Manager to register with. Defaults to [NativeDisplaySlotManager.instance];
  /// injectable for tests.
  final NativeDisplaySlotManager? manager;

  const NativeDisplaySlot({
    super.key,
    required this.slotId,
    this.actionListener,
    this.componentListener,
    this.onNotificationViewed,
    this.onNotificationClicked,
    this.loadingBuilder,
    this.manager,
  });

  @override
  State<NativeDisplaySlot> createState() => _NativeDisplaySlotState();
}

class _NativeDisplaySlotState extends State<NativeDisplaySlot>
    implements NativeDisplaySlotObserver {
  NativeDisplayUnit? _unit;

  // True while a synchronous registerSlot() is running, during which an
  // immediate cached-unit delivery must not call setState (we're inside
  // initState / didUpdateWidget, before the resulting build).
  bool _registering = false;

  NativeDisplaySlotManager get _manager =>
      widget.manager ?? NativeDisplaySlotManager.instance;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(NativeDisplaySlot old) {
    super.didUpdateWidget(old);
    final oldManager = old.manager ?? NativeDisplaySlotManager.instance;
    if (old.slotId != widget.slotId || !identical(oldManager, _manager)) {
      oldManager.unregisterSlot(old.slotId, this);
      _unit = null;
      _register();
    }
  }

  @override
  void dispose() {
    _manager.unregisterSlot(widget.slotId, this);
    super.dispose();
  }

  void _register() {
    _registering = true;
    _manager.registerSlot(widget.slotId, this);
    _registering = false;
  }

  @override
  void onUnitAvailable(NativeDisplayUnit unit) {
    if (_registering) {
      // Immediate cached delivery during (re)registration — the pending build
      // will pick this up; setState here would throw.
      _unit = unit;
      return;
    }
    if (!mounted) {
      _unit = unit;
      return;
    }
    setState(() => _unit = unit);
  }

  @override
  void onUnitCleared(String slotId) {
    if (_registering || !mounted) {
      _unit = null;
      return;
    }
    setState(() => _unit = null);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unit;
    if (unit == null) {
      return widget.loadingBuilder?.call(context, widget.slotId) ??
          const SizedBox.shrink();
    }
    return NativeDisplayView(
      config: unit.config,
      resolvedStyles: unit.resolvedStyles,
      unitId: unit.unitId,
      actionListener: widget.actionListener,
      componentListener: widget.componentListener,
      onNotificationViewed: widget.onNotificationViewed,
      onNotificationClicked: widget.onNotificationClicked,
    );
  }
}
