package com.clevertap.android.nativedisplay.renderer

import android.graphics.RenderNode
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.rememberAsyncImagePainter
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.models.*
import com.clevertap.android.nativedisplay.style.StyleResolver
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Main entry point for rendering native display UI.
 */
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    modifier: Modifier = Modifier
) {
    val styleResolver = StyleResolver(config.theme, config.styleClasses)
    val evaluator = VariableEvaluator(config.variables)

    RenderNode(
        node = config.root,
        styleResolver = styleResolver,
        evaluator = evaluator,
        parentStyle = null,
        modifier = modifier
    )
}

/**
 * Recursively render a display node (container or element).
 */
@Composable
private fun RenderNode(
    node: NativeDisplayNode,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    parentStyle: Style?,
    modifier: Modifier = Modifier
) {
    // Check visibility condition
    if (node.visible != null) {
        val isVisible = evaluator.evaluateBoolean(node.visible!!)
        if (!isVisible) return
    }

    // Resolve style with inheritance
    val resolvedStyle = styleResolver.resolveWithColors(node, parentStyle)

    // Apply modifiers in correct order
    var finalModifier = modifier
    finalModifier = finalModifier.applySizing(node.layout)
    finalModifier = finalModifier.applyOffset(node.layout)  // Use offset instead of margin
    finalModifier = finalModifier.applyDecorations(resolvedStyle)

    // Render based on node type
    when (node) {
        is NativeDisplayContainer -> RenderContainer(
            container = node,
            styleResolver = styleResolver,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            layout = node.layout,
            modifier = finalModifier
        )

        is NativeDisplayElement -> RenderElement(
            element = node,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            layout = node.layout,
            modifier = finalModifier
        )
    }
}

/**
 * Render a container with its children.
 */
@Composable
private fun RenderContainer(
    container: NativeDisplayContainer,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    layout: Layout?,
    modifier: Modifier = Modifier
) {
    val spacing = container.layout?.spacing?.dp ?: 0.dp
    val containerModifier = modifier.applyPadding(layout)

    when (container.containerType) {
        ContainerType.VERTICAL -> {
            Column(
                modifier = containerModifier,
                verticalArrangement = Arrangement.spacedBy(spacing)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier
                    )
                }
            }
        }

        ContainerType.HORIZONTAL -> {
            Row(
                modifier = containerModifier,
                horizontalArrangement = Arrangement.spacedBy(spacing)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier
                    )
                }
            }
        }

        ContainerType.BOX, ContainerType.STACK -> {
            Box(modifier = containerModifier) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier
                    )
                }
            }
        }
        
        ContainerType.GALLERY -> {
            RenderGallery(
                container = container,
                styleResolver = styleResolver,
                evaluator = evaluator,
                resolvedStyle = resolvedStyle,
                modifier = containerModifier
            )
        }
    }
}

/**
 * Render a gallery/carousel container.
 */
@Composable
private fun RenderGallery(
    container: NativeDisplayContainer,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier
) {
    val config = container.galleryConfig ?: GalleryConfig()
    
    // Use different implementations based on snap behavior
    if (config.snapBehavior == SnapBehavior.NONE) {
        RenderFreeFlowGallery(
            container = container,
            config = config,
            styleResolver = styleResolver,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            modifier = modifier
        )
    } else {
        RenderSnappingGallery(
            container = container,
            config = config,
            styleResolver = styleResolver,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            modifier = modifier
        )
    }
}

/**
 * Render free-flowing gallery (no snap).
 */
