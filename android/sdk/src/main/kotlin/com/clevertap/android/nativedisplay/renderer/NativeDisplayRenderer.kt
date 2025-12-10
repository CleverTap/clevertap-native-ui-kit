package com.clevertap.android.nativedisplay.renderer

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.models.*
import com.clevertap.android.nativedisplay.style.StyleResolver
import androidx.core.graphics.toColorInt

/**
 * Main entry point for rendering native display UI.
 *
 * @param config The display configuration (monolithic or with references)
 * @param modifier Optional modifier for the root composable
 */
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    modifier: Modifier = Modifier
) {
    val styleResolver = StyleResolver(config.theme, config.styleClasses)
    val evaluator = VariableEvaluator(config.variables)

    // Render the root node
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

    // Render based on node type
    when (node) {
        is NativeDisplayContainer -> RenderContainer(
            container = node,
            styleResolver = styleResolver,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            modifier = modifier
        )

        is NativeDisplayElement -> RenderElement(
            element = node,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            modifier = modifier
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
    modifier: Modifier = Modifier
) {
    val containerModifier = modifier.applyStyle(resolvedStyle)

    when (container.containerType) {
        ContainerType.VERTICAL -> {
            Column(modifier = containerModifier) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,  // Pass style for inheritance
                        modifier = Modifier
                    )
                }
            }
        }

        ContainerType.HORIZONTAL -> {
            Row(modifier = containerModifier) {
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
    modifier: Modifier = Modifier
) {
    val elementModifier = modifier.applyStyle(resolvedStyle)

    when (element.elementType) {
        ElementType.TEXT -> {
            val text = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            Text(
                text = text,
                modifier = elementModifier,
                color = parseColor(resolvedStyle.textColor),
                fontSize = resolvedStyle.fontSize?.sp ?: 14.sp
            )
        }

        ElementType.SPACER -> {
            Spacer(modifier = elementModifier)
        }

        // TODO: Implement other element types
        ElementType.IMAGE -> {
            // Placeholder for image rendering
            Box(modifier = elementModifier)
        }

        ElementType.BUTTON -> {
            // Placeholder for button rendering
            Box(modifier = elementModifier)
        }

        ElementType.VIDEO -> {
            // Placeholder for video rendering
            Box(modifier = elementModifier)
        }
    }
}

/**
 * Apply style properties to a modifier.
 */
private fun Modifier.applyStyle(style: Style): Modifier {
    var modifier = this

    // Background color
    style.backgroundColor?.let { color ->
        modifier = modifier.background(parseColor(color))
    }

    // Padding (if we had layout info)
    // This is simplified - full implementation would use Layout properties

    return modifier
}

/**
 * Parse hex color string to Compose Color.
 */
private fun parseColor(colorString: String?): Color {
    if (colorString == null) return Color.Unspecified

    return try {
        val hex = colorString.removePrefix("#")
        when (hex.length) {
            6 -> Color("#$hex".toColorInt())
            8 -> Color("#$hex".toColorInt())
            else -> Color.Unspecified
        }
    } catch (e: Exception) {
        Color.Unspecified
    }
}
