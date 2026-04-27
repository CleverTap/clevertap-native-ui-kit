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
     */
    private fun wireListener(
        ctApi: CleverTapAPI,
        bridge: NativeDisplayBridge,
        clientListener: DisplayUnitListener? = null
    ): Boolean {
        ctApi.setDisplayUnitListener(object : DisplayUnitListener {
            override fun onDisplayUnitsLoaded(units: ArrayList<CleverTapDisplayUnit>?) {
                // Forward to client's listener first
                if (clientListener != null) {
                    try {
                        clientListener.onDisplayUnitsLoaded(units)
                    } catch (e: Exception) {
                        Log.w(TAG, "Client listener threw exception: ${e.message}")
                    }
                }

                // Then process for bridge
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
        })
        Log.d(TAG, "Wired to CleverTap instance${if (clientListener != null) " (with client listener forwarding)" else ""}")
        return true
    }
}
