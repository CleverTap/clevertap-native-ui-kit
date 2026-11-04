import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';

/// One-call CleverTap integration for the Native Display slot system.
///
/// The core `clevertap_native_display` package is pure Dart and has no
/// dependency on `clevertap_plugin`, so on its own the host must hand-wire four
/// things: the display-units handler, the cached-units pull, slot-sync, and
/// attribution for every rendered unit. This extension does all of it in one
/// call, mirroring what `CleverTapAutoWire` does inside the Android/iOS SDKs.
///
/// Usage:
/// ```dart
/// // 1. get the instance
/// final manager = NativeDisplaySlotManager.instance;
/// // 2. drop NativeDisplaySlot(slotId: ...) widgets anywhere in the tree
/// // 3. wire CleverTap once at startup (after CleverTapPlugin is initialised)
/// await manager.bindCleverTap();
/// ```
///
/// After [bindCleverTap], slots render server-driven units automatically and
/// attribution (viewed / clicked / element-clicked) is reported to the Core SDK
/// — no per-widget callbacks required. Per-widget
/// `onNotificationViewed` / `onNotificationClicked` still take precedence when a
/// specific widget needs custom handling.
extension CleverTapNativeDisplayBinding on NativeDisplaySlotManager {
  /// Wire this slot manager to CleverTap via `clevertap_plugin`:
  ///
  /// 1. registers the display-units handler (push) → [processDisplayUnits]
  /// 2. pulls already-cached units → [processDisplayUnits]
  /// 3. wires [onSlotSync] out → `CleverTapPlugin.recordEvent`
  /// 4. installs the global attribution sink → `pushDisplayUnit*Event`
  ///
  /// Idempotent-safe to call once at startup. Pass [plugin] only to inject a
  /// specific [CleverTapPlugin] instance (defaults to the singleton).
  ///
  /// [onUnits] is an optional observer called with every raw display-unit batch
  /// (push and the initial cached pull) — useful for hosts that also render or
  /// inspect units outside the slot system (a debug canvas, logging, etc.). Slot
  /// routing happens regardless; this is purely additive.
  Future<void> bindCleverTap({
    CleverTapPlugin? plugin,
    void Function(List<dynamic> rawUnits)? onUnits,
  }) async {
    final ct = plugin ?? CleverTapPlugin();

    // 1. Push: new display units arrive via the Core SDK delegate → slots.
    ct.setCleverTapDisplayUnitsLoadedHandler((units) {
      final list = units ?? const <dynamic>[];
      if (list.isNotEmpty) {
        processDisplayUnits(list);
        onUnits?.call(list);
      }
    });

    // 2. Slot-sync out: report active slot ids to the server.
    onSlotSync = (eventName, eventData) {
      CleverTapPlugin.recordEvent(
        eventName,
        Map<String, dynamic>.from(eventData),
      );
    };

    // 3. Attribution: global fallback, so every rendered unit reports without the
    //    host wiring each NativeDisplaySlot / NativeDisplayView. Per-widget
    //    callbacks still win.
    NativeDisplayAttribution.instance.onViewed =
        (unitId) => CleverTapPlugin.pushDisplayUnitViewedEvent(unitId);
    NativeDisplayAttribution.instance.onClicked = (unitId, elementId, extras) {
      if (elementId.isNotEmpty) {
        CleverTapPlugin.pushDisplayUnitElementClickedEvent(
          unitId,
          Map<String, dynamic>.from(extras),
        );
      } else {
        CleverTapPlugin.pushDisplayUnitClickedEvent(unitId);
      }
    };

    // 4. Pull: deliver units already cached before bind (e.g. from a prior
    //    session's response) so slots mounted at startup fill immediately.
    final cached = await CleverTapPlugin.getAllDisplayUnits();
    if (cached != null && cached.isNotEmpty) {
      await processDisplayUnits(cached);
      onUnits?.call(cached);
    }
  }

  /// Tear down the CleverTap wiring installed by [bindCleverTap].
  ///
  /// Clears [onSlotSync] and the global attribution sink. Note:
  /// `clevertap_plugin` exposes no API to remove the display-units handler, so it
  /// stays registered but harmlessly forwards to [processDisplayUnits].
  void unbindCleverTap() {
    onSlotSync = null;
    NativeDisplayAttribution.instance.clear();
  }
}
