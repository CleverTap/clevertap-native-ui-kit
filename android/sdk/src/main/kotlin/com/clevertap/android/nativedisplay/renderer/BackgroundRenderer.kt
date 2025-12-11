package com.clevertap.android.nativedisplay.renderer

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil.compose.rememberAsyncImagePainter
import com.clevertap.android.nativedisplay.models.*
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/**
 * Apply background to a modifier based on the Background configuration.
 */
@Composable
fun Modifier.applyBackground(background: Background?): Modifier {
    if (background == null) return this
    
    return this.then(
        when (background) {
            is Background.Solid -> applySolidBackground(background)
            is Background.LinearGradient -> applyLinearGradient(background)
            is Background.RadialGradient -> applyRadialGradient(background)
            is Background.SweepGradient -> applySweepGradient(background)
            is Background.Image -> applyImageBackground(background)
            is Background.Shimmer -> applyShimmerBackground(background)
            is Background.AnimatedGradient -> applyAnimatedGradient(background)
            is Background.Pulse -> applyPulseBackground(background)
            is Background.Pattern -> applyPatternBackground(background)
            is Background.Particles -> applyParticlesBackground(background)
            is Background.Layered -> applyLayeredBackground(background)
        }
    )
}

/**
 * Solid color background.
 */
@Composable
private fun applySolidBackground(bg: Background.Solid): Modifier {
    val color = parseColor(bg.color) ?: Color.Transparent
    return Modifier.background(color)
}

/**
 * Linear gradient background.
 */
@Composable
private fun applyLinearGradient(bg: Background.LinearGradient): Modifier {
    val colors = bg.colors.mapNotNull { parseColor(it) }
    if (colors.isEmpty()) return Modifier
    
    // Create color stops if provided
    val brush = if (bg.stops != null && bg.stops.isNotEmpty()) {
        val colorStops = colors.mapIndexed { index, color ->
            val stop = bg.stops.getOrNull(index) ?: (index.toFloat() / (colors.size - 1))
            stop to color
        }
        Brush.linearGradient(
            colorStops = colorStops.toTypedArray(),
            start = calculateGradientStart(bg.angle),
            end = calculateGradientEnd(bg.angle)
        )
    } else {
        Brush.linearGradient(
            colors = colors,
            start = calculateGradientStart(bg.angle),
            end = calculateGradientEnd(bg.angle)
        )
    }
    
    return Modifier.background(brush)
}

/**
 * Radial gradient background.
 */
@Composable
private fun applyRadialGradient(bg: Background.RadialGradient): Modifier {
    val colors = bg.colors.mapNotNull { parseColor(it) }
    if (colors.isEmpty()) return Modifier
    
    return Modifier.drawWithContent {
        val brush = if (bg.stops != null && bg.stops.isNotEmpty()) {
            val colorStops = colors.mapIndexed { index, color ->
                val stop = bg.stops.getOrNull(index) ?: (index.toFloat() / (colors.size - 1))
                stop to color
            }
            Brush.radialGradient(
                colorStops = colorStops.toTypedArray(),
                center = Offset(size.width * bg.centerX, size.height * bg.centerY),
                radius = size.minDimension * bg.radius
            )
        } else {
            Brush.radialGradient(
                colors = colors,
                center = Offset(size.width * bg.centerX, size.height * bg.centerY),
                radius = size.minDimension * bg.radius
            )
        }
        drawRect(brush)
        drawContent()
    }
}

/**
 * Sweep/Conic gradient background.
 */
@Composable
private fun applySweepGradient(bg: Background.SweepGradient): Modifier {
    val colors = bg.colors.mapNotNull { parseColor(it) }
    if (colors.isEmpty()) return Modifier
    
    return Modifier.drawWithContent {
        val brush = if (bg.stops != null && bg.stops.isNotEmpty()) {
            val colorStops = colors.mapIndexed { index, color ->
                val stop = bg.stops.getOrNull(index) ?: (index.toFloat() / (colors.size - 1))
                stop to color
            }
            Brush.sweepGradient(
                colorStops = colorStops.toTypedArray(),
                center = Offset(size.width * bg.centerX, size.height * bg.centerY)
            )
        } else {
            Brush.sweepGradient(
                colors = colors,
                center = Offset(size.width * bg.centerX, size.height * bg.centerY)
            )
        }
        drawRect(brush)
        drawContent()
    }
}

/**
 * Image background.
 */
@Composable
private fun applyImageBackground(bg: Background.Image): Modifier {
    return Modifier.drawWithContent {
        drawContent()
        
        // Note: Image rendering needs to be done in a Box overlay
        // This is a simplified version
    }.background(Color.Transparent)
}

/**
 * Shimmer effect background.
 */
