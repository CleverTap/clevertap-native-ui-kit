package com.clevertap.android.nativedisplay.bridge

import android.content.Context
import android.util.Log
import com.clevertap.android.sdk.CleverTapAPI
import com.clevertap.android.sdk.displayunits.DisplayUnitListener
import com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit

/**
 * Wires the [NativeDisplayBridge] to the CleverTap Core SDK.
 *
 * Uses `compileOnly` dependency — the Core SDK is available at compile time but NOT
 * bundled with this library. If the Core SDK is absent at runtime, calls to this class
 * will throw [NoClassDefFoundError] which callers must catch.
 */
internal object CleverTapAutoWire {

    private const val TAG = "NativeDisplayBridge"

    /**
     * Strong reference to the listener we register with the Core SDK.
     *
     * The Core SDK's CallbackManager stores the DisplayUnitListener as a WeakReference.
     * Without a strong reference here, the anonymous listener object would be garbage
     * collected and the Core SDK would log "No registered listener, failed to notify".
     */
    private var activeListener: DisplayUnitListener? = null

    /**
     * Strong reference to the cache proxy installed via
     * `CleverTapAPI.setDisplayUnitCache(...)` on Core SDK v7.x+.
     */
    private var activeCache: Any? = null

    /**
     * Auto-wire using the default CleverTapAPI instance.
     *
     * @param context Application context for instance lookup
     * @param bridge The bridge to forward display units to
     * @return true if wiring succeeded
     */
    fun tryAutoWire(context: Context, bridge: NativeDisplayBridge): Boolean {
        return try {
            val ctApi = CleverTapAPI.getDefaultInstance(context.applicationContext)
            if (ctApi == null) {
                Log.w(TAG, "CleverTapAPI.getDefaultInstance() returned null")
                return false
            }
            wireListener(ctApi, bridge)
        } catch (e: NoClassDefFoundError) {
            Log.d(TAG, "CleverTap Core SDK not found, manual mode only")
            false
        } catch (e: Exception) {
            Log.w(TAG, "Auto-wire failed: ${e.message}")
            false
        }
    }

    /**
     * Bind the bridge to a specific [CleverTapAPI] instance.
     *
     * @param cleverTapApi The CleverTapAPI instance to wire to
     * @param bridge The bridge to forward display units to
     * @param clientListener Optional client listener to also forward raw units to
     * @return true if binding succeeded
     */
    fun bindToInstance(
        cleverTapApi: CleverTapAPI,
        bridge: NativeDisplayBridge,
        clientListener: DisplayUnitListener? = null
    ): Boolean {
        return try {
            wireListener(cleverTapApi, bridge, clientListener)
        } catch (e: NoClassDefFoundError) {
            Log.w(TAG, "CleverTap Core SDK classes not available at runtime")
            false
        } catch (e: Exception) {
            Log.w(TAG, "bind() failed: ${e.message}")
            false
        }
    }

    /**
     * Register a composite [DisplayUnitListener] that:
     * 1. Extracts JSON and forwards to the bridge
     * 2. Forwards the raw units to the optional client listener
     *
     * This avoids replacing the client's listener since the Core SDK
     * only supports a single [DisplayUnitListener].
     *
     * The listener is stored in [activeListener] to prevent GC, since the
     * Core SDK holds it via a WeakReference.
     */
    private fun wireListener(
        ctApi: CleverTapAPI,
        bridge: NativeDisplayBridge,
        clientListener: DisplayUnitListener? = null
    ): Boolean {
        // Store the CleverTapAPI reference so the bridge can push attribution events
        bridge.cleverTapApi = ctApi

        // Prefer the cache-attachment API (Core SDK v7.x+). When attached, server-driven
        // updates flow via cache.updateDisplayUnits → bridge.processDisplayUnits, so a
        // separate DisplayUnitListener is unnecessary. The client's own
        // setDisplayUnitListener (if any) is forwarded for backward compatibility.
        if (tryAttachCache(ctApi, bridge)) {
            if (clientListener != null) {
                ctApi.setDisplayUnitListener(clientListener)
            }
            Log.d(TAG, "Wired to CleverTap via cache attachment${if (clientListener != null) " (client listener forwarded)" else ""}")
            return true
        }

        // Fallback for older Core SDK without setDisplayUnitCache: register a composite
        // DisplayUnitListener and rely on ReflectionSeeder per push event for attribution.
        val listener = object : DisplayUnitListener {
            override fun onDisplayUnitsLoaded(units: ArrayList<CleverTapDisplayUnit>?) {
                if (clientListener != null) {
                    try {
                        clientListener.onDisplayUnitsLoaded(units)
                    } catch (e: Exception) {
                        Log.w(TAG, "Client listener threw exception: ${e.message}")
                    }
                }

                if (units.isNullOrEmpty()) return
                val jsonStrings = units.mapNotNull { unit ->
                    try {
                        unit.jsonObject?.toString()
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to extract JSON from display unit: ${e.message}")
                        null
                    }
                }
                if (jsonStrings.isNotEmpty()) {
                    bridge.processDisplayUnits(jsonStrings)
                }
            }
        }

        // Keep a strong reference so the Core SDK's WeakReference doesn't lose it
        activeListener = listener
        ctApi.setDisplayUnitListener(listener)

        Log.d(TAG, "Wired to CleverTap via DisplayUnitListener fallback${if (clientListener != null) " (with client listener forwarding)" else ""}")
        return true
    }

    /**
     * Reflectively invokes `CleverTapAPI.setDisplayUnitCache(...)`, returning
     * `true` only when the method exists and the call succeeds. The cache
     * proxy is retained in [activeCache] so its identity stays stable for
     * comparison/detach.
     */
    private fun tryAttachCache(ctApi: CleverTapAPI, bridge: NativeDisplayBridge): Boolean {
        val ifaceClass = try {
            Class.forName("com.clevertap.android.sdk.displayunits.DisplayUnitCache")
        } catch (_: ClassNotFoundException) {
            return false
        }
        val setter = try {
            ctApi.javaClass.getMethod("setDisplayUnitCache", ifaceClass)
        } catch (_: NoSuchMethodException) {
            return false
        }
        val proxy = NativeDisplayUnitCacheImpl(bridge).asProxy() ?: return false
        return try {
            setter.invoke(ctApi, proxy)
            activeCache = proxy
            true
        } catch (t: Throwable) {
            Log.w(TAG, "setDisplayUnitCache invocation failed: ${t.message}")
            false
        }
    }
}
