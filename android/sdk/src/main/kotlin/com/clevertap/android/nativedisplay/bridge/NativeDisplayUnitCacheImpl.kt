package com.clevertap.android.nativedisplay.bridge

import android.util.Log
import java.lang.reflect.Proxy
import org.json.JSONArray
import org.json.JSONObject

/**
 * Owns the in-memory store of [NativeDisplayUnit]s for the bridge **and**
 * exposes itself as Core SDK's `DisplayUnitCache` interface (when present at
 * runtime) so that `pushDisplayUnit*EventForID` lookups resolve through the
 * same data.
 *
 * Single source of truth — no duplicate storage between this class and
 * [NativeDisplayBridge]. The bridge holds one instance and delegates its
 * storage operations here; the proxy returned by [asProxy] also reads from
 * the same map, so Core SDK and ND SDK agree on what is cached.
 *
 * Thread-safe: all reads/writes guarded by an internal lock.
 */
internal class NativeDisplayUnitCacheImpl {

    private val cache = LinkedHashMap<String, NativeDisplayUnit>()
    private val lock = Any()

    // -- Bridge-facing storage primitives --

    /** Replace the entire cache with the supplied units, keyed by `unitId`. */
    fun replaceAll(units: List<NativeDisplayUnit>) {
        synchronized(lock) {
            cache.clear()
            for (unit in units) cache[unit.unitId] = unit
        }
    }

    /** Add or update a single entry (does not clear other entries). */
    fun put(unit: NativeDisplayUnit) {
        synchronized(lock) { cache[unit.unitId] = unit }
    }

    /** @return the unit with [unitId], or null if absent. */
    fun get(unitId: String): NativeDisplayUnit? = synchronized(lock) { cache[unitId] }

    /** @return a snapshot list of all units. */
    fun getAll(): List<NativeDisplayUnit> = synchronized(lock) { cache.values.toList() }

    /** @return current number of units. */
    fun size(): Int = synchronized(lock) { cache.size }

    /** Empty the cache. */
    fun clear() {
        synchronized(lock) { cache.clear() }
    }

    // -- Core SDK adapter --

    /**
     * Returns a JDK [Proxy] implementing
     * `com.clevertap.android.sdk.displayunits.DisplayUnitCache` when that
     * type is present on the classpath, else null. The proxy reads from this
     * instance's storage and forwards server-driven [updateDisplayUnits]
     * calls (and [reset] calls) through the supplied callbacks so that the
     * bridge's parser and listener machinery still fire.
     */
    fun asProxy(
        onServerUpdate: (JSONArray) -> Unit,
        onReset: () -> Unit
    ): Any? {
        val ifaceClass = try {
            Class.forName("com.clevertap.android.sdk.displayunits.DisplayUnitCache")
        } catch (_: ClassNotFoundException) {
            return null
        }
        return Proxy.newProxyInstance(ifaceClass.classLoader, arrayOf(ifaceClass)) { proxy, method, args ->
            try {
                when (method.name) {
                    "getDisplayUnitForID" -> resolveAsCt(args?.firstOrNull() as? String)
                    "getAllDisplayUnits" -> allAsCt()
                    "updateDisplayUnits" -> {
                        (args?.firstOrNull() as? JSONArray)?.let(onServerUpdate); null
                    }
                    "reset" -> { onReset(); null }
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

    private fun resolveAsCt(unitId: String?): Any? {
        if (unitId.isNullOrEmpty()) return null
        return get(unitId)?.rawJson?.let(::toCleverTapDisplayUnit)
    }

    private fun allAsCt(): Any? {
        val units = getAll().mapNotNull { it.rawJson?.let(::toCleverTapDisplayUnit) }
        return if (units.isEmpty()) null else ArrayList(units)
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
