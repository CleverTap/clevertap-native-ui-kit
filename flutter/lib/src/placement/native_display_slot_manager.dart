import '../bridge/native_display_config_parser.dart';
import '../internal/nd_logger.dart';
import '../models/native_display_unit.dart';

/// Observer for slot-based Native Display unit delivery.
///
/// Implement this to be notified when a display unit becomes available or is
/// cleared for a specific slot. Mirrors Android `SlotObserver` and iOS
/// `NativeDisplaySlotObserver`.
abstract class NativeDisplaySlotObserver {
  /// Called when a Native Display [unit] is available for the observed slot.
  void onUnitAvailable(NativeDisplayUnit unit);

  /// Called when the unit for [slotId] has been cleared.
  void onUnitCleared(String slotId);
}

/// Callback invoked to report the active slot ids to the CleverTap server.
///
/// The Flutter plugin is pure-Dart and cannot call the Core SDK directly, so
/// slot-sync is host-mediated: the host wires this to
/// `CleverTapPlugin.recordEvent(eventName, eventData)`. Called with
/// [NativeDisplaySlotManager.wzrkNdSlotSync] and `{"slots": [...]}`.
typedef NativeDisplaySlotSync = void Function(
  String eventName,
  Map<String, Object?> eventData,
);

/// Manages Native Display slot registrations and routes display units to
/// observers based on each unit's [NativeDisplayUnit.slotId] (sourced from the
/// top-level `slot_id` key).
///
/// A "slot" is a named, server-driven placement zone. Units carry a `slot_id`;
/// a view registers as an observer for a slot id and the manager delivers the
/// latest matching unit to it. This is a placement concept — not a layout or
/// z-order concept.
///
/// **Slot lifecycle:**
/// 1. A view registers a slot via [registerSlot].
/// 2. If a unit already exists for that slot, it is delivered immediately.
/// 3. When new units arrive via [processDisplayUnits], matching observers are
///    notified.
/// 4. When a view is torn down, it calls [unregisterSlot].
///
/// **Divergence from native (intentional):** Android/iOS `SlotManager` receives
/// units automatically via the bridge and calls the Core SDK directly for
/// slot-sync. Flutter's bridge is pure-Dart (SDK-6019), so both ingestion and
/// slot-sync are host-mediated — the host forwards CleverTap display-unit JSON
/// into [processDisplayUnits] and wires [onSlotSync] out to `clevertap_plugin`.
///
/// **Threading:** Dart is single-threaded per isolate; all routing runs on the
/// root isolate event loop, so no locks are needed (unlike the Android/iOS
/// implementations which guard shared state).
///
/// **Usage:**
/// ```dart
/// final manager = NativeDisplaySlotManager.instance;
/// manager.registerSlot('hero_banner', myObserver);
/// // ... later
/// manager.unregisterSlot('hero_banner', myObserver);
/// ```
class NativeDisplaySlotManager {
  NativeDisplaySlotManager._();

  /// Process-wide singleton. Mirrors Android `getInstance()` /
  /// iOS `NativeDisplaySlotManager.shared`.
  static final NativeDisplaySlotManager instance = NativeDisplaySlotManager._();

  static const String _tag = 'NDSlotManager';

  /// Event name sent to the CleverTap server to sync active slot ids.
  static const String wzrkNdSlotSync = 'wzrk_nd_slot_sync';

  /// slot_id → observers currently registered for that slot.
  final Map<String, List<NativeDisplaySlotObserver>> _activeSlots = {};

  /// slot_id → latest unit seen for that slot (delivered to late registrants).
  final Map<String, NativeDisplayUnit> _unitIndex = {};

  /// Host-provided hook that forwards the `wzrk_nd_slot_sync` event to the
  /// Core SDK via `clevertap_plugin`. See [syncActiveSlots].
  NativeDisplaySlotSync? onSlotSync;

  // --- Registration ---

  /// Register [observer] for [slotId].
  ///
  /// If a unit is already cached for this slot, [NativeDisplaySlotObserver
  /// .onUnitAvailable] is invoked immediately (synchronously) on the caller.
  void registerSlot(String slotId, NativeDisplaySlotObserver observer) {
    final observers = _activeSlots.putIfAbsent(slotId, () => []);
    if (!observers.contains(observer)) {
      observers.add(observer);
    }
    NDLogger.d(_tag, 'Registered observer for slot: $slotId');

    final existing = _unitIndex[slotId];
    if (existing != null) {
      NDLogger.d(
        _tag,
        'Cached unit immediately delivered for slot: $slotId '
        '(unitId=${existing.unitId})',
      );
      _deliver(observer, existing);
    }
  }

