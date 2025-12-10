package com.clevertap.android.nativedisplay.renderer

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.rememberAsyncImagePainter
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.models.*
import com.clevertap.android.nativedisplay.style.StyleResolver

/**
 * Main entry point for rendering native display UI.
 */
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    modifier: Modifier = Modifier
) {
    val styleResolver = StyleResolver(config.theme, config.styleClasses)
    val evaluator = VariableEvaluator(config.variables)

    RenderNode(
        node = config.root,
        styleResolver = styleResolver,
        evaluator = evaluator,
        parentStyle = null,
        modifier = modifier
    )
}

/**
 * Recursively render a display node (container or element).
 */
@Composable
private fun RenderNode(
    node: NativeDisplayNode,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    parentStyle: Style?,
    modifier: Modifier = Modifier
) {
    // Check visibility condition
    if (node.visible != null) {
        val isVisible = evaluator.evaluateBoolean(node.visible!!)
        if (!isVisible) return
    }

    // Resolve style with inheritance
    val resolvedStyle = styleResolver.resolveWithColors(node, parentStyle)

    // Apply modifiers in correct order
    var finalModifier = modifier
    finalModifier = finalModifier.applySizing(node.layout)
    finalModifier = finalModifier.applyMargin(node.layout)
    finalModifier = finalModifier.applyDecorations(resolvedStyle)

    // Render based on node type
    when (node) {
        is NativeDisplayContainer -> RenderContainer(
            container = node,
            styleResolver = styleResolver,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            layout = node.layout,
            modifier = finalModifier
        )

        is NativeDisplayElement -> RenderElement(
            element = node,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            layout = node.layout,
            modifier = finalModifier
        )
    }
}

/**
 * Render a container with its children.
 */
@Composable
private fun RenderContainer(
    container: NativeDisplayContainer,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    layout: Layout?,
    modifier: Modifier = Modifier
) {
    val spacing = container.layout?.spacing?.dp ?: 0.dp
    val containerModifier = modifier.applyPadding(layout)

    when (container.containerType) {
        ContainerType.VERTICAL -> {
            Column(
                modifier = containerModifier,
                verticalArrangement = Arrangement.spacedBy(spacing)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier
                    )
                }
            }
        }

        ContainerType.HORIZONTAL -> {
            Row(
                modifier = containerModifier,
                horizontalArrangement = Arrangement.spacedBy(spacing)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier
                    )
                }
            }
        }

        ContainerType.BOX, ContainerType.STACK -> {
            Box(modifier = containerModifier) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier
                    )
                }
            }
        }
    }
}

/**
 * Render an element based on its type.
 */
@Composable
private fun RenderElement(
    element: NativeDisplayElement,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    layout: Layout?,
    modifier: Modifier = Modifier
) {
    val elementModifier = modifier.applyPadding(layout)
    
    when (element.elementType) {
        ElementType.TEXT -> {
            val text = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            Text(
                text = text,
                modifier = elementModifier,
                color = parseColor(resolvedStyle.textColor) ?: Color.Black,
                fontSize = (resolvedStyle.fontSize ?: 14f).sp,
                fontWeight = resolveFontWeight(resolvedStyle.fontWeight),
                textDecoration = resolveTextDecoration(resolvedStyle.textDecoration),
                textAlign = resolveTextAlign(resolvedStyle.textAlign),
                lineHeight = resolvedStyle.lineHeight?.sp ?: (resolvedStyle.fontSize?.times(1.5f) ?: 21f).sp
            )
        }

        ElementType.IMAGE -> {
            val imageUrl = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            if (imageUrl.isNotEmpty()) {
                Image(
                    painter = rememberAsyncImagePainter(imageUrl),
                    contentDescription = element.bindings["contentDescription"]?.let {
                        evaluator.evaluateString(it)
                    },
                    modifier = elementModifier,
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = elementModifier.background(Color.LightGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No Image", color = Color.Gray, fontSize = 12.sp)
                }
            }
        }

        ElementType.BUTTON -> {
            val buttonText = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: "Button"

            Button(
                onClick = { /* TODO: Handle actions */ },
                modifier = elementModifier,
                colors = ButtonDefaults.buttonColors(
                    containerColor = parseColor(resolvedStyle.backgroundColor) ?: Color(0xFF007AFF),
                    contentColor = parseColor(resolvedStyle.textColor) ?: Color.White
                ),
                shape = RoundedCornerShape((resolvedStyle.borderRadius ?: 8f).dp)
            ) {
                Text(
                    text = buttonText,
                    fontSize = (resolvedStyle.fontSize ?: 16f).sp,
                    fontWeight = resolveFontWeight(resolvedStyle.fontWeight)
                )
            }
        }

        ElementType.VIDEO -> {
            Box(
                modifier = elementModifier.background(Color.Black),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Video Player",
                    color = Color.White,
                    fontSize = 16.sp
                )
            }
        }

        ElementType.SPACER -> {
            Spacer(modifier = elementModifier)
        }
    }
}

/**
 * Apply width and height from layout.
 */
