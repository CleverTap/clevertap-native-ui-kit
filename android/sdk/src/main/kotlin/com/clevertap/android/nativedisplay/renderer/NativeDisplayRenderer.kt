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
import androidx.compose.ui.unit.Constraints
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.ActionTriggers
import com.clevertap.android.nativedisplay.models.ContainerType
import com.clevertap.android.nativedisplay.models.DimensionUnit
import com.clevertap.android.nativedisplay.models.ElementType
import com.clevertap.android.nativedisplay.models.NativeDisplayContainer
import com.clevertap.android.nativedisplay.models.NativeDisplayElement
import android.content.Context
import com.clevertap.android.nativedisplay.models.Layout
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

    BoxWithConstraints(modifier = modifier) {
        val parentWidthPx = if (constraints.maxWidth != Constraints.Infinity) constraints.maxWidth.toFloat() else 0f
        val parentHeightPx = if (constraints.maxHeight != Constraints.Infinity) constraints.maxHeight.toFloat() else 0f
        val rootHeightPx = resolveRootHeightPx(config.root.layout, parentWidthPx, parentHeightPx, context)
        RenderNode(
            node = config.root,
            resolvedStyles = resolvedStyles,
            evaluator = evaluator,
            modifier = Modifier,
            actionHandler = actionHandler,
            componentListener = componentListener,
            isRoot = true,
            rootHeightPx = rootHeightPx,
        )
    }
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
    rootHeightPx: Float = 0f,
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
            rootHeightPx = rootHeightPx,
        )

        is NativeDisplayElement -> RenderElement(
            element = node,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            modifier = finalModifier,
            actionHandler = actionHandler,
            rootHeightPx = rootHeightPx,
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
    rootHeightPx: Float = 0f,
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
                            componentListener = componentListener,
                            rootHeightPx = rootHeightPx,
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
                            componentListener = componentListener,
                            rootHeightPx = rootHeightPx,
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
                            componentListener = componentListener,
                            rootHeightPx = rootHeightPx,
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
                componentListener = componentListener,
                rootHeightPx = rootHeightPx,
            )
        }
    }
}

/**
 * Resolve the root container's height in pixels for TextDimension percentage calculations.
 *
 * Priority:
 * 1. Root layout has a fixed height (dp/sp/px) → convert to px
 * 2. Root layout has aspect ratio + known parent width → compute height from width/aspectRatio
 * 3. Root layout has percent height + known parent height → compute from parent
 * 4. Parent height is bounded → use parent height directly
 * 5. Fallback → screen height
 */
private fun resolveRootHeightPx(
    rootLayout: Layout?,
    parentWidthPx: Float,
    parentHeightPx: Float,
    context: Context,
): Float {
    val height = rootLayout?.height
    val density = context.resources.displayMetrics.density

    // 1. Fixed height in dp/sp/px
    if (height != null && height.special == null) {
        when (height.unit) {
            DimensionUnit.DP, DimensionUnit.SP -> {
                val px = height.value * density
                if (px > 0) return px
            }
            DimensionUnit.PX -> {
                if (height.value > 0) return height.value
            }
            DimensionUnit.PERCENT -> {
                // percent needs parent height — handled below
            }
        }
    }

    // 2. Aspect ratio + known width → height = width / aspectRatio
    val aspectRatio = rootLayout?.aspectRatio
    if (aspectRatio != null && aspectRatio > 0f) {
        val rootWidthPx = resolveRootWidthPx(rootLayout, parentWidthPx, density)
        if (rootWidthPx > 0f) return rootWidthPx / aspectRatio
    }

    // 3. Percent height + bounded parent
    if (height != null && height.special == null && height.unit == DimensionUnit.PERCENT && parentHeightPx > 0f) {
        return parentHeightPx * height.value / 100f
    }

    // 4. Bounded parent height
    if (parentHeightPx > 0f) return parentHeightPx

    // 5. Fallback: screen height
    return context.resources.displayMetrics.heightPixels.toFloat()
}

/** Resolve root width in px for aspect-ratio height calculation. */
private fun resolveRootWidthPx(rootLayout: Layout?, parentWidthPx: Float, density: Float): Float {
    val width = rootLayout?.width ?: return parentWidthPx
    if (width.special != null) return parentWidthPx  // match_parent / wrap_content → use parent
    return when (width.unit) {
        DimensionUnit.DP, DimensionUnit.SP -> width.value * density
        DimensionUnit.PX -> width.value
        DimensionUnit.PERCENT -> if (parentWidthPx > 0f) parentWidthPx * width.value / 100f else 0f
    }
}