@Composable
private fun RenderFreeFlowGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier
) {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    
    // Calculate item width based on peek percentage
    val peekFraction = config.peekPercentage / 100f
    val itemWidth = screenWidth * (1f - peekFraction)
    val startPadding = (screenWidth * peekFraction / 2)
    
    Box(modifier = modifier) {
        if (config.orientation == Orientation.HORIZONTAL) {
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = startPadding),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(container.children.size) { index ->
                    Box(modifier = Modifier.width(itemWidth)) {
                        container.children.getOrNull(index)?.let { child ->
                            RenderNode(
                                node = child,
                                styleResolver = styleResolver,
                                evaluator = evaluator,
                                parentStyle = resolvedStyle,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                }
            }
        } else {
            val screenHeight = configuration.screenHeightDp.dp
            val itemHeight = screenHeight * (1f - peekFraction)
            
            LazyColumn(
                modifier = Modifier.fillMaxHeight(),
                contentPadding = PaddingValues(vertical = startPadding),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(container.children.size) { index ->
                    Box(modifier = Modifier.height(itemHeight)) {
                        container.children.getOrNull(index)?.let { child ->
                            RenderNode(
                                node = child,
                                styleResolver = styleResolver,
                                evaluator = evaluator,
                                parentStyle = resolvedStyle,
                                modifier = Modifier.fillMaxHeight()
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Render snapping gallery (center, start, or end snap).
 */
@Composable
private fun RenderSnappingGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier
) {
    val pagerState = rememberPagerState(
        initialPage = config.initialPage.coerceIn(0, maxOf(0, container.children.size - 1)),
        pageCount = { container.children.size }
    )
    val scope = rememberCoroutineScope()
    
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    
    // Calculate content padding for peek effect
    val peekFraction = config.peekPercentage / 100f
    val contentPadding = screenWidth * peekFraction / 2
    
    // Auto-scroll effect
    if (config.autoScrollInterval > 0) {
        LaunchedEffect(pagerState.currentPage) {
            delay(config.autoScrollInterval)
            val nextPage = if (config.infiniteScroll) {
                (pagerState.currentPage + 1) % container.children.size
            } else {
                (pagerState.currentPage + 1).coerceAtMost(container.children.size - 1)
            }
            if (nextPage != pagerState.currentPage) {
                pagerState.animateScrollToPage(nextPage)
            }
        }
    }
    
    Box(modifier = modifier) {
        // Pager
        if (config.orientation == Orientation.HORIZONTAL) {
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = contentPadding),
                pageSpacing = 8.dp
            ) { page ->
                container.children.getOrNull(page)?.let { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        } else {
            val screenHeight = configuration.screenHeightDp.dp
            val verticalPadding = screenHeight * peekFraction / 2
            
            VerticalPager(
                state = pagerState,
                modifier = Modifier.fillMaxHeight(),
                contentPadding = PaddingValues(vertical = verticalPadding),
                pageSpacing = 8.dp
            ) { page ->
                container.children.getOrNull(page)?.let { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        parentStyle = resolvedStyle,
                        modifier = Modifier.fillMaxHeight()
                    )
                }
            }
        }
        
        // Navigation arrows
        if (config.showArrows && container.children.size > 1) {
            RenderGalleryArrows(
                pagerState = pagerState,
                config = config,
                onPrevious = {
                    scope.launch {
                        val prevPage = if (config.infiniteScroll && pagerState.currentPage == 0) {
                            container.children.size - 1
                        } else {
                            (pagerState.currentPage - 1).coerceAtLeast(0)
                        }
                        pagerState.animateScrollToPage(prevPage)
                    }
                },
                onNext = {
                    scope.launch {
                        val nextPage = if (config.infiniteScroll && pagerState.currentPage == container.children.size - 1) {
                            0
                        } else {
                            (pagerState.currentPage + 1).coerceAtMost(container.children.size - 1)
                        }
                        pagerState.animateScrollToPage(nextPage)
                    }
                },
                modifier = Modifier.align(Alignment.Center)
            )
        }
        
        // Page indicators
        if (config.showIndicators && container.children.size > 1) {
            RenderGalleryIndicators(
                pagerState = pagerState,
                config = config,
                pageCount = container.children.size,
                modifier = Modifier.align(
                    when (config.indicatorStyle?.position) {
                        "top" -> Alignment.TopCenter
                        "left" -> Alignment.CenterStart
                        "right" -> Alignment.CenterEnd
                        else -> Alignment.BottomCenter
                    }
                )
            )
        }
    }
}

/**
 * Render gallery navigation arrows.
 */
@Composable
private fun RenderGalleryArrows(
    pagerState: androidx.compose.foundation.pager.PagerState,
    config: GalleryConfig,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    modifier: Modifier = Modifier
) {
    val arrowStyle = config.arrowStyle ?: ArrowStyle()
    val arrowColor = parseColor(arrowStyle.color) ?: Color.Black
    val arrowBgColor = arrowStyle.backgroundColor?.let { parseColor(it) }
    
    val arrowModifier = Modifier
        .size((arrowStyle.size + arrowStyle.padding * 2).dp)
        .then(
            if (arrowBgColor != null) {
                Modifier
                    .background(arrowBgColor, CircleShape)
                    .padding(arrowStyle.padding.dp)
            } else {
                Modifier
            }
        )
    
    if (config.orientation == Orientation.HORIZONTAL) {
        Row(
            modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Previous arrow
            IconButton(
                onClick = onPrevious,
                modifier = arrowModifier,
                enabled = config.infiniteScroll || pagerState.currentPage > 0
            ) {
                Icon(
                    imageVector = Icons.Default.KeyboardArrowLeft,
                    contentDescription = "Previous",
                    tint = arrowColor,
                    modifier = Modifier.size(arrowStyle.size.dp)
                )
            }
            
            // Next arrow
            IconButton(
                onClick = onNext,
                modifier = arrowModifier,
                enabled = config.infiniteScroll || pagerState.currentPage < pagerState.pageCount - 1
            ) {
                Icon(
                    imageVector = Icons.Default.KeyboardArrowRight,
                    contentDescription = "Next",
                    tint = arrowColor,
                    modifier = Modifier.size(arrowStyle.size.dp)
                )
            }
        }
    } else {
        Column(
            modifier = modifier.fillMaxHeight().padding(vertical = 16.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Previous arrow
            IconButton(
                onClick = onPrevious,
                modifier = arrowModifier,
                enabled = config.infiniteScroll || pagerState.currentPage > 0
            ) {
                Icon(
                    imageVector = Icons.Default.KeyboardArrowUp,
                    contentDescription = "Previous",
                    tint = arrowColor,
                    modifier = Modifier.size(arrowStyle.size.dp)
                )
            }
            
            // Next arrow
            IconButton(
                onClick = onNext,
                modifier = arrowModifier,
                enabled = config.infiniteScroll || pagerState.currentPage < pagerState.pageCount - 1
            ) {
                Icon(
                    imageVector = Icons.Default.KeyboardArrowDown,
                    contentDescription = "Next",
                    tint = arrowColor,
                    modifier = Modifier.size(arrowStyle.size.dp)
                )
            }
        }
    }
}

/**
 * Render gallery page indicators.
 */
@Composable
private fun RenderGalleryIndicators(
    pagerState: androidx.compose.foundation.pager.PagerState,
    config: GalleryConfig,
    pageCount: Int,
    modifier: Modifier = Modifier
) {
    val indicatorStyle = config.indicatorStyle ?: IndicatorStyle()
    val activeColor = parseColor(indicatorStyle.activeColor) ?: Color.Blue
    val inactiveColor = parseColor(indicatorStyle.inactiveColor) ?: Color.LightGray
    
    val arrangement = if (config.orientation == Orientation.HORIZONTAL) {
        Arrangement.spacedBy(indicatorStyle.spacing.dp)
    } else {
        Arrangement.spacedBy(indicatorStyle.spacing.dp)
    }
    
    if (config.orientation == Orientation.HORIZONTAL) {
        Row(
            modifier = modifier.padding(16.dp),
            horizontalArrangement = arrangement
        ) {
            repeat(pageCount) { index ->
                Box(
                    modifier = Modifier
                        .size(indicatorStyle.size.dp)
                        .background(
                            color = if (pagerState.currentPage == index) activeColor else inactiveColor,
                            shape = if (indicatorStyle.shape == "circle") CircleShape else RoundedCornerShape(2.dp)
                        )
                )
            }
        }
    } else {
        Column(
            modifier = modifier.padding(16.dp),
            verticalArrangement = arrangement
        ) {
            repeat(pageCount) { index ->
                Box(
                    modifier = Modifier
                        .size(indicatorStyle.size.dp)
                        .background(
                            color = if (pagerState.currentPage == index) activeColor else inactiveColor,
                            shape = if (indicatorStyle.shape == "circle") CircleShape else RoundedCornerShape(2.dp)
                        )
                )
            }
        }
    }
}

/**
 * Render an element based on its type.
 */
@Composable
private fun RenderElement(
    element: NativeDisplayElement,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    layout: Layout?,
    modifier: Modifier = Modifier
) {
    val elementModifier = modifier.applyPadding(layout)
    
    when (element.elementType) {
        ElementType.TEXT -> {
            val text = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            Text(
                text = text,
                modifier = elementModifier,
                color = parseColor(resolvedStyle.textColor) ?: Color.Black,
                fontSize = (resolvedStyle.fontSize ?: 14f).sp,
                fontWeight = resolveFontWeight(resolvedStyle.fontWeight),
                textDecoration = resolveTextDecoration(resolvedStyle.textDecoration),
                textAlign = resolveTextAlign(resolvedStyle.textAlign),
                lineHeight = resolvedStyle.lineHeight?.sp ?: (resolvedStyle.fontSize?.times(1.5f) ?: 21f).sp
            )
        }

        ElementType.IMAGE -> {
            val imageUrl = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            if (imageUrl.isNotEmpty()) {
                Image(
                    painter = rememberAsyncImagePainter(imageUrl),
                    contentDescription = element.bindings["contentDescription"]?.let {
                        evaluator.evaluateString(it)
                    },
                    modifier = elementModifier,
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = elementModifier.background(Color.LightGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No Image", color = Color.Gray, fontSize = 12.sp)
                }
            }
        }

        ElementType.BUTTON -> {
            val buttonText = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: "Button"

            Button(
                onClick = { /* TODO: Handle actions */ },
                modifier = elementModifier,
                colors = ButtonDefaults.buttonColors(
                    containerColor = parseColor(resolvedStyle.backgroundColor) ?: Color(0xFF007AFF),
                    contentColor = parseColor(resolvedStyle.textColor) ?: Color.White
                ),
                shape = RoundedCornerShape((resolvedStyle.borderRadius ?: 8f).dp)
            ) {
                Text(
                    text = buttonText,
                    fontSize = (resolvedStyle.fontSize ?: 16f).sp,
                    fontWeight = resolveFontWeight(resolvedStyle.fontWeight)
                )
            }
        }

        ElementType.VIDEO -> {
            Box(
                modifier = elementModifier.background(Color.Black),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Video Player",
                    color = Color.White,
                    fontSize = 16.sp
                )
            }
        }

        ElementType.SPACER -> {
            Spacer(modifier = elementModifier)
        }
        
        ElementType.DIVIDER -> {
            val dividerConfig = element.dividerConfig ?: DividerConfig()
            val dividerColor = parseColor(dividerConfig.color) ?: Color.LightGray
            
            when (dividerConfig.orientation) {
                Orientation.HORIZONTAL -> {
                    Divider(
                        modifier = elementModifier.height(dividerConfig.thickness.dp),
                        color = dividerColor
                    )
                }
                Orientation.VERTICAL -> {
                    Divider(
                        modifier = elementModifier.width(dividerConfig.thickness.dp).fillMaxHeight(),
                        color = dividerColor
                    )
                }
            }
        }
    }
}

/**
 * Apply width and height from layout.
 */
private fun Modifier.applySizing(layout: Layout?): Modifier {
    if (layout == null) return this
    var modifier = this

    layout.width?.let { width ->
        modifier = when {
            width.special == SpecialDimension.MATCH_PARENT -> modifier.fillMaxWidth()
            width.special == SpecialDimension.WRAP_CONTENT -> modifier.wrapContentWidth()
            else -> when (width.unit) {
                DimensionUnit.DP -> modifier.width(width.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxWidth(width.value / 100f)
                else -> modifier.width(width.value.dp)
            }
        }
    }

    layout.height?.let { height ->
        modifier = when {
            height.special == SpecialDimension.MATCH_PARENT -> modifier.fillMaxHeight()
            height.special == SpecialDimension.WRAP_CONTENT -> modifier.wrapContentHeight()
            else -> when (height.unit) {
                DimensionUnit.DP -> modifier.height(height.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxHeight(height.value / 100f)
                else -> modifier.height(height.value.dp)
            }
        }
    }

    return modifier
}

/**
 * Apply absolute offset positioning (replaces margin).
 * This properly positions elements within their container bounds using x/y coordinates.
 * 
 * Note: Offset moves the element after layout, so it works correctly for absolute positioning
 * within Box/Stack containers. For Column/Row, the spacing is handled by Arrangement.spacedBy.
 */
private fun Modifier.applyOffset(layout: Layout?): Modifier {
    if (layout?.margin == null) return this
    
    val margin = layout.margin
    
    // Use offset for absolute positioning (x, y within container bounds)
    // Negative margins are supported (negative offset values)
    return this.offset(
        x = margin.resolveLeft().dp,
        y = margin.resolveTop().dp
    )
    // Note: right and bottom margins don't affect offset directly,
    // they would need to be handled by the parent container's layout calculations
}

/**
 * Apply padding (inside spacing).
 */
private fun Modifier.applyPadding(layout: Layout?): Modifier {
    if (layout?.padding == null) return this
    
    val padding = layout.padding
    return this.padding(
        start = padding.resolveLeft().dp,
        top = padding.resolveTop().dp,
        end = padding.resolveRight().dp,
        bottom = padding.resolveBottom().dp
    )
}

/**
 * Apply visual decorations (shadow, background, border).
 */
@Composable
private fun Modifier.applyDecorations(style: Style): Modifier {
    var modifier = this
    
    val shape = RoundedCornerShape((style.borderRadius ?: 0f).dp)
    
    if (style.shadowRadius != null && style.shadowRadius > 0f) {
        modifier = modifier.shadow(
            elevation = style.shadowRadius.dp,
            shape = shape,
            spotColor = parseColor(style.shadowColor) ?: Color.Black.copy(alpha = 0.25f)
        )
    }
    
    if (style.borderRadius != null && style.borderRadius > 0f) {
        modifier = modifier.clip(shape)
    }
    
    // Apply background (new system takes precedence over old backgroundColor)
    if (style.background != null) {
        modifier = modifier.applyBackground(style.background)
    } else if (style.backgroundColor != null) {
        modifier = modifier.background(
            color = parseColor(style.backgroundColor) ?: Color.Transparent,
            shape = shape
        )
    }
    
    if (style.borderWidth != null && style.borderWidth > 0f) {
        modifier = modifier.border(
            width = style.borderWidth.dp,
            color = parseColor(style.borderColor) ?: Color.Gray,
            shape = shape
        )
    }
    
    style.opacity?.let { opacity ->
        modifier = modifier.alpha(opacity.coerceIn(0f, 1f))
    }
    
    return modifier
}

/**
 * Parse hex color string to Compose Color.
 */
fun parseColor(colorString: String?): Color? {
    if (colorString == null) return null

    return try {
        val hex = colorString.removePrefix("#")
        when (hex.length) {
            6 -> {
                val rgb = hex.toLong(16)
                Color(
                    red = ((rgb shr 16) and 0xFF) / 255f,
                    green = ((rgb shr 8) and 0xFF) / 255f,
                    blue = (rgb and 0xFF) / 255f,
                    alpha = 1f
                )
            }
            8 -> {
                val argb = hex.toLong(16)
                Color(
                    alpha = ((argb shr 24) and 0xFF) / 255f,
                    red = ((argb shr 16) and 0xFF) / 255f,
                    green = ((argb shr 8) and 0xFF) / 255f,
                    blue = (argb and 0xFF) / 255f
                )
            }
            else -> null
        }
    } catch (e: Exception) {
        null
    }
}

/**
 * Resolve font weight from model to Compose.
 */
private fun resolveFontWeight(fontWeight: FontWeight?): ComposeFontWeight {
    return when (fontWeight) {
        FontWeight.LIGHT -> ComposeFontWeight.Light
        FontWeight.NORMAL -> ComposeFontWeight.Normal
        FontWeight.MEDIUM -> ComposeFontWeight.Medium
        FontWeight.BOLD -> ComposeFontWeight.Bold
        null -> ComposeFontWeight.Normal
    }
}

typealias ndtd = com.clevertap.android.nativedisplay.models.TextDecoration

/**
 * Resolve text decoration from model to Compose.
 */
private fun resolveTextDecoration(decoration: ndtd?): TextDecoration {
    return when (decoration) {
        ndtd.UNDERLINE -> TextDecoration.Underline
        ndtd.STRIKETHROUGH -> TextDecoration.LineThrough
        ndtd.NONE, null -> TextDecoration.None
    }
}

/**
 * Resolve text alignment from string to Compose.
 */
private fun resolveTextAlign(align: String?): TextAlign {
    return when (align?.lowercase()) {
        "left" -> TextAlign.Left
        "center" -> TextAlign.Center
        "right" -> TextAlign.Right
        "justify" -> TextAlign.Justify
        else -> TextAlign.Start
    }
}
