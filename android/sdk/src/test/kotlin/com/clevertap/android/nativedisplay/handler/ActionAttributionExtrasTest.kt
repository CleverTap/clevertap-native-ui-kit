package com.clevertap.android.nativedisplay.handler

import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.models.ExecutionMode
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for [ActionAttributionExtras] — the pure helper that turns an [Action] into
 * a flat property bag for the Core SDK's `pushDisplayUnit*EventForID(unitId, HashMap)` overload.
 */
class ActionAttributionExtrasTest {

    @Test
    fun `from with null action returns empty map`() {
        val extras = ActionAttributionExtras.from(action = null)
        assertTrue(extras.isEmpty())
    }

    @Test
    fun `from open_url emits url and browser flag`() {
        val action = Action.OpenUrl(
            url = "https://example.com",
            openInBrowser = true,
            customTabsEnabled = false
        )
        val extras = ActionAttributionExtras.from(action)

        assertEquals("open_url", extras["action_type"])
        assertEquals("https://example.com", extras["action_url"])
        assertEquals(true, extras["action_open_in_browser"])
        assertFalse(extras.containsKey("wzrk_btn_id"))
    }

    @Test
    fun `from custom_action spreads JsonObject value entries verbatim`() {
        val action = Action.CustomAction(
            key = "kv",
            value = buildJsonObject {
                put("sku", "SKU-123")
                put("qty", 2)
            },
            metadata = mapOf("campaign" to "summer", "tier" to "gold")
        )
        val extras = ActionAttributionExtras.from(action)

        assertEquals("custom", extras["action_type"])
        assertEquals("kv", extras["action_key"])
        // Value entries land as first-class extras (no stringified action_value blob).
        assertFalse(
            "action_value should not be set when value is a JsonObject",
            extras.containsKey("action_value")
        )
        assertEquals("SKU-123", extras["sku"])
        assertEquals(2L, extras["qty"])
        // metadata entries continue to spread verbatim alongside value entries
        assertEquals("summer", extras["campaign"])
        assertEquals("gold", extras["tier"])
    }

    @Test
    fun `from custom_action metadata wins on key collision with value entries`() {
        val action = Action.CustomAction(
            key = "kv",
            value = buildJsonObject {
                put("user_id", "from-value")
                put("only_in_value", "v")
            },
            metadata = mapOf("user_id" to "from-meta", "only_in_meta" to "m")
        )
        val extras = ActionAttributionExtras.from(action)

        // metadata is spread AFTER value entries → last-write-wins on collision
        assertEquals("from-meta", extras["user_id"])
        // non-colliding entries from both sides are preserved
        assertEquals("v", extras["only_in_value"])
        assertEquals("m", extras["only_in_meta"])
    }

    @Test
    fun `from custom_action with empty JsonObject value emits no spread entries`() {
        val action = Action.CustomAction(
            key = "kv",
            value = buildJsonObject { },
            metadata = null
        )
        val extras = ActionAttributionExtras.from(action)

        assertEquals("custom", extras["action_type"])
        assertEquals("kv", extras["action_key"])
        assertFalse(
            "Empty JsonObject value should not emit action_value",
            extras.containsKey("action_value")
        )
        // Exactly the reserved keys, nothing else.
        assertEquals(
            setOf("action_type", "action_key"),
            extras.keys
        )
    }

    @Test
    fun `from custom_action scalar value round-trips as native type`() {
        val action = Action.CustomAction(
            key = "amount",
            value = JsonPrimitive(42),
            metadata = null
        )
        val extras = ActionAttributionExtras.from(action)
        assertEquals(42L, extras["action_value"])
    }

    @Test
    fun `from custom_action metadata spreads BE-injected wzrk attribution fields`() {
        val action = Action.CustomAction(
            key = "kv",
            value = buildJsonObject { },
            metadata = mapOf(
                "wzrk_element_id" to "btn_hero",
                "wzrk_c2a" to "Buy Now",
                "wzrk_act" to "click"
            )
        )
        val extras = ActionAttributionExtras.from(action)

        // BE-injected wzrk_* fields arrive via metadata and flow through as-is
        assertEquals("btn_hero", extras["wzrk_element_id"])
        assertEquals("Buy Now", extras["wzrk_c2a"])
        assertEquals("click", extras["wzrk_act"])
    }

