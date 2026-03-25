package com.clevertap.android.nativedisplay.renderer

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.ActionTriggers
import com.clevertap.android.nativedisplay.models.ContainerType
import com.clevertap.android.nativedisplay.models.ElementType
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
        isRoot = true,
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
    isRoot: Boolean = false,
) {
    // Check visibility condition
    val isVisible = node.visible?.let { evaluator.evaluateBoolean(it) } ?: true
    if (!isVisible) return

    // Resolve style
    val resolvedStyle = resolvedStyles[node.id] ?: Style.EMPTY

    // Check if this component needs clickable modifier
    val hasServerActions = node.actions?.isNotEmpty() == true
    val isClientInterested = componentListener?.getInterestedNodeIds()?.contains(node.id) ?: (componentListener != null)  // If getInterestedNodeIds returns null, listen to all

    val isButton = node is NativeDisplayElement && node.elementType == ElementType.BUTTON

    // Buttons are always clickable (for "Notification Clicked" system event)
    val shouldApplyClickable = hasServerActions || isClientInterested || isButton

    // Apply modifiers in correct order
    // IMPORTANT: Offset must be applied BEFORE sizing so percentage calculations
    // use the parent's constraints, not the element's constrained size
    val finalModifier = modifier
        .applyOffset(node.layout)
        .applySizing(node.layout)
        .applyEntranceAnimation(node.animation)
        .let { mod ->
            if (actionHandler != null && shouldApplyClickable) {
                mod.applyClickable(
                    nodeId = node.id,
                    actions = node.actions,
                    actionHandler = actionHandler,
                    componentListener = componentListener,
                    onSystemClick = if (isButton) {
                        { actionHandler.fireSystemEvent("Notification Clicked", mapOf("nodeId" to node.id)) }
                    } else {
                        null
                    }
                )
            } else mod
        }
        .applyDecorations(resolvedStyle)

    // Wire lifecycle action triggers (onAppear / onDisappear)
    val onAppearAction = node.actions?.get(ActionTriggers.ON_APPEAR)
    val onDisappearAction = node.actions?.get(ActionTriggers.ON_DISAPPEAR)

    if (actionHandler != null && (onAppearAction != null || isRoot)) {
        LaunchedEffect(node.id) {
            // Fire "Notification Viewed" system event once for the root node
            if (isRoot) {
                actionHandler.fireSystemEvent("Notification Viewed", deduplicate = true)
            }
            // Fire server-driven onAppear action if present
            if (onAppearAction != null) {
                actionHandler.handleLifecycleAction(onAppearAction, node.id)
            }
        }
    }

    if (actionHandler != null && onDisappearAction != null) {
        DisposableEffect(node.id) {
            onDispose {
                actionHandler.handleLifecycleAction(onDisappearAction, node.id)
            }
        }
    }

    // Render based on node type
    when (node) {
        is NativeDisplayContainer -> RenderContainer(
            container = node,
            resolvedStyles = resolvedStyles,
            evaluator = evaluator,
            modifier = finalModifier,
            actionHandler = actionHandler,
            componentListener = componentListener,
        )

        is NativeDisplayElement -> RenderElement(
            element = node,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
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
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val containerModifier = modifier.applyPadding(container.layout)

    when (container.containerType) {
        ContainerType.VERTICAL -> {
            Column(
                modifier = containerModifier,
                verticalArrangement = resolveVerticalArrangement(container.layout?.arrangement)
            ) {
                container.children.forEach { child ->
                    key(child.id) {
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
        }

        ContainerType.HORIZONTAL -> {
            Row(
                modifier = containerModifier,
                horizontalArrangement = resolveHorizontalArrangement(container.layout?.arrangement)
            ) {
                container.children.forEach { child ->
                    key(child.id) {
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
        }

        ContainerType.BOX -> {
            Box(modifier = containerModifier) {
                container.children.forEach { child ->
                    key(child.id) {
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
