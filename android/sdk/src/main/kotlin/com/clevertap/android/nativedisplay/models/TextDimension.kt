package com.clevertap.android.nativedisplay.models

import androidx.compose.runtime.Immutable
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
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

@Immutable
@Serializable(with = TextDimensionSerializer::class)
data class TextDimension(
    val value: Float,
    val unit: TextDimensionUnit = TextDimensionUnit.PLATFORM
) {
    fun resolve(rootHeightPx: Float): Float = when (unit) {
        TextDimensionUnit.PLATFORM -> value
        TextDimensionUnit.PERCENT -> rootHeightPx * value / 1000f
    }
}

enum class TextDimensionUnit { PLATFORM, PERCENT }

object TextDimensionSerializer : KSerializer<TextDimension> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("TextDimension")

    override fun deserialize(decoder: Decoder): TextDimension {
        val jsonDecoder = decoder as JsonDecoder
        val element = jsonDecoder.decodeJsonElement()
        return when (element) {
            is JsonPrimitive -> {
                TextDimension(value = element.float, unit = TextDimensionUnit.PLATFORM)
            }
            is JsonObject -> {
                val value = element["value"]?.jsonPrimitive?.float ?: 0f
                val unitStr = element["unit"]?.jsonPrimitive?.content ?: "platform"
                val unit = when (unitStr.lowercase()) {
                    "percent" -> TextDimensionUnit.PERCENT
                    else -> TextDimensionUnit.PLATFORM
                }
                TextDimension(value = value, unit = unit)
            }
            else -> TextDimension(value = 0f, unit = TextDimensionUnit.PLATFORM)
        }
    }

    override fun serialize(encoder: Encoder, value: TextDimension) {
        val jsonEncoder = encoder as JsonEncoder
        if (value.unit == TextDimensionUnit.PLATFORM) {
            jsonEncoder.encodeJsonElement(JsonPrimitive(value.value))
        } else {
            jsonEncoder.encodeJsonElement(
                JsonObject(mapOf(
                    "value" to JsonPrimitive(value.value),
                    "unit" to JsonPrimitive(value.unit.name.lowercase())
                ))
            )
        }
    }
}
