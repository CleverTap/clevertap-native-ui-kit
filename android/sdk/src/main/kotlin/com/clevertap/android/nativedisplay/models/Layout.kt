package com.clevertap.android.nativedisplay.models

import androidx.compose.runtime.Immutable
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonEncoder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.float
import kotlinx.serialization.json.jsonPrimitive

/**
 * Represents a dimension value that can be either a specific value or a special dimension.
 */
@Immutable
@Serializable
data class Dimension(
    val value: Float = 0f,
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
 * Serializer for Dimension that accepts both raw numbers (treated as DP) and
 * object format `{"value": N, "unit": "percent"}`.
 *
 * Used by `borderRadius` in Style so that:
 * - `"borderRadius": 12` → `Dimension(12f, DimensionUnit.DP)`
 * - `"borderRadius": {"value": 50, "unit": "percent"}` → `Dimension(50f, DimensionUnit.PERCENT)`
 */
object DimensionAsNumberSerializer : KSerializer<Dimension> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("DimensionAsNumber")

    override fun deserialize(decoder: Decoder): Dimension {
        val jsonDecoder = decoder as JsonDecoder
        val element = jsonDecoder.decodeJsonElement()
        return when {
            element is JsonPrimitive && !element.isString -> {
                // Raw number → DP (backward compatible)
                Dimension(value = element.float, unit = DimensionUnit.DP)
            }
            element is JsonObject -> {
                // Object format: {"value": N, "unit": "percent"|"dp"|...}
                val value = element["value"]?.jsonPrimitive?.float ?: 0f
                val unitStr = element["unit"]?.jsonPrimitive?.content ?: "dp"
                val unit = when (unitStr.lowercase()) {
                    "percent" -> DimensionUnit.PERCENT
                    "sp" -> DimensionUnit.SP
                    "px" -> DimensionUnit.PX
                    else -> DimensionUnit.DP
                }
                Dimension(value = value, unit = unit)
            }
            else -> Dimension(value = 0f, unit = DimensionUnit.DP)
        }
    }

    override fun serialize(encoder: Encoder, value: Dimension) {
        val jsonEncoder = encoder as JsonEncoder
        if (value.unit == DimensionUnit.DP && value.special == null) {
            // Serialize simple DP values as raw numbers for compact JSON output
            jsonEncoder.encodeJsonElement(JsonPrimitive(value.value))
        } else {
            jsonEncoder.encodeJsonElement(
                JsonObject(
                    mapOf(
                        "value" to JsonPrimitive(value.value),
                        "unit" to JsonPrimitive(value.unit.name.lowercase())
                    )
                )
            )
        }
    }
}

/**
 * Nullable wrapper around [DimensionAsNumberSerializer].
 * Used by `Style.borderRadius` so that a JSON `null` deserializes to Kotlin `null`.
 */
object DimensionAsNumberSerializerNullable : KSerializer<Dimension?> {
    private val inner = DimensionAsNumberSerializer.nullable
    override val descriptor: SerialDescriptor = inner.descriptor

    override fun deserialize(decoder: Decoder): Dimension? = inner.deserialize(decoder)

    override fun serialize(encoder: Encoder, value: Dimension?) = inner.serialize(encoder, value)
}

/**
 * Offset for absolute positioning within a container (x, y coordinates).
 * Used for positioning elements at specific locations within Box containers.
 * Supports negative values for positioning outside the normal flow.
 */
@Immutable
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
@Immutable
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
@Immutable
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
@Immutable
@Serializable
data class Layout(
    val width: Dimension? = null,
    val height: Dimension? = null,
    val aspectRatio: Float? = null,  // Maintain fixed width:height ratio (e.g., 1.777 for 16:9)
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
