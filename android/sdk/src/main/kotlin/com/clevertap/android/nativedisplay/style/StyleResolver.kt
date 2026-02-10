package com.clevertap.android.nativedisplay.style

import com.clevertap.android.nativedisplay.models.*

/**
 * Resolves styles with proper cascading and priority.
 *
 * Priority (highest to lowest):
 * 1. Inline style (node.style)
 * 2. Style class (node.styleClass)
 * 3. Theme default style
 */
class StyleResolver(
    private val theme: Theme,
    private val styleClasses: List<StyleClass>
) {
    private val styleClassMap = styleClasses.associateBy { it.name }
    
    /**
     * Resolve the final style for a node.
     *
     * @param node The node to resolve style for
     * @return Fully resolved style
     */
    fun resolve(
        node: NativeDisplayNode
    ): Style {
        // Start with theme default
        var resolvedStyle = theme.defaultStyle

        // Apply style class if specified (overrides theme)
        if (node.styleClass != null) {
            val classStyle = styleClassMap[node.styleClass]?.style
            if (classStyle != null) {
                resolvedStyle = classStyle.mergeWith(resolvedStyle)
            }
        }

        // Apply inline style (highest priority, overrides everything)
        val nodeStyle = node.style
        if (nodeStyle != null) {
            resolvedStyle = nodeStyle.mergeWith(resolvedStyle)
        }

        return resolvedStyle
    }
    
    /**
     * Resolve style for an element with color palette support.
     * Replaces color names with actual color values from theme.
     */
    fun resolveWithColors(
        node: NativeDisplayNode
    ): Style {
        val style = resolve(node)
        
        return style.copy(
            textColor = resolveColor(style.textColor),
            backgroundColor = resolveColor(style.backgroundColor),
            borderColor = resolveColor(style.borderColor),
            shadowColor = resolveColor(style.shadowColor)
        )
    }
    
    /**
     * Resolve a color value, checking theme palette if it's a named color.
     */
    private fun resolveColor(color: String?): String? {
        if (color == null) return null
        
        // If starts with #, it's already a hex color
        if (color.startsWith("#")) return color
        
        // Otherwise, try to get from theme palette
        return theme.getColor(color) ?: color
    }
}
