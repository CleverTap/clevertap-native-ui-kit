// ============================================================================
// SDK INTERNAL IMPLEMENTATION - NOT CLIENT USAGE
// ============================================================================
// This shows SDK's internal background rendering. Clients only provide JSON.
// ============================================================================

// Custom Background Implementation Examples
// Demonstrates rendering all 10+ background types

package com.clevertap.android.nativedisplay.examples

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import kotlin.math.cos
import kotlin.math.sin

/**
 * Apply background based on type
 */
fun Modifier.applyBackgroundType(background: Background): Modifier {
    return when (background) {
        is Background.Solid -> applySolidBackground(background)
        is Background.LinearGradient -> applyLinearGradient(background)
        is Background.RadialGradient -> applyRadialGradient(background)
        is Background.SweepGradient -> applySweepGradient(background)
        is Background.Shimmer -> applyShimmer(background)
        is Background.AnimatedGradient -> applyAnimatedGradient(background)
        is Background.Pulse -> applyPulse(background)
        // ... other types
    }
}

// 1. Solid Background
fun Modifier.applySolidBackground(bg: Background.Solid): Modifier {
    return background(bg.color.parseColor())
}

// 2. Linear Gradient
fun Modifier.applyLinearGradient(bg: Background.LinearGradient): Modifier {
    val colors = bg.colors.map { it.parseColor() }
    val angleRad = Math.toRadians(bg.angle.toDouble())

    // Convert angle to start/end offset
    val startX = 0.5f - cos(angleRad).toFloat() * 0.5f
    val startY = 0.5f - sin(angleRad).toFloat() * 0.5f
    val endX = 0.5f + cos(angleRad).toFloat() * 0.5f
    val endY = 0.5f + sin(angleRad).toFloat() * 0.5f

    return background(
        Brush.linearGradient(
            colors = colors,
            start = Offset(startX, startY),
            end = Offset(endX, endY)
        )
    )
}

// 3. Radial Gradient
fun Modifier.applyRadialGradient(bg: Background.RadialGradient): Modifier {
    val colors = bg.colors.map { it.parseColor() }

    return background(
        Brush.radialGradient(
            colors = colors,
            center = Offset(bg.centerX, bg.centerY),
            radius = bg.radius
        )
    )
}

// 4. Sweep Gradient
fun Modifier.applySweepGradient(bg: Background.SweepGradient): Modifier {
    val colors = bg.colors.map { it.parseColor() }

    return background(
        Brush.sweepGradient(
            colors = colors,
            center = Offset(bg.centerX, bg.centerY)
        )
    )
}

// 5. Shimmer Background (Animated)
@Composable
fun Modifier.applyShimmer(bg: Background.Shimmer): Modifier {
    val infiniteTransition = rememberInfiniteTransition()
    val offsetX by infiniteTransition.animateFloat(
        initialValue = -1000f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = bg.duration.toInt(),
                easing = LinearEasing
            ),
            repeatMode = if (bg.loop) RepeatMode.Restart else RepeatMode.Reverse
        )
    )

    val baseColor = bg.baseColor.parseColor()
    val highlightColor = bg.highlightColor.parseColor()
    val angleRad = Math.toRadians(bg.angle.toDouble())

    return background(
        Brush.linearGradient(
            colors = listOf(baseColor, highlightColor, baseColor),
            start = Offset(offsetX, offsetX),
            end = Offset(
                offsetX + 500f * cos(angleRad).toFloat(),
                offsetX + 500f * sin(angleRad).toFloat()
            )
        )
    )
}

