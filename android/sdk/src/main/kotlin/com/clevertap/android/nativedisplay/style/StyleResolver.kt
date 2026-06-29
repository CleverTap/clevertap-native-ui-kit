package com.clevertap.android.nativedisplay.style

import com.clevertap.android.nativedisplay.models.*
import kotlinx.collections.immutable.PersistentMap
import kotlinx.collections.immutable.toPersistentMap

/**
 * Resolves styles with proper cascading and priority.
 *
 * Priority (highest to lowest):
 * 1. Inline style (node.style)
 * 2. Style class (node.styleClass)
 * 3. Theme default style
 */
internal class StyleResolver(
    private val theme: Theme,
    styleClasses: List<StyleClass>
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
     * Pre-resolve styles for an entire node tree in a single pass.
     * Call this once at config-set time; pass the result into composables instead of StyleResolver.
     *
     * Includes parent-to-child cascading of text properties so composables only need
     * an O(1) map lookup — no style resolution logic at render time.
     *
     * @param node Root node to start resolution from
     * @param parentCascadingStyle Cascading text style from parent (empty for root)
     * @return Immutable map from node ID → fully resolved Style (including cascading)
     */
    fun resolveAll(
        node: NativeDisplayNode,
        parentCascadingStyle: Style = Style.EMPTY
    ): PersistentMap<String, Style> {
        val result = mutableMapOf<String, Style>()
        resolveAllInto(node, parentCascadingStyle, result)
        return result.toPersistentMap()
    }

    private fun resolveAllInto(
        node: NativeDisplayNode,
        parentCascadingStyle: Style,
        result: MutableMap<String, Style>
    ) {
        // Resolve this node's own style (theme + styleClass + inline + color palette)
        val ownStyle = resolveWithColors(node)
        // Merge with parent's cascading text properties (own style wins, parent fills gaps)
        val finalStyle = ownStyle.mergeWith(parentCascadingStyle)
        result[node.id] = finalStyle

        // Recurse into children with cascading text properties
        if (node is NativeDisplayContainer) {
            val cascading = finalStyle.cascadingOnly()
            for (child in node.children) {
                resolveAllInto(child, cascading, result)
            }
        }
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
