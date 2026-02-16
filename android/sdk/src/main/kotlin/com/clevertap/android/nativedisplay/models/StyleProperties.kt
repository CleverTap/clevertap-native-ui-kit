package com.clevertap.android.nativedisplay.models

/**
 * Text styling properties extracted from Style.
 * Used internally by renderer for text elements (TEXT, BUTTON).
 *
 * Contains all text-related properties that cascade through the style hierarchy:
 * - color: Text color in hex format
 * - size: Font size in SP
 * - family: Font family name
 * - weight: Font weight (NORMAL, BOLD, etc.)
 * - style: Font style (NORMAL, ITALIC)
 * - lineHeight: Line height in SP
 * - letterSpacing: Letter spacing in SP
 * - decoration: Text decoration (UNDERLINE, LINE_THROUGH, etc.)
 * - align: Text alignment (LEFT, CENTER, RIGHT, JUSTIFY)
 * - maxLines: Maximum number of lines before truncation
 * - overflow: Text overflow behavior (CLIP, ELLIPSIS, VISIBLE)
 * - textShadow: Drop shadow effect on text
 * - textGradient: Gradient effect on text
 * - opacity: Text opacity (0.0 to 1.0)
 */
data class TextProperties(
    val color: String?,
    val size: Float?,
    val family: String?,
    val weight: FontWeight?,
    val style: FontStyle?,
    val lineHeight: Float?,
    val letterSpacing: Float?,
    val decoration: TextDecoration?,
    val align: String?,
    val maxLines: Int?,
    val overflow: TextOverflow?,
    val textShadow: TextShadow?,
    val textGradient: TextGradient?,
    val opacity: Float?
) {
    companion object {
        /**
         * Default text properties with sensible defaults.
         * Used as fallback when properties are not specified.
         */
        val DEFAULT = TextProperties(
            color = null,
            size = 14f,
            family = null,
            weight = null,
            style = null,
            lineHeight = null,
            letterSpacing = null,
            decoration = null,
            align = null,
            maxLines = null,
            overflow = null,
            textShadow = null,
            textGradient = null,
            opacity = null
        )
    }
}

/**
 * Visual styling properties for containers and visual elements.
 * Used internally by renderer for background and opacity.
 *
 * Contains non-cascading visual properties:
 * - background: Complex background (gradients, images, animations)
 * - backgroundColor: Simple solid background color
 * - opacity: Element opacity (0.0 to 1.0)
 */
data class VisualProperties(
    val background: Background?,
    val backgroundColor: String?,
    val opacity: Float?
) {
    companion object {
        /**
         * Empty visual properties (no background, no opacity).
         */
        val EMPTY = VisualProperties(
            background = null,
            backgroundColor = null,
            opacity = null
        )
    }
}

/**
 * Border styling properties.
 * Used internally by applyDecorations for rendering borders.
 *
 * Contains border-related properties:
 * - radius: Border radius in DP (rounded corners)
 * - width: Border width in DP (stroke thickness)
 * - color: Border color in hex format
 */
data class BorderProperties(
    val radius: Float?,
    val width: Float?,
    val color: String?
) {
    companion object {
        /**
         * Empty border properties (no border).
         */
        val EMPTY = BorderProperties(
            radius = null,
            width = null,
            color = null
        )
    }
}

/**
 * Shadow styling properties.
 * Used internally by applyDecorations for rendering shadows.
 *
 * Contains shadow-related properties:
 * - color: Shadow color in hex format
 * - radius: Shadow blur radius in DP
 * - offsetX: Horizontal shadow offset in DP
 * - offsetY: Vertical shadow offset in DP
 */
data class ShadowProperties(
    val color: String?,
    val radius: Float?,
    val offsetX: Float?,
    val offsetY: Float?
) {
    companion object {
        /**
         * Empty shadow properties (no shadow).
         */
        val EMPTY = ShadowProperties(
            color = null,
            radius = null,
            offsetX = null,
            offsetY = null
        )
    }
}
