package com.clevertap.android.nativedisplay.models

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.Stable
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonEncoder
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

/**
 * Represents different types of actions that can be triggered by user interactions
 * in the Native Display System.
 */
@Stable
@Serializable
sealed class Action {

    /**
     * Opens a URL in browser or custom tab.
     *
     * @property url The URL to open
     * @property openInBrowser If true, opens in external browser. If false, uses Chrome Custom Tab
     * @property customTabsEnabled If true and openInBrowser is false, uses Chrome Custom Tabs
     */
    @Immutable
    @Serializable(with = OpenUrlSerializer::class)
    @SerialName("open_url")
    data class OpenUrl(
        val url: String,
        val openInBrowser: Boolean = false,
        val customTabsEnabled: Boolean = true,
        val metadata: Map<String, String>? = null
    ) : Action()

    /**
     * Executes a custom action defined by the client application.
     * The key identifies the action type, and value contains the action data.
     *
     * @property key Identifier for the custom action (e.g., "add_to_cart", "share")
     * @property value The data associated with this action (can be any JSON type)
     * @property metadata Optional additional metadata for the action
     */
    @Immutable
    @Serializable(with = CustomActionSerializer::class)
    @SerialName("custom")
    data class CustomAction(
        val key: String,
        val value: JsonElement,
        val metadata: Map<String, String>? = null
    ) : Action()

    /**
     * Navigates to a different screen/destination in the app.
     *
     * @property destination The navigation destination identifier
     * @property params Optional navigation parameters
     */
    @Immutable
    @Serializable
    @SerialName("navigate")
    data class Navigate(
        val destination: String,
        val params: Map<String, String>? = null
    ) : Action()

    /**
     * Tracks an analytics event.
     *
     * @property eventName The name of the event to track
     * @property properties Optional event properties
     */
    @Immutable
    @Serializable
    @SerialName("event")
    data class TrackEvent(
        val eventName: String,
        val properties: Map<String, JsonElement>? = null
    ) : Action()

    /**
     * Executes multiple actions either sequentially or in parallel.
     *
     * @property actions List of actions to execute
     * @property executionMode Whether to execute actions sequentially or in parallel
     */
    @Immutable
    @Serializable
    @SerialName("composite")
    data class CompositeAction(
        val actions: List<Action>,
        val executionMode: ExecutionMode = ExecutionMode.SEQUENTIAL
    ) : Action()
}

/**
 * Custom serializer for [Action.OpenUrl] that handles platform-specific URL values.
 *
 * The `url` field in JSON can be either:
 * - A plain string: `"url": "https://example.com"` (used directly)
 * - A platform object: `"url": {"android": "https://play.google.com", "ios": "https://apps.apple.com"}`
 *   (the `"android"` key is extracted)
 *
 * If the `url` is an object and the `"android"` key is missing, the URL defaults to an empty string.
 */
internal object OpenUrlSerializer : KSerializer<Action.OpenUrl> {

    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("open_url")

    override fun deserialize(decoder: Decoder): Action.OpenUrl {
        val jsonDecoder = decoder as JsonDecoder
        val obj = jsonDecoder.decodeJsonElement().jsonObject

        val url = resolveUrl(obj["url"])
        val openInBrowser = (obj["openInBrowser"] as? JsonPrimitive)?.booleanOrNull ?: false
        val customTabsEnabled = (obj["customTabsEnabled"] as? JsonPrimitive)?.booleanOrNull ?: true
        val metadata = parseMetadataToStringMap(obj)

        return Action.OpenUrl(
            url = url,
            openInBrowser = openInBrowser,
            customTabsEnabled = customTabsEnabled,
            metadata = metadata,
        )
    }

    override fun serialize(encoder: Encoder, value: Action.OpenUrl) {
        val jsonEncoder = encoder as JsonEncoder
        jsonEncoder.encodeJsonElement(buildJsonObject {
            put("url", value.url)
            put("openInBrowser", value.openInBrowser)
            put("customTabsEnabled", value.customTabsEnabled)
            value.metadata?.let { meta ->
                put("metadata", buildJsonObject { for ((k, v) in meta) put(k, v) })
            }
        })
    }

    // Resolves the url field, which can be:
    //   "https://..."                      — plain string
    //   {"android": "https://...", ...}   — platform object with string values
    //   {"android": {text, replacements}} — legacy Ultron object format; uses `text`
    // Android uses the "android" key only — no ios fallback.
    private fun resolveUrl(urlElement: JsonElement?): String {
        if (urlElement == null || urlElement is JsonNull) return ""
        if (urlElement is JsonPrimitive) return urlElement.content
        if (urlElement !is JsonObject) return ""
        val platformEl = urlElement["android"] ?: return ""
        return when (platformEl) {
            is JsonPrimitive -> platformEl.content
            is JsonObject -> (platformEl["text"] as? JsonPrimitive)?.content ?: ""
            else -> ""
        }
    }
}

internal object CustomActionSerializer : KSerializer<Action.CustomAction> {

    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("custom")

    override fun deserialize(decoder: Decoder): Action.CustomAction {
        val jsonDecoder = decoder as JsonDecoder
        val obj = jsonDecoder.decodeJsonElement().jsonObject
        val key = (obj["key"] as? JsonPrimitive)?.content ?: ""
        val value = obj["value"] ?: JsonNull
        val metadata = parseMetadataToStringMap(obj)
        return Action.CustomAction(key = key, value = value, metadata = metadata)
    }

    override fun serialize(encoder: Encoder, value: Action.CustomAction) {
        val jsonEncoder = encoder as JsonEncoder
        jsonEncoder.encodeJsonElement(buildJsonObject {
            put("key", value.key)
            put("value", value.value)
            value.metadata?.let { meta ->
                put("metadata", buildJsonObject { for ((k, v) in meta) put(k, v) })
            }
        })
    }
}

/**
 * Parses the `metadata` field from an action JSON object into a flat [String, String] map.
 *
 * Values that are JSON primitives are taken as-is. Values that are JSON objects or arrays
 * are serialized to a compact JSON string so the map stays [String, String] without crashing.
 * Null JSON values are skipped.
 */
internal fun parseMetadataToStringMap(obj: JsonObject): Map<String, String>? {
    val metaEl = obj["metadata"] as? JsonObject ?: return null
    val result = mutableMapOf<String, String>()
    for ((k, v) in metaEl) {
        when (v) {
            is JsonNull -> Unit
            is JsonPrimitive -> result[k] = v.content
            else -> result[k] = v.toString()  // JsonObject / JsonArray → compact JSON string
        }
    }
    return result.ifEmpty { null }
}

/**
 * Defines how multiple actions in a CompositeAction should be executed.
 */
@Serializable
enum class ExecutionMode {
    /**
     * Execute actions one after another, waiting for each to complete
     */
    @SerialName("sequential")
    SEQUENTIAL,

    /**
     * Execute all actions simultaneously
     */
    @SerialName("parallel")
    PARALLEL
}