package com.clevertap.android.nativedisplay.renderer

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import coil.compose.rememberAsyncImagePainter
import coil.request.ImageRequest
import com.clevertap.android.nativedisplay.internal.ImageLoaderProvider
import com.clevertap.android.nativedisplay.models.*
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/**
 * Apply background to a modifier based on the Background configuration.
 * 
 * This is @Composable because animated backgrounds (Shimmer, AnimatedGradient, Pulse, 
 * Particles) require Compose animation APIs. Static backgrounds (Solid, LinearGradient, etc.) 
 * are delegated to non-composable implementations for optimal performance.
 * 
 * @param background The background configuration to apply
 * @return Modified Modifier with background applied
 */
@Composable
internal fun Modifier.applyBackground(background: Background?): Modifier {
    if (background == null) return this
    
    return when (background) {
        // Static backgrounds - use non-composable implementations
        is Background.Solid -> this.applyStaticSolid(background)
        is Background.LinearGradient -> this.applyStaticLinearGradient(background)
        is Background.RadialGradient -> this.applyStaticRadialGradient(background)
        is Background.SweepGradient -> this.applyStaticSweepGradient(background)
        is Background.Pattern -> this.applyStaticPattern(background)
        is Background.Image -> this.applyStaticImage(background)
        
        // Animated backgrounds - require @Composable
        is Background.Shimmer -> this.applyAnimatedShimmer(background)
        is Background.AnimatedGradient -> this.applyAnimatedGradient(background)
        is Background.Pulse -> this.applyAnimatedPulse(background)
        is Background.Particles -> this.applyAnimatedParticles(background)
        is Background.Layered -> this.applyLayeredBackground(background)
    }
}

// ============================================================================
// STATIC BACKGROUNDS (Non-Composable)
// ============================================================================

/**
 * Apply solid color background (non-composable).
 */
private fun Modifier.applyStaticSolid(bg: Background.Solid): Modifier {
    val color = parseColor(bg.color) ?: Color.Transparent
    return this.background(color)
}

/**
 * Apply linear gradient background (non-composable).
 * Uses drawWithContent so gradient start/end are computed from the actual component
 * size at draw time — fixes solid-color appearance on small elements like buttons.
 */
private fun Modifier.applyStaticLinearGradient(bg: Background.LinearGradient): Modifier {
    val colors = bg.colors.mapNotNull { parseColor(it) }
    if (colors.isEmpty()) return this

    return this.drawWithContent {
        val angleRadians = Math.toRadians((bg.angle - 90.0))
        val start = Offset(
            x = (0.5f - cos(angleRadians).toFloat() * 0.5f) * size.width,
            y = (0.5f - sin(angleRadians).toFloat() * 0.5f) * size.height
        )
        val end = Offset(
            x = (0.5f + cos(angleRadians).toFloat() * 0.5f) * size.width,
            y = (0.5f + sin(angleRadians).toFloat() * 0.5f) * size.height
        )
        val brush = if (bg.stops != null && bg.stops.isNotEmpty()) {
            val colorStops = colors.mapIndexed { index, color ->
                val stop = bg.stops.getOrNull(index) ?: (index.toFloat() / (colors.size - 1))
                stop to color
            }
            Brush.linearGradient(
                colorStops = colorStops.toTypedArray(),
                start = start,
                end = end
            )
        } else {
            Brush.linearGradient(
                colors = colors,
                start = start,
                end = end
            )
        }
        drawRect(brush)
        drawContent()
    }
}

/**
 * Apply radial gradient background (non-composable).
 */
