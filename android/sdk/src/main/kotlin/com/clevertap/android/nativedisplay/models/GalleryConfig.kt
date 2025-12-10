package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Gallery configuration for carousel/gallery containers.
 * Provides full control over carousel behavior, appearance, and interaction.
 */
@Serializable
data class GalleryConfig(
    /**
     * Snap behavior for items.
     * - NONE: Free scrolling, no snapping
     * - START: Items snap to the start
     * - CENTER: One item centered (classic carousel)
     * - END: Items snap to the end
     */
    @SerialName("snap_behavior")
    val snapBehavior: SnapBehavior = SnapBehavior.CENTER,
    
    /**
     * Percentage of next/previous item to show (0-100).
     * E.g., 20 means 20% of adjacent items are visible.
     * Creates a "peek" effect.
     */
    @SerialName("peek_percentage")
    val peekPercentage: Float = 0f,
    
    /**
     * Spacing between items in dp.
     * Default is 8dp.
     */
    @SerialName("item_spacing")
    val itemSpacing: Float = 8f,
    
    /**
     * Show navigation arrows for manual control.
     */
    @SerialName("show_arrows")
    val showArrows: Boolean = false,
    
    /**
     * Show page indicators (dots) at the bottom/top.
     */
    @SerialName("show_indicators")
    val showIndicators: Boolean = true,
    
    /**
     * Enable infinite/loop scrolling.
     * When reaching the end, loops back to the beginning.
     */
    @SerialName("infinite_scroll")
    val infiniteScroll: Boolean = false,
    
    /**
     * Auto-scroll interval in milliseconds (0 = disabled).
     * If > 0, gallery auto-scrolls after this duration.
     */
    @SerialName("auto_scroll_interval")
    val autoScrollInterval: Long = 0,
    
    /**
     * Orientation of the gallery.
     */
    @SerialName("orientation")
    val orientation: Orientation = Orientation.HORIZONTAL,
    
    /**
     * Arrow style configuration.
     * Only applicable if showArrows is true.
     */
    @SerialName("arrow_style")
    val arrowStyle: ArrowStyle? = null,
    
    /**
     * Indicator style configuration.
     * Only applicable if showIndicators is true.
     */
    @SerialName("indicator_style")
    val indicatorStyle: IndicatorStyle? = null,
    
    /**
     * Initial page index to show (0-based).
     */
    @SerialName("initial_page")
    val initialPage: Int = 0
)

/**
 * Arrow style for gallery navigation.
 */
@Serializable
data class ArrowStyle(
    /**
     * Arrow size in dp.
     */
    @SerialName("size")
    val size: Float = 24f,
    
    /**
     * Arrow color (hex).
     */
    @SerialName("color")
    val color: String = "#000000",
    
    /**
     * Background color for arrow container (hex).
     * If null, arrows are rendered without background.
     */
    @SerialName("background_color")
    val backgroundColor: String? = "#FFFFFF",
    
    /**
     * Border radius for arrow container in dp.
     */
    @SerialName("border_radius")
    val borderRadius: Float = 20f,
    
    /**
     * Padding inside arrow container in dp.
     */
    @SerialName("padding")
    val padding: Float = 8f,
    
    /**
     * Position: "inside" (overlay on gallery) or "outside" (beside gallery).
     */
    @SerialName("position")
    val position: String = "inside"
)

/**
 * Indicator style for page indicators.
 */
@Serializable
data class IndicatorStyle(
    /**
     * Size of each indicator dot in dp.
     */
    @SerialName("size")
    val size: Float = 8f,
    
    /**
     * Active indicator color (hex).
     */
    @SerialName("active_color")
    val activeColor: String = "#007AFF",
    
    /**
     * Inactive indicator color (hex).
     */
    @SerialName("inactive_color")
    val inactiveColor: String = "#CCCCCC",
    
    /**
     * Spacing between indicators in dp.
     */
    @SerialName("spacing")
    val spacing: Float = 8f,
    
    /**
     * Position of indicators: "top", "bottom", "left", "right".
     * For horizontal galleries: top/bottom
     * For vertical galleries: left/right
     */
    @SerialName("position")
    val position: String = "bottom",
    
    /**
     * Shape of indicators: "circle" or "line".
     */
    @SerialName("shape")
    val shape: String = "circle"
)
