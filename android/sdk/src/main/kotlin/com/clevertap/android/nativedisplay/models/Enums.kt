package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Types of containers that can be rendered.
 * Containers hold and organize child nodes (both containers and elements).
 */
@Serializable
enum class ContainerType {
    @SerialName("vertical")
    VERTICAL,
    
    @SerialName("horizontal")
    HORIZONTAL,
    
    @SerialName("box")
    BOX,

    @SerialName("gallery")
    GALLERY
}

/**
 * Types of UI elements that can be rendered.
 * Elements are leaf nodes that display actual content.
 */
@Serializable
enum class ElementType {
    @SerialName("text")
    TEXT,
    
    @SerialName("image")
    IMAGE,
    
    @SerialName("button")
    BUTTON,
    
    @SerialName("video")
    VIDEO,
    
    @SerialName("spacer")
    SPACER,
    
    @SerialName("divider")
    DIVIDER,

    @SerialName("html")
    HTML
}

/**
 * Units for dimension values.
 */
@Serializable
enum class DimensionUnit {
    @SerialName("dp")
    DP,
    
    @SerialName("sp")
    SP,
    
    @SerialName("percent")
    PERCENT,
    
    @SerialName("px")
    PX
}

/**
 * Special dimension values.
 */
@Serializable
enum class SpecialDimension {
    @SerialName("wrap_content")
    WRAP_CONTENT,
    
    @SerialName("match_parent")
    MATCH_PARENT
}

/**
 * Font weight values.
 */
@Serializable
enum class FontWeight {
    @SerialName("normal")
    NORMAL,

    @SerialName("medium")
    MEDIUM,

    @SerialName("bold")
    BOLD,

    @SerialName("light")
    LIGHT
}

/**
 * Font style values.
 */
@Serializable
enum class FontStyle {
    @SerialName("normal")
    NORMAL,

    @SerialName("italic")
    ITALIC
}

/**
 * Text decoration values.
 */
@Serializable
enum class TextDecoration {
    @SerialName("none")
    NONE,

    @SerialName("underline")
    UNDERLINE,

    @SerialName("strikethrough")
    STRIKETHROUGH
}

/**
 * Text overflow behavior when text exceeds available space.
 */
@Serializable
enum class TextOverflow {
    @SerialName("clip")
    CLIP,           // Cut off at container edge

    @SerialName("ellipsis")
    ELLIPSIS,       // Show ellipsis (...)

    @SerialName("visible")
    VISIBLE         // Allow text to overflow container
}

/**
 * Orientation for divider and gallery.
 */
@Serializable
enum class Orientation {
    @SerialName("horizontal")
    HORIZONTAL,
    
    @SerialName("vertical")
    VERTICAL
}

/**
 * Snap behavior for gallery/carousel.
 */
@Serializable
enum class SnapBehavior {
    @SerialName("none")
    NONE,           // Free scrolling
    
    @SerialName("start")
    START,          // Snap to start
    
    @SerialName("center")
    CENTER,         // Snap to center (one item centered)
    
    @SerialName("end")
    END             // Snap to end
}

/**
 * Arrangement strategies for positioning children in Column/Row containers.
 * Maps to Jetpack Compose Arrangement options.
 */
@Serializable
enum class ArrangementStrategy {
    /**
     * Fixed spacing between children.
     * Uses the spacing value from ChildArrangement.
     * Maps to: Arrangement.spacedBy(spacing.dp)
     */
    @SerialName("spaced")
    SPACED,
    
    /**
     * Space between children, no space at edges.
     * Example: [child1]---[child2]---[child3]
     * Maps to: Arrangement.SpaceBetween
     */
    @SerialName("space_between")
    SPACE_BETWEEN,
    
    /**
     * Equal space between children AND at edges.
     * Example: ---[child1]---[child2]---[child3]---
     * Maps to: Arrangement.SpaceEvenly
     */
    @SerialName("space_evenly")
    SPACE_EVENLY,
    
    /**
     * Equal space around each child (half space at edges).
     * Example: -[child1]--[child2]--[child3]-
     * Maps to: Arrangement.SpaceAround
     */
    @SerialName("space_around")
    SPACE_AROUND,
    
    /**
     * Align children to start, no extra spacing.
     * Example: [child1][child2][child3]          
     * Maps to: Arrangement.Start (horizontal) / Arrangement.Top (vertical)
     */
    @SerialName("start")
    START,
    
    /**
     * Center children, no extra spacing.
     * Example:     [child1][child2][child3]     
     * Maps to: Arrangement.Center
     */
    @SerialName("center")
    CENTER,
    
    /**
     * Align children to end, no extra spacing.
     * Example:          [child1][child2][child3]
     * Maps to: Arrangement.End (horizontal) / Arrangement.Bottom (vertical)
     */
    @SerialName("end")
    END
}

/**
 * Animation types for component entrance effects.
 * Each component animates independently on first appearance.
 */
@Serializable
enum class AnimationType {
    @SerialName("none")
    NONE,

    // === FADE ANIMATIONS ===
    @SerialName("fade_in")
    FADE_IN,

    // === SLIDE ANIMATIONS ===
    @SerialName("slide_in_left")
    SLIDE_IN_LEFT,

    @SerialName("slide_in_right")
    SLIDE_IN_RIGHT,

    @SerialName("slide_in_top")
    SLIDE_IN_TOP,

    @SerialName("slide_in_bottom")
    SLIDE_IN_BOTTOM,

    // === SCALE ANIMATIONS ===
    @SerialName("scale_in")
    SCALE_IN,

    // === COMBINED ANIMATIONS ===
    @SerialName("fade_scale_in")
    FADE_SCALE_IN,

    @SerialName("fade_slide_in")
    FADE_SLIDE_IN
}

/**
 * Easing functions for animations.
 * Maps to Compose's built-in easing functions.
 */
@Serializable
enum class Easing {
    @SerialName("linear")
    LINEAR,

    @SerialName("ease_in")
    EASE_IN,

    @SerialName("ease_out")
    EASE_OUT,

    @SerialName("ease_in_out")
    EASE_IN_OUT,

    @SerialName("ease_in_back")
    EASE_IN_BACK,

    @SerialName("ease_out_back")
    EASE_OUT_BACK,

    @SerialName("spring")
    SPRING
}
