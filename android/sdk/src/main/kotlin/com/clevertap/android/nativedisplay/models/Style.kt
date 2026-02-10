package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.Serializable

/**
 * Style properties for visual appearance.
 * 
 * Cascading properties (inherited by children):
 * - textColor, fontSize, fontFamily, fontWeight, lineHeight
 * 
 * Non-cascading properties (container-only):
 * - background, backgroundColor, borderRadius, shadowRadius, etc.
 */
@Serializable
data class Style(
    // Text properties (cascading)
    val textColor: String? = null,
    val fontSize: Float? = null,
    val fontFamily: String? = null,
    val fontWeight: FontWeight? = null,
    val lineHeight: Float? = null,
    val textDecoration: TextDecoration? = null,
    val textAlign: String? = null,  // "left", "center", "right"
    
    // Background (non-cascading)
    val background: Background? = null,  // New: Rich background support
    val backgroundColor: String? = null,  // Legacy: Simple color (backward compatible)
    
    // Border (non-cascading)
    val borderRadius: Float? = null,
    val borderWidth: Float? = null,
    val borderColor: String? = null,
    
    // Shadow (non-cascading)
    val shadowColor: String? = null,
    val shadowRadius: Float? = null,
    val shadowOffsetX: Float? = null,
    val shadowOffsetY: Float? = null,
    
    // Opacity (cascading)
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
            lineHeight = lineHeight ?: other.lineHeight,
            textDecoration = textDecoration ?: other.textDecoration,
            textAlign = textAlign ?: other.textAlign,
            
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
            lineHeight = lineHeight,
            textDecoration = textDecoration,
            textAlign = textAlign,
            opacity = opacity
        )
    }
    
    companion object {
        val EMPTY = Style()
    }
}

/**
 * Named style class that can be referenced by elements.
 */
@Serializable
data class StyleClass(
    val name: String,
    val style: Style
)

/**
 * Theme containing default styles and color palette.
 */
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
