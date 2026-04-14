package com.clevertap.android.nativedisplay.models

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable

/**
 * Style properties for visual appearance.
 *
 * ## Internal SDK Usage
 *
 * For SDK developers rendering elements, use extraction methods instead of direct property access:
 * - `extractTextProperties()` - Get text styling (color, size, weight, etc.) for TEXT/BUTTON elements
 * - `extractVisualProperties()` - Get background and opacity for all elements
 * - `extractBorderProperties()` - Get border styling for visual decorations
 * - `extractShadowProperties()` - Get shadow styling for visual decorations
 *
 * ## Property Grouping
 *
 * **Text Properties (cascading):**
 * - textColor, fontSize, fontFamily, fontWeight, lineHeight, textDecoration, textAlign
 * - Used by: TEXT, BUTTON elements
 * - Inherited by child elements in the hierarchy
 *
 * **Visual Properties (non-cascading):**
 * - background, backgroundColor
 * - Used by: All elements and containers
 * - Not inherited by children
 *
 * **Border Properties (non-cascading):**
 * - borderRadius, borderWidth, borderColor
 * - Used by: Visual decorations on all elements
 * - Not inherited by children
 *
 * **Shadow Properties (non-cascading):**
 * - shadowColor, shadowRadius, shadowOffsetX, shadowOffsetY
 * - Used by: Visual decorations on all elements
 * - Not inherited by children
 *
 * **Universal:**
 * - opacity (cascades to children)
 *
 * ## JSON Compatibility
 *
 * This class maintains full backward compatibility with existing JSON configurations.
 * All properties are nullable and optional.
 */
