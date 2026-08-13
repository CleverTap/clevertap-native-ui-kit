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

  static final Set<String> _viewed = <String>{};

  /// Adds [unitId] to the tracker. Returns `true` if this is the first time
  /// the id is being added (caller should fire the attribution event) and
  /// `false` if it was already present.
  static bool addIfNew(String unitId) => _viewed.add(unitId);

  /// Removes [unitId] from the tracker so a future mount counts as a fresh
  /// impression.
  static void remove(String unitId) => _viewed.remove(unitId);

  /// Visible for testing — clears all tracked ids.
  static void resetForTesting() => _viewed.clear();
}
