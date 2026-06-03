package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Test

class ActionSerializerTest {

    private val json = Json { ignoreUnknownKeys = true }

    // ── metadata: string values ──────────────────────────────────────────────

    @Test
    fun `CustomAction metadata string values are preserved as-is`() {
        val input = """
            {
              "type": "custom", "key": "kv",
              "value": {"key1": "v1"},
              "metadata": {
                "wzrk_element_id": "button-1",
                "wzrk_c2a": "KV Button",
                "wzrk_act": "kv"
              }
            }
        """.trimIndent()
        val action = json.decodeFromString<Action>(input) as Action.CustomAction
        assertEquals("button-1", action.metadata?.get("wzrk_element_id"))
        assertEquals("KV Button", action.metadata?.get("wzrk_c2a"))
        assertEquals("kv", action.metadata?.get("wzrk_act"))
    }

    // ── metadata: wzrk_data as JSON object ───────────────────────────────────

    @Test
    fun `CustomAction metadata wzrk_data object is serialized to JSON string`() {
        // BE sends wzrk_data as a JSON object — SDK must convert to a JSON string, not crash
        val input = """
            {
              "type": "custom", "key": "kv",
              "value": {"key1": "value1", "key2": "value2", "key3": "value3"},
              "metadata": {
                "wzrk_element_id": "button-1",
                "wzrk_c2a": "KV Button",
                "wzrk_act": "kv",
                "wzrk_data": {"key1": "value1 default@email.com", "key2": "value2", "key3": "value3"}
              }
            }
        """.trimIndent()
        val action = json.decodeFromString<Action>(input) as Action.CustomAction

        // Primitive metadata values are plain strings
        assertEquals("button-1", action.metadata?.get("wzrk_element_id"))
        assertEquals("kv", action.metadata?.get("wzrk_act"))

        // wzrk_data (a JSON object) is stored as a compact JSON string
        val wzrkData = action.metadata?.get("wzrk_data")
        assertNotNull(wzrkData)
        // Must be a valid JSON string, not the raw BSON/object
        assertEquals("""{"key1":"value1 default@email.com","key2":"value2","key3":"value3"}""", wzrkData)
    }

    @Test
    fun `OpenUrl metadata wzrk_data object is serialized to JSON string`() {
        val input = """
            {
              "type": "open_url",
              "url": {"android": "https://www.amazon.in", "ios": "https://www.amazon.com"},
              "metadata": {
                "wzrk_element_id": "button-2",
                "wzrk_c2a": "Open url",
                "wzrk_act": "url",
                "wzrk_data": {"android": "https://www.amazon.in", "ios": "https://www.amazon.com"}
              }
            }
        """.trimIndent()
        val action = json.decodeFromString<Action>(input) as Action.OpenUrl

        assertEquals("https://www.amazon.in", action.url)
        assertEquals("button-2", action.metadata?.get("wzrk_element_id"))
        assertEquals("url", action.metadata?.get("wzrk_act"))

        val wzrkData = action.metadata?.get("wzrk_data")
        assertNotNull(wzrkData)
        assertEquals("""{"android":"https://www.amazon.in","ios":"https://www.amazon.com"}""", wzrkData)
    }

    @Test
    fun `metadata null JSON value is dropped from map`() {
        val input = """
            {
              "type": "custom", "key": "close", "value": true,
              "metadata": {"wzrk_act": "close", "phantom": null}
            }
        """.trimIndent()
        val action = json.decodeFromString<Action>(input) as Action.CustomAction
        assertEquals("close", action.metadata?.get("wzrk_act"))
        assertFalse(action.metadata?.containsKey("phantom") ?: false)
    }

    @Test
    fun `OpenUrl deserializes plain string url`() {
        val input = """{"type": "open_url", "url": "https://www.google.com"}"""
        val action = json.decodeFromString<Action>(input)

        val openUrl = action as Action.OpenUrl
        assertEquals("https://www.google.com", openUrl.url)
    }

    @Test
    fun `OpenUrl deserializes platform object url with android key`() {
        val input = """{"type": "open_url", "url": {"android": "https://play.google.com", "ios": "https://apps.apple.com"}}"""
        val action = json.decodeFromString<Action>(input)

        val openUrl = action as Action.OpenUrl
        assertEquals("https://play.google.com", openUrl.url)
    }

    @Test
    fun `OpenUrl defaults to empty string when android key missing from platform object`() {
        val input = """{"type": "open_url", "url": {"ios": "https://apps.apple.com"}}"""
        val action = json.decodeFromString<Action>(input)

        val openUrl = action as Action.OpenUrl
        assertEquals("", openUrl.url)
    }

    @Test
    fun `OpenUrl preserves other fields with platform object url`() {
        val input = """{"type": "open_url", "url": {"android": "https://play.google.com"}, "openInBrowser": true, "customTabsEnabled": false}"""
        val action = json.decodeFromString<Action>(input)

        val openUrl = action as Action.OpenUrl
        assertEquals("https://play.google.com", openUrl.url)
        assertEquals(true, openUrl.openInBrowser)
        assertEquals(false, openUrl.customTabsEnabled)
    }

    @Test
    fun `OpenUrl preserves other fields with plain string url`() {
        val input = """{"type": "open_url", "url": "https://example.com", "openInBrowser": true}"""
        val action = json.decodeFromString<Action>(input)

        val openUrl = action as Action.OpenUrl
        assertEquals("https://example.com", openUrl.url)
        assertEquals(true, openUrl.openInBrowser)
    }
}
