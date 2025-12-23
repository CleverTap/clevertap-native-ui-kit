package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.Serializable

/**
 * Represents a dimension value that can be either a specific value or a special dimension.
 */
@Serializable
data class Dimension(
    val value: Float,
    val unit: DimensionUnit = DimensionUnit.DP,
    val special: SpecialDimension? = null
) {
    companion object {
        fun dp(value: Float) = Dimension(value, DimensionUnit.DP)
        fun sp(value: Float) = Dimension(value, DimensionUnit.SP)
        fun percent(value: Float) = Dimension(value, DimensionUnit.PERCENT)
        fun px(value: Float) = Dimension(value, DimensionUnit.PX)
        
        val WRAP_CONTENT = Dimension(0f, DimensionUnit.DP, SpecialDimension.WRAP_CONTENT)
        val MATCH_PARENT = Dimension(0f, DimensionUnit.DP, SpecialDimension.MATCH_PARENT)
    }
}

/**
 * Offset for absolute positioning within a container (x, y coordinates).
 * Used for positioning elements at specific locations within Box/Stack containers.
 * Supports negative values for positioning outside the normal flow.
 */
@Serializable
data class Offset(
    val x: Float = 0f,
    val y: Float = 0f,
    val unit: DimensionUnit = DimensionUnit.DP
) {
    companion object {
        fun dp(x: Float, y: Float) = Offset(x, y, DimensionUnit.DP)
        fun percent(x: Float, y: Float) = Offset(x, y, DimensionUnit.PERCENT)
        
        val ZERO = Offset(0f, 0f)
    }
}

/**
 * Spacing values for padding.
 * Can specify individual sides or use shortcuts for all/horizontal/vertical.
 */
@Serializable
data class Spacing(
    val all: Float? = null,
    val horizontal: Float? = null,
    val vertical: Float? = null,
    val top: Float? = null,
    val bottom: Float? = null,
    val left: Float? = null,
    val right: Float? = null,
    val unit: DimensionUnit = DimensionUnit.DP
) {
    /**
     * Resolve individual spacing values with proper fallbacks.
     */
    fun resolveTop(): Float = top ?: vertical ?: all ?: 0f
    fun resolveBottom(): Float = bottom ?: vertical ?: all ?: 0f
    fun resolveLeft(): Float = left ?: horizontal ?: all ?: 0f
    fun resolveRight(): Float = right ?: horizontal ?: all ?: 0f
    
    companion object {
        fun all(value: Float, unit: DimensionUnit = DimensionUnit.DP) = 
            Spacing(all = value, unit = unit)
        
        fun horizontal(value: Float, unit: DimensionUnit = DimensionUnit.DP) = 
            Spacing(horizontal = value, unit = unit)
        
        fun vertical(value: Float, unit: DimensionUnit = DimensionUnit.DP) = 
            Spacing(vertical = value, unit = unit)
    }
}

/**
 * Child arrangement strategy for container layouts.
 * Defines how children are positioned and spaced within Column/Row containers.
 */
@Serializable
data class ChildArrangement(
    /**
     * Spacing value between children (used when strategy is SPACED).
     */
    val spacing: Float? = null,
    
    /**
     * Unit for spacing value.
     */
    val spacingUnit: DimensionUnit = DimensionUnit.DP,
    
    /**
     * Arrangement strategy for positioning children.
     */
    val strategy: ArrangementStrategy = ArrangementStrategy.SPACED
) {
    companion object {
        /**
         * Default arrangement: no spacing between children.
         */
        val DEFAULT = ChildArrangement(spacing = 0f, strategy = ArrangementStrategy.SPACED)
        
        /**
         * Fixed spacing between children.
         */
        fun spaced(spacing: Float, unit: DimensionUnit = DimensionUnit.DP) = 
            ChildArrangement(spacing = spacing, spacingUnit = unit, strategy = ArrangementStrategy.SPACED)
        
        /**
         * Equal space between children, no space at edges.
         */
        fun spaceBetween() = 
            ChildArrangement(strategy = ArrangementStrategy.SPACE_BETWEEN)
        
        /**
         * Equal space between children AND at edges.
         */
        fun spaceEvenly() = 
            ChildArrangement(strategy = ArrangementStrategy.SPACE_EVENLY)
        
        /**
         * Equal space around each child (half space at edges).
         */
        fun spaceAround() = 
            ChildArrangement(strategy = ArrangementStrategy.SPACE_AROUND)
        
        /**
         * Children aligned to start, no spacing.
         */
        fun start() = 
            ChildArrangement(strategy = ArrangementStrategy.START)
        
        /**
         * Children centered, no spacing.
         */
        fun center() = 
            ChildArrangement(strategy = ArrangementStrategy.CENTER)
        
        /**
         * Children aligned to end, no spacing.
         */
        fun end() = 
            ChildArrangement(strategy = ArrangementStrategy.END)
    }
}

/**
 * Layout properties for positioning and sizing elements.
 */
@Serializable
data class Layout(
    val width: Dimension? = null,
    val height: Dimension? = null,
    val offset: Offset? = null,  // Changed from margin: Spacing to offset: Offset
    val padding: Spacing? = null,
    val arrangement: ChildArrangement? = null  // Changed from spacing/spacingUnit to arrangement
) {
    companion object {
        val DEFAULT = Layout(
            width = Dimension.WRAP_CONTENT,
            height = Dimension.WRAP_CONTENT
        )
    }
}
