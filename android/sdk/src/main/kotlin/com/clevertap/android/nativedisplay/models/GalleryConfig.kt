package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Gallery mode determines the behavior and layout strategy.
 */
@Serializable
enum class GalleryMode {
    @SerialName("snapping")
    SNAPPING,           // Pager with full-size items and peek support

    @SerialName("free_flow")
    FREE_FLOW,          // Items size themselves independently (no peek)

    @SerialName("free_flow_grid")
    FREE_FLOW_GRID      // Fixed items per view with peek via itemsPerView
}

/**
 * Gallery configuration for carousel/scrolling containers.
 *
 * Three distinct modes:
 * 1. SNAPPING: Full-size items with snap, peek shows adjacent items (image carousels)
 * 2. FREE_FLOW: Items define their own size, natural scrolling (tag lists, varying widths)
 * 3. FREE_FLOW_GRID: Fixed items per view, peek via itemsPerView (product grids)
 */
@Serializable
data class GalleryConfig(
    // Core mode selection
    val mode: GalleryMode = GalleryMode.SNAPPING,
    val orientation: Orientation = Orientation.HORIZONTAL,

    // SNAPPING mode parameters
    val snapBehavior: SnapBehavior = SnapBehavior.CENTER,
    val peekPercentage: Float = 0f,  // 0-100, percentage of adjacent items to show

    // FREE_FLOW_GRID mode parameters
    val itemsPerView: Float = 1f,    // Number of items visible (2.5 = 2 full + 0.5 peek)

    // Common parameters
    val spacing: Float = 8f,          // Gap between items in dp
    val showIndicators: Boolean = false,
    val indicatorStyle: IndicatorStyle? = null,
    val autoScrollInterval: Long = 0,  // Auto-scroll interval in ms (0 = disabled)
    val infiniteScroll: Boolean = false,
    val showArrows: Boolean = false,
    val arrowStyle: ArrowStyle? = null,
    val initialPage: Int = 0
)

@Serializable
data class IndicatorStyle(
    val size: Float = 8f,
    val spacing: Float = 8f,
    val activeColor: String = "#2196F3",
    val inactiveColor: String = "#BDBDBD",
    val shape: String = "circle",  // "circle" or "rectangle"
    val position: String = "bottom"  // "top", "bottom", "left", "right"
)

@Serializable
data class ArrowStyle(
    val size: Float = 24f,
    val color: String = "#FFFFFF",
    val backgroundColor: String? = null,
    val padding: Float = 8f
)
