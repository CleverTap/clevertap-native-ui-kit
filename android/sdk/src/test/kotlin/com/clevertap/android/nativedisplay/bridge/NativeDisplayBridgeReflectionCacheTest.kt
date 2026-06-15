package com.clevertap.android.nativedisplay.bridge

import com.clevertap.android.sdk.CleverTapAPI
import java.lang.reflect.Method
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Verifies that the two per-click reflection probes inside [NativeDisplayBridge]
 * (`pushDisplayUnitElementClickedEventForID` lookup and `setDisplayUnitCache`
 * availability check) run exactly once per attached `CleverTapAPI` instance and
 * cache their results — including "method absent" — so the click hot path no
 * longer pays for reflection on every call.
 *
 * Setup notes:
 *
 * - `CleverTapAPI` has a private constructor, so the test creates an uninitialised
 *   shell via `sun.misc.Unsafe.allocateInstance(...)`. The shell never executes
 *   real Core SDK logic (and would NPE if it did) — but the bridge's reflection
 *   probes only inspect `javaClass`, and the bridge's outer try/catch swallows
 *   the inevitable NPE from `pushDisplayUnitClickedEventForID(unitId)` so each
 *   `pushClickedEvent` call returns cleanly.
 * - The bridged Core SDK 7.5.0 on the test classpath does NOT expose either
 *   probed method, so both resolvers naturally cache an "absent" result. That's
 *   the most important regression to guard against — "absent" should NOT trigger
 *   a re-probe on every click.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class NativeDisplayBridgeReflectionCacheTest {

    private lateinit var bridge: NativeDisplayBridge

    @Before
    fun setUp() {
        Dispatchers.setMain(UnconfinedTestDispatcher())
        resetSingleton()
        bridge = NativeDisplayBridge.create()
        bridge.cleverTapApi = newCleverTapShell()
    }

    @After
    fun tearDown() {
        bridge.clear()
        resetSingleton()
        Dispatchers.resetMain()
    }

    // --- element-clicked method probe ---

    @Test
    fun `element clicked method probe runs exactly once across multiple clicks`() {
        // Sanity: pre-call state is "not yet probed".
        assertFalse(
            "elementClickedResolved should start false",
            readBoolean("elementClickedResolved")
        )
        assertNull(
            "elementClickedMethod should start null",
            readMethod("elementClickedMethod")
        )

        // First click probes the class and caches the result. Core SDK 7.5.0 on the
        // test classpath has no `pushDisplayUnitElementClickedEventForID`, so the
        // resolved value is null — but the `resolved` flag flips to true.
        bridge.pushClickedEvent("unit-1", mapOf("wzrk_btn_id" to "btn"))

        assertTrue(
            "elementClickedResolved should be true after first probe",
            readBoolean("elementClickedResolved")
        )
        assertNull(
            "Core SDK 7.5.0 does not expose the element-clicked method",
            readMethod("elementClickedMethod")
        )

        // Stamp a sentinel directly into the cache. If a subsequent click re-probes,
        // the sentinel gets overwritten with null and assertSame below fails.
        val sentinel = String::class.java.getMethod("length")
        writeMethod("elementClickedMethod", sentinel)

        repeat(3) { bridge.pushClickedEvent("unit-1", mapOf("wzrk_btn_id" to "btn")) }

        assertSame(
            "Cached method must survive N subsequent clicks (no re-probe)",
            sentinel,
            readMethod("elementClickedMethod")
        )
    }

    @Test
    fun `setDisplayUnitCache probe runs exactly once across multiple clicks`() {
        assertNull(
            "setDisplayUnitCacheAvailable should start null (not yet probed)",
            readNullableBoolean("setDisplayUnitCacheAvailable")
        )

        bridge.pushClickedEvent("unit-1", mapOf("wzrk_btn_id" to "btn"))

        // Core SDK 7.5.0 has no `setDisplayUnitCache(...)` either — cache resolves false.
        assertNotNull(
            "Probe should have run and cached a result",
            readNullableBoolean("setDisplayUnitCacheAvailable")
        )

        // Flip the cache to true — a re-probe would reset it back to false.
        writeNullableBoolean("setDisplayUnitCacheAvailable", true)

        repeat(3) { bridge.pushClickedEvent("unit-1", mapOf("wzrk_btn_id" to "btn")) }

        assertSame(
            "Cached availability must survive N subsequent clicks (no re-probe)",
            true,
            readNullableBoolean("setDisplayUnitCacheAvailable")
        )
    }

    // --- cache invalidation on cleverTapApi (re)assignment ---

    @Test
    fun `reassigning cleverTapApi invalidates both caches`() {
        bridge.pushClickedEvent("unit-1", mapOf("wzrk_btn_id" to "btn"))
        assertTrue(readBoolean("elementClickedResolved"))
        assertNotNull(readNullableBoolean("setDisplayUnitCacheAvailable"))

        // Stamp sentinels so we can prove they get cleared on reassignment.
        val sentinel = String::class.java.getMethod("length")
        writeMethod("elementClickedMethod", sentinel)
        writeNullableBoolean("setDisplayUnitCacheAvailable", true)

        bridge.cleverTapApi = newCleverTapShell()

        assertFalse(
            "elementClickedResolved should reset on reassignment",
            readBoolean("elementClickedResolved")
        )
        assertNull(
            "elementClickedMethod should clear on reassignment",
            readMethod("elementClickedMethod")
        )
        assertNull(
            "setDisplayUnitCacheAvailable should clear on reassignment",
            readNullableBoolean("setDisplayUnitCacheAvailable")
        )
    }

    @Test
    fun `clearing cleverTapApi to null invalidates both caches`() {
        bridge.pushClickedEvent("unit-1", mapOf("wzrk_btn_id" to "btn"))
        writeMethod("elementClickedMethod", String::class.java.getMethod("length"))
        writeNullableBoolean("setDisplayUnitCacheAvailable", true)

        bridge.cleverTapApi = null

        assertFalse(readBoolean("elementClickedResolved"))
        assertNull(readMethod("elementClickedMethod"))
        assertNull(readNullableBoolean("setDisplayUnitCacheAvailable"))
    }

    // --- helpers ---

    /**
     * Create an uninitialised `CleverTapAPI` shell. Reflection probes work against the
     * class object (not instance state), and the bridge's outer try/catch swallows the
     * NPE thrown by the legacy fallback invocation on this uninitialised instance.
     */
    private fun newCleverTapShell(): CleverTapAPI {
        val unsafeClass = Class.forName("sun.misc.Unsafe")
        val unsafeField = unsafeClass.getDeclaredField("theUnsafe").apply {
            isAccessible = true
        }
        val unsafe = unsafeField.get(null)
        val allocateInstance = unsafeClass.getMethod("allocateInstance", Class::class.java)
        return allocateInstance.invoke(unsafe, CleverTapAPI::class.java) as CleverTapAPI
    }

    private fun readBoolean(name: String): Boolean =
        bridgeField(name).getBoolean(bridge)

    private fun readMethod(name: String): Method? =
        bridgeField(name).get(bridge) as Method?

    private fun readNullableBoolean(name: String): Boolean? =
        bridgeField(name).get(bridge) as Boolean?

    private fun writeMethod(name: String, value: Method?) {
        bridgeField(name).set(bridge, value)
    }

    private fun writeNullableBoolean(name: String, value: Boolean?) {
        bridgeField(name).set(bridge, value)
    }

    private fun bridgeField(name: String) =
        NativeDisplayBridge::class.java.getDeclaredField(name).apply { isAccessible = true }

    /**
     * Reset the bridge singleton between tests so each test sees a fresh instance.
     * Mirrors the pattern in [NativeDisplayBridgeTest].
     */
    private fun resetSingleton() {
        try {
            val field = NativeDisplayBridge::class.java.getDeclaredField("instance")
            field.isAccessible = true
            field.set(null, null)
        } catch (_: NoSuchFieldException) {
            NativeDisplayBridge::class.java.declaredFields
                .firstOrNull { it.type == NativeDisplayBridge::class.java }
                ?.let {
                    it.isAccessible = true
                    it.set(null, null)
                }
        }
    }
}