private fun Modifier.applyStaticRadialGradient(bg: Background.RadialGradient): Modifier {
    val colors = bg.colors.mapNotNull { parseColor(it) }
    if (colors.isEmpty()) return this
    
    return this.drawWithContent {
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
 * Apply sweep/conic gradient background (non-composable).
 */
private fun Modifier.applyStaticSweepGradient(bg: Background.SweepGradient): Modifier {
    val colors = bg.colors.mapNotNull { parseColor(it) }
    if (colors.isEmpty()) return this
    
    return this.drawWithContent {
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
 * Apply pattern background (non-composable).
 */
private fun Modifier.applyStaticPattern(bg: Background.Pattern): Modifier {
    val primaryColor = parseColor(bg.primaryColor) ?: Color.Gray
    val secondaryColor = parseColor(bg.secondaryColor) ?: Color.LightGray
    
    return this.drawWithContent {
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
 * Apply image background.
 * Loads asynchronously via Coil and paints behind content using drawWithContent.
 */
@Composable
private fun Modifier.applyStaticImage(bg: Background.Image): Modifier {
    val context = LocalContext.current
    val imageLoaderFactory = LocalImageLoader.current
    val imageLoader = remember(context, imageLoaderFactory) {
        imageLoaderFactory?.invoke(context) ?: ImageLoaderProvider.getImageLoader(context)
    }

    val contentScale = when (bg.fit) {
        ImageFit.CROP -> ContentScale.Crop
        ImageFit.CONTAIN -> ContentScale.Fit
        ImageFit.FILL -> ContentScale.FillBounds
        ImageFit.TILE -> ContentScale.Crop
    }

    val painter = rememberAsyncImagePainter(
        model = ImageRequest.Builder(context)
            .data(bg.url)
            .crossfade(true)
            .build(),
        imageLoader = imageLoader,
        contentScale = contentScale
    )

    return this.drawWithContent {
        with(painter) {
            draw(size = this@drawWithContent.size, alpha = bg.opacity)
        }
        drawContent()
    }
}

// ============================================================================
// ANIMATED BACKGROUNDS (Composable)
// ============================================================================

/**
 * Apply shimmer effect background (animated, requires @Composable).
 */
@Composable
private fun Modifier.applyAnimatedShimmer(bg: Background.Shimmer): Modifier {
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
    
    return this.drawWithContent {
        val angleRadians = Math.toRadians((bg.angle - 90.0))
        // Offset pans the gradient across the component; scale by component dimension so
        // the sweep covers the full component regardless of its size.
        val panX = offset * size.width
        val panY = offset * size.height
        val shimmerStart = Offset(
            x = (0.5f - cos(angleRadians).toFloat() * 0.5f) * size.width + panX,
            y = (0.5f - sin(angleRadians).toFloat() * 0.5f) * size.height + panY
        )
        val shimmerEnd = Offset(
            x = (0.5f + cos(angleRadians).toFloat() * 0.5f) * size.width + panX,
            y = (0.5f + sin(angleRadians).toFloat() * 0.5f) * size.height + panY
        )
        val brush = Brush.linearGradient(
            colors = listOf(baseColor, highlightColor, baseColor),
            start = shimmerStart,
            end = shimmerEnd
        )
        drawRect(brush)
        drawContent()
    }
}

/**
 * Apply animated gradient background (animated, requires @Composable).
 */
@Composable
private fun Modifier.applyAnimatedGradient(bg: Background.AnimatedGradient): Modifier {
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
    if (colors.isEmpty()) return this
    
    return this.drawWithContent {
        // Rotate colors based on animation style
        val rotatedColors = when (bg.animationStyle) {
            AnimationStyle.SMOOTH -> colors  // Colors stay in place, just animate
            AnimationStyle.SHIFT -> {
                // Shift color positions
                val shift = (animatedValue * colors.size).toInt()
                colors.takeLast(shift) + colors.dropLast(shift)
            }
            AnimationStyle.PULSE -> colors  // Same as smooth for now
        }
        
        val angleRadians = Math.toRadians((bg.angle - 90.0))
        val gradStart = Offset(
            x = (0.5f - cos(angleRadians).toFloat() * 0.5f) * size.width,
            y = (0.5f - sin(angleRadians).toFloat() * 0.5f) * size.height
        )
        val gradEnd = Offset(
            x = (0.5f + cos(angleRadians).toFloat() * 0.5f) * size.width,
            y = (0.5f + sin(angleRadians).toFloat() * 0.5f) * size.height
        )
        val brush = when (bg.gradientType) {
            GradientType.LINEAR -> Brush.linearGradient(
                colors = rotatedColors,
                start = gradStart,
                end = gradEnd
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
 * Apply pulse/breathing effect background (animated, requires @Composable).
 */
@Composable
private fun Modifier.applyAnimatedPulse(bg: Background.Pulse): Modifier {
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
    return this.background(color)
}

/**
 * Apply particles effect background (animated, requires @Composable).
 */
@Composable
private fun Modifier.applyAnimatedParticles(bg: Background.Particles): Modifier {
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
    
    return this.drawWithContent {
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
 * Apply layered background (requires @Composable due to recursive calls).
 */
@Composable
private fun Modifier.applyLayeredBackground(bg: Background.Layered): Modifier {
    var modifier = this as Modifier
    bg.layers.forEach { layer ->
        modifier = modifier.applyBackground(layer)
    }
    return modifier
}

// ============================================================================
// HELPER FUNCTIONS (Non-Composable)
// ============================================================================


/**
 * Draw dots pattern.
 * Pure drawing function - no composition needed.
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
 * Pure drawing function - no composition needed.
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
 * Pure drawing function - no composition needed.
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
 * Pure drawing function - no composition needed.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawDiagonalStripes(
    color: Color,
    stripeWidth: Float,
    spacing: Float
) {
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
 * Pure drawing function - no composition needed.
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
 * Pure drawing function - no composition needed.
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
 * Pure drawing function - no composition needed.
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
 * Pure data structure - no composition needed.
 */
private data class Particle(
    val x: Float,
    val y: Float,
    val vx: Float,
    val vy: Float
)
