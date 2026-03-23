package com.clevertap.android.nativedisplay.bridge

import android.content.Context
import android.util.Log
import com.clevertap.android.sdk.CleverTapAPI
import java.lang.ref.WeakReference

/**
 * Main entry point for the CleverTap Core SDK bridge adapter.
 *
 * Provides two modes of operation:
 *
 * **Auto-wire mode** — detects the CleverTap Core SDK at runtime via reflection
 * and automatically registers as a display unit listener. If the Core SDK is not
 * present, this silently falls back to manual mode.
 * ```kotlin
 * val bridge = NativeDisplayBridge.initialize(applicationContext)
 * bridge.addListener(myListener)
 * ```
 *
 * **Manual mode** — no Core SDK detection; the client feeds JSON strings directly.
 * ```kotlin
 * val bridge = NativeDisplayBridge.create()
 * bridge.processDisplayUnits(jsonStrings)
 * ```
 *
 * Thread-safe. Listeners are held as [WeakReference] to avoid memory leaks.
 */
class NativeDisplayBridge private constructor() {

    private val parser = NativeDisplayConfigParser()

    // Cache: unitId → NativeDisplayUnit, synchronized access
    private val cache = LinkedHashMap<String, NativeDisplayUnit>()
    private val cacheLock = Any()

    // Listeners stored as weak references to avoid leaking activities/fragments
    private val listeners = mutableListOf<WeakReference<NativeDisplayBridgeListener>>()
    private val listenersLock = Any()

    companion object {
        private const val TAG = "NativeDisplayBridge"

        @Volatile
        private var instance: NativeDisplayBridge? = null

        /**
         * Initialize the bridge with auto-wire support.
         *
         * Attempts to detect the CleverTap Core SDK via reflection and register
         * as a display unit listener. If the Core SDK is absent, the bridge is
         * still created and works in manual mode.
         *
         * Safe to call multiple times — returns the existing instance if already initialized.
         *
         * @param context Application context (used for Core SDK instance lookup)
         * @return The singleton bridge instance
         */
        fun initialize(context: Context): NativeDisplayBridge {
            return instance ?: synchronized(this) {
                instance ?: NativeDisplayBridge().also { bridge ->
                    instance = bridge
                    CleverTapAutoWire.tryAutoWire(context.applicationContext, bridge)
                }
            }
        }

        /**
         * Create a bridge instance in manual mode (no Core SDK detection).
         *
         * Use this when you want full control over JSON input or when the
         * CleverTap Core SDK is not used.
         *
         * Safe to call multiple times — returns the existing instance if already created.
         *
         * @return The singleton bridge instance
         */
        fun create(): NativeDisplayBridge {
            return instance ?: synchronized(this) {
                instance ?: NativeDisplayBridge().also { bridge ->
                    instance = bridge
                }
            }
        }

        /**
         * Get the current bridge instance, or null if not yet initialized.
         */
        fun getInstance(): NativeDisplayBridge? = instance
    }

    // --- Manual Mode: accept raw JSON ---

    /**
     * Parse and cache a list of display unit JSON strings.
     *
     * This **replaces** the entire cache (mirrors CleverTap Core SDK behavior where
     * each callback delivers the full current set of display units).
     *
     * Successfully parsed units are cached and listeners are notified.
     * Malformed or non-ND units are silently skipped (with a log warning).
     *
     * @param displayUnitJsonStrings List of raw JSON strings from display unit payloads
     */
    fun processDisplayUnits(displayUnitJsonStrings: List<String>) {
        val parsedUnits: List<NativeDisplayUnit> = displayUnitJsonStrings.mapNotNull { jsonString ->
            parser.tryParse(jsonString)
        }

        synchronized(cacheLock) {
            cache.clear()
            for (unit in parsedUnits) {
                cache[unit.unitId] = unit
            }
        }

        Log.d(TAG, "Processed ${parsedUnits.size}/${displayUnitJsonStrings.size} display units")
        notifyListeners(parsedUnits)
    }