@Composable
private fun applyShimmerBackground(bg: Background.Shimmer): Modifier {
    val infiniteTransition = rememberInfiniteTransition(label = "shimmer")
    val offset by infiniteTransition.animateFloat(
        initialValue = -1f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(bg.duration.toInt(), easing = LinearEasing),
            repeatMode = if (bg.loop) RepeatMode.Restart else RepeatMode.Reverse
        ),
        label = "shimmer_offset"
    )
    
    val baseColor = parseColor(bg.baseColor) ?: Color.LightGray
    val highlightColor = parseColor(bg.highlightColor) ?: Color.White
    
    return Modifier.drawWithContent {
        val brush = Brush.linearGradient(
            colors = listOf(
                baseColor,
                highlightColor,
                baseColor
            ),
            start = calculateGradientStart(bg.angle, offset),
            end = calculateGradientEnd(bg.angle, offset)
        )
        drawRect(brush)
        drawContent()
    }
}

/**
 * Animated gradient background.
 */
@Composable
private fun applyAnimatedGradient(bg: Background.AnimatedGradient): Modifier {
    val infiniteTransition = rememberInfiniteTransition(label = "animated_gradient")
    val animatedValue by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(bg.duration.toInt(), easing = LinearEasing),
            repeatMode = if (bg.loop) RepeatMode.Restart else RepeatMode.Reverse
        ),
        label = "gradient_animation"
    )
    
    val colors = bg.colors.mapNotNull { parseColor(it) }
    if (colors.isEmpty()) return Modifier
    
    return Modifier.drawWithContent {
        // Rotate colors based on animation
        val rotatedColors = when (bg.animationStyle) {
            AnimationStyle.SMOOTH -> colors  // Colors stay in place, just animate
            AnimationStyle.SHIFT -> {
                // Shift color positions
                val shift = (animatedValue * colors.size).toInt()
                colors.takeLast(shift) + colors.dropLast(shift)
            }
            AnimationStyle.PULSE -> colors  // Same as smooth for now
        }
        
        val brush = when (bg.gradientType) {
            GradientType.LINEAR -> Brush.linearGradient(
                colors = rotatedColors,
                start = calculateGradientStart(bg.angle),
                end = calculateGradientEnd(bg.angle)
            )
            GradientType.RADIAL -> Brush.radialGradient(
                colors = rotatedColors,
                center = Offset(size.width * 0.5f, size.height * 0.5f),
                radius = size.minDimension * (0.5f + animatedValue * 0.5f)  // Animate radius
            )
            GradientType.SWEEP -> Brush.sweepGradient(
                colors = rotatedColors,
                center = Offset(size.width * 0.5f, size.height * 0.5f)
            )
        }
        
        drawRect(brush)
        drawContent()
    }
}

/**
 * Pulse/breathing effect background.
 */
@Composable
private fun applyPulseBackground(bg: Background.Pulse): Modifier {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val alpha by infiniteTransition.animateFloat(
        initialValue = bg.minOpacity,
        targetValue = bg.maxOpacity,
        animationSpec = infiniteRepeatable(
            animation = tween(bg.duration.toInt(), easing = FastOutSlowInEasing),
            repeatMode = if (bg.loop) RepeatMode.Reverse else RepeatMode.Restart
        ),
        label = "pulse_alpha"
    )
    
    val color = parseColor(bg.color)?.copy(alpha = alpha) ?: Color.Transparent
    return Modifier.background(color)
}

/**
 * Pattern background.
 */
@Composable
private fun applyPatternBackground(bg: Background.Pattern): Modifier {
    val primaryColor = parseColor(bg.primaryColor) ?: Color.Gray
    val secondaryColor = parseColor(bg.secondaryColor) ?: Color.LightGray
    
    return Modifier.drawWithContent {
        // Draw base color
        drawRect(primaryColor)
        
        // Draw pattern
        when (bg.patternType) {
            PatternType.DOTS -> drawDotsPattern(secondaryColor, bg.size, bg.spacing)
            PatternType.STRIPES_HORIZONTAL -> drawHorizontalStripes(secondaryColor, bg.size, bg.spacing)
            PatternType.STRIPES_VERTICAL -> drawVerticalStripes(secondaryColor, bg.size, bg.spacing)
            PatternType.STRIPES_DIAGONAL -> drawDiagonalStripes(secondaryColor, bg.size, bg.spacing)
            PatternType.GRID -> drawGridPattern(secondaryColor, bg.size, bg.spacing)
            PatternType.CHECKERBOARD -> drawCheckerboard(secondaryColor, bg.size)
            PatternType.POLKA_DOTS -> drawPolkaDotsPattern(secondaryColor, bg.size, bg.spacing)
        }
        
        drawContent()
    }
}

/**
 * Particles effect background.
 */
@Composable
private fun applyParticlesBackground(bg: Background.Particles): Modifier {
    val particles = remember {
        List(bg.particleCount) {
            Particle(
                x = Random.nextFloat(),
                y = Random.nextFloat(),
                vx = (Random.nextFloat() - 0.5f) * bg.speed,
                vy = when (bg.direction) {
                    ParticleDirection.UP -> -Random.nextFloat() * bg.speed
                    ParticleDirection.DOWN -> Random.nextFloat() * bg.speed
                    ParticleDirection.LEFT -> -Random.nextFloat() * bg.speed
                    ParticleDirection.RIGHT -> Random.nextFloat() * bg.speed
                    ParticleDirection.RANDOM -> (Random.nextFloat() - 0.5f) * bg.speed
                }
            )
        }
    }
    
    val infiniteTransition = rememberInfiniteTransition(label = "particles")
    val time by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "particle_time"
    )
    
    val particleColor = parseColor(bg.particleColor)?.copy(alpha = bg.opacity) ?: Color.White
    
    return Modifier.drawWithContent {
        drawContent()
        
        particles.forEach { particle ->
            val x = ((particle.x + particle.vx * time * 0.001f) % 1f) * size.width
            val y = ((particle.y + particle.vy * time * 0.001f) % 1f) * size.height
            
            drawCircle(
                color = particleColor,
                radius = bg.particleSize,
                center = Offset(x, y)
            )
        }
    }
}

