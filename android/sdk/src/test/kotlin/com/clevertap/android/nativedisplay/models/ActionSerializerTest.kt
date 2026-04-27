package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Test

class ActionSerializerTest {

    private val json = Json { ignoreUnknownKeys = true }

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