    /**
     * Parse and cache a single display unit JSON string.
     *
     * This **adds or updates** a single entry in the cache (does not replace).
     * Use this for incremental updates.
     *
     * @param displayUnitJsonString Raw JSON string from a display unit payload
     */
    fun processDisplayUnit(displayUnitJsonString: String) {
        val unit = parser.tryParse(displayUnitJsonString)
        if (unit == null) {
            Log.w(TAG, "Failed to parse display unit, skipping")
            return
        }

        synchronized(cacheLock) {
            cache[unit.unitId] = unit
        }

        Log.d(TAG, "Processed display unit: ${unit.unitId}")
        notifyListeners(listOf(unit))
    }

    // --- Pull API ---

    /**
     * Get all currently cached Native Display units.
     *
     * @return A snapshot list of all cached units (safe to iterate)
     */
    fun getAllNativeDisplays(): List<NativeDisplayUnit> {
        synchronized(cacheLock) {
            return cache.values.toList()
        }
    }

    /**
     * Get a specific Native Display unit by its ID.
     *
     * @param unitId The unit identifier (typically `wzrk_id`)
     * @return The matching unit, or null if not found
     */
    fun getNativeDisplayForId(unitId: String): NativeDisplayUnit? {
        synchronized(cacheLock) {
            return cache[unitId]
        }
    }

    // --- Push API ---

    /**
     * Register a listener to receive display unit updates.
     *
     * Listeners are held as [WeakReference] — they will be automatically
     * cleaned up if the owning object is garbage collected.
     *
     * @param listener The listener to register
     */
    fun addListener(listener: NativeDisplayBridgeListener) {
        synchronized(listenersLock) {
            // Avoid duplicate registration
            val alreadyRegistered = listeners.any { it.get() === listener }
            if (!alreadyRegistered) {
                listeners.add(WeakReference(listener))
            }
        }
    }

    /**
     * Unregister a previously registered listener.
     *
     * @param listener The listener to remove
     */
    fun removeListener(listener: NativeDisplayBridgeListener) {
        synchronized(listenersLock) {
            listeners.removeAll { it.get() === listener || it.get() == null }
        }
    }

    /**
     * Bind the bridge to a CleverTap API instance.
     *
     * Registers as a display unit listener on the provided [CleverTapAPI] instance.
     * Uses `compileOnly` dependency — the Core SDK must be present at runtime
     * (provided by the host app). If not present, this returns false gracefully.
     *
     * ```kotlin
     * val bridge = NativeDisplayBridge.create()
     * bridge.bind(CleverTapAPI.getDefaultInstance(context)!!)
     * ```
     *
     * @param cleverTapApi The [CleverTapAPI] instance to wire to.
     * @return true if binding succeeded, false otherwise
     */
    fun bind(cleverTapApi: CleverTapAPI): Boolean {
        return CleverTapAutoWire.bindToInstance(cleverTapApi, this)
    }

    /**
     * Clear all cached display units and remove all listeners.
     */
    fun clear() {
        synchronized(cacheLock) {
            cache.clear()
        }
        synchronized(listenersLock) {
            listeners.clear()
        }
        Log.d(TAG, "Bridge cleared")
    }

    // --- Internal ---

    /**
     * Notify all active listeners. Cleans up dead weak references during iteration.
     */
    private fun notifyListeners(units: List<NativeDisplayUnit>) {
        val activeListeners: List<NativeDisplayBridgeListener>
        synchronized(listenersLock) {
            // Collect active listeners and prune dead references
            val dead = mutableListOf<WeakReference<NativeDisplayBridgeListener>>()
            activeListeners = listeners.mapNotNull { ref ->
                ref.get() ?: run {
                    dead.add(ref)
                    null
                }
            }
            listeners.removeAll(dead)
        }

        for (listener in activeListeners) {
            try {
                listener.onNativeDisplaysLoaded(units)
            } catch (e: Exception) {
                Log.w(TAG, "Listener threw exception: ${e.message}")
            }
        }
    }
}