    @Test
    fun `from navigate emits destination and spreads params`() {
        val action = Action.Navigate(
            destination = "profile",
            params = mapOf("user_id" to "u-1")
        )
        val extras = ActionAttributionExtras.from(action)
        assertEquals("navigate", extras["action_type"])
        assertEquals("profile", extras["action_destination"])
        assertEquals("u-1", extras["user_id"])
        assertFalse(extras.containsKey("wzrk_btn_id"))
    }

    @Test
    fun `from track_event emits event name and spreads properties`() {
        val action = Action.TrackEvent(
            eventName = "Banner Tapped",
            properties = mapOf(
                "position" to JsonPrimitive(3),
                "is_hero" to JsonPrimitive(true)
            )
        )
        val extras = ActionAttributionExtras.from(action)
        assertEquals("Banner Tapped", extras["action_event_name"])
        assertEquals(3L, extras["position"])
        assertEquals(true, extras["is_hero"])
    }

    @Test
    fun `from composite emits count and mode`() {
        val action = Action.CompositeAction(
            actions = listOf(
                Action.OpenUrl("https://a", false, true),
                Action.Navigate("home", null)
            ),
            executionMode = ExecutionMode.PARALLEL
        )
        val extras = ActionAttributionExtras.from(action)
        assertEquals(2, extras["action_count"])
        assertEquals("parallel", extras["action_mode"])
    }

    // sanitize

    @Test
    fun `sanitize on null input returns only the ND lib version stamp`() {
        val out = ActionAttributionExtras.sanitize(null)
        assertEquals(BuildConfig.ND_LIB_VERSION_NAME, out["nd_lib_v_name"])
        assertEquals(BuildConfig.ND_LIB_VERSION_CODE, out["nd_lib_v_code"])
        assertEquals(setOf("nd_lib_v_name", "nd_lib_v_code"), out.keys)
    }

    @Test
    fun `sanitize on empty input returns only the ND lib version stamp`() {
        val out = ActionAttributionExtras.sanitize(emptyMap())
        assertEquals(BuildConfig.ND_LIB_VERSION_NAME, out["nd_lib_v_name"])
        assertEquals(BuildConfig.ND_LIB_VERSION_CODE, out["nd_lib_v_code"])
        assertEquals(setOf("nd_lib_v_name", "nd_lib_v_code"), out.keys)
    }

    @Test
    fun `sanitize keeps scalars and collections drops nulls and empty keys`() {
        val input: Map<String, Any?> = mapOf(
            "s" to "x",
            "i" to 1,
            "b" to true,
            "n" to null,
            "" to "ignored",
            "arr" to listOf(1, 2, 3),
            "obj" to mapOf("k" to "v")
        )
        val out = ActionAttributionExtras.sanitize(input)
        assertEquals("x", out["s"])
        assertEquals(1, out["i"])
        assertEquals(true, out["b"])
        assertFalse(out.containsKey("n"))
        assertFalse(out.containsKey(""))
        assertEquals(listOf(1, 2, 3), out["arr"])
        assertEquals(mapOf("k" to "v"), out["obj"])
        // Version stamp is always present alongside caller-supplied keys.
        assertEquals(BuildConfig.ND_LIB_VERSION_NAME, out["nd_lib_v_name"])
        assertEquals(BuildConfig.ND_LIB_VERSION_CODE, out["nd_lib_v_code"])
    }

    @Test
    fun `sanitize does not overwrite caller-supplied version keys`() {
        val input: Map<String, Any?> = mapOf(
            "nd_lib_v_name" to "caller-wins",
            "nd_lib_v_code" to 999_999
        )
        val out = ActionAttributionExtras.sanitize(input)
        assertEquals("caller-wins", out["nd_lib_v_name"])
        assertEquals(999_999, out["nd_lib_v_code"])
    }

    // versionStamp

    @Test
    fun `versionStamp returns exactly the ND lib version keys`() {
        val out = ActionAttributionExtras.versionStamp()
        assertEquals(BuildConfig.ND_LIB_VERSION_NAME, out["nd_lib_v_name"])
        assertEquals(BuildConfig.ND_LIB_VERSION_CODE, out["nd_lib_v_code"])
        assertEquals(setOf("nd_lib_v_name", "nd_lib_v_code"), out.keys)
    }
}