private fun Modifier.applySizing(layout: Layout?): Modifier {
    if (layout == null) return this
    var modifier = this

    layout.width?.let { width ->
        modifier = when {
            width.special == SpecialDimension.MATCH_PARENT -> modifier.fillMaxWidth()
            width.special == SpecialDimension.WRAP_CONTENT -> modifier.wrapContentWidth()
            else -> when (width.unit) {
                DimensionUnit.DP -> modifier.width(width.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxWidth(width.value / 100f)
                else -> modifier.width(width.value.dp)
            }
        }
    }

    layout.height?.let { height ->
        modifier = when {
            height.special == SpecialDimension.MATCH_PARENT -> modifier.fillMaxHeight()
            height.special == SpecialDimension.WRAP_CONTENT -> modifier.wrapContentHeight()
            else -> when (height.unit) {
                DimensionUnit.DP -> modifier.height(height.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxHeight(height.value / 100f)
                else -> modifier.height(height.value.dp)
            }
        }
    }

    return modifier
}

/**
 * Apply margin (outside spacing).
 */
private fun Modifier.applyMargin(layout: Layout?): Modifier {
    if (layout?.margin == null) return this
    
    val margin = layout.margin
    return this.padding(
        start = margin.resolveLeft().dp,
        top = margin.resolveTop().dp,
        end = margin.resolveRight().dp,
        bottom = margin.resolveBottom().dp
    )
}

/**
 * Apply padding (inside spacing).
 */
private fun Modifier.applyPadding(layout: Layout?): Modifier {
    if (layout?.padding == null) return this
    
    val padding = layout.padding
    return this.padding(
        start = padding.resolveLeft().dp,
        top = padding.resolveTop().dp,
        end = padding.resolveRight().dp,
        bottom = padding.resolveBottom().dp
    )
}

/**
 * Apply visual decorations (shadow, background, border).
 */
private fun Modifier.applyDecorations(style: Style): Modifier {
    var modifier = this
    
    val shape = RoundedCornerShape((style.borderRadius ?: 0f).dp)
    
    if (style.shadowRadius != null && style.shadowRadius > 0f) {
        modifier = modifier.shadow(
            elevation = style.shadowRadius.dp,
            shape = shape,
            spotColor = parseColor(style.shadowColor) ?: Color.Black.copy(alpha = 0.25f)
        )
    }
    
    if (style.borderRadius != null && style.borderRadius > 0f) {
        modifier = modifier.clip(shape)
    }
    
    style.backgroundColor?.let { color ->
        modifier = modifier.background(
            color = parseColor(color) ?: Color.Transparent,
            shape = shape
        )
    }
    
    if (style.borderWidth != null && style.borderWidth > 0f) {
        modifier = modifier.border(
            width = style.borderWidth.dp,
            color = parseColor(style.borderColor) ?: Color.Gray,
            shape = shape
        )
    }
    
    style.opacity?.let { opacity ->
        modifier = modifier.alpha(opacity.coerceIn(0f, 1f))
    }
    
    return modifier
}

/**
 * Parse hex color string to Compose Color.
 */
private fun parseColor(colorString: String?): Color? {
    if (colorString == null) return null

    return try {
        val hex = colorString.removePrefix("#")
        when (hex.length) {
            6 -> {
                val rgb = hex.toLong(16)
                Color(
                    red = ((rgb shr 16) and 0xFF) / 255f,
                    green = ((rgb shr 8) and 0xFF) / 255f,
                    blue = (rgb and 0xFF) / 255f,
                    alpha = 1f
                )
            }
            8 -> {
                val argb = hex.toLong(16)
                Color(
                    alpha = ((argb shr 24) and 0xFF) / 255f,
                    red = ((argb shr 16) and 0xFF) / 255f,
                    green = ((argb shr 8) and 0xFF) / 255f,
                    blue = (argb and 0xFF) / 255f
                )
            }
            else -> null
        }
    } catch (e: Exception) {
        null
    }
}

/**
 * Resolve font weight from model to Compose.
 */
private fun resolveFontWeight(fontWeight: FontWeight?): ComposeFontWeight {
    return when (fontWeight) {
        FontWeight.LIGHT -> ComposeFontWeight.Light
        FontWeight.NORMAL -> ComposeFontWeight.Normal
        FontWeight.MEDIUM -> ComposeFontWeight.Medium
        FontWeight.BOLD -> ComposeFontWeight.Bold
        null -> ComposeFontWeight.Normal
    }
}

typealias ndtd = com.clevertap.android.nativedisplay.models.TextDecoration

/**
 * Resolve text decoration from model to Compose.
 */
private fun resolveTextDecoration(decoration: ndtd?): TextDecoration {
    return when (decoration) {
        ndtd.UNDERLINE -> TextDecoration.Underline
        ndtd.STRIKETHROUGH -> TextDecoration.LineThrough
        ndtd.NONE, null -> TextDecoration.None
    }
}

/**
 * Resolve text alignment from string to Compose.
 */
private fun resolveTextAlign(align: String?): TextAlign {
    return when (align?.lowercase()) {
        "left" -> TextAlign.Left
        "center" -> TextAlign.Center
        "right" -> TextAlign.Right
        "justify" -> TextAlign.Justify
        else -> TextAlign.Start
    }
}
