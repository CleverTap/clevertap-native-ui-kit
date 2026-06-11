package com.clevertap.android.nativedisplay.bridge

import androidx.annotation.VisibleForTesting
import com.clevertap.android.nativedisplay.internal.NDLogger
import com.clevertap.android.nativedisplay.models.NativeDisplayConfig
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.models.Style
import com.clevertap.android.nativedisplay.models.Theme
import com.clevertap.android.nativedisplay.style.StyleResolver
import kotlinx.collections.immutable.PersistentMap
import kotlinx.collections.immutable.persistentMapOf
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.decodeFromJsonElement
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
     * Test-only seam. When non-null, invoked at the start of every [tryParse]
     * call with the executing thread. Production callers must not set this —
     * exposed solely so unit tests (e.g. NativeDisplayBridgeOffMainParseTest)
     * can verify parsing happens off the caller's thread without needing to
     * subclass this class.
     */
    @VisibleForTesting
    internal var threadObserver: ((Thread) -> Unit)? = null

    /**
     * Attempt to parse a raw JSON string into a [NativeDisplayUnit].
     *
     * @param jsonString Raw JSON string from a display unit payload
     * @return A parsed [NativeDisplayUnit], or null if not an ND unit or parse fails
     */
    fun tryParse(jsonString: String): NativeDisplayUnit? {
        threadObserver?.invoke(Thread.currentThread())
        return try {
            val jsonObj = json.parseToJsonElement(jsonString).jsonObject
            val unitId = extractUnitId(jsonObj) ?: run {
                NDLogger.w(TAG, "Missing wzrk_id in display unit JSON, using fallback id '0_0'")
                "0_0"
            }
            val slotId = extractSlotId(jsonObj)
            val customExtras = extractCustomExtras(jsonObj)

            val resolvedConfig = tryParseNativeDisplayConfig(jsonObj)
                ?: tryParseFromCustomKv(jsonObj)
                ?: tryParseAsRootConfig(jsonObj)
                ?: return null

            // Pre-resolve the entire node-tree style map here, on the parse dispatcher,
            // so renderers don't repeat the work on main. StyleResolver is pure data —
            // no Compose / density / lifecycle context required.
            val resolvedStyles = preResolveStyles(resolvedConfig)

            NativeDisplayUnit(
                unitId = unitId,
                config = resolvedConfig,
                resolvedStyles = resolvedStyles,
                slotId = slotId,
                customExtras = customExtras,
                rawJson = jsonString
            )
        } catch (e: Exception) {
            NDLogger.w(TAG, "Failed to parse display unit JSON: ${e.message}")
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
            NDLogger.w(TAG, "Failed to parse native_display_config: ${e.message}")
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
            NDLogger.w(TAG, "Failed to parse custom_kv.nd_config: ${e.message}")
            null
        }
    }

    /**
     * Strategy 3: If `root` key is present, treat the entire JSON as an ND config.
     */
    private fun tryParseAsRootConfig(jsonObj: JsonObject): ResolvedConfig? {
        if (!jsonObj.containsKey("root")) return null
        return try {
            val ndConfig = json.decodeFromJsonElement(NativeDisplayConfig.serializer(), jsonObj)
            ndConfig.toResolvedConfig()
        } catch (e: Exception) {
            NDLogger.w(TAG, "Failed to parse JSON as NativeDisplayConfig: ${e.message}")
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
     * Extract `slot_id` from the top-level JSON. Empty strings are normalized to null.
     */
    private fun extractSlotId(jsonObj: JsonObject): String? {
        val raw = jsonObj["slot_id"]?.jsonPrimitive?.contentOrNull ?: return null
        return raw.takeIf { it.isNotEmpty() }
    }

    /**
     * Extract `custom_kv` as a flat String→String map.
     */
    private fun extractCustomExtras(jsonObj: JsonObject): Map<String, String> {
        val customKv = jsonObj["custom_kv"]?.jsonObject ?: return emptyMap()
        return customKv.entries.associate { (key, value) ->
            key to ((value as? JsonPrimitive)?.contentOrNull ?: value.toString())
        }
    }

    /**
     * Run [StyleResolver.resolveAll] on the parsed config so the resulting node-id →
     * Style map is ready before the unit reaches the UI thread. Returns an empty
     * persistent map if resolution throws — the renderer falls back to per-node
     * resolution in that case.
     */
    private fun preResolveStyles(config: ResolvedConfig): PersistentMap<String, Style> {
        return try {
            StyleResolver(config.theme, config.styleClasses).resolveAll(config.root)
        } catch (e: Exception) {
            NDLogger.w(TAG, "Style pre-resolution failed: ${e.message}")
            persistentMapOf()
        }
    }

    /**
     * Convert a [NativeDisplayConfig] to a [ResolvedConfig].
     * Returns null if the config has no root node (required by [ResolvedConfig]).
     */
    private fun NativeDisplayConfig.toResolvedConfig(): ResolvedConfig? {
        val rootNode = this.root ?: run {
            NDLogger.w(TAG, "NativeDisplayConfig has no root node, skipping")
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
        private const val TAG = "NDConfigParser"
    }
}