@Immutable
@Serializable
data class Style(
    // ==================== TEXT PROPERTIES (Cascading) ====================

    val textColor: String? = null,
    val fontSize: TextDimension? = null,
    val fontFamily: String? = null,
    val fontWeight: FontWeight? = null,
    val fontStyle: FontStyle? = null,
    val lineHeight: TextDimension? = null,
    val letterSpacing: Float? = null,
    val textDecoration: TextDecoration? = null,
    val textAlign: String? = null,  // "left", "center", "right", "justify"
    val maxLines: Int? = null,
    val overflow: TextOverflow? = null,
    val textShadow: TextShadow? = null,
    val textGradient: TextGradient? = null,

    // ==================== VISUAL PROPERTIES (Non-cascading) ====================

    val background: Background? = null,  // Rich background support (gradients, images, animations)
    val backgroundColor: String? = null,  // Simple solid color (backward compatible)

    // ==================== BORDER PROPERTIES (Non-cascading) ====================

    @Serializable(with = DimensionAsNumberSerializerNullable::class)
    val borderRadius: Dimension? = null,
    val borderWidth: Float? = null,
    val borderColor: String? = null,

    // ==================== SHADOW PROPERTIES (Non-cascading) ====================

    val shadowColor: String? = null,
    val shadowRadius: Float? = null,
    val shadowOffsetX: Float? = null,
    val shadowOffsetY: Float? = null,

    // ==================== UNIVERSAL PROPERTIES ====================

    val opacity: Float? = null
) {
    /**
     * Merge this style with another, giving priority to this style's values.
     * Used for style resolution: inline > class > inherited > theme
     */
    fun mergeWith(other: Style?): Style {
        if (other == null) return this
        
        return Style(
            textColor = textColor ?: other.textColor,
            fontSize = fontSize ?: other.fontSize,
            fontFamily = fontFamily ?: other.fontFamily,
            fontWeight = fontWeight ?: other.fontWeight,
            fontStyle = fontStyle ?: other.fontStyle,
            lineHeight = lineHeight ?: other.lineHeight,
            letterSpacing = letterSpacing ?: other.letterSpacing,
            textDecoration = textDecoration ?: other.textDecoration,
            textAlign = textAlign ?: other.textAlign,
            maxLines = maxLines ?: other.maxLines,
            overflow = overflow ?: other.overflow,
            textShadow = textShadow ?: other.textShadow,
            textGradient = textGradient ?: other.textGradient,

            background = background ?: other.background,
            backgroundColor = backgroundColor ?: other.backgroundColor,
            borderRadius = borderRadius ?: other.borderRadius,
            borderWidth = borderWidth ?: other.borderWidth,
            borderColor = borderColor ?: other.borderColor,

            shadowColor = shadowColor ?: other.shadowColor,
            shadowRadius = shadowRadius ?: other.shadowRadius,
            shadowOffsetX = shadowOffsetX ?: other.shadowOffsetX,
            shadowOffsetY = shadowOffsetY ?: other.shadowOffsetY,

            opacity = opacity ?: other.opacity
        )
    }
    
    /**
     * Extract only cascading properties (for inheritance).
     */
    fun cascadingOnly(): Style {
        return Style(
            textColor = textColor,
            fontSize = fontSize,
            fontFamily = fontFamily,
            fontWeight = fontWeight,
            fontStyle = fontStyle,
            lineHeight = lineHeight,
            letterSpacing = letterSpacing,
            textDecoration = textDecoration,
            textAlign = textAlign,
            maxLines = maxLines,
            overflow = overflow,
            textShadow = textShadow,
            textGradient = textGradient,
            opacity = opacity
        )
    }

    // ==================== PROPERTY EXTRACTION METHODS ====================

    /**
     * Extract text properties for rendering text elements.
     *
     * Use this method in TEXT and BUTTON renderers to get all text-related styling
     * in a single grouped object, making the code clearer and more maintainable.
     *
     * Example:
     * ```kotlin
     * val textProps = resolvedStyle.extractTextProperties()
     * Text(
     *     color = parseColor(textProps.color) ?: Color.Black,
     *     fontSize = (textProps.size ?: 14f).sp,
     *     fontWeight = resolveFontWeight(textProps.weight)
     * )
     * ```
     *
     * @return TextProperties containing all text styling values
     */
    fun extractTextProperties(): TextProperties {
        return TextProperties(
            color = textColor,
            size = fontSize,
            family = fontFamily,
            weight = fontWeight,
            style = fontStyle,
            lineHeight = lineHeight,
            letterSpacing = letterSpacing,
            decoration = textDecoration,
            align = textAlign,
            maxLines = maxLines,
            overflow = overflow,
            textShadow = textShadow,
            textGradient = textGradient,
            opacity = opacity
        )
    }

    /**
     * Extract visual properties for rendering backgrounds.
     *
     * Use this method to get background and opacity properties for any element.
     * This is used by all elements and containers for background rendering.
     *
     * Example:
     * ```kotlin
     * val visualProps = resolvedStyle.extractVisualProperties()
     * if (visualProps.background != null) {
     *     modifier = modifier.applyBackground(visualProps.background)
     * } else if (visualProps.backgroundColor != null) {
     *     modifier = modifier.background(parseColor(visualProps.backgroundColor))
     * }
     * ```
     *
     * @return VisualProperties containing background and opacity values
     */
    fun extractVisualProperties(): VisualProperties {
        return VisualProperties(
            background = background,
            backgroundColor = backgroundColor,
            opacity = opacity
        )
    }

    /**
     * Extract border properties for rendering borders.
     *
     * Use this method in applyDecorations() to get all border-related styling
     * in a single grouped object.
     *
     * Example:
     * ```kotlin
     * val borderProps = style.extractBorderProperties()
     * val radiusDp = borderProps.radius?.resolveRadiusDp() ?: 0f
     * val shape = RoundedCornerShape(radiusDp.dp)
     * if (borderProps.width != null && borderProps.width > 0f) {
     *     modifier = modifier.border(
     *         width = borderProps.width.dp,
     *         color = parseColor(borderProps.color) ?: Color.Gray,
     *         shape = shape
     *     )
     * }
     * ```
     *
     * @return BorderProperties containing border styling values
     */
    fun extractBorderProperties(): BorderProperties {
        return BorderProperties(
            radius = borderRadius,
            width = borderWidth,
            color = borderColor
        )
    }

    /**
     * Extract shadow properties for rendering shadows.
     *
     * Use this method in applyDecorations() to get all shadow-related styling
     * in a single grouped object.
     *
     * Example:
     * ```kotlin
     * val shadowProps = style.extractShadowProperties()
     * if (shadowProps.radius != null && shadowProps.radius > 0f) {
     *     modifier = modifier.shadow(
     *         elevation = shadowProps.radius.dp,
     *         shape = shape,
     *         spotColor = parseColor(shadowProps.color) ?: Color.Black.copy(alpha = 0.25f)
     *     )
     * }
     * ```
     *
     * @return ShadowProperties containing shadow styling values
     */
    fun extractShadowProperties(): ShadowProperties {
        return ShadowProperties(
            color = shadowColor,
            radius = shadowRadius,
            offsetX = shadowOffsetX,
            offsetY = shadowOffsetY
        )
    }

    companion object {
        val EMPTY = Style()
    }
}

/**
 * Text shadow configuration for text elements.
 * Provides drop shadow effect on text.
 */
@Immutable
@Serializable
data class TextShadow(
    val color: String,              // Hex color (e.g., "#00000040" for semi-transparent black)
    val offsetX: Float = 0f,        // Horizontal offset in DP
    val offsetY: Float = 0f,        // Vertical offset in DP
    val blur: Float = 0f            // Blur radius in DP
)

/**
 * Text gradient configuration for gradient text effects.
 * Supports linear gradients on text.
 */
@Immutable
@Serializable
data class TextGradient(
    val type: String = "linear",    // "linear" (radial and sweep not supported on text)
    val colors: List<String>,       // Hex colors for gradient stops
    val angle: Float = 0f,          // Angle in degrees (0 = left to right)
    val stops: List<Float>? = null  // Optional gradient stops (0.0 to 1.0)
)

/**
 * Named style class that can be referenced by elements.
 */
@Immutable
@Serializable
data class StyleClass(
    val id: String,
    val style: Style
)

/**
 * Theme containing default styles and color palette.
 */
@Immutable
@Serializable
data class Theme(
    val id: String,
    val defaultStyle: Style = Style.EMPTY,
    val colors: Map<String, String> = emptyMap()
) {
    /**
     * Get a color from the theme palette.
     */
    fun getColor(name: String): String? = colors[name]
    
    companion object {
        val DEFAULT = Theme(
            id = "default",
            defaultStyle = Style.EMPTY,
            colors = emptyMap()
        )
    }
}
