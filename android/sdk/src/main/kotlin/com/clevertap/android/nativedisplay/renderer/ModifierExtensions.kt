package com.clevertap.android.nativedisplay.renderer

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.listener.InteractionType
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.models.ActionTriggers
import com.clevertap.android.nativedisplay.models.Animation
import com.clevertap.android.nativedisplay.models.AnimationType
import com.clevertap.android.nativedisplay.models.Dimension
import com.clevertap.android.nativedisplay.models.DimensionUnit
import com.clevertap.android.nativedisplay.models.Layout
import com.clevertap.android.nativedisplay.models.SpecialDimension
import com.clevertap.android.nativedisplay.models.Style

@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun Modifier.applyClickable(
    nodeId: String,
    actions: Map<String, Action>?,
    actionHandler: ActionHandler,
    componentListener: NativeDisplayComponentListener? = null,
    onSystemClick: (() -> Unit)? = null
): Modifier {
    // Early exit if no interactions are enabled from server or client.
    if (actions.isNullOrEmpty() && componentListener == null && onSystemClick == null) return this

    val onClickAction = actions?.get(ActionTriggers.ON_CLICK)
    val onLongPressAction = actions?.get(ActionTriggers.ON_LONG_PRESS)
    val onDoubleTapAction = actions?.get(ActionTriggers.ON_DOUBLE_TAP)

    // Resolve callbacks: prioritize specific actions, fallback to component listener notification
    val onClick = {
        onSystemClick?.invoke()
        onClickAction?.let { actionHandler.handleAction(it, nodeId, InteractionType.CLICK) }
            ?: actionHandler.handleInteractionWithoutAction(nodeId, InteractionType.CLICK)
    }

    val onLongClick = onLongPressAction?.let {
        { actionHandler.handleAction(it, nodeId, InteractionType.LONG_PRESS) }
    } ?: if (componentListener != null) {
        { actionHandler.handleInteractionWithoutAction(nodeId, InteractionType.LONG_PRESS) }
    } else null

    val onDoubleClick = onDoubleTapAction?.let {
        { actionHandler.handleAction(it, nodeId, InteractionType.DOUBLE_TAP) }
    } ?: if (componentListener != null) {
        { actionHandler.handleInteractionWithoutAction(nodeId, InteractionType.DOUBLE_TAP) }
    } else null

    return combinedClickable(
        onClick = onClick,
        onLongClick = onLongClick,
        onDoubleClick = onDoubleClick
    )
}

/**
 * Apply width and height from layout.
 * Aspect ratio is applied when one or both dimensions are flexible.
 *
 * [density] is the screen density (pixels per dp) used to convert PX values correctly.
 */
