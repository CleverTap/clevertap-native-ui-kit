package com.clevertap.android.nativedisplay.bridge

import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for [ViewedUnitsTracker] — the process-singleton set that the renderer
 * consults to gate `Notification Viewed` across Activity configuration changes.
 *
 * The tracker is process-scoped, so each test brackets itself with [clear] to stay hermetic.
 */
class ViewedUnitsTrackerTest {

    @Before
    fun setUp() {
        ViewedUnitsTracker.clear()
    }

    @After
    fun tearDown() {
        ViewedUnitsTracker.clear()
    }

    @Test
    fun `markViewedIfNew returns true on first call, false on second for same id`() {
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-1"))
        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-1"))
        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-1"))
    }

    @Test
    fun `remove allows next markViewedIfNew to return true`() {
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-1"))
        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-1"))

        ViewedUnitsTracker.remove("unit-1")

        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-1"))
        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-1"))
    }

    @Test
    fun `independent ids tracked independently`() {
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-a"))
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-b"))
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-c"))

        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-a"))
        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-b"))
        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-c"))

        // Removing one does not affect the others
        ViewedUnitsTracker.remove("unit-b")

        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-a"))
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-b"))
        assertFalse(ViewedUnitsTracker.markViewedIfNew("unit-c"))
    }

    @Test
    fun `remove on absent id is a no-op`() {
        ViewedUnitsTracker.remove("never-added")
        // Should still treat it as new on first call afterwards.
        assertTrue(ViewedUnitsTracker.markViewedIfNew("never-added"))
    }

    @Test
    fun `clear resets all tracked ids`() {
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-1"))
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-2"))

        ViewedUnitsTracker.clear()

        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-1"))
        assertTrue(ViewedUnitsTracker.markViewedIfNew("unit-2"))
    }
}
