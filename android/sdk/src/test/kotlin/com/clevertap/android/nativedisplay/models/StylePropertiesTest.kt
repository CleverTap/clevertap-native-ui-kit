package com.clevertap.android.nativedisplay.models

import org.junit.Assert.*
import org.junit.Test

class StylePropertiesTest {

    @Test
    fun `extractTextProperties returns correct properties`() {
        val style = Style(
            textColor = "#000000",
            fontSize = 16f,
            fontWeight = FontWeight.BOLD,
            fontFamily = "Arial",
            lineHeight = 24f,
            textDecoration = TextDecoration.UNDERLINE,
            textAlign = "center",
            opacity = 0.9f,
            // Non-text properties (should not appear in text props)
            borderRadius = 8f,
            backgroundColor = "#FFFFFF"
        )

        val textProps = style.extractTextProperties()

        assertEquals("#000000", textProps.color)
        assertEquals(16f, textProps.size)
        assertEquals(FontWeight.BOLD, textProps.weight)
        assertEquals("Arial", textProps.family)
        assertEquals(24f, textProps.lineHeight)
        assertEquals(TextDecoration.UNDERLINE, textProps.decoration)
        assertEquals("center", textProps.align)
        assertEquals(0.9f, textProps.opacity)
    }

    @Test
    fun `extractTextProperties handles null values`() {
        val style = Style.EMPTY

        val textProps = style.extractTextProperties()

        assertNull(textProps.color)
        assertNull(textProps.size)
        assertNull(textProps.weight)
        assertNull(textProps.family)
        assertNull(textProps.lineHeight)
        assertNull(textProps.decoration)
        assertNull(textProps.align)
        assertNull(textProps.opacity)
    }

    @Test
    fun `extractVisualProperties returns correct properties`() {
        val background = Background.Solid(color = "#FF0000")
        val style = Style(
            background = background,
            backgroundColor = "#FFFFFF",
            opacity = 0.8f,
            // Non-visual properties (should not appear in visual props)
            fontSize = 16f,
            borderRadius = 8f
        )

        val visualProps = style.extractVisualProperties()

        assertEquals(background, visualProps.background)
        assertEquals("#FFFFFF", visualProps.backgroundColor)
        assertEquals(0.8f, visualProps.opacity)
    }

    @Test
    fun `extractVisualProperties handles null values`() {
        val style = Style.EMPTY

        val visualProps = style.extractVisualProperties()

        assertNull(visualProps.background)
        assertNull(visualProps.backgroundColor)
        assertNull(visualProps.opacity)
    }

    @Test
    fun `extractBorderProperties returns correct properties`() {
        val style = Style(
            borderRadius = 12f,
            borderWidth = 2f,
            borderColor = "#CCCCCC",
            // Non-border properties (should not appear in border props)
            fontSize = 16f,
            backgroundColor = "#FFFFFF"
        )

        val borderProps = style.extractBorderProperties()

        assertEquals(12f, borderProps.radius)
        assertEquals(2f, borderProps.width)
        assertEquals("#CCCCCC", borderProps.color)
    }

    @Test
    fun `extractBorderProperties handles null values`() {
        val style = Style.EMPTY

        val borderProps = style.extractBorderProperties()

        assertNull(borderProps.radius)
        assertNull(borderProps.width)
        assertNull(borderProps.color)
    }

    @Test
    fun `extractShadowProperties returns correct properties`() {
        val style = Style(
            shadowColor = "#000000",
            shadowRadius = 4f,
            shadowOffsetX = 2f,
            shadowOffsetY = 3f,
            // Non-shadow properties (should not appear in shadow props)
            fontSize = 16f,
            backgroundColor = "#FFFFFF"
        )

        val shadowProps = style.extractShadowProperties()

        assertEquals("#000000", shadowProps.color)
        assertEquals(4f, shadowProps.radius)
        assertEquals(2f, shadowProps.offsetX)
        assertEquals(3f, shadowProps.offsetY)
    }