  /// Unregister [observer] from [slotId]. Removes the slot entry once it has no
  /// remaining observers.
  void unregisterSlot(String slotId, NativeDisplaySlotObserver observer) {
    final observers = _activeSlots[slotId];
    if (observers == null) return;
    observers.remove(observer);
    if (observers.isEmpty) {
      _activeSlots.remove(slotId);
    }
    NDLogger.d(_tag, 'Unregistered observer for slot: $slotId');
  }

  // --- Query ---

  /// The set of slot ids that currently have at least one active observer.
  Set<String> getActiveSlotIds() => _activeSlots.keys.toSet();

  /// The latest cached unit for [slotId], or `null` if none has arrived.
  NativeDisplayUnit? getUnit(String slotId) => _unitIndex[slotId];

  // --- Ingestion ---

  /// Parse raw CleverTap display-unit JSON (as forwarded from `clevertap_plugin`)
  /// off the main isolate via [NativeDisplayConfigParser] and route each parsed
  /// unit to its slot. Units without a `slot_id` are ignored.
  Future<void> processDisplayUnits(List<dynamic> rawUnits) async {
    final units = await NativeDisplayConfigParser.parseAll(rawUnits);
    _onUnitsLoaded(units);
  }

  /// Single-unit convenience over [processDisplayUnits].
  Future<void> processDisplayUnit(dynamic rawUnit) async {
    final unit = await NativeDisplayConfigParser.tryParse(rawUnit);
    if (unit != null) {
      _onUnitsLoaded([unit]);
    }
  }

  /// Route already-parsed [units] to their slots. Exposed for hosts that parse
  /// via [NativeDisplayConfigParser] themselves.
  void deliverUnits(List<NativeDisplayUnit> units) => _onUnitsLoaded(units);

  void _onUnitsLoaded(List<NativeDisplayUnit> units) {
    NDLogger.d(_tag, 'onUnitsLoaded: ${units.length} unit(s) received');
    for (final unit in units) {
      final slotId = unit.slotId;
      if (slotId == null) continue;

      _unitIndex[slotId] = unit;
      NDLogger.d(_tag, 'Unit ${unit.unitId} mapped to slot: $slotId');

      final observers = _activeSlots[slotId];
      if (observers == null) continue;
      // Copy so an observer that unregisters during delivery can't mutate the
      // list we're iterating.
      for (final observer in List.of(observers)) {
        _deliver(observer, unit);
      }
    }
  }

  // --- Clearing ---

  /// Clear the cached unit for [slotId] and notify its observers.
  void clearSlot(String slotId) {
    _unitIndex.remove(slotId);
    final observers = _activeSlots[slotId];
    if (observers == null) return;
    for (final observer in List.of(observers)) {
      _notifyCleared(observer, slotId);
    }
  }

  /// Clear every cached unit and notify all observers.
  void clearAll() {
    final slotIds = {..._unitIndex.keys, ..._activeSlots.keys};
    _unitIndex.clear();
    for (final slotId in slotIds) {
      final observers = _activeSlots[slotId];
      if (observers == null) continue;
      for (final observer in List.of(observers)) {
        _notifyCleared(observer, slotId);
      }
    }
  }

  // --- Server sync ---

  /// Report the active slot ids to the server via [onSlotSync].
  ///
  /// Sends a [wzrkNdSlotSync] event with payload `{"slots": [...]}`. Returns
  /// `false` (and logs) when no [onSlotSync] callback has been wired.
  bool syncActiveSlots() {
    final callback = onSlotSync;
    if (callback == null) {
      NDLogger.w(
        _tag,
        'syncActiveSlots() skipped — no onSlotSync callback wired. '
        'Set NativeDisplaySlotManager.instance.onSlotSync to forward '
        '$wzrkNdSlotSync via clevertap_plugin.',
      );
      return false;
    }
    final slots = getActiveSlotIds().toList();
    try {
      callback(wzrkNdSlotSync, {'slots': slots});
      NDLogger.d(_tag, 'Synced ${slots.length} slot id(s) to server: $slots');
      return true;
    } catch (e) {
      NDLogger.w(_tag, 'syncActiveSlots() failed: $e');
      return false;
    }
  }

  void _deliver(NativeDisplaySlotObserver observer, NativeDisplayUnit unit) {
    try {
      observer.onUnitAvailable(unit);
    } catch (e) {
      NDLogger.w(_tag, 'Observer threw during onUnitAvailable: $e');
    }
  }

  void _notifyCleared(NativeDisplaySlotObserver observer, String slotId) {
    try {
      observer.onUnitCleared(slotId);
    } catch (e) {
      NDLogger.w(_tag, 'Observer threw during onUnitCleared: $e');
    }
  }

  /// Reset all state. Test-only — the singleton is otherwise process-global and
  /// would leak registrations and cached units between test cases.
  void resetForTest() {
    _activeSlots.clear();
    _unitIndex.clear();
    onSlotSync = null;
  }
}