/**
 * Layered background (multiple backgrounds stacked).
 */
@Composable
private fun applyLayeredBackground(bg: Background.Layered): Modifier {
    var modifier = Modifier as Modifier
    bg.layers.forEach { layer ->
        modifier = modifier.applyBackground(layer)
    }
    return modifier
}

// Helper functions

/**
 * Calculate gradient start offset based on angle.
 */
private fun calculateGradientStart(angleDegrees: Float, offset: Float = 0f): Offset {
    val angleRadians = Math.toRadians(angleDegrees.toDouble())
    val adjustedOffset = offset * 1000f
    return Offset(
        x = (0.5f - cos(angleRadians).toFloat() * 0.5f) * 1000f + adjustedOffset,
        y = (0.5f - sin(angleRadians).toFloat() * 0.5f) * 1000f + adjustedOffset
    )
}

/**
 * Calculate gradient end offset based on angle.
 */
private fun calculateGradientEnd(angleDegrees: Float, offset: Float = 0f): Offset {
    val angleRadians = Math.toRadians(angleDegrees.toDouble())
    val adjustedOffset = offset * 1000f
    return Offset(
        x = (0.5f + cos(angleRadians).toFloat() * 0.5f) * 1000f + adjustedOffset,
        y = (0.5f + sin(angleRadians).toFloat() * 0.5f) * 1000f + adjustedOffset
    )
}

/**
 * Draw dots pattern.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawDotsPattern(
    color: Color,
    dotSize: Float,
    spacing: Float
) {
    val rows = (size.height / spacing).toInt() + 1
    val cols = (size.width / spacing).toInt() + 1
    
    for (row in 0..rows) {
        for (col in 0..cols) {
            drawCircle(
                color = color,
                radius = dotSize / 2,
                center = Offset(col * spacing, row * spacing)
            )
        }
    }
}

/**
 * Draw horizontal stripes.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawHorizontalStripes(
    color: Color,
    stripeHeight: Float,
    spacing: Float
) {
    val count = (size.height / (stripeHeight + spacing)).toInt() + 1
    for (i in 0..count) {
        val y = i * (stripeHeight + spacing)
        drawRect(
            color = color,
            topLeft = Offset(0f, y),
            size = Size(size.width, stripeHeight)
        )
    }
}

/**
 * Draw vertical stripes.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawVerticalStripes(
    color: Color,
    stripeWidth: Float,
    spacing: Float
) {
    val count = (size.width / (stripeWidth + spacing)).toInt() + 1
    for (i in 0..count) {
        val x = i * (stripeWidth + spacing)
        drawRect(
            color = color,
            topLeft = Offset(x, 0f),
            size = Size(stripeWidth, size.height)
        )
    }
}

/**
 * Draw diagonal stripes.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawDiagonalStripes(
    color: Color,
    stripeWidth: Float,
    spacing: Float
) {
    // Simplified diagonal stripes implementation
    val count = ((size.width + size.height) / (stripeWidth + spacing)).toInt() + 1
    for (i in 0..count) {
        val offset = i * (stripeWidth + spacing)
        drawLine(
            color = color,
            start = Offset(offset, 0f),
            end = Offset(0f, offset),
            strokeWidth = stripeWidth
        )
    }
}

/**
 * Draw grid pattern.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawGridPattern(
    color: Color,
    lineWidth: Float,
    spacing: Float
) {
    drawHorizontalStripes(color, lineWidth, spacing)
    drawVerticalStripes(color, lineWidth, spacing)
}

/**
 * Draw checkerboard pattern.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawCheckerboard(
    color: Color,
    squareSize: Float
) {
    val rows = (size.height / squareSize).toInt() + 1
    val cols = (size.width / squareSize).toInt() + 1
    
    for (row in 0..rows) {
        for (col in 0..cols) {
            if ((row + col) % 2 == 0) {
                drawRect(
                    color = color,
                    topLeft = Offset(col * squareSize, row * squareSize),
                    size = Size(squareSize, squareSize)
                )
            }
        }
    }
}

/**
 * Draw polka dots pattern (larger dots with more spacing).
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawPolkaDotsPattern(
    color: Color,
    dotSize: Float,
    spacing: Float
) {
    drawDotsPattern(color, dotSize, spacing)
}

/**
 * Particle data class.
 */
private data class Particle(
    val x: Float,
    val y: Float,
    val vx: Float,
    val vy: Float
)
