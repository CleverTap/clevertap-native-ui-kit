package com.clevertap.android.nativedisplay.bridge

import com.clevertap.android.nativedisplay.models.ResolvedConfig

/**
 * A parsed Native Display unit ready for rendering.
 *
 * Contains the resolved config that can be passed directly to
 * [com.clevertap.android.nativedisplay.renderer.NativeDisplayView],
 * along with metadata from the original display unit payload.
 *
 * @param unitId Unique identifier for this display unit (typically `wzrk_id` from the server)
 * @param config The resolved configuration ready for rendering
 * @param customExtras Key-value pairs from the `custom_kv` field in the original payload
 * @param rawJson The original JSON string that produced this unit (retained for debugging)
 */
data class NativeDisplayUnit(
    val unitId: String,
    val config: ResolvedConfig,
    val customExtras: Map<String, String> = emptyMap(),
    val rawJson: String? = null
)
