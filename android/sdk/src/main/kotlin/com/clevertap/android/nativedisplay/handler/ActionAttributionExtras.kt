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
 * key/value pairs suitable for the additional-properties payload of CleverTap Core SDK's
 * `pushDisplayUnitClickedEventForID(unitId, extras)` / `pushDisplayUnitViewedEventForID`
 * overloads.
 *
 * The output is intentionally flat and JSON-friendly — Core SDK's event pipeline expects
 * scalar values (`String` / `Number` / `Boolean`). Nested objects/arrays from `CustomAction.value`
 * are JSON-serialized into a single string so attribution dashboards receive a complete record
 * of what the button did rather than dropping structured payloads on the floor.
 *
 * Reserved keys produced by this helper:
 * - `wzrk_btn_id` — the node id of the clicked component (matches Core SDK push-notification
 *   convention for button identification).
 * - `wzrk_action_type` — one of `open_url` / `custom` / `navigate` / `event` / `composite`.
 *
 * Action-specific keys are scoped with the `action_` prefix to avoid collisions with the
 * Core SDK's own `wzrk_*` enrichment. Per-action `metadata` / `params` / `properties` maps
 * are spread verbatim so the client's own keys land on the event with their original names.
 */
internal object ActionAttributionExtras {

    private const val KEY_BUTTON_ID = "wzrk_btn_id"
    private const val KEY_ACTION_TYPE = "wzrk_action_type"

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
                out["action_value"] = jsonElementToScalar(action.value)
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
