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

    private const val TAG = "CleverTapAutoWire"

    /**
     * Strong reference to the listener we register with the Core SDK.
     *
     * The Core SDK's CallbackManager stores the DisplayUnitListener as a WeakReference.
     * Without a strong reference here, the anonymous listener object would be garbage
     * collected and the Core SDK would log "No registered listener, failed to notify".
     */
    private var activeListener: DisplayUnitListener? = null

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
     * Wire the bridge to a CleverTap instance.
     *
     * Prefers the cache-attachment API (Core SDK v7.x+): the proxy handles both
     * "data out" (attribution lookups via [getDisplayUnitForID]) and "data in"
     * (server updates via [updateDisplayUnits] → [NativeDisplayBridge.processDisplayUnits]).
     * When cache attachment succeeds no [DisplayUnitListener] is needed.
     *
     * Falls back to a composite [DisplayUnitListener] on older Core SDK versions that
     * don't expose [setDisplayUnitCache]. The listener is stored in [activeListener] to
     * prevent GC — the Core SDK holds it via WeakReference.
     */
    private fun wireListener(
        ctApi: CleverTapAPI,
        bridge: NativeDisplayBridge,
        clientListener: DisplayUnitListener? = null
    ): Boolean {
        bridge.cleverTapApi = ctApi

        // Prefer cache-attachment (Core SDK v7.x+).
        // updateDisplayUnits on the proxy extracts JSON from CleverTapDisplayUnit objects
        // via getJsonObject() reflection — no separate DisplayUnitListener needed.
        if (tryAttachCache(ctApi, bridge)) {
            if (clientListener != null) {
                ctApi.setDisplayUnitListener(clientListener)
            }
            Log.d(TAG, "Wired to CleverTap via cache attachment${if (clientListener != null) " (client listener forwarded)" else ""}")
            return true
        }

        // Fallback: older Core SDK without setDisplayUnitCache.
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

        activeListener = listener
        ctApi.setDisplayUnitListener(listener)

        Log.d(TAG, "Wired to CleverTap via DisplayUnitListener fallback${if (clientListener != null) " (client listener forwarded)" else ""}")
        return true
    }

    /**
     * Reflectively invokes `CleverTapAPI.setDisplayUnitCache(...)`, returning
     * `true` only when the method exists and the call succeeds.
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
        val proxy = bridge.coreSdkCacheProxy() ?: return false
        return try {
            setter.invoke(ctApi, proxy)
            true
        } catch (t: Throwable) {
            Log.w(TAG, "setDisplayUnitCache invocation failed: ${t.message}")
            false
        }
    }
}