    @Test
    fun `extractShadowProperties handles null values`() {
        val style = Style.EMPTY

        val shadowProps = style.extractShadowProperties()

        assertNull(shadowProps.color)
        assertNull(shadowProps.radius)
        assertNull(shadowProps.offsetX)
        assertNull(shadowProps.offsetY)
    }

    @Test
    fun `property extraction does not leak properties between groups`() {
        val style = Style(
            // Text properties
            textColor = "#000000",
            fontSize = 16f,
            // Visual properties
            backgroundColor = "#FFFFFF",
            opacity = 0.9f,
            // Border properties
            borderRadius = 8f,
            borderWidth = 2f,
            borderColor = "#CCCCCC",
            // Shadow properties
            shadowColor = "#000000",
            shadowRadius = 4f,
            shadowOffsetX = 2f,
            shadowOffsetY = 3f
        )

        val textProps = style.extractTextProperties()
        val visualProps = style.extractVisualProperties()
        val borderProps = style.extractBorderProperties()
        val shadowProps = style.extractShadowProperties()

        // Verify text properties are isolated
        assertEquals("#000000", textProps.color)
        assertEquals(16f, textProps.size)
        assertEquals(0.9f, textProps.opacity) // opacity is universal

        // Verify visual properties are isolated
        assertEquals("#FFFFFF", visualProps.backgroundColor)
        assertEquals(0.9f, visualProps.opacity) // opacity is universal
        assertNull(visualProps.background)

        // Verify border properties are isolated
        assertEquals(8f, borderProps.radius)
        assertEquals(2f, borderProps.width)
        assertEquals("#CCCCCC", borderProps.color)

        // Verify shadow properties are isolated
        assertEquals("#000000", shadowProps.color)
        assertEquals(4f, shadowProps.radius)
        assertEquals(2f, shadowProps.offsetX)
        assertEquals(3f, shadowProps.offsetY)
    }

    @Test
    fun `TextProperties DEFAULT has sensible defaults`() {
        val defaults = TextProperties.DEFAULT

        assertNull(defaults.color)
        assertEquals(14f, defaults.size)
        assertNull(defaults.family)
        assertNull(defaults.weight)
        assertNull(defaults.lineHeight)
        assertNull(defaults.decoration)
        assertNull(defaults.align)
        assertNull(defaults.opacity)
    }

    @Test
    fun `VisualProperties EMPTY has all null values`() {
        val empty = VisualProperties.EMPTY

        assertNull(empty.background)
        assertNull(empty.backgroundColor)
        assertNull(empty.opacity)
    }

    @Test
    fun `BorderProperties EMPTY has all null values`() {
        val empty = BorderProperties.EMPTY

        assertNull(empty.radius)
        assertNull(empty.width)
        assertNull(empty.color)
    }

    @Test
    fun `ShadowProperties EMPTY has all null values`() {
        val empty = ShadowProperties.EMPTY

        assertNull(empty.color)
        assertNull(empty.radius)
        assertNull(empty.offsetX)
        assertNull(empty.offsetY)
    }

    @Test
    fun `extraction preserves partial property sets`() {
        // Test that extraction works correctly when only some properties are set
        val style = Style(
            textColor = "#000000",
            // fontSize is null
            fontWeight = FontWeight.BOLD,
            backgroundColor = "#FFFFFF"
            // borderRadius is null
        )

        val textProps = style.extractTextProperties()
        assertEquals("#000000", textProps.color)
        assertNull(textProps.size)
        assertEquals(FontWeight.BOLD, textProps.weight)

        val visualProps = style.extractVisualProperties()
        assertEquals("#FFFFFF", visualProps.backgroundColor)
        assertNull(visualProps.background)

        val borderProps = style.extractBorderProperties()
        assertNull(borderProps.radius)
        assertNull(borderProps.width)
    }
}
