package com.clevertap.android.nativeui.sample.samples

import com.clevertap.android.nativedisplay.models.*

/**
 * Sample configurations demonstrating all background types.
 */
object BackgroundSamples {
    
    /**
     * Tab 10: Linear Gradients Demo
     */
    fun linearGradientsSample() = ResolvedConfig(
        root = NativeDisplayContainer(
            id = "bg_linear_root",
            containerType = ContainerType.VERTICAL,
            layout = Layout(
                arrangement = ChildArrangement.spaced(16f),
                padding = Spacing(all = 16f)
            ),
            children = listOf(
                // Diagonal gradient
                NativeDisplayContainer(
                    id = "bg_linear_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 100f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.LinearGradient(
                            angle = 45f,
                            colors = listOf("#FF6B6B", "#4ECDC4")
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_linear_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Diagonal Gradient (45°)"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Vertical gradient
                NativeDisplayContainer(
                    id = "bg_linear_2",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 100f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.LinearGradient(
                            angle = 180f,
                            colors = listOf("#667eea", "#764ba2")
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_linear_2_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Vertical Gradient (180°)"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Multi-color gradient
                NativeDisplayContainer(
                    id = "bg_linear_3",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 100f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.LinearGradient(
                            angle = 90f,
                            colors = listOf("#FA709A", "#FEE140", "#30CFD0")
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_linear_3_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Multi-Color Gradient"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                )
            )
        ),
        theme = Theme.DEFAULT,
        styleClasses = emptyList(),
        variables = emptyMap()
    )
    
    /**
     * Tab 11: Radial & Sweep Gradients Demo
     */
    fun radialAndSweepGradientsSample() = ResolvedConfig(
        root = NativeDisplayContainer(
            id = "bg_radial_root",
            containerType = ContainerType.VERTICAL,
            layout = Layout(
                arrangement = ChildArrangement.spaced(16f),
                padding = Spacing(all = 16f)
            ),
            children = listOf(
                // Radial gradient (centered)
                NativeDisplayContainer(
                    id = "bg_radial_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 150f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.RadialGradient(
                            centerX = 0.5f,
                            centerY = 0.5f,
                            radius = 1.0f,
                            colors = listOf("#FFD700", "#FF6B6B")
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_radial_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Radial Gradient (Center)"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Sweep gradient
                NativeDisplayContainer(
                    id = "bg_sweep_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 150f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.SweepGradient(
                            centerX = 0.5f,
                            centerY = 0.5f,
                            colors = listOf("#FF0000", "#00FF00", "#0000FF", "#FF0000")
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_sweep_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Sweep Gradient (Conic)"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                )
            )
        ),
        theme = Theme.DEFAULT,
        styleClasses = emptyList(),
        variables = emptyMap()
    )
    
    /**
     * Tab 12: Animated Backgrounds Demo
     */
    fun animatedBackgroundsSample() = ResolvedConfig(
        root = NativeDisplayContainer(
            id = "bg_animated_root",
            containerType = ContainerType.VERTICAL,
            layout = Layout(
                arrangement = ChildArrangement.spaced(16f),
                padding = Spacing(all = 16f)
            ),
            children = listOf(
                // Shimmer effect
                NativeDisplayContainer(
                    id = "bg_shimmer_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 80f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Shimmer(
                            baseColor = "#E0E0E0",
                            highlightColor = "#F5F5F5",
                            angle = 45f,
                            duration = 1500
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_shimmer_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Shimmer Loading Effect"),
                            style = Style(
                                textColor = "#666666",
                                fontSize = TextDimension(18f)
                            )
                        )
                    )
                ),
                
                // Animated gradient
                NativeDisplayContainer(
                    id = "bg_anim_grad_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 80f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.AnimatedGradient(
                            gradientType = GradientType.LINEAR,
                            angle = 45f,
                            colors = listOf("#FFD700", "#FFA500", "#FFD700"),
                            duration = 3000,
                            loop = true,
                            animationStyle = AnimationStyle.SMOOTH
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_anim_grad_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Animated Gradient (Premium)"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Pulse effect
                NativeDisplayContainer(
                    id = "bg_pulse_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 80f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Pulse(
                            color = "#FF6B6B",
                            minOpacity = 0.3f,
                            maxOpacity = 1.0f,
                            duration = 1000,
                            loop = true
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_pulse_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Pulse Effect (Live Status)"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Particles effect
                NativeDisplayContainer(
                    id = "bg_particles_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 120f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Particles(
                            particleColor = "#FFD700",
                            particleCount = 30,
                            particleSize = 4f,
                            speed = 1.5f,
                            direction = ParticleDirection.UP,
                            opacity = 0.7f
                        ),
                        backgroundColor = "#1A1A2E",
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_particles_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Particles Effect (Celebration)"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                )
            )
        ),
        theme = Theme.DEFAULT,
        styleClasses = emptyList(),
        variables = emptyMap()
    )
    
    /**
     * Tab 13: Pattern Backgrounds Demo
     */
    fun patternBackgroundsSample() = ResolvedConfig(
        root = NativeDisplayContainer(
            id = "bg_pattern_root",
            containerType = ContainerType.VERTICAL,
            layout = Layout(
                arrangement = ChildArrangement.spaced(16f),
                padding = Spacing(all = 16f)
            ),
            children = listOf(
                // Dots pattern
                NativeDisplayContainer(
                    id = "bg_dots_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 80f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Pattern(
                            patternType = PatternType.DOTS,
                            primaryColor = "#F0F0F0",
                            secondaryColor = "#CCCCCC",
                            size = 8f,
                            spacing = 20f
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_dots_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Dots Pattern"),
                            style = Style(
                                textColor = "#333333",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Stripes pattern
                NativeDisplayContainer(
                    id = "bg_stripes_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 80f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Pattern(
                            patternType = PatternType.STRIPES_HORIZONTAL,
                            primaryColor = "#F5F5F5",
                            secondaryColor = "#E0E0E0",
                            size = 10f,
                            spacing = 15f
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_stripes_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Horizontal Stripes"),
                            style = Style(
                                textColor = "#333333",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Grid pattern
                NativeDisplayContainer(
                    id = "bg_grid_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 80f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Pattern(
                            patternType = PatternType.GRID,
                            primaryColor = "#FFFFFF",
                            secondaryColor = "#DDDDDD",
                            size = 2f,
                            spacing = 30f
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_grid_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Grid Pattern"),
                            style = Style(
                                textColor = "#333333",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Checkerboard
                NativeDisplayContainer(
                    id = "bg_checker_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 80f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Pattern(
                            patternType = PatternType.CHECKERBOARD,
                            primaryColor = "#F0F0F0",
                            secondaryColor = "#E0E0E0",
                            size = 20f,
                            spacing = 0f
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_checker_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Checkerboard"),
                            style = Style(
                                textColor = "#333333",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                )
            )
        ),
        theme = Theme.DEFAULT,
        styleClasses = emptyList(),
        variables = emptyMap()
    )
    
    /**
     * Tab 14: Layered & Complex Backgrounds Demo
     */
    fun layeredBackgroundsSample() = ResolvedConfig(
        root = NativeDisplayContainer(
            id = "bg_layered_root",
            containerType = ContainerType.VERTICAL,
            layout = Layout(
                arrangement = ChildArrangement.spaced(16f),
                padding = Spacing(all = 16f)
            ),
            children = listOf(
                // Gradient + Pattern
                NativeDisplayContainer(
                    id = "bg_layered_1",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 120f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Layered(
                            layers = listOf(
                                Background.LinearGradient(
                                    angle = 45f,
                                    colors = listOf("#667eea", "#764ba2")
                                ),
                                Background.Pattern(
                                    patternType = PatternType.DOTS,
                                    primaryColor = "#00000000",
                                    secondaryColor = "#FFFFFF20",
                                    size = 6f,
                                    spacing = 15f
                                )
                            )
                        ),
                        borderRadius = Dimension.dp(16f)
                    ),
                    children = listOf(
                        NativeDisplayElement(
                            id = "bg_layered_1_text",
                            elementType = ElementType.TEXT,
                            layout = Layout(padding = Spacing(all = 16f)),
                            bindings = mapOf("text" to "Gradient + Pattern Overlay"),
                            style = Style(
                                textColor = "#FFFFFF",
                                fontSize = TextDimension(18f),
                                fontWeight = FontWeight.BOLD
                            )
                        )
                    )
                ),
                
                // Complex card design
                NativeDisplayContainer(
                    id = "bg_layered_2",
                    containerType = ContainerType.BOX,
                    layout = Layout(
                        width = Dimension(value = 100f, unit = DimensionUnit.PERCENT),
                        height = Dimension(value = 150f, unit = DimensionUnit.DP)
                    ),
                    style = Style(
                        background = Background.Layered(
                            layers = listOf(
                                Background.RadialGradient(
                                    centerX = 0.2f,
                                    centerY = 0.2f,
                                    radius = 0.8f,
                                    colors = listOf("#FF6B6B", "#FF8E53")
                                ),
                                Background.Pattern(
                                    patternType = PatternType.GRID,
                                    primaryColor = "#00000000",
                                    secondaryColor = "#FFFFFF10",
                                    size = 1f,
                                    spacing = 20f
                                )
                            )
                        ),
                        borderRadius = Dimension.dp(16f),
                        shadowRadius = 8f,
                        shadowColor = "#00000040"
                    ),
                    children = listOf(
                        NativeDisplayContainer(
                            id = "bg_layered_2_content",
                            containerType = ContainerType.VERTICAL,
                            layout = Layout(padding = Spacing(all = 16f)),
                            children = listOf(
                                NativeDisplayElement(
                                    id = "bg_layered_2_title",
                                    elementType = ElementType.TEXT,
                                    bindings = mapOf("text" to "Premium Card"),
                                    style = Style(
                                        textColor = "#FFFFFF",
                                        fontSize = TextDimension(24f),
                                        fontWeight = FontWeight.BOLD
                                    )
                                ),
                                NativeDisplayElement(
                                    id = "bg_layered_2_subtitle",
                                    elementType = ElementType.TEXT,
                                    bindings = mapOf("text" to "Radial gradient with grid overlay"),
                                    style = Style(
                                        textColor = "#FFFFFFCC",
                                        fontSize = TextDimension(14f)
                                    )
                                )
                            )
                        )
                    )
                )
            )
        ),
        theme = Theme.DEFAULT,
        styleClasses = emptyList(),
        variables = emptyMap()
    )
}
