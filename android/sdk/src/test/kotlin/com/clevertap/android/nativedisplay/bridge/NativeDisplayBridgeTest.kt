package com.clevertap.android.nativedisplay.bridge

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Tests for [NativeDisplayBridge] covering cache management, listener notification,
 * and singleton behavior.
 */
class NativeDisplayBridgeTest {

    private lateinit var bridge: NativeDisplayBridge

    /**
     * Minimal valid display unit JSON for testing.
     * Uses strategy 1 (native_display_config key).
     */
    private fun makeUnitJson(unitId: String, text: String = "Hello"): String = """
        {
            "wzrk_id": "$unitId",
            "native_display_config": {
                "root": {
                    "type": "element",
                    "id": "txt_$unitId",
                    "elementType": "text",
                    "bindings": { "text": "$text" },
                    "layout": {
                        "width": { "special": "match_parent" },
                        "height": { "special": "wrap_content" }
                    }
                }
            }
        }
    """.trimIndent()

    @Before
    fun setUp() {
        // Reset the singleton so each test starts fresh
        resetSingleton()
        bridge = NativeDisplayBridge.create()
    }

    @After
    fun tearDown() {
        bridge.clear()
        resetSingleton()
    }

    /**
     * Reset the singleton instance via reflection.
     * Required because [NativeDisplayBridge] uses a companion object singleton
     * and tests need isolation.
     */
    private fun resetSingleton() {
        // The @Volatile companion field is stored on the NativeDisplayBridge class itself in bytecode
        try {
            val field = NativeDisplayBridge::class.java.getDeclaredField("instance")
            field.isAccessible = true
            field.set(null, null)
        } catch (_: NoSuchFieldException) {
            // Try alternate bytecode name
            NativeDisplayBridge::class.java.declaredFields
                .firstOrNull { it.type == NativeDisplayBridge::class.java }
                ?.let {
                    it.isAccessible = true
                    it.set(null, null)
                }
        }
    }

    // -- processDisplayUnits replaces cache --

    @Test
    fun `processDisplayUnits replaces entire cache`() {
        val listA = listOf(makeUnitJson("a1"), makeUnitJson("a2"))
        bridge.processDisplayUnits(listA)
        assertEquals(2, bridge.getAllNativeDisplays().size)

        val listB = listOf(makeUnitJson("b1"))
        bridge.processDisplayUnits(listB)

        val all = bridge.getAllNativeDisplays()
        assertEquals(1, all.size)
        assertEquals("b1", all[0].unitId)
    }

    @Test
    fun `processDisplayUnits with empty list clears cache`() {
        bridge.processDisplayUnits(listOf(makeUnitJson("a1")))
        assertEquals(1, bridge.getAllNativeDisplays().size)

        bridge.processDisplayUnits(emptyList())

        assertTrue(bridge.getAllNativeDisplays().isEmpty())
    }

    // -- processDisplayUnit adds to cache --

    @Test
    fun `processDisplayUnit adds single unit to cache`() {
        bridge.processDisplayUnit(makeUnitJson("unit_1"))

        val all = bridge.getAllNativeDisplays()
        assertEquals(1, all.size)
        assertEquals("unit_1", all[0].unitId)
    }

    @Test
    fun `processDisplayUnit adds multiple units incrementally`() {
        bridge.processDisplayUnit(makeUnitJson("unit_1"))
        bridge.processDisplayUnit(makeUnitJson("unit_2"))

        val all = bridge.getAllNativeDisplays()
        assertEquals(2, all.size)
        val ids = all.map { it.unitId }.toSet()
        assertTrue(ids.contains("unit_1"))
        assertTrue(ids.contains("unit_2"))
    }

    @Test
    fun `processDisplayUnit updates existing unit with same id`() {
        bridge.processDisplayUnit(makeUnitJson("unit_1", text = "Original"))
        bridge.processDisplayUnit(makeUnitJson("unit_1", text = "Updated"))

        val all = bridge.getAllNativeDisplays()
        assertEquals(1, all.size)
        assertEquals("unit_1", all[0].unitId)
    }

    @Test
    fun `processDisplayUnit with invalid JSON does not add to cache`() {
        bridge.processDisplayUnit("{ invalid }")

        assertTrue(bridge.getAllNativeDisplays().isEmpty())
    }

    // -- getNativeDisplayForId --

    @Test
    fun `getNativeDisplayForId returns correct unit`() {
        bridge.processDisplayUnits(listOf(
            makeUnitJson("alpha"),
            makeUnitJson("beta")
        ))

        val unit = bridge.getNativeDisplayForId("beta")

        assertNotNull(unit)
        assertEquals("beta", unit!!.unitId)
    }

    @Test
    fun `getNativeDisplayForId returns null for unknown id`() {
        bridge.processDisplayUnits(listOf(makeUnitJson("alpha")))

        val unit = bridge.getNativeDisplayForId("unknown")

        assertNull(unit)
    }

