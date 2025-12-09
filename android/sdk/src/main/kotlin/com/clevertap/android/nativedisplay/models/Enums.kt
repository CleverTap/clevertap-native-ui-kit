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
    
    @SerialName("stack")
    STACK
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
    SPACER
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
