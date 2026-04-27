package com.clevertap.android.nativedisplay.bridge

import android.util.Log
import com.clevertap.android.nativedisplay.models.NativeDisplayConfig
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.models.Theme
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Parses raw display unit JSON strings into [NativeDisplayUnit] instances.
 *
 * Detection strategy (tried in order):
 * 1. `native_display_config` top-level key — parse its value as [NativeDisplayConfig]
 * 2. `custom_kv.nd_config` string value — parse that string as [NativeDisplayConfig]
 * 3. `root` top-level key present — treat the entire JSON object as [NativeDisplayConfig]
 *
 * Returns `null` if the JSON is not a Native Display unit or if parsing fails.
 */
internal class NativeDisplayConfigParser {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    /**
     * Attempt to parse a raw JSON string into a [NativeDisplayUnit].
     *
     * @param jsonString Raw JSON string from a display unit payload
     * @return A parsed [NativeDisplayUnit], or null if not an ND unit or parse fails
     */
    fun tryParse(jsonString: String): NativeDisplayUnit? {
        return try {
            val jsonObj = json.parseToJsonElement(jsonString).jsonObject
            val unitId = extractUnitId(jsonObj) ?: return null
            val customExtras = extractCustomExtras(jsonObj)

            val resolvedConfig = tryParseNativeDisplayConfig(jsonObj)
                ?: tryParseFromCustomKv(jsonObj)
                ?: tryParseAsRootConfig(jsonString, jsonObj)
                ?: return null

            NativeDisplayUnit(
                unitId = unitId,
                config = resolvedConfig,
                customExtras = customExtras,
                rawJson = jsonString
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse display unit JSON: ${e.message}")
            null
        }
    }

    /**
     * Strategy 1: Look for `native_display_config` key and parse its value.
     */
    private fun tryParseNativeDisplayConfig(jsonObj: JsonObject): ResolvedConfig? {
        val ndConfigElement = jsonObj["native_display_config"] ?: return null
        return try {
            val ndConfig = json.decodeFromJsonElement(
                NativeDisplayConfig.serializer(),
                ndConfigElement
            )
            ndConfig.toResolvedConfig()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse native_display_config: ${e.message}")
            null
        }
    }

    /**
     * Strategy 2: Look for `custom_kv.nd_config` string and parse it.
     */
    private fun tryParseFromCustomKv(jsonObj: JsonObject): ResolvedConfig? {
        val customKv = jsonObj["custom_kv"]?.jsonObject ?: return null
        val ndConfigStr = customKv["nd_config"]?.jsonPrimitive?.contentOrNull ?: return null
        return try {
            val ndConfig = json.decodeFromString(NativeDisplayConfig.serializer(), ndConfigStr)
            ndConfig.toResolvedConfig()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse custom_kv.nd_config: ${e.message}")
            null
        }
    }

    /**
     * Strategy 3: If `root` key is present, treat the entire JSON as an ND config.
     */
    private fun tryParseAsRootConfig(jsonString: String, jsonObj: JsonObject): ResolvedConfig? {
        if (!jsonObj.containsKey("root")) return null
        return try {
            val ndConfig = json.decodeFromString(NativeDisplayConfig.serializer(), jsonString)
            ndConfig.toResolvedConfig()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse JSON as NativeDisplayConfig: ${e.message}")
            null
        }
    }

    /**
     * Extract `wzrk_id` from the JSON object.
     */
    private fun extractUnitId(jsonObj: JsonObject): String? {
        return jsonObj["wzrk_id"]?.jsonPrimitive?.contentOrNull
    }

    /**
     * Extract `custom_kv` as a flat String→String map.
     */
    private fun extractCustomExtras(jsonObj: JsonObject): Map<String, String> {
        val customKv = jsonObj["custom_kv"]?.jsonObject ?: return emptyMap()
        return customKv.entries.associate { (key, value) ->
            key to (value.jsonPrimitive.contentOrNull ?: value.toString())
        }
    }

    /**
     * Convert a [NativeDisplayConfig] to a [ResolvedConfig].
     * Returns null if the config has no root node (required by [ResolvedConfig]).
     */
    private fun NativeDisplayConfig.toResolvedConfig(): ResolvedConfig? {
        val rootNode = this.root ?: run {
            Log.w(TAG, "NativeDisplayConfig has no root node, skipping")
            return null
        }
        return ResolvedConfig(
            theme = this.theme ?: Theme.DEFAULT,
            styleClasses = this.styleClasses,
            variables = this.variables,
            root = rootNode
        )
    }

    companion object {
        private const val TAG = "NativeDisplayBridge"
    }
}
