package com.clevertap.android.nativedisplay.bridge

/**
 * Tracks which display unit IDs currently have a live impression on screen, so
 * `Notification Viewed` fires exactly once per impression across Activity
 * configuration changes (rotation, locale, uimode flip).
 *
 * Lifecycle:
 *  - The renderer calls [markViewedIfNew] when the root composable enters
 *    composition. If the call returns true, the caller fires the event.
 *  - The renderer calls [remove] from its DisposableEffect onDispose ONLY when
 *    the host Activity reports `isChangingConfigurations == false` — i.e. the
 *    composable left composition for a real reason (scroll, navigation, finish)
 *    rather than because the Activity is mid-recreation.
 *
 * The set is process-scoped (cleared on process death). It is intentionally NOT
 * cleared on Activity destruction — that's the whole point: a unit being viewed
 * when rotation begins should remain in the set so the post-rotation Activity
 * sees the dedupe.
 */
internal object ViewedUnitsTracker {
    private val viewed = mutableSetOf<String>()

    @Synchronized
    fun markViewedIfNew(unitId: String): Boolean = viewed.add(unitId)

    @Synchronized
    fun remove(unitId: String) { viewed.remove(unitId) }

    /** Test-only: clear all entries. */
    @Synchronized
    internal fun clear() { viewed.clear() }
}
