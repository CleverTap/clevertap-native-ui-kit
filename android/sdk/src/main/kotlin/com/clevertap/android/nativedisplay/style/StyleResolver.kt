package com.clevertap.android.nativedisplay.style

import com.clevertap.android.nativedisplay.models.*

/**
 * Resolves styles with proper inheritance and priority.
 * 
 * Priority (highest to lowest):
 * 1. Inline style (node.style)
 * 2. Style class (node.styleClass)
 * 3. Inherited style (from parent - cascading properties only)
 * 4. Theme default style
 */
class StyleResolver(
    private val theme: Theme,
    private val styleClasses: List<StyleClass>
) {
    private val styleClassMap = styleClasses.associateBy { it.name }
    
    /**
     * Resolve the final style for a node, considering inheritance.
     * 
     * @param node The node to resolve style for
     * @param parentStyle The parent's resolved style (for inheritance)
     * @return Fully resolved style
     */
    fun resolve(
        node: NativeDisplayNode,
        parentStyle: Style? = null
    ): Style {
        // Start with theme default
        var resolvedStyle = theme.defaultStyle
        
        // Apply inherited cascading properties from parent
        if (parentStyle != null) {
            resolvedStyle = resolvedStyle.mergeWith(parentStyle.cascadingOnly())
        }
        
        // Apply style class if specified
        if (node.styleClass != null) {
            val classStyle = styleClassMap[node.styleClass]?.style
            if (classStyle != null) {
                resolvedStyle = resolvedStyle.mergeWith(classStyle)
            }
        }
        
        // Apply inline style (highest priority)
        if (node.style != null) {
            resolvedStyle = resolvedStyle.mergeWith(node.style)
        }
        
        return resolvedStyle
    }
    
    /**
     * Resolve style for an element with color palette support.
     * Replaces color names with actual color values from theme.
     */
    fun resolveWithColors(
        node: NativeDisplayNode,
        parentStyle: Style? = null
    ): Style {
        val style = resolve(node, parentStyle)
        
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
