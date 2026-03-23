package com.clevertap.android.nativedisplay.bridge

import android.content.Context
import android.util.Log

/**
 * Runtime auto-wiring to the CleverTap Core SDK via reflection.
 *
 * Uses [Class.forName] and [java.lang.reflect.Proxy] to detect and register
 * as a display unit listener without any compile-time dependency on the Core SDK.
 *
 * If the Core SDK is not present on the classpath, all operations silently no-op.
 */
internal object CleverTapAutoWire {

    private const val TAG = "NativeDisplayBridge"

    private const val CT_API_CLASS = "com.clevertap.android.sdk.CleverTapAPI"
    private const val CT_LISTENER_CLASS =
        "com.clevertap.android.sdk.displayunits.DisplayUnitListener"

    /**
     * Attempt to auto-wire the bridge to the CleverTap Core SDK.
     *
     * @param context Application context used to obtain the default CleverTapAPI instance
     * @param bridge The bridge instance to forward display units to
     * @return true if auto-wiring succeeded, false otherwise
     */
    fun tryAutoWire(context: Context, bridge: NativeDisplayBridge): Boolean {
        return try {
            // 1. Check if CleverTapAPI class exists on the classpath
            val ctClass = Class.forName(CT_API_CLASS)

            // 2. Get the default instance: CleverTapAPI.getDefaultInstance(Context)
            val getInstanceMethod = ctClass.getMethod(
                "getDefaultInstance",
                Context::class.java
            )
            val ctApi = getInstanceMethod.invoke(null, context.applicationContext)
            if (ctApi == null) {
                Log.w(TAG, "CleverTapAPI.getDefaultInstance() returned null")
                return false
            }

            // 3. Load the DisplayUnitListener interface
            val listenerClass = Class.forName(CT_LISTENER_CLASS)

            // 4. Create a dynamic proxy that forwards onDisplayUnitsLoaded to the bridge
            val proxy = java.lang.reflect.Proxy.newProxyInstance(
                listenerClass.classLoader,
                arrayOf(listenerClass)
            ) { _, method, args ->
                if (method.name == "onDisplayUnitsLoaded" && args != null && args.isNotEmpty()) {
                    handleDisplayUnitsLoaded(args[0], bridge)
                }
                null
            }

            // 5. Register the proxy: ctApi.setDisplayUnitListener(proxy)
            val setListenerMethod = ctClass.getMethod(
                "setDisplayUnitListener",
                listenerClass
            )
            setListenerMethod.invoke(ctApi, proxy)

            Log.d(TAG, "Auto-wired to CleverTap Core SDK")
            true
        } catch (e: ClassNotFoundException) {
            Log.d(TAG, "CleverTap Core SDK not found, manual mode only")
            false
        } catch (e: Exception) {
            Log.w(TAG, "Auto-wire failed: ${e.message}")
            false
        }
    }

    /**
     * Bind the bridge to a specific CleverTapAPI instance.
     *
     * Unlike [tryAutoWire], this accepts the instance directly (as [Any]) rather than
     * looking it up via reflection. The caller passes the CleverTapAPI object.
     *
     * @param cleverTapApi The CleverTapAPI instance (typed as Any to avoid compile dependency)
     * @param bridge The bridge to forward display units to
     * @return true if binding succeeded
     */
    fun bindToInstance(cleverTapApi: Any, bridge: NativeDisplayBridge): Boolean {
        return try {
            val ctClass = cleverTapApi::class.java

            // Verify this looks like a CleverTapAPI (check class name)
            if (!ctClass.name.contains("CleverTapAPI")) {
                Log.w(TAG, "bind() called with non-CleverTapAPI object: ${ctClass.name}")
                return false
            }

            // Load the DisplayUnitListener interface
            val listenerClass = Class.forName(CT_LISTENER_CLASS)

            // Create a dynamic proxy that forwards to the bridge
            val proxy = java.lang.reflect.Proxy.newProxyInstance(
                listenerClass.classLoader,
                arrayOf(listenerClass)
            ) { _, method, args ->
                if (method.name == "onDisplayUnitsLoaded" && args != null && args.isNotEmpty()) {
                    handleDisplayUnitsLoaded(args[0], bridge)
                }
                null
            }

            // Register: cleverTapApi.setDisplayUnitListener(proxy)
            val setListenerMethod = ctClass.getMethod("setDisplayUnitListener", listenerClass)
            setListenerMethod.invoke(cleverTapApi, proxy)

            Log.d(TAG, "Bound to CleverTap instance: ${ctClass.simpleName}")
            true
        } catch (e: ClassNotFoundException) {
            Log.w(TAG, "DisplayUnitListener class not found: ${e.message}")
            false
        } catch (e: Exception) {
            Log.w(TAG, "bind() failed: ${e.message}")
            false
        }
    }

    /**
     * Extract JSON strings from display unit objects via reflection and forward to the bridge.
     */
    private fun handleDisplayUnitsLoaded(unitsArg: Any?, bridge: NativeDisplayBridge) {
        try {
            val units = unitsArg as? ArrayList<*> ?: return
            val jsonStrings = units.mapNotNull { unit ->
                if (unit == null) return@mapNotNull null
                try {
                    val getJsonMethod = unit::class.java.getMethod("getJsonObject")
                    val jsonObject = getJsonMethod.invoke(unit)
                    jsonObject?.toString()
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to extract JSON from display unit: ${e.message}")
                    null
                }
            }
            if (jsonStrings.isNotEmpty()) {
                bridge.processDisplayUnits(jsonStrings)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to process display units from Core SDK: ${e.message}")
        }
    }
}
