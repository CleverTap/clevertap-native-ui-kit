package com.clevertap.android.nativedisplay.placement

import android.util.Log
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridgeListener
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.sdk.CleverTapAPI
import java.lang.ref.WeakReference

/**
 * Observer interface for slot-based Native Display unit delivery.
 *
 * Implement this to receive notifications when a display unit is available
 * or cleared for a specific slot.
 */
interface SlotObserver {

    /**
     * Called when a Native Display unit is available for the observed slot.
     *
     * @param unit The display unit ready for rendering
     */
    fun onUnitAvailable(unit: NativeDisplayUnit)

    /**
     * Called when the display unit for the observed slot has been cleared.
     *
     * @param slotId The slot identifier that was cleared
     */
    fun onUnitCleared(slotId: String)
}

/**
 * Manages Native Display slot registrations and routes display units to observers.
 *
 * This singleton listens for display units via [NativeDisplayBridgeListener] and
 * routes them to registered [SlotObserver] instances based on the `slot_id` key
 * in each unit's [NativeDisplayUnit.customExtras].
 *
 * **Slot lifecycle:**
 * 1. A view registers a slot via [registerSlot]
 * 2. If a unit already exists for that slot, it is delivered immediately
 * 3. When new units arrive from the bridge, matching observers are notified
 * 4. When a view is torn down, it calls [unregisterSlot]
 *
 * **Thread safety:** All mutable state is guarded by `synchronized` blocks.
 * Observers are stored as [WeakReference] to prevent memory leaks.
 *
 * **Usage:**
 * ```kotlin
 * val manager = NativeDisplaySlotManager.getInstance()
 * manager.registerSlot("hero_banner", myObserver)
 * // ... later
 * manager.unregisterSlot("hero_banner", myObserver)
 * ```
 */
class NativeDisplaySlotManager private constructor() : NativeDisplayBridgeListener {

    companion object {
        private const val TAG = "NDSlotManager"

        /** Key used to extract the slot identifier from [NativeDisplayUnit.customExtras]. */
        const val SLOT_ID_KEY = "slot_id"

        /** Event name sent to CleverTap server to sync active slot IDs. */
        internal const val WZRK_ND_SLOT_SYNC = "wzrk_nd_slot_sync"

        @Volatile
        private var instance: NativeDisplaySlotManager? = null

        /**
         * Get or create the singleton [NativeDisplaySlotManager].
         *
         * On first creation, automatically registers as a listener on
         * [NativeDisplayBridge] to receive incoming display units.
         *
         * @return The singleton instance
         */
        fun getInstance(): NativeDisplaySlotManager {
            return instance ?: synchronized(this) {
                instance ?: NativeDisplaySlotManager().also { mgr ->
                    instance = mgr
                    NativeDisplayBridge.getInstance()?.addListener(mgr)
                }
            }
        }
    }

    // slot_id → list of weak observers
    private val activeSlots = mutableMapOf<String, MutableList<WeakReference<SlotObserver>>>()
    private val slotsLock = Any()

    // slot_id → latest unit for that slot
    private val unitIndex = mutableMapOf<String, NativeDisplayUnit>()
    private val unitIndexLock = Any()

    // --- Registration ---

    /**
     * Register an observer for a given slot.
     *
     * If a display unit is already cached for this slot, [SlotObserver.onUnitAvailable]
     * is called immediately on the current thread.
     *
     * @param slotId The slot identifier to observe
     * @param observer The observer to notify
     */
    fun registerSlot(slotId: String, observer: SlotObserver) {
        synchronized(slotsLock) {
            val observers = activeSlots.getOrPut(slotId) { mutableListOf() }
            // Avoid duplicate registration
            val alreadyRegistered = observers.any { it.get() === observer }
            if (!alreadyRegistered) {
                observers.add(WeakReference(observer))
            }
        }

        Log.d(TAG, "Registered observer for slot: $slotId")

        // Deliver existing unit immediately if available
        val existingUnit: NativeDisplayUnit?
        synchronized(unitIndexLock) {
            existingUnit = unitIndex[slotId]
        }
        if (existingUnit != null) {
            try {
                observer.onUnitAvailable(existingUnit)
            } catch (e: Exception) {
                Log.w(TAG, "Observer threw exception during immediate delivery: ${e.message}")
            }
        }
    }

