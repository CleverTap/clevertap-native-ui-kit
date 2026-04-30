package com.clevertap.android.nativedisplay.bridge

import android.util.Log
import java.lang.reflect.Proxy
import org.json.JSONArray
import org.json.JSONObject

/**
 * Builds a runtime proxy implementing Core SDK's `DisplayUnitCache` interface
 * (when present) backed by [NativeDisplayBridge]'s own cache. Routes Core SDK
 * lookups (`getDisplayUnitForID`, `getAllDisplayUnits`) through the bridge,
 * and routes server-driven `updateDisplayUnits` calls into the bridge's
 * existing parse pipeline so existing [NativeDisplayBridgeListener]s still
 * fire.
 *
 * Uses [Proxy] so the ND SDK retains its zero-runtime-dependency on Core SDK.
 * If `DisplayUnitCache` is not on the classpath at runtime, [asProxy] returns
 * null and the caller falls back to [ReflectionSeeder].
 */
internal class NativeDisplayUnitCacheImpl(private val bridge: NativeDisplayBridge) {

    /** @return a proxy implementing `DisplayUnitCache`, or null if absent at runtime. */
    fun asProxy(): Any? {
        val ifaceClass = try {
            Class.forName("com.clevertap.android.sdk.displayunits.DisplayUnitCache")
        } catch (_: ClassNotFoundException) {
            return null
        }
        return Proxy.newProxyInstance(ifaceClass.classLoader, arrayOf(ifaceClass)) { proxy, method, args ->
            try {
                when (method.name) {
                    "getDisplayUnitForID" -> resolve(args?.firstOrNull() as? String)
                    "getAllDisplayUnits" -> all()
                    "updateDisplayUnits" -> ingestServer(args?.firstOrNull() as? JSONArray)
                    "reset" -> { bridge.clear(); null }
                    "equals" -> args?.firstOrNull() === proxy
                    "hashCode" -> System.identityHashCode(proxy)
                    "toString" -> "NativeDisplayUnitCacheImpl"
                    else -> null
                }
            } catch (t: Throwable) {
                Log.w(TAG, "${method.name} failed: ${t.message}")
                null
            }
        }
    }

    private fun resolve(unitId: String?): Any? {
        if (unitId.isNullOrEmpty()) return null
        val unit = bridge.getNativeDisplayForId(unitId) ?: return null
        return unit.rawJson?.let { toCleverTapDisplayUnit(it) }
    }

    private fun all(): Any? {
        val units = bridge.getAllNativeDisplays()
            .mapNotNull { it.rawJson?.let(::toCleverTapDisplayUnit) }
        return if (units.isEmpty()) null else ArrayList(units)
    }

    private fun ingestServer(messages: JSONArray?): Any? {
        if (messages == null || messages.length() == 0) return null
        val jsonStrings = (0 until messages.length()).mapNotNull { i ->
            try { messages.optJSONObject(i)?.toString() } catch (_: Throwable) { null }
        }
        if (jsonStrings.isNotEmpty()) {
            bridge.processDisplayUnits(jsonStrings)
        }
        return null
    }

    private fun toCleverTapDisplayUnit(rawJson: String): Any? = try {
        val obj = JSONObject(rawJson)
        Class.forName("com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit")
            .getMethod("toDisplayUnit", JSONObject::class.java)
            .invoke(null, obj)
    } catch (t: Throwable) {
        Log.w(TAG, "toDisplayUnit conversion failed: ${t.message}")
        null
    }

    private companion object {
        private const val TAG = "NDCacheImpl"
    }
}
