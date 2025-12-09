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
 * Spacing values for padding or margin.
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
 * Layout properties for positioning and sizing elements.
 */
@Serializable
data class Layout(
    val width: Dimension? = null,
    val height: Dimension? = null,
    val margin: Spacing? = null,
    val padding: Spacing? = null,
    val spacing: Float? = null,  // For container children spacing
    val spacingUnit: DimensionUnit = DimensionUnit.DP
) {
    companion object {
        val DEFAULT = Layout(
            width = Dimension.WRAP_CONTENT,
            height = Dimension.WRAP_CONTENT
        )
    }
}
