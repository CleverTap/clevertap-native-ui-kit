package com.clevertap.android.nativedisplay.bridge

import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.models.Style
import kotlinx.collections.immutable.PersistentMap
import kotlinx.collections.immutable.persistentMapOf

/**
 * A parsed Native Display unit ready for rendering.
 *
 * Contains the resolved config that can be passed directly to
 * [com.clevertap.android.nativedisplay.renderer.NativeDisplayView],
 * along with metadata from the original display unit payload.
 *
 * @param unitId Unique identifier for this display unit (typically `wzrk_id` from the server)
 * @param config The resolved configuration ready for rendering
 * @param resolvedStyles Pre-computed style map (nodeId → Style) produced by the parser on
 *   the off-main parse dispatcher. Renderers should consume this directly instead of
 *   re-running [com.clevertap.android.nativedisplay.style.StyleResolver.resolveAll] on
 *   the main thread. Empty map for units constructed outside the parser.
 * @param slotId Slot identifier from the top-level `slot_id` key, or null when the unit
 *   is not bound to a placement slot
 * @param customExtras Key-value pairs from the `custom_kv` field in the original payload
 * @param rawJson The original JSON string that produced this unit (retained for debugging)
 */
data class NativeDisplayUnit(
    val unitId: String,
    val config: ResolvedConfig,
    val resolvedStyles: PersistentMap<String, Style> = persistentMapOf(),
    val slotId: String? = null,
    val customExtras: Map<String, String> = emptyMap(),
    val rawJson: String? = null
)