    @Test
    fun `getNativeDisplayForId returns null when cache is empty`() {
        assertNull(bridge.getNativeDisplayForId("anything"))
    }

    // -- Listener notification --

    @Test
    fun `listener is notified when processDisplayUnits is called`() {
        val received = mutableListOf<List<NativeDisplayUnit>>()
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                received.add(units)
            }
        }
        bridge.addListener(listener)

        bridge.processDisplayUnits(listOf(makeUnitJson("u1"), makeUnitJson("u2")))

        assertEquals(1, received.size)
        assertEquals(2, received[0].size)
    }

    @Test
    fun `listener is notified when processDisplayUnit is called`() {
        val received = mutableListOf<List<NativeDisplayUnit>>()
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                received.add(units)
            }
        }
        bridge.addListener(listener)

        bridge.processDisplayUnit(makeUnitJson("single"))

        assertEquals(1, received.size)
        assertEquals(1, received[0].size)
        assertEquals("single", received[0][0].unitId)
    }

    @Test
    fun `listener receives correct unit ids`() {
        var receivedIds = emptyList<String>()
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                receivedIds = units.map { it.unitId }
            }
        }
        bridge.addListener(listener)

        bridge.processDisplayUnits(listOf(makeUnitJson("x"), makeUnitJson("y")))

        assertEquals(listOf("x", "y"), receivedIds)
    }

    // -- Multiple listeners --

    @Test
    fun `multiple listeners are all notified`() {
        var count1 = 0
        var count2 = 0
        val listener1 = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) { count1++ }
        }
        val listener2 = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) { count2++ }
        }
        bridge.addListener(listener1)
        bridge.addListener(listener2)

        bridge.processDisplayUnits(listOf(makeUnitJson("u1")))

        assertEquals(1, count1)
        assertEquals(1, count2)
    }

    @Test
    fun `duplicate listener registration is ignored`() {
        var callCount = 0
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) { callCount++ }
        }
        bridge.addListener(listener)
        bridge.addListener(listener) // duplicate

        bridge.processDisplayUnits(listOf(makeUnitJson("u1")))

        assertEquals(1, callCount)
    }

    // -- Remove listener --

    @Test
    fun `removed listener is not notified`() {
        var called = false
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) { called = true }
        }
        bridge.addListener(listener)
        bridge.removeListener(listener)

        bridge.processDisplayUnits(listOf(makeUnitJson("u1")))

        assertFalse(called)
    }

    @Test
    fun `removing unregistered listener is safe`() {
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {}
        }

        // Should not throw
        bridge.removeListener(listener)
    }

    // -- clear() --

    @Test
    fun `clear empties cache`() {
        bridge.processDisplayUnits(listOf(makeUnitJson("u1"), makeUnitJson("u2")))
        assertEquals(2, bridge.getAllNativeDisplays().size)

        bridge.clear()

        assertTrue(bridge.getAllNativeDisplays().isEmpty())
    }

    @Test
    fun `clear removes listeners`() {
        var called = false
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) { called = true }
        }
        bridge.addListener(listener)
        bridge.clear()

        bridge.processDisplayUnits(listOf(makeUnitJson("u1")))

        assertFalse(called)
    }

    // -- Singleton behavior --

    @Test
    fun `create returns same instance on multiple calls`() {
        val instance1 = NativeDisplayBridge.create()
        val instance2 = NativeDisplayBridge.create()

        assertSame(instance1, instance2)
    }

    @Test
    fun `getInstance returns instance after create`() {
        val created = NativeDisplayBridge.create()
        val fetched = NativeDisplayBridge.getInstance()

        assertSame(created, fetched)
    }

    @Test
    fun `getInstance returns null before create`() {
        resetSingleton()

        assertNull(NativeDisplayBridge.getInstance())
    }

    // -- Edge cases --

    @Test
    fun `processDisplayUnits skips invalid JSON entries silently`() {
        val jsons = listOf(
            makeUnitJson("valid_1"),
            "{ totally broken }",
            makeUnitJson("valid_2")
        )

        bridge.processDisplayUnits(jsons)

        val all = bridge.getAllNativeDisplays()
        assertEquals(2, all.size)
        val ids = all.map { it.unitId }.toSet()
        assertTrue(ids.contains("valid_1"))
        assertTrue(ids.contains("valid_2"))
    }

    @Test
    fun `listener exception does not prevent other listeners from being notified`() {
        var secondCalled = false
        val throwingListener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                throw RuntimeException("Listener error")
            }
        }
        val safeListener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                secondCalled = true
            }
        }
        bridge.addListener(throwingListener)
        bridge.addListener(safeListener)

        bridge.processDisplayUnits(listOf(makeUnitJson("u1")))

        assertTrue(secondCalled)
    }
}
