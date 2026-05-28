// ============================================================================
// SDK INTERNAL IMPLEMENTATION - NOT CLIENT USAGE
// ============================================================================
// This shows SDK's internal style resolution logic. Clients don't implement this.
// ============================================================================

// Complete Style Resolution Implementation
// Demonstrates style cascading with theme, style classes, and inheritance

package com.clevertap.android.nativedisplay.examples

/**
 * StyleResolver handles the complete style resolution pipeline:
 * 1. Theme default style (base)
 * 2. Style class (if specified)
 * 3. Inline node style
 * 4. Parent style inheritance (text properties only)
 */
class StyleResolver(
    private val theme: Theme?,
    private val styleClasses: List<StyleClass>?
) {
    /**
     * Resolve final style for a node
     */
    fun resolve(node: NativeDisplayNode, parentStyle: Style? = null): Style {
        // Start with theme default style
        var style = theme?.defaultStyle ?: Style()

        // Apply style class if specified
        node.styleClass?.let { className ->
            val classStyle = styleClasses?.find { it.name == className }?.style
            if (classStyle != null) {
                style = style.merge(classStyle)
            }
        }

        // Apply inline style (highest priority)
        if (node.style != null) {
            style = style.merge(node.style)
        }

        // Inherit text properties from parent
        if (parentStyle != null) {
            style = style.inheritTextProperties(parentStyle)
        }

        return style
    }
}

/**
 * Merge two styles
 * Properties from `other` override properties from `this`
 */
fun Style.merge(other: Style?): Style {
    if (other == null) return this

    return Style(
        // Text properties (can be overridden)
        textColor = other.textColor ?: this.textColor,
        fontSize = other.fontSize ?: this.fontSize,
        fontFamily = other.fontFamily ?: this.fontFamily,
        fontWeight = other.fontWeight ?: this.fontWeight,
        lineHeight = other.lineHeight ?: this.lineHeight,
        textDecoration = other.textDecoration ?: this.textDecoration,
        textAlign = other.textAlign ?: this.textAlign,
        opacity = other.opacity ?: this.opacity,

        // Visual properties (can be overridden)
        background = other.background ?: this.background,
        backgroundColor = other.backgroundColor ?: this.backgroundColor,
        borderRadius = other.borderRadius ?: this.borderRadius,
        borderWidth = other.borderWidth ?: this.borderWidth,
        borderColor = other.borderColor ?: this.borderColor,
        shadowColor = other.shadowColor ?: this.shadowColor,
        shadowRadius = other.shadowRadius ?: this.shadowRadius,
        shadowOffsetX = other.shadowOffsetX ?: this.shadowOffsetX,
        shadowOffsetY = other.shadowOffsetY ?: this.shadowOffsetY
    )
}

/**
 * Inherit text properties from parent
 * Only text properties cascade, visual properties do NOT
 */
fun Style.inheritTextProperties(parentStyle: Style): Style {
    return this.copy(
        textColor = this.textColor ?: parentStyle.textColor,
        fontSize = this.fontSize ?: parentStyle.fontSize,
        fontFamily = this.fontFamily ?: parentStyle.fontFamily,
        fontWeight = this.fontWeight ?: parentStyle.fontWeight,
        lineHeight = this.lineHeight ?: parentStyle.lineHeight,
        textDecoration = this.textDecoration ?: parentStyle.textDecoration,
        textAlign = this.textAlign ?: parentStyle.textAlign,
        opacity = this.opacity ?: parentStyle.opacity
        // Visual properties (background, border, etc.) are NOT inherited
    )
}

/*
USAGE EXAMPLE:

val config = NativeDisplayConfig(
    theme = Theme(
        id = "light",
        defaultStyle = Style(
            textColor = "#212121",
            fontSize = 14f,
            fontFamily = "Roboto"
        )
    ),
    styleClasses = listOf(
        StyleClass(
            name = "card",
            style = Style(
                backgroundColor = "#FFFFFF",
                borderRadius = 12f,
                shadowColor = "#000000",
                shadowRadius = 4f,
                shadowOffsetY = 2f
            )
        ),
        StyleClass(
            name = "title",
            style = Style(
                fontSize = 18f,
                fontWeight = FontWeight.BOLD,
                textColor = "#000000"
            )
        )
    ),
    root = NativeDisplayNode(
        id = "card",
        containerType = ContainerType.VERTICAL,
        styleClass = "card",  // Applies card style class
        style = Style(
            backgroundColor = "#F5F5F5"  // Overrides card background
        ),
        children = listOf(
            NativeDisplayNode(
                id = "title",
                elementType = ElementType.TEXT,
                styleClass = "title",  // Applies title style class
                bindings = mapOf("text" to "Product Name"),
                // Inherits textColor from parent if not specified
            ),
            NativeDisplayNode(
                id = "description",
                elementType = ElementType.TEXT,
                bindings = mapOf("text" to "Description"),
                style = Style(
                    fontSize = 12f  // Overrides theme fontSize
                )
                // Inherits textColor and fontFamily from parent
            )
        )
    )
)

// Resolve styles
val resolver = StyleResolver(config.theme, config.styleClasses)

// Card node
val cardStyle = resolver.resolve(config.root, parentStyle = null)
// Result: backgroundColor = "#F5F5F5" (inline overrides class)
//         borderRadius = 12f (from class)
//         textColor = "#212121" (from theme)
//         fontSize = 14f (from theme)

// Title node (child of card)
val titleStyle = resolver.resolve(config.root.children!![0], parentStyle = cardStyle)
// Result: fontSize = 18f (from class)
//         fontWeight = BOLD (from class)
//         textColor = "#000000" (from class, overrides theme)
//         fontFamily = "Roboto" (inherited from parent/theme)

// Description node (child of card)
val descStyle = resolver.resolve(config.root.children!![1], parentStyle = cardStyle)
// Result: fontSize = 12f (from inline)
//         textColor = "#212121" (inherited from parent)
//         fontFamily = "Roboto" (inherited from parent)

RESOLUTION ORDER VISUALIZATION:

Card Node:
  Theme: textColor=#212121, fontSize=14
    ↓
  Class "card": backgroundColor=#FFFFFF, borderRadius=12
    ↓
  Inline: backgroundColor=#F5F5F5 (overrides class)
    ↓
  Final: backgroundColor=#F5F5F5, borderRadius=12, textColor=#212121, fontSize=14

Title Node (child):
  Theme: textColor=#212121, fontSize=14
    ↓
  Class "title": fontSize=18, fontWeight=BOLD, textColor=#000000
    ↓
  Parent inheritance: fontFamily="Roboto" (text property)
    ↓
  Final: fontSize=18, fontWeight=BOLD, textColor=#000000, fontFamily="Roboto"

KEY RULES:
1. Inline style > Style class > Theme
2. Only TEXT properties cascade to children
3. Visual properties (background, border, shadow) do NOT cascade
4. Null values fallback to next level in hierarchy
*/
