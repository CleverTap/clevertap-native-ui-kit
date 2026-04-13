package com.clevertap.android.nativedisplay.bridge

import android.content.Context
import android.util.Log
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
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

    /** CleverTapAPI instance used to push display unit attribution events. */
    internal var cleverTapApi: CleverTapAPI? = null


    companion object {
        private const val TAG = "NativeDisplayBridge"

        /** Event name for server fetch requests. */
        internal const val WZRK_FETCH = "wzrk_fetch"

        /** Fetch type constant for Native Display units. */
        internal const val FETCH_TYPE_NATIVE_DISPLAY = 9

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
     * Registers a composite display unit listener that forwards to both the bridge
     * and an optional client listener. This avoids replacing the client's existing
     * listener, since the Core SDK only supports a single `DisplayUnitListener`.
     *
     * ```kotlin
     * // Without client listener
     * bridge.bind(CleverTapAPI.getDefaultInstance(context)!!)
     *
     * // With client listener (both receive callbacks)
     * bridge.bind(CleverTapAPI.getDefaultInstance(context)!!, forwardTo = myListener)
     * ```
     *
     * @param cleverTapApi The [CleverTapAPI] instance to wire to.
     * @param forwardTo Optional client [DisplayUnitListener] to forward raw display units to.
     *                  If provided, it receives the same callback the Core SDK would normally
     *                  deliver, preserving the client's existing display unit handling.
     * @return true if binding succeeded, false otherwise
     */
    fun bind(
        cleverTapApi: CleverTapAPI,
        forwardTo: com.clevertap.android.sdk.displayunits.DisplayUnitListener? = null
    ): Boolean {
        return CleverTapAutoWire.bindToInstance(cleverTapApi, this, forwardTo)
    }

    /**
     * Request the CleverTap server to fetch Native Display units.
     *
     * Sends a `wzrk_fetch` event with fetch type `9` (Native Display) via the
     * provided [CleverTapAPI] instance. The server will respond with display units
     * through the normal `adUnit_notifs` pipeline, which the bridge listener
     * will pick up automatically.
     *
     * ```kotlin
     * bridge.fetchNativeDisplays(CleverTapAPI.getDefaultInstance(context)!!)
     * // Response arrives via NativeDisplayBridgeListener.onNativeDisplaysLoaded()
     * ```
     *
     * @param cleverTapApi The [CleverTapAPI] instance to send the fetch event through.
     * @return true if the fetch event was sent successfully
     */
    fun fetchNativeDisplays(cleverTapApi: CleverTapAPI): Boolean {
        return try {
            val eventData = mapOf("t" to FETCH_TYPE_NATIVE_DISPLAY)
            cleverTapApi.pushEvent(WZRK_FETCH, eventData)
            Log.d(TAG, "Sent wzrk_fetch request for Native Display (type=$FETCH_TYPE_NATIVE_DISPLAY)")
            true
        } catch (e: NoClassDefFoundError) {
            Log.w(TAG, "CleverTap Core SDK not available for fetch")
            false
        } catch (e: Exception) {
            Log.w(TAG, "fetchNativeDisplays() failed: ${e.message}")
            false
        }
    }

    /**
     * Push a display unit viewed (impression) attribution event to the CleverTap Core SDK.
     *
     * Calls `CleverTapAPI.pushDisplayUnitViewedEventForID(unitId)` if a [CleverTapAPI]
     * instance has been stored (set automatically when using auto-wire or [bind]).
     *
     * @param unitId The ID of the display unit that was viewed
     * @return true if the event was pushed successfully, false if no CleverTapAPI is available
     */
    fun pushViewedEvent(unitId: String): Boolean {
        return try {
            cleverTapApi?.pushDisplayUnitViewedEventForID(unitId)
            cleverTapApi != null
        } catch (e: Exception) {
            Log.w(TAG, "pushViewedEvent failed: ${e.message}")
            false
        }
    }

    /**
     * Push a display unit clicked attribution event to the CleverTap Core SDK.
     *
     * Calls `CleverTapAPI.pushDisplayUnitClickedEventForID(unitId)` if a [CleverTapAPI]
     * instance has been stored (set automatically when using auto-wire or [bind]).
     *
     * @param unitId The ID of the display unit that was clicked
     * @return true if the event was pushed successfully, false if no CleverTapAPI is available
     */
    fun pushClickedEvent(unitId: String): Boolean {
        return try {
            cleverTapApi?.pushDisplayUnitClickedEventForID(unitId)
            cleverTapApi != null
        } catch (e: Exception) {
            Log.w(TAG, "pushClickedEvent failed: ${e.message}")
            false
        }
    }

    /**
     * Create a [NativeDisplayActionListener] that automatically forwards display unit
     * attribution events to the CleverTap Core SDK via [pushViewedEvent] and [pushClickedEvent].
     *
     * An optional [base] listener is invoked first so that the client's own handling
     * is preserved. This listener can be passed as the `actionListener` parameter to
     * [NativeDisplayView] or [NativeDisplayViewGroup.setConfig].
     *
     * ```kotlin
     * val listener = bridge.createEventForwardingListener(base = myListener)
     * NativeDisplayView(config = config, actionListener = listener, unitId = unit.unitId)
     * ```
     *
     * @param base Optional client listener to delegate all callbacks to first
     * @return A [NativeDisplayActionListener] that forwards attribution events to the Core SDK
     */
    fun createEventForwardingListener(
        base: NativeDisplayActionListener? = null
    ): NativeDisplayActionListener {
        return object : NativeDisplayActionListener {
            override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
                base?.onCustomAction(key, value, metadata)
            }
            override fun onNavigate(destination: String, params: Map<String, String>?) {
                base?.onNavigate(destination, params)
            }
            override fun onTrackEvent(eventName: String, properties: Map<String, Any?>?) {
                base?.onTrackEvent(eventName, properties)
            }
            override fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean {
                return base?.onOpenUrl(url, openInBrowser) ?: false
            }
            override fun onDisplayUnitViewed(unitId: String) {
                base?.onDisplayUnitViewed(unitId)
                pushViewedEvent(unitId)
            }
            override fun onDisplayUnitClicked(unitId: String) {
                base?.onDisplayUnitClicked(unitId)
                pushClickedEvent(unitId)
            }
        }
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
