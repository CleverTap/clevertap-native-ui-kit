// ============================================================================
// SDK INTERNAL IMPLEMENTATION - NOT CLIENT USAGE
// ============================================================================
// This file shows how the SDK INTERNALLY implements vertical container rendering.
// CLIENTS DO NOT write this code - they only provide JSON configurations.
//
// Client usage:
//   val config = Json.decodeFromString<NativeDisplayConfig>(jsonString)
//   NativeDisplayView(config)  // That's it!
// ============================================================================

// Complete Vertical Container Implementation Example
// Demonstrates VERTICAL container with arrangement strategies

package com.clevertap.android.nativedisplay.examples

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp

@Composable
fun RenderVerticalContainer(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style,
    onRenderChild: @Composable (NativeDisplayNode) -> Unit
) {
    // Build modifier chain in correct order
    val modifier = Modifier
        // 1. Dimensions
        .applyDimension(node.layout.width, parentSize.width, isWidth = true)
        .applyDimension(node.layout.height, parentSize.height, isWidth = false)
        // 2. Background
        .applyBackground(style.background, style.backgroundColor)
        // 3. Padding (inside)
        .applyPadding(node.layout.padding)
        // 4. Border (outside padding)
        .applyBorder(style.borderWidth, style.borderColor, style.borderRadius)
        // 5. Shadow
        .applyShadow(style)

    // Convert arrangement to Compose
    val verticalArrangement = node.arrangement?.toVerticalArrangement()
        ?: Arrangement.spacedBy(0.dp)

    Column(
        modifier = modifier,
        verticalArrangement = verticalArrangement,
        horizontalAlignment = Alignment.Start
    ) {
        node.children?.forEach { child ->
            onRenderChild(child)
        }
    }
}

// Extension: Convert ChildArrangement to Compose Vertical Arrangement
fun ChildArrangement.toVerticalArrangement(): Arrangement.Vertical {
    return when (strategy) {
        ArrangementStrategy.SPACED -> {
            val spacingDp = spacing?.dp ?: 0.dp
            Arrangement.spacedBy(spacingDp)
        }
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Top
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.Bottom
    }
}

// Extension: Apply dimension to modifier
fun Modifier.applyDimension(
    dimension: Dimension?,
    parentSize: Int,
    isWidth: Boolean
): Modifier {
    if (dimension == null) return this

    return when {
        dimension.special == SpecialDimension.MATCH_PARENT -> {
            if (isWidth) fillMaxWidth() else fillMaxHeight()
        }
        dimension.special == SpecialDimension.WRAP_CONTENT -> {
            wrapContentSize()
        }
        else -> {
            val sizeDp = when (dimension.unit) {
                DimensionUnit.DP -> dimension.value.dp
                DimensionUnit.SP -> dimension.value.dp // SP handled same as DP for layout
                DimensionUnit.PERCENT -> ((parentSize * dimension.value) / 100).dp
                DimensionUnit.PX -> (dimension.value / density).dp // Convert px to dp
            }
            if (isWidth) width(sizeDp) else height(sizeDp)
        }
    }
}

// Extension: Apply padding
fun Modifier.applyPadding(spacing: Spacing?): Modifier {
    if (spacing == null) return this

    val unit = spacing.unit ?: DimensionUnit.DP

    return when {
        spacing.all != null -> padding(spacing.all.toDp(unit))
        else -> padding(
            start = (spacing.left ?: spacing.horizontal ?: 0f).toDp(unit),
            end = (spacing.right ?: spacing.horizontal ?: 0f).toDp(unit),
            top = (spacing.top ?: spacing.vertical ?: 0f).toDp(unit),
            bottom = (spacing.bottom ?: spacing.vertical ?: 0f).toDp(unit)
        )
    }
}

// Extension: Apply border
fun Modifier.applyBorder(
    borderWidth: Float?,
    borderColor: String?,
    borderRadius: Float?
): Modifier {
    if (borderWidth == null || borderWidth <= 0f) return this

    val color = borderColor?.parseColor() ?: Color.Black
    val shape = RoundedCornerShape((borderRadius ?: 0f).dp)

    return border(borderWidth.dp, color, shape)
}

// Extension: Apply background
fun Modifier.applyBackground(
    background: Background?,
    backgroundColor: String?
): Modifier {
    // Prefer new background system
    if (background != null) {
        return applyBackgroundType(background)
    }

    // Fallback to legacy backgroundColor
    if (backgroundColor != null) {
        return background(backgroundColor.parseColor())
    }

    return this
}

// Helper: Convert float to Dp based on unit
fun Float.toDp(unit: DimensionUnit): Dp {
    return when (unit) {
        DimensionUnit.DP -> this.dp
        DimensionUnit.SP -> this.dp // For layout, treat SP same as DP
        DimensionUnit.PX -> (this / density).dp
        DimensionUnit.PERCENT -> this.dp // Should be calculated earlier
    }
}

// Helper: Parse color string to Compose Color
fun String.parseColor(): Color {
    val cleanHex = this.removePrefix("#")
    val argb = when (cleanHex.length) {
        6 -> "FF$cleanHex"  // RGB → ARGB (add full alpha)
        8 -> cleanHex       // Already ARGB
        else -> "FF000000"  // Fallback to black
    }
    return Color(argb.toLongOrNull(16) ?: 0xFF000000)
}

/*
USAGE EXAMPLE:

val config = NativeDisplayConfig(
    root = NativeDisplayNode(
        id = "card",
        containerType = ContainerType.VERTICAL,
        layout = Layout(
            width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
            padding = Spacing(all = 16f)
        ),
        arrangement = ChildArrangement(
            spacing = 12f,
            strategy = ArrangementStrategy.SPACED
        ),
        style = Style(
            backgroundColor = "#FFFFFF",
            borderRadius = 12f
        ),
        children = listOf(
            // ... child nodes
        )
    )
)

@Composable
fun MyView() {
    BoxWithConstraints {
        val parentSize = IntSize(constraints.maxWidth, constraints.maxHeight)
        RenderVerticalContainer(
            node = config.root,
            parentSize = parentSize,
            style = resolvedStyle,
            onRenderChild = { child -> RenderNode(child) }
        )
    }
}
*/
