package com.clevertap.android.nativedisplay.bridge

import android.content.Context
import com.clevertap.android.nativedisplay.internal.NDLogger
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

    /** Library name reported to the Core SDK via [CleverTapAPI.setLibrary]. */
    private const val CUSTOM_SDK_NAME = "NativeDisplay"

    /**
     * Version code reported to the Core SDK via [CleverTapAPI.setCustomSdkVersion].
     * Bump on each release. Format: major*10000 + minor*100 + patch
     * (e.g. v1.00.00 -> 10000, v4.02.00 -> 40200).
     */
    private const val CUSTOM_SDK_VERSION = 10000

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
                NDLogger.w(TAG, "CleverTapAPI.getDefaultInstance() returned null")
                return false
            }
            wireListener(ctApi, bridge)
        } catch (e: NoClassDefFoundError) {
            NDLogger.d(TAG, "CleverTap Core SDK not found, manual mode only")
            false
        } catch (e: Exception) {
            NDLogger.w(TAG, "Auto-wire failed: ${e.message}")
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
            NDLogger.w(TAG, "CleverTap Core SDK classes not available at runtime")
            false
        } catch (e: Exception) {
            NDLogger.w(TAG, "bind() failed: ${e.message}")
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

        // Identify this wrapper SDK to the Core SDK. Best-effort: never blocks wiring.
        reportSdkVersion(ctApi)

        // Prefer cache-attachment (Core SDK v7.x+).
        // updateDisplayUnits on the proxy extracts JSON from CleverTapDisplayUnit objects
        // via getJsonObject() reflection — no separate DisplayUnitListener needed.
        if (tryAttachCache(ctApi, bridge)) {
            if (clientListener != null) {
                ctApi.setDisplayUnitListener(clientListener)
            }
            NDLogger.d(TAG, "Wired to CleverTap via cache attachment${if (clientListener != null) " (client listener forwarded)" else ""}")
            syncLogLevelFromCoreSdk(ctApi)
            return true
        }

        // Fallback: older Core SDK without setDisplayUnitCache.
        val listener = object : DisplayUnitListener {
            override fun onDisplayUnitsLoaded(units: ArrayList<CleverTapDisplayUnit>?) {
                if (clientListener != null) {
                    try {
                        clientListener.onDisplayUnitsLoaded(units)
                    } catch (e: Exception) {
                        NDLogger.w(TAG, "Client listener threw exception: ${e.message}")
                    }
                }

                if (units.isNullOrEmpty()) return
                val jsonStrings = units.mapNotNull { unit ->
                    try {
                        unit.jsonObject?.toString()
                    } catch (e: Exception) {
                        NDLogger.w(TAG, "Failed to extract JSON from display unit: ${e.message}")
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

        NDLogger.d(TAG, "Wired to CleverTap via DisplayUnitListener fallback${if (clientListener != null) " (client listener forwarded)" else ""}")
        syncLogLevelFromCoreSdk(ctApi)
        return true
    }

    /**
     * Reports the Native Display SDK version to the Core SDK so it can be attributed
     * as a custom/wrapper SDK. Best-effort — wrapped in try/catch so a missing API or
     * any failure never breaks the actual display-unit wiring.
     */
    private fun reportSdkVersion(ctApi: CleverTapAPI) {
        try {
            ctApi.setLibrary(CUSTOM_SDK_NAME)
            ctApi.setCustomSdkVersion(CUSTOM_SDK_NAME, CUSTOM_SDK_VERSION)
            NDLogger.d(TAG, "Reported custom SDK version: $CUSTOM_SDK_NAME $CUSTOM_SDK_VERSION")
        } catch (t: Throwable) {
            NDLogger.d(TAG, "setCustomSdkVersion unavailable on this Core SDK: ${t.message}")
        }
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
            NDLogger.w(TAG, "setDisplayUnitCache invocation failed: ${t.message}")
            false
        }
    }

    /**
     * Reflectively reads `CleverTapAPI.getDebugLevel()` and forwards the result to
     * [NDLogger.syncFromCoreSdk]. Only fires when [NDLogger.isExplicitlySet] is false so
     * a client-supplied [NativeDisplayBridge.setLogLevel] always takes precedence.
     *
     * Uses try/catch — if the method is absent or throws, the SDK default is preserved.
     */
    private fun syncLogLevelFromCoreSdk(ctApi: CleverTapAPI) {
        if (NDLogger.isExplicitlySet()) return
        try {
            val level = ctApi.javaClass.getMethod("getDebugLevel").invoke(ctApi)
            if (level is Int) {
                NDLogger.syncFromCoreSdk(level)
                NDLogger.d(TAG, "Log level synced from Core SDK: $level → ${NDLogger.getLevel()}")
            }
        } catch (_: Throwable) {
            // getDebugLevel() unavailable on this Core SDK version — leave the default intact.
        }
    }
}