    /**
     * Unregister an observer from a given slot.
     *
     * Also cleans up dead weak references for the slot. If no observers remain,
     * the slot entry is removed from the registry.
     *
     * @param slotId The slot identifier
     * @param observer The observer to remove
     */
    fun unregisterSlot(slotId: String, observer: SlotObserver) {
        synchronized(slotsLock) {
            val observers = activeSlots[slotId] ?: return
            observers.removeAll { it.get() === observer || it.get() == null }
            if (observers.isEmpty()) {
                activeSlots.remove(slotId)
            }
        }
        Log.d(TAG, "Unregistered observer for slot: $slotId")
    }

    // --- Query ---

    /**
     * Returns the set of slot IDs that currently have at least one active observer.
     *
     * Dead weak references are pruned during this call.
     *
     * @return Set of active slot IDs
     */
    fun getActiveSlotIds(): Set<String> {
        synchronized(slotsLock) {
            // Prune dead references while collecting
            val deadSlots = mutableListOf<String>()
            for ((slotId, observers) in activeSlots) {
                observers.removeAll { it.get() == null }
                if (observers.isEmpty()) {
                    deadSlots.add(slotId)
                }
            }
            deadSlots.forEach { activeSlots.remove(it) }
            return activeSlots.keys.toSet()
        }
    }

    /**
     * Send the current set of active slot IDs to the CleverTap server.
     *
     * Pushes a `wzrk_nd_slot_sync` event containing the list of registered slots.
     * Uses try/catch for reflection safety in case the CleverTap Core SDK is absent.
     *
     * @param cleverTapApi The CleverTap API instance to send the event through
     * @return true if the event was sent successfully
     */
    fun syncCurrentSlotIds(cleverTapApi: CleverTapAPI): Boolean {
        return try {
            val slotIds = getActiveSlotIds().toList()
            val eventData = mapOf("slots" to slotIds)
            cleverTapApi.pushEvent(WZRK_ND_SLOT_SYNC, eventData)
            Log.d(TAG, "Synced ${slotIds.size} slot IDs to server: $slotIds")
            true
        } catch (e: NoClassDefFoundError) {
            Log.w(TAG, "CleverTap Core SDK not available for slot sync")
            false
        } catch (e: Exception) {
            Log.w(TAG, "syncCurrentSlotIds() failed: ${e.message}")
            false
        }
    }

    // --- NativeDisplayBridgeListener ---

    override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
        // Index units by slot_id and notify matching observers
        for (unit in units) {
            val slotId = unit.customExtras[SLOT_ID_KEY] ?: continue

            synchronized(unitIndexLock) {
                unitIndex[slotId] = unit
            }

            Log.d(TAG, "Unit ${unit.unitId} mapped to slot: $slotId")
            notifyObservers(slotId, unit)
        }
    }

    // --- Internal ---

    /**
     * Notify all active observers for a given slot. Cleans up dead weak references.
     */
    private fun notifyObservers(slotId: String, unit: NativeDisplayUnit) {
        val activeObservers: List<SlotObserver>
        synchronized(slotsLock) {
            val observers = activeSlots[slotId] ?: return
            val dead = mutableListOf<WeakReference<SlotObserver>>()
            activeObservers = observers.mapNotNull { ref ->
                ref.get() ?: run {
                    dead.add(ref)
                    null
                }
            }
            observers.removeAll(dead)
        }

        for (observer in activeObservers) {
            try {
                observer.onUnitAvailable(unit)
            } catch (e: Exception) {
                Log.w(TAG, "Observer threw exception: ${e.message}")
            }
        }
    }
}
