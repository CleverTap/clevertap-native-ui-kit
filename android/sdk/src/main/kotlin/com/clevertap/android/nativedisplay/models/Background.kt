package com.clevertap.android.nativedisplay.models

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Background configuration for elements and containers.
 * Supports various background types from simple colors to complex animations.
 */
@Immutable
@Serializable
sealed class Background {
    /**
     * Solid color background.
     */
    @Immutable
    @Serializable
    @SerialName("solid")
    data class Solid(
        @SerialName("color")
        val color: String
    ) : Background()
    
    /**
     * Linear gradient background.
     * Colors blend in a straight line at the specified angle.
     */
    @Immutable
    @Serializable
    @SerialName("linear_gradient")
    data class LinearGradient(
        @SerialName("angle")
        val angle: Float,
        @SerialName("colors")
        val colors: List<String>,
        @SerialName("stops")
        val stops: List<Float>? = null
    ) : Background()
    
    /**
     * Radial gradient background.
     * Colors blend from center outward in a circular pattern.
     */
    @Immutable
    @Serializable
    @SerialName("radial_gradient")
    data class RadialGradient(
        @SerialName("center_x")
        val centerX: Float = 0.5f,
        @SerialName("center_y")
        val centerY: Float = 0.5f,
        @SerialName("radius")
        val radius: Float = 1.0f,
        @SerialName("colors")
        val colors: List<String>,
        @SerialName("stops")
        val stops: List<Float>? = null
    ) : Background()
    
    /**
     * Sweep/Conic gradient background.
     * Colors blend in a circular sweep pattern.
     */
    @Immutable
    @Serializable
    @SerialName("sweep_gradient")
    data class SweepGradient(
        @SerialName("center_x")
        val centerX: Float = 0.5f,
        @SerialName("center_y")
        val centerY: Float = 0.5f,
        @SerialName("start_angle")
        val startAngle: Float = 0f,
        @SerialName("colors")
        val colors: List<String>,
        @SerialName("stops")
        val stops: List<Float>? = null
    ) : Background()
    
    /**
     * Image background.
     * Static image with various fit modes and effects.
     */
    @Immutable
    @Serializable
    @SerialName("image")
    data class Image(
        @SerialName("url")
        val url: String,
        @SerialName("fit")
        val fit: ImageFit = ImageFit.CROP,
        @SerialName("opacity")
        val opacity: Float = 1.0f,
        @SerialName("blur")
        val blur: Float = 0f,
        @SerialName("tint")
        val tint: String? = null,
        @SerialName("tint_opacity")
        val tintOpacity: Float = 0f
    ) : Background()
    
    /**
     * Shimmer/shine effect background.
     * Light sweeps across background - great for loading states.
     */
    @Immutable
    @Serializable
    @SerialName("shimmer")
    data class Shimmer(
        @SerialName("base_color")
        val baseColor: String,
        @SerialName("highlight_color")
        val highlightColor: String,
        @SerialName("angle")
        val angle: Float = 45f,
        @SerialName("duration")
        val duration: Long = 1500,
        @SerialName("loop")
        val loop: Boolean = true
    ) : Background()
    
    /**
     * Animated gradient background.
     * Gradient with animated color transitions.
     */
    @Immutable
    @Serializable
    @SerialName("animated_gradient")
    data class AnimatedGradient(
        @SerialName("gradient_type")
        val gradientType: GradientType,
        @SerialName("angle")
        val angle: Float = 0f,
        @SerialName("colors")
        val colors: List<String>,
        @SerialName("duration")
        val duration: Long = 3000,
        @SerialName("loop")
        val loop: Boolean = true,
        @SerialName("animation_style")
        val animationStyle: AnimationStyle = AnimationStyle.SMOOTH
    ) : Background()
    
    /**
     * Pulse/breathing effect background.
     * Background opacity or color pulses.
     */
    @Immutable
    @Serializable
    @SerialName("pulse")
    data class Pulse(
        @SerialName("color")
        val color: String,
        @SerialName("min_opacity")
        val minOpacity: Float = 0.3f,
        @SerialName("max_opacity")
        val maxOpacity: Float = 1.0f,
        @SerialName("duration")
        val duration: Long = 1000,
        @SerialName("loop")
        val loop: Boolean = true
    ) : Background()
    
    /**
     * Pattern background.
     * Repeating visual pattern.
     */
    @Immutable
    @Serializable
    @SerialName("pattern")
    data class Pattern(
        @SerialName("pattern_type")
        val patternType: PatternType,
        @SerialName("primary_color")
        val primaryColor: String,
        @SerialName("secondary_color")
        val secondaryColor: String,
        @SerialName("size")
        val size: Float = 20f,
        @SerialName("spacing")
        val spacing: Float = 30f,
        @SerialName("opacity")
        val opacity: Float = 1.0f
    ) : Background()
    
    /**
     * Particle effect background.
     * Moving particles in background.
     */
    @Immutable
    @Serializable
    @SerialName("particles")
    data class Particles(
        @SerialName("particle_color")
        val particleColor: String,
        @SerialName("particle_count")
        val particleCount: Int = 50,
        @SerialName("particle_size")
        val particleSize: Float = 4f,
        @SerialName("speed")
        val speed: Float = 2f,
        @SerialName("direction")
        val direction: ParticleDirection = ParticleDirection.UP,
        @SerialName("opacity")
        val opacity: Float = 0.7f
    ) : Background()
    
    /**
     * Layered background.
     * Multiple background layers stacked.
     */
    @Immutable
    @Serializable
    @SerialName("layered")
    data class Layered(
        @SerialName("layers")
        val layers: List<Background>
    ) : Background()
}

/**
 * Image fit modes for image backgrounds.
 */
@Serializable
enum class ImageFit {
    @SerialName("crop")
    CROP,       // Fill entire area, may crop edges

    @SerialName("contain")
    CONTAIN,    // Fit within area, may letterbox

    @SerialName("fill")
    FILL,       // Stretch to fill

    @SerialName("tile")
    TILE        // Repeat image
}

/**
 * Gradient type for animated gradients.
 */
@Serializable
enum class GradientType {
    @SerialName("linear")
    LINEAR,
    
    @SerialName("radial")
    RADIAL,
    
    @SerialName("sweep")
    SWEEP
}

/**
 * Animation style for animated backgrounds.
 */
@Serializable
enum class AnimationStyle {
    @SerialName("smooth")
    SMOOTH,     // Colors blend smoothly
    
    @SerialName("shift")
    SHIFT,      // Colors shift positions
    
    @SerialName("pulse")
    PULSE       // Colors pulse intensity
}

/**
 * Pattern types for pattern backgrounds.
 */
@Serializable
enum class PatternType {
    @SerialName("dots")
    DOTS,
    
    @SerialName("stripes_horizontal")
    STRIPES_HORIZONTAL,
    
    @SerialName("stripes_vertical")
    STRIPES_VERTICAL,
    
    @SerialName("stripes_diagonal")
    STRIPES_DIAGONAL,
    
    @SerialName("grid")
    GRID,
    
    @SerialName("checkerboard")
    CHECKERBOARD,
    
    @SerialName("polka_dots")
    POLKA_DOTS
}

/**
 * Particle movement direction.
 */
@Serializable
enum class ParticleDirection {
    @SerialName("up")
    UP,
    
    @SerialName("down")
    DOWN,
    
    @SerialName("left")
    LEFT,
    
    @SerialName("right")
    RIGHT,
    
    @SerialName("random")
    RANDOM
}
