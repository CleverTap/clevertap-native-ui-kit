/// Process-singleton set that gates "Notification Viewed" attribution.
///
/// Mirrors Android's `ViewedUnitsTracker`. Without this gate, every rebuild of
/// a `NativeDisplayView` (e.g. ListView item recycling, parent setState,
/// hot-reload) would refire Notification Viewed.
///
/// Semantics:
///   - First mount of a unitId → tracker is empty for that id → fire and add.
///   - Subsequent rebuilds while widget stays mounted → already tracked → skip.
///   - Widget unmounts → caller removes the id, so the next mount (genuine
///     reappear after scroll-out, navigation, fresh launch) fires again.
///
/// Per-impression semantics are emergent: the tracker only sees `add`/`remove`
/// calls from the widget's lifecycle. There is no time- or rotation-based
/// dedupe because Flutter does not destroy the widget tree on rotation by
/// default — the same `NativeDisplayView` instance survives, and no spurious
/// re-fire happens.
class ViewedUnitsTracker {
  ViewedUnitsTracker._();

  // Reference count per unitId. The same unitId can legitimately render in two
  // places at once (e.g. a list and a detail view); counting ensures the first
  // mount fires once and the last unmount clears the gate — a plain Set would
  // mis-fire when a second instance mounts after the first unmounts.
  static final Map<String, int> _counts = <String, int>{};

  /// Increments the reference count for [unitId]. Returns `true` only on the
  /// 0→1 transition (first live instance — caller should fire the attribution
  /// event); `false` while any instance is already tracked.
  static bool addIfNew(String unitId) {
    final next = (_counts[unitId] ?? 0) + 1;
    _counts[unitId] = next;
    return next == 1;
  }

  /// Decrements the reference count for [unitId], deleting the entry when it
  /// reaches zero so a future mount counts as a fresh impression.
  static void remove(String unitId) {
    final current = _counts[unitId];
    if (current == null) return;
    if (current <= 1) {
      _counts.remove(unitId);
    } else {
      _counts[unitId] = current - 1;
    }
  }

  /// Visible for testing — clears all tracked ids.
  static void resetForTesting() => _counts.clear();
}
