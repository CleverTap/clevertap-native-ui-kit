// ============================================================================
// SDK INTERNAL IMPLEMENTATION - NOT CLIENT USAGE
// ============================================================================
// This file shows SDK internal implementation. Clients don't write this code.
// ============================================================================

// Complete Horizontal Container Implementation Example
// Demonstrates HORIZONTAL container with RTL support

package com.clevertap.android.nativedisplay.examples

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp

@Composable
fun RenderHorizontalContainer(
    node: NativeDisplayNode,
    parentSize: IntSize,
    style: Style,
    onRenderChild: @Composable (NativeDisplayNode) -> Unit
) {
    val modifier = Modifier
        .applyDimension(node.layout.width, parentSize.width, isWidth = true)
        .applyDimension(node.layout.height, parentSize.height, isWidth = false)
        .applyBackground(style.background, style.backgroundColor)
        .applyPadding(node.layout.padding)
        .applyBorder(style.borderWidth, style.borderColor, style.borderRadius)

    val horizontalArrangement = node.arrangement?.toHorizontalArrangement()
        ?: Arrangement.spacedBy(0.dp)

    Row(
        modifier = modifier,
        horizontalArrangement = horizontalArrangement,
        verticalAlignment = Alignment.Top
    ) {
        node.children?.forEach { child ->
            onRenderChild(child)
        }
    }
}

// Convert ChildArrangement to Compose Horizontal Arrangement
fun ChildArrangement.toHorizontalArrangement(): Arrangement.Horizontal {
    return when (strategy) {
        ArrangementStrategy.SPACED -> {
            val spacingDp = spacing?.dp ?: 0.dp
            Arrangement.spacedBy(spacingDp)
        }
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Start  // Auto RTL
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.End  // Auto RTL
    }
}

/*
USAGE EXAMPLE:

// Product tags in a horizontal row
val tagRow = NativeDisplayNode(
    id = "tags",
    containerType = ContainerType.HORIZONTAL,
    layout = Layout(
        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
        padding = Spacing(horizontal = 16f, vertical = 8f)
    ),
    arrangement = ChildArrangement(
        spacing = 8f,
        strategy = ArrangementStrategy.SPACED
    ),
    children = listOf(
        NativeDisplayNode(
            id = "tag1",
            elementType = ElementType.TEXT,
            bindings = mapOf("text" to "New"),
            style = Style(
                backgroundColor = "#E3F2FD",
                textColor = "#1976D2",
                borderRadius = 16f
            ),
            layout = Layout(padding = Spacing(horizontal = 12f, vertical = 4f))
        ),
        NativeDisplayNode(
            id = "tag2",
            elementType = ElementType.TEXT,
            bindings = mapOf("text" to "Sale"),
            style = Style(
                backgroundColor = "#FFEBEE",
                textColor = "#C62828",
                borderRadius = 16f
            ),
            layout = Layout(padding = Spacing(horizontal = 12f, vertical = 4f))
        )
    )
)

@Composable
fun TagRow() {
    BoxWithConstraints {
        val parentSize = IntSize(constraints.maxWidth, constraints.maxHeight)
        RenderHorizontalContainer(
            node = tagRow,
            parentSize = parentSize,
            style = Style(),
            onRenderChild = { child -> RenderElement(child) }
        )
    }
}

// RTL Support:
// When app is in RTL mode (Arabic, Hebrew, etc.):
// - START → Right edge
// - END → Left edge
// - Spacing uses start/end instead of left/right
// - All handled automatically by Compose Row
*/
