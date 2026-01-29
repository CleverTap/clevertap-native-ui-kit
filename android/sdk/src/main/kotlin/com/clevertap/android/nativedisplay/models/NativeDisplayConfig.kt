package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/**
 * Main configuration for native display rendering.
 * Supports both Phase 1 (monolithic) and Phase 2+ (split APIs).
 */
@Serializable
data class NativeDisplayConfig(
    val version: String = "1.0",
    
    // Phase 1: Inline data (everything together)
    val theme: Theme? = null,
    val styleClasses: List<StyleClass> = emptyList(),
    val variables: Map<String, JsonElement> = emptyMap(),
    val root: NativeDisplayNode? = null,
    
    // Phase 2+: References to external resources (optional)
    val templateRef: TemplateReference? = null,
    val styleRef: StyleReference? = null,
    val dataRef: DataReference? = null
) {
    /**
     * Check if this is a monolithic config (Phase 1).
     */
    fun isMonolithic(): Boolean {
        return theme != null && 
               root != null && 
               templateRef == null && 
               styleRef == null && 
               dataRef == null
    }
    
    /**
     * Check if this config has external references (Phase 2+).
     */
    fun hasReferences(): Boolean {
        return templateRef != null || 
               styleRef != null || 
               dataRef != null
    }
}

/**
 * Reference to external template (Phase 2+).
 */
@Serializable
data class TemplateReference(
    val templateId: String,
    val version: String,
    val url: String? = null  // Optional direct URL
)

/**
 * Reference to external style data (Phase 2+).
 */
@Serializable
data class StyleReference(
    val styleId: String,
    val version: String,
    val url: String? = null
)

/**
 * Reference to external data (Phase 2+).
 */
@Serializable
data class DataReference(
    val dataId: String,
    val url: String
)

/**
 * Resolved configuration after loading all resources.
 * Used internally after fetching templates, styles, and data.
 */
@Serializable
data class ResolvedConfig(
    val theme: Theme,
    val styleClasses: List<StyleClass> = emptyList(),
    val variables: Map<String, JsonElement> = emptyMap(),
    val root: NativeDisplayNode
)
