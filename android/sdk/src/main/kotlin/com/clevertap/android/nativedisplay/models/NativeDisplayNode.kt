package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/**
 * Base sealed class for all display nodes (containers and elements).
 * Supports unlimited nesting for maximum flexibility.
 */
@Serializable
sealed class NativeDisplayNode {
    abstract val id: String
    abstract val layout: Layout?
    abstract val style: Style?
    abstract val styleClass: String?
    
    // Phase 1: Conditional rendering
    abstract val visible: String?  // "{{expression}}"
    
    // Phase 3+: User interactions (future)
    abstract val actions: Map<String, Action>?
    
    // Phase 4+: Animations (future)
    abstract val animation: Animation?
}

/**
 * Container node that can hold multiple children (both containers and elements).
 * Supports unlimited nesting depth.
 */
@Serializable
@SerialName("container")
data class NativeDisplayContainer(
    override val id: String,
    val containerType: ContainerType,
    val children: List<NativeDisplayNode> = emptyList(),
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null,
    override val visible: String? = null,
    override val actions: Map<String, Action>? = null,
    override val animation: Animation? = null,
    
    // Gallery configuration (only used when containerType = GALLERY)
    val galleryConfig: GalleryConfig? = null,
    
    // Divider configuration (only used when elementType = DIVIDER)
    val dividerConfig: DividerConfig? = null
) : NativeDisplayNode()

/**
 * Element node that displays actual content (leaf node).
 */
@Serializable
@SerialName("element")
data class NativeDisplayElement(
    override val id: String,
    val elementType: ElementType,
    val bindings: Map<String, String> = emptyMap(),  // Template bindings
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null,
    override val visible: String? = null,
    override val actions: Map<String, Action>? = null,
    override val animation: Animation? = null,
    
    // Divider configuration (only used when elementType = DIVIDER)
    val dividerConfig: DividerConfig? = null
) : NativeDisplayNode()

/**
 * Divider configuration.
 */
@Serializable
data class DividerConfig(
    val orientation: Orientation = Orientation.HORIZONTAL,
    val thickness: Float = 1f,  // in dp
    val color: String = "#E0E0E0"
)

/**
 * Action that can be triggered by user interaction (Phase 3+).
 */
@Serializable
data class Action(
    val type: String,  // "updateVariable", "openUrl", "close", etc.
    val data: Map<String, JsonElement> = emptyMap()
)

/**
 * Animation configuration (Phase 4+).
 */
@Serializable
data class Animation(
    val type: String,  // "fadeIn", "slideIn", etc.
    val duration: Long = 300,
    val delay: Long = 0
)
