package com.clevertap.android.nativedisplay.bridge

import com.clevertap.android.nativedisplay.internal.NDLogger
import org.json.JSONObject

/**
 * Older-Core-SDK fallback used when [CleverTapAPI.setDisplayUnitCache] is not
 * available on the host's Core SDK version. Mutates the existing
 * `CTDisplayUnitController.items` HashMap directly so that the unit becomes
 * visible to `pushDisplayUnit*EventForID` lookups, without invoking
 * `updateDisplayUnits` (which is replace-mode and would clobber Core SDK's
 * own server-driven entries).
 *
 * All access is reflective; failures are logged once per process and
 * propagated as a `false` return so callers can fall through to a
 * callback-only path.
 */
internal object ReflectionSeeder {

    private const val TAG = "NDReflectionSeeder"

    @Volatile
    private var loggedFailure = false

    /**
     * Seeds the supplied units into the Core SDK's display-unit cache.
     *
     * @return true if at least one unit was added; false on any failure
     * (logged once per process).
     */
    fun seed(cleverTapApi: Any, units: List<JSONObject>): Boolean {
        if (units.isEmpty()) return false
        return try {
            val controller = resolveController(cleverTapApi) ?: return logOnce("controller unreachable")
            @Suppress("UNCHECKED_CAST")
            val items = field(controller, "items") as MutableMap<String, Any>
            val toDisplayUnit = Class.forName("com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit")
                .getMethod("toDisplayUnit", JSONObject::class.java)
            val getUnitID = Class.forName("com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit")
                .getMethod("getUnitID")
            synchronized(controller) {
                for (json in units) {
                    val unit = toDisplayUnit.invoke(null, json) ?: continue
                    val id = getUnitID.invoke(unit) as? String ?: continue
                    items[id] = unit
                }
            }
            true
        } catch (t: Throwable) {
            logOnce("seed failed: ${t.message}")
        }
    }

    private fun resolveController(cleverTapApi: Any): Any? {
        val coreState = field(cleverTapApi, "coreState")
        val analyticsManager = coreState.javaClass.getMethod("getAnalyticsManager").invoke(coreState) ?: return null
        val controllerManager = field(analyticsManager, "controllerManager")
        // Newer Core SDK exposes getDisplayUnitCache(); older only getCTDisplayUnitController().
        return try {
            controllerManager.javaClass.getMethod("getDisplayUnitCache").invoke(controllerManager)
        } catch (_: NoSuchMethodException) {
            controllerManager.javaClass.getMethod("getCTDisplayUnitController").invoke(controllerManager)
        }
    }

    private fun field(obj: Any, name: String): Any =
        obj.javaClass.getDeclaredField(name).apply { isAccessible = true }.get(obj)
            ?: throw IllegalStateException("Field '$name' on ${obj.javaClass.simpleName} was null")

    // Always returns `false` so callers can `return logOnce(...)` as a "log once
    // and signal failure" shortcut from a Boolean-returning function.
    @Suppress("FunctionOnlyReturningConstant")
    private fun logOnce(message: String): Boolean {
        if (!loggedFailure) {
            loggedFailure = true
            NDLogger.w(TAG, "$message; events will be unattributed.")
        }
        return false
    }
}
