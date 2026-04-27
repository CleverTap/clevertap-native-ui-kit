package com.clevertap.android.nativedisplay.models

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.Stable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Base sealed class for all display nodes (containers and elements).
 * Supports unlimited nesting for maximum flexibility.
 */
@Stable
@Serializable
sealed class NativeDisplayNode {
    abstract val id: String
    abstract val layout: Layout?
    abstract val style: Style?
    abstract val styleClass: String?
    abstract val visible: String?
    abstract val actions: Map<String, Action>?
    abstract val animation: Animation?
}

/**
 * Container node that can hold multiple children (both containers and elements).
 * Supports unlimited nesting depth.
 */
@Immutable
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
@Immutable
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
    val dividerConfig: DividerConfig? = null,

    // Image configuration (only used when elementType = IMAGE)
    val imageConfig: ImageConfig? = null
) : NativeDisplayNode()

/**
 * Divider configuration.
 */
@Immutable
@Serializable
data class DividerConfig(
    val orientation: Orientation = Orientation.HORIZONTAL,
    val thickness: Float = 1f,  // in dp
    val color: String = "#E0E0E0"
)

/**
 * Image configuration.
 * Controls how images are displayed within their bounds.
 */
@Immutable
@Serializable
data class ImageConfig(
    val fit: ImageFit = ImageFit.CROP,  // How to fit image within bounds
    val animated: Boolean? = null  // null=auto-detect, true=force, false=disable
)

/**
 * Animation configuration (Phase 4+).
 */
@Immutable
@Serializable
data class Animation(
    val type: AnimationType = AnimationType.NONE,
    val duration: Long = 300,
    val delay: Long = 0,
    val easing: Easing = Easing.EASE_OUT
)
