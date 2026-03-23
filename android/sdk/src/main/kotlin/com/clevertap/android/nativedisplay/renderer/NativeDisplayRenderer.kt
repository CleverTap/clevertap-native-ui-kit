package com.clevertap.android.nativedisplay.renderer

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.ContainerType
import com.clevertap.android.nativedisplay.models.Layout
import com.clevertap.android.nativedisplay.models.NativeDisplayContainer
import com.clevertap.android.nativedisplay.models.NativeDisplayElement
import com.clevertap.android.nativedisplay.models.NativeDisplayNode
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.models.Style
import com.clevertap.android.nativedisplay.style.StyleResolver
import kotlinx.collections.immutable.PersistentMap

/**
 * Convenience overload that pre-resolves styles internally.
 * Use this when calling NativeDisplayView directly without going through NativeDisplayViewGroup.
 */
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    modifier: Modifier = Modifier,
    actionListener: NativeDisplayActionListener? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val resolvedStyles = remember(config) {
        StyleResolver(config.theme, config.styleClasses).resolveAll(config.root)
    }
    NativeDisplayView(
        config = config,
        resolvedStyles = resolvedStyles,
        modifier = modifier,
        actionListener = actionListener,
        componentListener = componentListener,
    )
}

/**
 * Main entry point for rendering native display UI.
 */
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    resolvedStyles: PersistentMap<String, Style>,
    modifier: Modifier = Modifier,
    actionListener: NativeDisplayActionListener? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val context = LocalContext.current

    val actionHandler = remember(actionListener, componentListener) {
        ActionHandler(
            context = context,
            listener = actionListener,
            componentListener = componentListener
        )
    }

    DisposableEffect(actionHandler) {
        onDispose {
            actionHandler.cleanup()
        }
    }

    val evaluator = remember(config.variables) {
        VariableEvaluator(variables = config.variables)
    }

    RenderNode(
        node = config.root,
        resolvedStyles = resolvedStyles,
        evaluator = evaluator,
        modifier = modifier,
        actionHandler = actionHandler,
        componentListener = componentListener,
    )
}

/**
 * Recursively render a display node (container or element).
 */
@Composable
fun RenderNode(
    node: NativeDisplayNode,
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    // Check visibility condition
    if (node.visible != null) {
        val isVisible = evaluator.evaluateBoolean(node.visible!!)
        if (!isVisible) return
    }

    // Resolve style
    val resolvedStyle = resolvedStyles[node.id] ?: Style.EMPTY

    // Check if this component needs clickable modifier
    val hasServerActions = node.actions?.isNotEmpty() == true
    val isClientInterested = componentListener?.getInterestedNodeIds()?.contains(node.id) ?: (componentListener != null)  // If getInterestedNodeIds returns null, listen to all

    val shouldApplyClickable = hasServerActions || isClientInterested

    // Apply modifiers in correct order
    // IMPORTANT: Offset must be applied BEFORE sizing so percentage calculations
    // use the parent's constraints, not the element's constrained size
    var finalModifier = modifier
    finalModifier = finalModifier.applyOffset(node.layout)  // First: sees parent size
    finalModifier = finalModifier.applySizing(node.layout)  // Second: constrains size
    finalModifier = finalModifier.applyEntranceAnimation(node.animation)

    // Apply clickable only when needed (server actions exist OR client is interested)
    if (actionHandler != null && shouldApplyClickable) {
        finalModifier = finalModifier.applyClickable(
            nodeId = node.id,
            actions = node.actions,
            actionHandler = actionHandler,
            componentListener = componentListener
        )
    }

    finalModifier = finalModifier.applyDecorations(resolvedStyle)

    // Render based on node type
    when (node) {
        is NativeDisplayContainer -> RenderContainer(
            container = node,
            resolvedStyles = resolvedStyles,
            evaluator = evaluator,
            layout = node.layout,
            modifier = finalModifier,
            actionHandler = actionHandler,
            componentListener = componentListener,
        )

        is NativeDisplayElement -> RenderElement(
            element = node,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            layout = node.layout,
            modifier = finalModifier,
            actionHandler = actionHandler,
        )
    }
}

/**
 * Render a container with its children.
 */
@Composable
private fun RenderContainer(
    container: NativeDisplayContainer,
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
    layout: Layout?,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val containerModifier = modifier.applyPadding(layout)

    when (container.containerType) {
        ContainerType.VERTICAL -> {
            Column(
                modifier = containerModifier,
                verticalArrangement = resolveVerticalArrangement(container.layout?.arrangement)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        resolvedStyles = resolvedStyles,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener
                    )
                }
            }
        }

        ContainerType.HORIZONTAL -> {
            Row(
                modifier = containerModifier,
                horizontalArrangement = resolveHorizontalArrangement(container.layout?.arrangement)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        resolvedStyles = resolvedStyles,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener
                    )
                }
            }
        }

        ContainerType.BOX -> {
            Box(modifier = containerModifier) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        resolvedStyles = resolvedStyles,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener
                    )
                }
            }
        }

        ContainerType.GALLERY -> {
            RenderGallery(
                container = container,
                resolvedStyles = resolvedStyles,
                evaluator = evaluator,
                modifier = containerModifier,
                actionHandler = actionHandler,
                componentListener = componentListener
            )
        }
    }
}