// 6. Animated Gradient
@Composable
fun Modifier.applyAnimatedGradient(bg: Background.AnimatedGradient): Modifier {
    val infiniteTransition = rememberInfiniteTransition()
    val angle by infiniteTransition.animateFloat(
        initialValue = bg.angle,
        targetValue = bg.angle + 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = bg.duration.toInt(),
                easing = when (bg.animationStyle) {
                    AnimationStyle.SMOOTH -> LinearEasing
                    AnimationStyle.SHIFT -> FastOutSlowInEasing
                    AnimationStyle.PULSE -> CubicBezierEasing(0.4f, 0f, 0.6f, 1f)
                }
            ),
            repeatMode = if (bg.loop) RepeatMode.Restart else RepeatMode.Reverse
        )
    )

    val colors = bg.colors.map { it.parseColor() }
    val angleRad = Math.toRadians(angle.toDouble())

    return background(
        Brush.linearGradient(
            colors = colors,
            start = Offset(
                0.5f - cos(angleRad).toFloat() * 0.5f,
                0.5f - sin(angleRad).toFloat() * 0.5f
            ),
            end = Offset(
                0.5f + cos(angleRad).toFloat() * 0.5f,
                0.5f + sin(angleRad).toFloat() * 0.5f
            )
        )
    )
}

// 7. Pulse Background (Animated Opacity)
@Composable
fun Modifier.applyPulse(bg: Background.Pulse): Modifier {
    val infiniteTransition = rememberInfiniteTransition()
    val alpha by infiniteTransition.animateFloat(
        initialValue = bg.minOpacity,
        targetValue = bg.maxOpacity,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = bg.duration.toInt(),
                easing = FastOutSlowInEasing
            ),
            repeatMode = if (bg.loop) RepeatMode.Reverse else RepeatMode.Restart
        )
    )

    val color = bg.color.parseColor().copy(alpha = alpha)
    return background(color)
}

/*
USAGE EXAMPLES:

// 1. Solid Background
val solidBg = Background.Solid(color = "#FF5722")

// 2. Linear Gradient (45 degrees, red to blue)
val linearGradient = Background.LinearGradient(
    angle = 45f,
    colors = listOf("#FF5722", "#2196F3"),
    stops = listOf(0f, 1f)
)

// 3. Radial Gradient (center, red to transparent)
val radialGradient = Background.RadialGradient(
    centerX = 0.5f,
    centerY = 0.5f,
    radius = 0.8f,
    colors = listOf("#FF5722", "#00000000"),
    stops = listOf(0f, 1f)
)

// 4. Shimmer Effect
val shimmer = Background.Shimmer(
    baseColor = "#E0E0E0",
    highlightColor = "#F5F5F5",
    angle = 45f,
    duration = 1500,
    loop = true
)

// 5. Animated Gradient
val animatedGradient = Background.AnimatedGradient(
    gradientType = GradientType.LINEAR,
    angle = 0f,
    colors = listOf("#FF5722", "#FFC107", "#4CAF50", "#2196F3"),
    duration = 3000,
    loop = true,
    animationStyle = AnimationStyle.SMOOTH
)

// 6. Pulse Effect
val pulse = Background.Pulse(
    color = "#2196F3",
    minOpacity = 0.3f,
    maxOpacity = 1.0f,
    duration = 1000,
    loop = true
)

// Apply to node
val node = NativeDisplayNode(
    id = "card",
    containerType = ContainerType.VERTICAL,
    style = Style(
        background = shimmer  // Use shimmer background
    ),
    layout = Layout(
        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
        height = Dimension(value = 200f, unit = DimensionUnit.DP)
    )
)

@Composable
fun ShimmerCard() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .applyBackgroundType(shimmer)  // Apply animated background
    ) {
        // Card content
    }
}

JSON CONFIGURATION:

{
  "style": {
    "background": {
      "type": "shimmer",
      "baseColor": "#E0E0E0",
      "highlightColor": "#F5F5F5",
      "angle": 45,
      "duration": 1500,
      "loop": true
    }
  }
}

PERFORMANCE TIPS:
1. Animated backgrounds use infiniteRepeatable - optimize duration
2. Cache gradient brushes with remember {} when possible
3. Limit particle count in Particles background
4. Use Shimmer sparingly (loading states only)
5. Test on lower-end devices

COMMON PATTERNS:
- Loading skeleton: Shimmer
- Hero sections: Animated gradient
- Call-to-action buttons: Pulse
- Product cards: Linear gradient
- Background overlays: Radial gradient
*/