internal fun Modifier.applySizing(layout: Layout?, density: Float): Modifier {
    if (layout == null) return this
    var modifier = this

    fun Float.pxToDp() = if (density > 0f) (this / density).dp else this.dp

    // Determine if dimensions are fixed (DP/SP/PX, not special)
    val hasFixedWidth = layout.width?.let {
        it.special == null && it.unit in listOf(DimensionUnit.DP, DimensionUnit.PX)
    } ?: false

    val hasFixedHeight = layout.height?.let {
        it.special == null && it.unit in listOf(DimensionUnit.DP, DimensionUnit.PX)
    } ?: false

    // Apply aspect ratio BEFORE sizing if appropriate
    // Skip if both dimensions are fixed (explicit sizes take precedence)
    // Skip if aspect ratio is invalid (≤ 0)
    val doesNotHaveFixedWidth = !(hasFixedWidth && hasFixedHeight)
    if (layout.aspectRatio != null && layout.aspectRatio > 0 && doesNotHaveFixedWidth) {
        modifier = modifier.aspectRatio(
            layout.aspectRatio,
            matchHeightConstraintsFirst = hasFixedHeight
        )
    }

    // Apply width
    layout.width?.let { width ->
        modifier = when (width.special) {
            SpecialDimension.MATCH_PARENT -> modifier.fillMaxWidth()
            SpecialDimension.WRAP_CONTENT -> modifier.wrapContentWidth()
            else -> when (width.unit) {
                DimensionUnit.DP -> modifier.width(width.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxWidth(width.value / 100f)
                DimensionUnit.PX -> modifier.width(width.value.pxToDp())
                else -> modifier.width(width.value.dp)
            }
        }
    }

    // Apply height
    layout.height?.let { height ->
        modifier = when (height.special) {
            SpecialDimension.MATCH_PARENT -> modifier.fillMaxHeight()
            SpecialDimension.WRAP_CONTENT -> modifier.wrapContentHeight()
            else -> when (height.unit) {
                DimensionUnit.DP -> modifier.height(height.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxHeight(height.value / 100f)
                DimensionUnit.PX -> modifier.height(height.value.pxToDp())
                else -> modifier.height(height.value.dp)
            }
        }
    }

    return modifier
}

/**
 * Apply absolute offset positioning.
 * This positions elements at specific x/y coordinates within their container.
 * For percentage-based offsets, calculates relative to parent dimensions.
 *
 * Offset moves the element after layout, making it perfect for:
 * - Absolute positioning within Box containers
 * - Negative values for positioning outside normal flow
 * - Fine-tuned positioning adjustments
 *
 * Note: For Column/Row containers, spacing between children is handled by
 * the arrangement strategy (SpaceBetween, SpaceEvenly, etc.).
 */
internal fun Modifier.applyOffset(layout: Layout?): Modifier {
    if (layout?.offset == null) return this

    val offset = layout.offset

    // Apply x/y offset based on unit type
    return when (offset.unit) {
        DimensionUnit.DP -> this.offset(
            x = offset.x.dp,
            y = offset.y.dp
        )
        DimensionUnit.PERCENT -> this.percentageOffset(offset.x, offset.y)
        else -> this.offset(
            x = offset.x.dp,
            y = offset.y.dp
        )
    }
}

/**
 * Apply percentage-based offset using custom layout modifier.
 * Calculates offset relative to parent container dimensions.
 *
 * IMPORTANT: This modifier must be applied BEFORE any sizing modifiers
 * (applySizing) to ensure constraints.maxWidth/maxHeight represent the
 * parent's actual dimensions, not the element's constrained size.
 *
 * For example, with a 300dp parent and 10% offset:
 * - Correct: offset applied first → sees parent's 300dp → calculates 30dp offset
 * - Wrong: sizing (50dp) applied first → offset sees 50dp → calculates 5dp offset
 */
internal fun Modifier.percentageOffset(xPercent: Float, yPercent: Float): Modifier {
    return this.layout { measurable, constraints ->
        val placeable = measurable.measure(constraints)
        // constraints.maxWidth/maxHeight represent parent dimensions when this
        // modifier is applied before sizing modifiers
        val offsetXPx = (xPercent / 100f * constraints.maxWidth).toInt()
        val offsetYPx = (yPercent / 100f * constraints.maxHeight).toInt()

        layout(placeable.width, placeable.height) {
            placeable.placeRelative(offsetXPx, offsetYPx)
        }
    }
}

/**
 * Apply entrance animation to a component.
 * Animation plays once when the component first appears.
 *
 * Pattern follows BackgroundRenderer.kt - composable when needed for animations.
 */
@Composable
internal fun Modifier.applyEntranceAnimation(animation: Animation?): Modifier {
    // No animation configured
    if (animation == null || animation.type == AnimationType.NONE) {
        return this
    }

    // Track if animation has played
    var hasAnimated by remember { mutableStateOf(false) }

    // Animate from 0 to 1
    val animatedValue by animateFloatAsState(
        targetValue = if (hasAnimated) 1f else 0f,
        animationSpec = tween(
            durationMillis = animation.duration.toInt(),
            delayMillis = animation.delay.toInt(),
            easing = resolveEasing(animation.easing)
        ),
        label = "entrance_animation"
    )

    // Start animation on first composition
    LaunchedEffect(Unit) {
        hasAnimated = true
    }

    // 100dp converted to px for graphicsLayer (which operates in pixels)
    val slideDistancePx = with(LocalDensity.current) { 100.dp.toPx() }

    // Apply animation transform based on type
    return this.graphicsLayer {
        when (animation.type) {
            AnimationType.FADE_IN -> {
                alpha = animatedValue
            }

            AnimationType.SLIDE_IN_LEFT -> {
                translationX = -(1f - animatedValue) * slideDistancePx
                alpha = animatedValue  // Subtle fade for polish
            }

            AnimationType.SLIDE_IN_RIGHT -> {
                translationX = (1f - animatedValue) * slideDistancePx
                alpha = animatedValue
            }

            AnimationType.SLIDE_IN_TOP -> {
                translationY = -(1f - animatedValue) * slideDistancePx
                alpha = animatedValue
            }

            AnimationType.SLIDE_IN_BOTTOM -> {
                translationY = (1f - animatedValue) * slideDistancePx
                alpha = animatedValue
            }

            AnimationType.SCALE_IN -> {
                scaleX = 0.8f + (animatedValue * 0.2f)  // Scale from 80% to 100%
                scaleY = 0.8f + (animatedValue * 0.2f)
                alpha = animatedValue
            }

            AnimationType.FADE_SCALE_IN -> {
                scaleX = 0.9f + (animatedValue * 0.1f)  // Subtle scale
                scaleY = 0.9f + (animatedValue * 0.1f)
                alpha = animatedValue
            }

            AnimationType.FADE_SLIDE_IN -> {
                translationY = (1f - animatedValue) * 30f  // Subtle slide
                alpha = animatedValue
            }

            AnimationType.NONE -> {
                // No transformation
            }
        }
    }
}

/**
 * Apply padding (inside spacing).
 */
internal fun Modifier.applyPadding(layout: Layout?): Modifier {
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
 * Resolve a border-radius [Dimension] to a DP float value.
 *
 * - [DimensionUnit.DP] (and SP/PX): returned as-is (treated as DP).
 * - [DimensionUnit.PERCENT]: `rootContainerHeightDp * (value / 100)`.
 *   Matches FE formula: `containerHeight * value / 100`.
 *
 * [rootContainerHeightDp] is only used for the percent case.
 */
internal fun Dimension.resolveRadiusDp(
    rootContainerHeightDp: Float = 0f,
): Float = when (unit) {
    DimensionUnit.PERCENT -> rootContainerHeightDp * (value / 100f)
    else -> value  // DP, SP, PX — all treated as dp
}

/**
 * Apply visual decorations (shadow, background, border).
 *
 * Border radius and border width are resolved using FE-matching formulas:
 * - borderRadius percent: `rootContainerHeight * value / 100`
 * - borderWidth: `rootContainerHeight * value / 1000`
 *
 * [rootHeightPx] must be passed from the root container's measured height in pixels.
 */
@Composable
internal fun Modifier.applyDecorations(style: Style, rootHeightPx: Float = 0f): Modifier {
    var modifier = this
    val densityValue = LocalDensity.current.density
    val rootHeightDp = if (densityValue > 0f) rootHeightPx / densityValue else 0f

    val borderProps = style.extractBorderProperties()
    val shadowProps = style.extractShadowProperties()
    val visualProps = style.extractVisualProperties()

    // Resolve borderWidth using FE formula: containerHeight * value / 1000
    val effectiveBorderWidthDp: Float = when {
        borderProps.width != null && borderProps.width > 0f && rootHeightDp > 0f ->
            rootHeightDp * borderProps.width / 1000f
        borderProps.width != null -> borderProps.width  // fallback: treat as dp when no rootHeight
        else -> 0f
    }

    val radiusDim = borderProps.radius
    val hasRadius = radiusDim != null && radiusDim.value > 0f
    if (radiusDim != null && radiusDim.unit == DimensionUnit.PERCENT) {
        // Percent radius path: FE formula = containerHeight * value / 100
        // rootHeightDp is captured from the enclosing @Composable scope.
        modifier = modifier.graphicsLayer {
            val resolvedRadiusDp = radiusDim.resolveRadiusDp(rootHeightDp)
            shape = RoundedCornerShape(resolvedRadiusDp.dp)
            clip = true
            if (shadowProps.radius != null && shadowProps.radius > 0f) {
                shadowElevation = shadowProps.radius
                spotShadowColor = parseColor(shadowProps.color) ?: Color.Black.copy(alpha = 0.25f)
            }
        }

        // Background — no shape needed here; graphicsLayer clip handles rounding
        if (visualProps.background != null) {
            modifier = modifier.applyBackground(visualProps.background)
        } else if (visualProps.backgroundColor != null) {
            modifier = modifier.background(
                color = parseColor(visualProps.backgroundColor) ?: Color.Transparent
            )
        }

        // Border drawn via canvas so it respects the percent-resolved radius
        if (effectiveBorderWidthDp > 0f) {
            val borderColor = parseColor(borderProps.color) ?: Color.Gray
            modifier = modifier.drawWithContent {
                drawContent()
                val resolvedRadiusDp = radiusDim.resolveRadiusDp(rootHeightDp)
                val radiusPx = resolvedRadiusDp * density
                val strokePx = effectiveBorderWidthDp * density
                drawRoundRect(
                    color = borderColor,
                    style = Stroke(width = strokePx),
                    cornerRadius = CornerRadius(radiusPx)
                )
            }
        }
    } else {
        // Fixed DP radius path (fast path, no extra draw passes)
        val radiusDp = radiusDim?.resolveRadiusDp(rootHeightDp) ?: 0f
        val shape = RoundedCornerShape(radiusDp.dp)

        // Apply shadow
        if (shadowProps.radius != null && shadowProps.radius > 0f) {
            modifier = modifier.shadow(
                elevation = shadowProps.radius.dp,
                shape = shape,
                spotColor = parseColor(shadowProps.color) ?: Color.Black.copy(alpha = 0.25f)
            )
        }

        // Apply clip
        if (hasRadius) {
            modifier = modifier.clip(shape)
        }

        // Apply background (new system takes precedence over old backgroundColor)
        if (visualProps.background != null) {
            modifier = modifier.applyBackground(visualProps.background)
        } else if (visualProps.backgroundColor != null) {
            modifier = modifier.background(
                color = parseColor(visualProps.backgroundColor) ?: Color.Transparent,
                shape = shape
            )
        }

        // Apply border
        if (effectiveBorderWidthDp > 0f) {
            modifier = modifier.border(
                width = effectiveBorderWidthDp.dp,
                color = parseColor(borderProps.color) ?: Color.Gray,
                shape = shape
            )
        }
    }

    // Apply opacity (both paths)
    visualProps.opacity?.let { opacity ->
        modifier = modifier.alpha(opacity.coerceIn(0f, 1f))
    }

    return modifier
}
