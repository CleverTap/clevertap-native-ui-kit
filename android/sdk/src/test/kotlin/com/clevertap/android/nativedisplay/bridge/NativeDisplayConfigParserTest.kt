package com.clevertap.android.nativedisplay.bridge

import com.clevertap.android.nativedisplay.models.ElementType
import com.clevertap.android.nativedisplay.models.NativeDisplayElement
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Tests for [NativeDisplayConfigParser] covering all three parsing strategies,
 * error handling, and custom_kv extraction.
 */

class NativeDisplayConfigParserTest {

    private lateinit var parser: NativeDisplayConfigParser

    @Before
    fun setUp() {
        parser = NativeDisplayConfigParser()
    }

    // -- Strategy 1: native_display_config key --

    @Test
    fun `tryParse with native_display_config key returns correct unit`() {
        val json = """
            {
                "wzrk_id": "unit_1",
                "slot_id": "hero_banner",
                "type": "native_display",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "Hello" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                },
                "custom_kv": { "key1": "value1" }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertEquals("unit_1", unit!!.unitId)
        assertEquals("hero_banner", unit.slotId)
        assertNotNull(unit.config)
        assertTrue(unit.config.root is NativeDisplayElement)
        val root = unit.config.root as NativeDisplayElement
        assertEquals(ElementType.TEXT, root.elementType)
        assertEquals("Hello", root.bindings["text"])
        assertEquals("value1", unit.customExtras["key1"])
    }

    // -- Root-level slot_id --

    @Test
    fun `tryParse without slot_id leaves slotId null`() {
        val json = """
            {
                "wzrk_id": "unit_no_slot",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "NoSlot" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertNull(unit!!.slotId)
    }

    @Test
    fun `tryParse normalises empty slot_id to null`() {
        val json = """
            {
                "wzrk_id": "unit_empty_slot",
                "slot_id": "",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "EmptySlot" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertNull(unit!!.slotId)
    }

    @Test
    fun `tryParse ignores slot_id nested under custom_kv`() {
        // Old contract — slot_id used to live under custom_kv. New contract puts it at the root.
        val json = """
            {
                "wzrk_id": "unit_legacy_slot",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "LegacySlot" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                },
                "custom_kv": { "slot_id": "legacy_slot" }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertNull(unit!!.slotId)
    }

    // -- Strategy 2: custom_kv.nd_config fallback --

    @Test
    fun `tryParse with custom_kv nd_config fallback parses correctly`() {
        // The nd_config value is a JSON string (escaped) inside custom_kv
        val ndConfigString = """{"root":{"type":"element","id":"txt1","elementType":"text","bindings":{"text":"FromKV"},"layout":{"width":{"special":"match_parent"},"height":{"special":"wrap_content"}}}}"""
        // Manually escape the JSON string for embedding inside another JSON string
        val escapedNdConfig = ndConfigString
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
        val json = """
            {
                "wzrk_id": "unit_2",
                "custom_kv": {
                    "nd_config": "$escapedNdConfig",
                    "extra_key": "extra_value"
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertEquals("unit_2", unit!!.unitId)
        assertTrue(unit.config.root is NativeDisplayElement)
        val root = unit.config.root as NativeDisplayElement
        assertEquals("FromKV", root.bindings["text"])
    }

    // -- Strategy 3: root key fallback --

    @Test
    fun `tryParse with root key fallback parses entire JSON as config`() {
        val json = """
            {
                "wzrk_id": "unit_3",
                "root": {
                    "type": "element",
                    "id": "txt1",
                    "elementType": "text",
                    "bindings": { "text": "RootFallback" },
                    "layout": {
                        "width": { "special": "match_parent" },
                        "height": { "special": "wrap_content" }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertEquals("unit_3", unit!!.unitId)
        assertTrue(unit.config.root is NativeDisplayElement)
        val root = unit.config.root as NativeDisplayElement
        assertEquals("RootFallback", root.bindings["text"])
    }

    // -- Non-ND unit --

    @Test
    fun `tryParse with non-ND display unit returns null`() {
        // Old-style display unit with content array but no ND config
        val json = """
            {
                "wzrk_id": "old_unit",
                "type": "display",
                "content": [
                    { "title": { "text": "Hello" }, "message": { "text": "World" } }
                ]
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNull(unit)
    }

    // -- Missing wzrk_id --

    @Test
    fun `tryParse without wzrk_id returns null`() {
        val json = """
            {
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "NoId" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNull(unit)
    }

    // -- Malformed JSON --

    @Test
    fun `tryParse with malformed JSON returns null`() {
        val unit = parser.tryParse("{ not valid json !!!")

        assertNull(unit)
    }

    @Test
    fun `tryParse with empty string returns null`() {
        val unit = parser.tryParse("")

        assertNull(unit)
    }

    // -- Missing root --

    @Test
    fun `tryParse with native_display_config but null root returns null`() {
        val json = """
            {
                "wzrk_id": "unit_no_root",
                "native_display_config": {}
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNull(unit)
    }

    // -- custom_kv extraction --

    @Test
    fun `tryParse extracts all custom_kv entries including nd_config`() {
        val json = """
            {
                "wzrk_id": "unit_extras",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "Hi" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                },
                "custom_kv": {
                    "key_a": "val_a",
                    "key_b": "val_b",
                    "nd_config": "some_string"
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertEquals(3, unit!!.customExtras.size)
        assertEquals("val_a", unit.customExtras["key_a"])
        assertEquals("val_b", unit.customExtras["key_b"])
        assertEquals("some_string", unit.customExtras["nd_config"])
    }

    @Test
    fun `tryParse with no custom_kv returns empty extras map`() {
        val json = """
            {
                "wzrk_id": "unit_no_kv",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "Hi" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertTrue(unit!!.customExtras.isEmpty())
    }

    @Test
    fun `tryParse retains rawJson`() {
        val json = """
            {
                "wzrk_id": "unit_raw",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "Hello" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertEquals(json, unit!!.rawJson)
    }

    @Test
    fun `tryParse strategy 1 takes precedence over strategy 3`() {
        // JSON has both native_display_config AND root key
        val json = """
            {
                "wzrk_id": "unit_both",
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt_from_nd",
                        "elementType": "text",
                        "bindings": { "text": "FromND" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                },
                "root": {
                    "type": "element",
                    "id": "txt_from_root",
                    "elementType": "text",
                    "bindings": { "text": "FromRoot" },
                    "layout": {
                        "width": { "special": "match_parent" },
                        "height": { "special": "wrap_content" }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        // Strategy 1 (native_display_config) should win
        val root = unit!!.config.root as NativeDisplayElement
        assertEquals("FromND", root.bindings["text"])
    }

    @Test
    fun `tryParse ignores unknown keys in JSON`() {
        val json = """
            {
                "wzrk_id": "unit_unknown",
                "some_unknown_field": 42,
                "native_display_config": {
                    "root": {
                        "type": "element",
                        "id": "txt1",
                        "elementType": "text",
                        "bindings": { "text": "Hello" },
                        "layout": {
                            "width": { "special": "match_parent" },
                            "height": { "special": "wrap_content" }
                        }
                    }
                }
            }
        """.trimIndent()

        val unit = parser.tryParse(json)

        assertNotNull(unit)
        assertEquals("unit_unknown", unit!!.unitId)
    }
}
