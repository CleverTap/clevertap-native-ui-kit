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
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
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
        val customTabsEnabled: Boolean = true
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
    @Serializable
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

        val urlElement = obj["url"]
        val url = when (urlElement) {
            is JsonObject -> urlElement["android"]?.jsonPrimitive?.content ?: ""
            is JsonPrimitive -> urlElement.content
            else -> ""
        }

        val openInBrowser = obj["openInBrowser"]?.jsonPrimitive?.booleanOrNull ?: false
        val customTabsEnabled = obj["customTabsEnabled"]?.jsonPrimitive?.booleanOrNull ?: true

        return Action.OpenUrl(
            url = url,
            openInBrowser = openInBrowser,
            customTabsEnabled = customTabsEnabled
        )
    }

    override fun serialize(encoder: Encoder, value: Action.OpenUrl) {
        val jsonEncoder = encoder as JsonEncoder
        val jsonElement = buildJsonObject {
            put("url", value.url)
            put("openInBrowser", value.openInBrowser)
            put("customTabsEnabled", value.customTabsEnabled)
        }
        jsonEncoder.encodeJsonElement(jsonElement)
    }
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