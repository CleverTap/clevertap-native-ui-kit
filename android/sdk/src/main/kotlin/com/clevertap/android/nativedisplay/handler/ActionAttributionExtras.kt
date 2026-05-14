package com.clevertap.android.nativedisplay.handler

import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.models.ExecutionMode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

/**
 * Pure helper that turns an [Action] (and the originating node id) into a flat map of
 * key/value pairs that the bridge feeds into Core SDK's element-click attribution path.
 *
 * Transport contract with [com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge]:
 * - `wzrk_btn_id` carries the clicked node id. The bridge extracts it and passes it as the
 *   `elementID` argument to the new Core SDK method
 *   `pushDisplayUnitElementClickedEventForID(unitId, elementId, additionalProperties)`.
 *   It does NOT forward it inside `additionalProperties` (Core SDK adds it to the event as
 *   `wzrk_element_id` from the dedicated parameter).
 * - All other entries become Core SDK's `additionalProperties` map and are merged into the
 *   event's `evtData` after the usual `wzrk_*` enrichment from the cached unit JSON. Core
 *   SDK strips any `wzrk_*` keys from this map defensively — so action fields use the
 *   `action_*` prefix (unprefixed within the wzrk namespace) and bundle entries from a
 *   `CustomAction.value` JSON object spread as first-class keys.
 *
 * Per-action `metadata` / `params` / `properties` maps are spread verbatim so the client's
 * own keys land on the event with their original names. A `CustomAction.value` that is a
 * JSON object is treated the same way (entries spread); primitive values land under a
 * single `action_value` key.
 *
 * Output keys produced by this helper:
 * - `wzrk_btn_id` — transport marker, extracted by the bridge as `elementID`.
 * - `action_type` — one of `open_url` / `custom` / `navigate` / `event` / `composite`.
 * - `action_key` — the [Action.CustomAction.key] discriminator (e.g. `"kv"` for the BE's
 *   KV-bundle shape, `"close"` for the close-action shape).
 * - Action-specific keys scoped with the `action_` prefix (`action_url`, `action_destination`,
 *   `action_event_name`, …).
 * - Spread entries from `CustomAction.value` JsonObject / metadata / params / properties.
 *
 * Key collisions resolve last-write-wins under this order: reserved keys → value entries →
 * metadata entries.
 */
internal object ActionAttributionExtras {

    /**
     * Transport marker — the bridge extracts this and passes it as Core SDK's `elementID`
     * argument. NOT forwarded as part of `additionalProperties`.
     */
    const val KEY_BUTTON_ID = "wzrk_btn_id"
    private const val KEY_ACTION_TYPE = "action_type"

    fun from(action: Action?, nodeId: String?): Map<String, Any?> {
        val out = linkedMapOf<String, Any?>()
        if (!nodeId.isNullOrEmpty()) out[KEY_BUTTON_ID] = nodeId
        if (action != null) appendAction(action, out)
        return out
    }

    private fun appendAction(action: Action, out: MutableMap<String, Any?>) {
        when (action) {
            is Action.OpenUrl -> {
                out[KEY_ACTION_TYPE] = "open_url"
                out["action_url"] = action.url
                out["action_open_in_browser"] = action.openInBrowser
            }
            is Action.CustomAction -> {
                out[KEY_ACTION_TYPE] = "custom"
                out["action_key"] = action.key
                val v = action.value
                if (v is JsonObject) {
                    // Spread the bundle entries so the dashboard can slice per KV name
                    // (e.g. the BE's `{ "type": "custom", "key": "kv", "value": {...} }` shape).
                    for ((entryKey, entryValue) in v) {
                        out[entryKey] = jsonElementToScalar(entryValue)
                    }
                } else {
                    out["action_value"] = jsonElementToScalar(v)
                }
                action.metadata?.forEach { (k, v) -> out[k] = v }
            }
            is Action.Navigate -> {
                out[KEY_ACTION_TYPE] = "navigate"
                out["action_destination"] = action.destination
                action.params?.forEach { (k, v) -> out[k] = v }
            }
            is Action.TrackEvent -> {
                out[KEY_ACTION_TYPE] = "event"
                out["action_event_name"] = action.eventName
                action.properties?.forEach { (k, v) -> out[k] = jsonElementToScalar(v) }
            }
            is Action.CompositeAction -> {
                out[KEY_ACTION_TYPE] = "composite"
                out["action_count"] = action.actions.size
                out["action_mode"] = when (action.executionMode) {
                    ExecutionMode.SEQUENTIAL -> "sequential"
                    ExecutionMode.PARALLEL -> "parallel"
                }
            }
        }
    }

    /**
     * Reduce a JsonElement to a Core-SDK-compatible scalar.
     * Scalars (string/number/bool) round-trip as their native type; objects/arrays are
     * serialized to a compact JSON string so the payload remains analytics-friendly.
     */
    private fun jsonElementToScalar(el: JsonElement): Any? = when (el) {
        is JsonNull -> null
        is JsonPrimitive -> when {
            el.isString -> el.content
            el.booleanOrNull != null -> el.boolean()
            el.longOrNull != null -> el.long()
            el.doubleOrNull != null -> el.double()
            else -> el.content
        }
        is JsonObject, is JsonArray -> el.toString()
    }

    private fun JsonPrimitive.boolean(): Boolean = booleanOrNull ?: content.toBoolean()
    private fun JsonPrimitive.long(): Long = longOrNull ?: content.toLong()
    private fun JsonPrimitive.double(): Double = doubleOrNull ?: content.toDouble()

    /**
     * Strip keys whose values are not Core-SDK-friendly scalars (`null`, exotic boxed types)
     * before handing the map to the Core SDK reflective call.
     *
     * Keeps `Number` / `Boolean` / `String` / nested `Map` & `List` (Core SDK serializes those)
     * and drops everything else.
     */
    fun sanitize(extras: Map<String, Any?>?): Map<String, Any>? {
        if (extras.isNullOrEmpty()) return null
        val out = linkedMapOf<String, Any>()
        for ((k, v) in extras) {
            if (k.isEmpty() || v == null) continue
            when (v) {
                is String, is Number, is Boolean, is Map<*, *>, is List<*> -> out[k] = v
                else -> out[k] = v.toString()
            }
        }
        return if (out.isEmpty()) null else out
    }
}
