package com.clevertap.android.nativedisplay.renderer

import androidx.compose.animation.core.EaseInBack
import androidx.compose.animation.core.EaseOutBack
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.VerticalDivider
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.rememberAsyncImagePainter
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.listener.InteractionType
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
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
    modifier: Modifier = Modifier,
    actionListener: NativeDisplayActionListener? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val context = LocalContext.current

    val actionHandler = remember(actionListener) {
        ActionHandler(
            context = context,
            listener = actionListener,
            componentListener = componentListener
        )
    }

    DisposableEffect(actionHandler) {
        onDispose {
            actionHandler.cleanup()
        }
    }

    val styleResolver = StyleResolver(theme = config.theme, styleClasses = config.styleClasses)
    val evaluator = VariableEvaluator(variables = config.variables)

    RenderNode(
        node = config.root,
        styleResolver = styleResolver,
        evaluator = evaluator,
        modifier = modifier,
        actionHandler = actionHandler,
        componentListener = componentListener,
    )
}

/**
 * Recursively render a display node (container or element).
 */
@Composable
fun RenderNode(
    node: NativeDisplayNode,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    // Check visibility condition
    if (node.visible != null) {
        val isVisible = evaluator.evaluateBoolean(node.visible!!)
        if (!isVisible) return
    }

    // Resolve style
    val resolvedStyle = styleResolver.resolveWithColors(node)

    // Check if this component needs clickable modifier
    val hasServerActions = node.actions?.isNotEmpty() == true
    val isClientInterested = componentListener?.getInterestedNodeIds()?.contains(node.id) ?: (componentListener != null)  // If getInterestedNodeIds returns null, listen to all

    val shouldApplyClickable = hasServerActions || isClientInterested
    val isButton = (node as? NativeDisplayElement)?.elementType == ElementType.BUTTON

    // Apply modifiers in correct order
    // IMPORTANT: Offset must be applied BEFORE sizing so percentage calculations
    // use the parent's constraints, not the element's constrained size
    var finalModifier = modifier
    finalModifier = finalModifier.applyOffset(node.layout)  // First: sees parent size
    finalModifier = finalModifier.applySizing(node.layout)  // Second: constrains size
    finalModifier = finalModifier.applyEntranceAnimation(node.animation)

    // Apply clickable only when needed (server actions exist OR client is interested)
    if (actionHandler != null && !isButton && shouldApplyClickable) {
        finalModifier = finalModifier.applyClickable(
            nodeId = node.id,
            actions = node.actions,
            actionHandler = actionHandler,
            componentListener = componentListener  // ← ADD THIS PARAMETER
        )
    }

    finalModifier = finalModifier.applyDecorations(resolvedStyle)

    // Render based on node type
    when (node) {
        is NativeDisplayContainer -> RenderContainer(
            container = node,
            styleResolver = styleResolver,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            layout = node.layout,
            modifier = finalModifier,
            actionHandler = actionHandler,
            componentListener = componentListener,
        )

        is NativeDisplayElement -> RenderElement(
            element = node,
            evaluator = evaluator,
            resolvedStyle = resolvedStyle,
            layout = node.layout,
            modifier = finalModifier,
            actionHandler = actionHandler,
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
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val containerModifier = modifier.applyPadding(layout)

    when (container.containerType) {
        ContainerType.VERTICAL -> {
            Column(
                modifier = containerModifier,
                verticalArrangement = resolveVerticalArrangement(container.layout?.arrangement)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener
                    )
                }
            }
        }

        ContainerType.HORIZONTAL -> {
            Row(
                modifier = containerModifier,
                horizontalArrangement = resolveHorizontalArrangement(container.layout?.arrangement)
            ) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener
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
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener
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
                modifier = containerModifier,
                actionHandler = actionHandler,
                componentListener = componentListener
            )
        }
    }
}

/**
 * Main gallery renderer that routes to the appropriate implementation based on mode.
 */
@Composable
fun RenderGallery(
    container: NativeDisplayContainer,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val config = container.galleryConfig ?: GalleryConfig()

    when (config.mode) {
        GalleryMode.SNAPPING -> {
            RenderSnappingGallery(
                container = container,
                config = config,
                styleResolver = styleResolver,
                evaluator = evaluator,
                resolvedStyle = resolvedStyle,
                modifier = modifier,
                actionHandler = actionHandler,
                componentListener = componentListener,
            )
        }

        GalleryMode.FREE_FLOW -> {
            RenderFreeFlowGallery(
                container = container,
                config = config,
                styleResolver = styleResolver,
                evaluator = evaluator,
                resolvedStyle = resolvedStyle,
                modifier = modifier,
                actionHandler = actionHandler,
                componentListener = componentListener,
            )
        }

        GalleryMode.FREE_FLOW_GRID -> {
            RenderFreeFlowGridGallery(
                container = container,
                config = config,
                styleResolver = styleResolver,
                evaluator = evaluator,
                resolvedStyle = resolvedStyle,
                modifier = modifier,
                actionHandler = actionHandler,
                componentListener = componentListener,
            )
        }
    }
}

/**
 * Mode 1: Snapping Gallery
 * - Full-size items with snap behavior
 * - Peek shows partial adjacent items via contentPadding
 * - Supports auto-scroll, indicators, arrows
 */
@Composable
private fun RenderSnappingGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    if (container.children.isEmpty()) return

    val pagerState = rememberPagerState(
        initialPage = config.initialPage.coerceIn(0, maxOf(0, container.children.size - 1)),
        pageCount = { container.children.size }
    )
    val scope = rememberCoroutineScope()

    BoxWithConstraints(modifier = modifier) {
        val containerWidth = this.maxWidth
        val containerHeight = this.maxHeight

        // Calculate peek padding
        val peekFraction = config.peekPercentage / 100f
        val horizontalPadding = if (container.children.size > 1 && peekFraction > 0f) {
            containerWidth * peekFraction / 2f
        } else {
            0.dp
        }
        val verticalPadding = if (container.children.size > 1 && peekFraction > 0f) {
            containerHeight * peekFraction / 2f
        } else {
            0.dp
        }

        // Auto-scroll
        if (config.autoScrollInterval > 0 && container.children.size > 1) {
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

        Box(modifier = Modifier.fillMaxSize()) {
            // Pager
            if (config.orientation == Orientation.HORIZONTAL) {
                HorizontalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxWidth(),
                    contentPadding = PaddingValues(horizontal = horizontalPadding),
                    pageSpacing = config.spacing.dp
                ) { page ->
                    container.children.getOrNull(page)?.let { child ->
                        RenderNode(
                            node = child,
                            styleResolver = styleResolver,
                            evaluator = evaluator,
                            modifier = Modifier.fillMaxWidth(),
                            actionHandler = actionHandler,
                            componentListener = componentListener,
                        )
                    }
                }
            } else {
                VerticalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxHeight(),
                    contentPadding = PaddingValues(vertical = verticalPadding),
                    pageSpacing = config.spacing.dp
                ) { page ->
                    container.children.getOrNull(page)?.let { child ->
                        RenderNode(
                            node = child,
                            styleResolver = styleResolver,
                            evaluator = evaluator,
                            modifier = Modifier.fillMaxHeight(),
                            actionHandler = actionHandler,
                            componentListener = componentListener,
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
}

/**
 * Mode 2: Free Flow - Independent Sizing
 * - Items define their own size via Layout properties
 * - Natural scrolling, no snap, no peek
 * - Use case: Tag lists, chips, varying-width items
 */
@Composable
private fun RenderFreeFlowGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    if (container.children.isEmpty()) return

    if (config.orientation == Orientation.HORIZONTAL) {
        LazyRow(
            modifier = modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(config.spacing.dp)
        ) {
            items(container.children.size) { index ->
                container.children.getOrNull(index)?.let { child ->
                    // Child sizes itself via its own Layout properties
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener,
                    )
                }
            }
        }
    } else {
        LazyColumn(
            modifier = modifier.fillMaxHeight(),
            verticalArrangement = Arrangement.spacedBy(config.spacing.dp)
        ) {
            items(container.children.size) { index ->
                container.children.getOrNull(index)?.let { child ->
                    // Child sizes itself via its own Layout properties
                    RenderNode(
                        node = child,
                        styleResolver = styleResolver,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener,
                    )
                }
            }
        }
    }
}

/**
 * Mode 3: Free Flow - Grid with Peek
 * - Fixed number of items per view (e.g., 2.5 items)
 * - Equal-sized items, natural scrolling
 * - Peek via itemsPerView (2.5 = 2 full + 0.5 peek on each side)
 * - Use case: Product grids, movie posters
 */
@Composable
private fun RenderFreeFlowGridGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    styleResolver: StyleResolver,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    if (container.children.isEmpty()) return

    BoxWithConstraints(modifier = modifier) {
        val containerWidth = this.maxWidth
        val containerHeight = this.maxHeight

        if (config.orientation == Orientation.HORIZONTAL) {
            // Calculate item width based on itemsPerView
            val itemsPerView = config.itemsPerView.coerceAtLeast(0.1f)
            val totalSpacing = config.spacing.dp * (itemsPerView - 1)
            val itemWidth = (containerWidth - totalSpacing) / itemsPerView

            // Calculate peek offset for centering
            val fullItems = itemsPerView.toInt()
            val partialItem = itemsPerView - fullItems
            val peekOffset = if (partialItem > 0) {
                itemWidth * partialItem / 2f
            } else {
                0.dp
            }

            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = peekOffset),
                horizontalArrangement = Arrangement.spacedBy(config.spacing.dp)
            ) {
                items(container.children.size) { index ->
                    Box(modifier = Modifier.width(itemWidth)) {
                        container.children.getOrNull(index)?.let { child ->
                            RenderNode(
                                node = child,
                                styleResolver = styleResolver,
                                evaluator = evaluator,
                                modifier = Modifier.fillMaxWidth(),
                                actionHandler = actionHandler,
                                componentListener = componentListener,
                            )
                        }
                    }
                }
            }
        } else {
            // Calculate item height based on itemsPerView
            val itemsPerView = config.itemsPerView.coerceAtLeast(0.1f)
            val totalSpacing = config.spacing.dp * (itemsPerView - 1)
            val itemHeight = (containerHeight - totalSpacing) / itemsPerView

            // Calculate peek offset for centering
            val fullItems = itemsPerView.toInt()
            val partialItem = itemsPerView - fullItems
            val peekOffset = if (partialItem > 0) {
                itemHeight * partialItem / 2f
            } else {
                0.dp
            }

            LazyColumn(
                modifier = Modifier.fillMaxHeight(),
                contentPadding = PaddingValues(vertical = peekOffset),
                verticalArrangement = Arrangement.spacedBy(config.spacing.dp)
            ) {
                items(container.children.size) { index ->
                    Box(modifier = Modifier.height(itemHeight)) {
                        container.children.getOrNull(index)?.let { child ->
                            RenderNode(
                                node = child,
                                styleResolver = styleResolver,
                                evaluator = evaluator,
                                modifier = Modifier.fillMaxHeight(),
                                actionHandler = actionHandler,
                                componentListener = componentListener,
                            )
                        }
                    }
                }
            }
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
            modifier = modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
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
            modifier = modifier
                .fillMaxHeight()
                .padding(vertical = 16.dp),
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
                            shape = if (indicatorStyle.shape == "circle") CircleShape else RoundedCornerShape(
                                2.dp
                            )
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
                            shape = if (indicatorStyle.shape == "circle") CircleShape else RoundedCornerShape(
                                2.dp
                            )
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
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null
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
                onClick = { element.actions?.get(ActionTriggers.ON_CLICK)?.let { action ->
                    actionHandler?.handleAction(action = action, nodeId = element.id)
                } },
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
                    HorizontalDivider(
                        modifier = elementModifier,
                        thickness = dividerConfig.thickness.dp,
                        color = dividerColor
                    )
                }
                Orientation.VERTICAL -> {
                    VerticalDivider(
                        modifier = elementModifier,
                        thickness = dividerConfig.thickness.dp,
                        color = dividerColor
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun Modifier.applyClickable(
    nodeId: String,
    actions: Map<String, Action>?,
    actionHandler: ActionHandler,
    componentListener: NativeDisplayComponentListener? = null
): Modifier {
    // Early exit if no interactions are enabled from server or client.
    if (actions.isNullOrEmpty() && componentListener == null) return this

    val onClickAction = actions?.get(ActionTriggers.ON_CLICK)
    val onLongPressAction = actions?.get(ActionTriggers.ON_LONG_PRESS)
    val onDoubleTapAction = actions?.get(ActionTriggers.ON_DOUBLE_TAP)

    // Resolve callbacks: prioritize specific actions, fallback to component listener notification
    val onClick = {
        onClickAction?.let { actionHandler.handleAction(it, nodeId, InteractionType.CLICK) }
            ?: actionHandler.handleInteractionWithoutAction(nodeId, InteractionType.CLICK)
    }

    val onLongClick = onLongPressAction?.let {
        { actionHandler.handleAction(it, nodeId, InteractionType.LONG_PRESS) }
    } ?: if (componentListener != null) {
        { actionHandler.handleInteractionWithoutAction(nodeId, InteractionType.LONG_PRESS) }
    } else null

    val onDoubleClick = onDoubleTapAction?.let {
        { actionHandler.handleAction(it, nodeId, InteractionType.DOUBLE_TAP) }
    } ?: if (componentListener != null) {
        { actionHandler.handleInteractionWithoutAction(nodeId, InteractionType.DOUBLE_TAP) }
    } else null

    return combinedClickable(
        onClick = onClick,
        onLongClick = onLongClick,
        onDoubleClick = onDoubleClick
    )
}

/**
 * Apply width and height from layout.
 * Aspect ratio is applied when one or both dimensions are flexible.
 */
private fun Modifier.applySizing(layout: Layout?): Modifier {
    if (layout == null) return this
    var modifier = this

    // Determine if dimensions are fixed (DP/SP/PX, not special)
    val hasFixedWidth = layout.width?.let {
        it.special == null && it.unit in listOf(DimensionUnit.DP, DimensionUnit.PX)
    } ?: false

    val hasFixedHeight = layout.height?.let {
        it.special == null && it.unit in listOf(DimensionUnit.DP, DimensionUnit.PX)
    } ?: false

    // Apply aspect ratio BEFORE sizing if appropriate
    // Skip if both dimensions are fixed (explicit sizes take precedence)
    // Skip if aspect ratio is invalid (≤ 0)
    val doesNotHaveFixedWidth = !(hasFixedWidth && hasFixedHeight)
    if (layout.aspectRatio != null && layout.aspectRatio > 0 && doesNotHaveFixedWidth) {
        modifier = modifier.aspectRatio(
            layout.aspectRatio,
            matchHeightConstraintsFirst = hasFixedHeight
        )
    }

    // Apply width
    layout.width?.let { width ->
        modifier = when {
            width.special == SpecialDimension.MATCH_PARENT -> modifier.fillMaxWidth()
            width.special == SpecialDimension.WRAP_CONTENT -> modifier.wrapContentWidth()
            else -> when (width.unit) {
                DimensionUnit.DP -> modifier.width(width.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxWidth(width.value / 100f)
                DimensionUnit.PX -> modifier.width(width.value.dp) // todo check pixel assignment
                else -> modifier.width(width.value.dp)
            }
        }
    }

    // Apply height
    layout.height?.let { height ->
        modifier = when {
            height.special == SpecialDimension.MATCH_PARENT -> modifier.fillMaxHeight()
            height.special == SpecialDimension.WRAP_CONTENT -> modifier.wrapContentHeight()
            else -> when (height.unit) {
                DimensionUnit.DP -> modifier.height(height.value.dp)
                DimensionUnit.PERCENT -> modifier.fillMaxHeight(height.value / 100f)
                DimensionUnit.PX -> modifier.height(height.value.dp)
                else -> modifier.height(height.value.dp)
            }
        }
    }

    return modifier
}

/**
 * Apply absolute offset positioning.
 * This positions elements at specific x/y coordinates within their container.
 * For percentage-based offsets, calculates relative to parent dimensions.
 *
 * Offset moves the element after layout, making it perfect for:
 * - Absolute positioning within Box/Stack containers
 * - Negative values for positioning outside normal flow
 * - Fine-tuned positioning adjustments
 *
 * Note: For Column/Row containers, spacing between children is handled by
 * the arrangement strategy (SpaceBetween, SpaceEvenly, etc.).
 */
private fun Modifier.applyOffset(layout: Layout?): Modifier {
    if (layout?.offset == null) return this

    val offset = layout.offset

    // Apply x/y offset based on unit type
    return when (offset.unit) {
        DimensionUnit.DP -> this.offset(
            x = offset.x.dp,
            y = offset.y.dp
        )
        DimensionUnit.PERCENT -> this.percentageOffset(offset.x, offset.y)
        else -> this.offset(
            x = offset.x.dp,
            y = offset.y.dp
        )
    }
}

/**
 * Apply percentage-based offset using custom layout modifier.
 * Calculates offset relative to parent container dimensions.
 *
 * IMPORTANT: This modifier must be applied BEFORE any sizing modifiers
 * (applySizing) to ensure constraints.maxWidth/maxHeight represent the
 * parent's actual dimensions, not the element's constrained size.
 *
 * For example, with a 300dp parent and 10% offset:
 * - Correct: offset applied first → sees parent's 300dp → calculates 30dp offset
 * - Wrong: sizing (50dp) applied first → offset sees 50dp → calculates 5dp offset
 */
private fun Modifier.percentageOffset(xPercent: Float, yPercent: Float): Modifier {
    return this.layout { measurable, constraints ->
        val placeable = measurable.measure(constraints)
        // constraints.maxWidth/maxHeight represent parent dimensions when this
        // modifier is applied before sizing modifiers
        val offsetXPx = (xPercent / 100f * constraints.maxWidth).toInt()
        val offsetYPx = (yPercent / 100f * constraints.maxHeight).toInt()

        layout(placeable.width, placeable.height) {
            placeable.placeRelative(offsetXPx, offsetYPx)
        }
    }
}

/**
 * Apply entrance animation to a component.
 * Animation plays once when the component first appears.
 *
 * Pattern follows BackgroundRenderer.kt - composable when needed for animations.
 */
@Composable
fun Modifier.applyEntranceAnimation(animation: Animation?): Modifier {
    // No animation configured
    if (animation == null || animation.type == AnimationType.NONE) {
        return this
    }

    // Track if animation has played
    var hasAnimated by remember { mutableStateOf(false) }

    // Animate from 0 to 1
    val animatedValue by animateFloatAsState(
        targetValue = if (hasAnimated) 1f else 0f,
        animationSpec = tween(
            durationMillis = animation.duration.toInt(),
            delayMillis = animation.delay.toInt(),
            easing = resolveEasing(animation.easing)
        ),
        label = "entrance_animation"
    )

    // Start animation on first composition
    LaunchedEffect(Unit) {
        hasAnimated = true
    }

    // Apply animation transform based on type
    return this.graphicsLayer {
        when (animation.type) {
            AnimationType.FADE_IN -> {
                alpha = animatedValue
            }

            AnimationType.SLIDE_IN_LEFT -> {
                translationX = -(1f - animatedValue) * 300f
                alpha = animatedValue  // Subtle fade for polish
            }

            AnimationType.SLIDE_IN_RIGHT -> {
                translationX = (1f - animatedValue) * 300f
                alpha = animatedValue
            }

            AnimationType.SLIDE_IN_TOP -> {
                translationY = -(1f - animatedValue) * 300f
                alpha = animatedValue
            }

            AnimationType.SLIDE_IN_BOTTOM -> {
                translationY = (1f - animatedValue) * 300f
                alpha = animatedValue
            }

            AnimationType.SCALE_IN -> {
                scaleX = 0.8f + (animatedValue * 0.2f)  // Scale from 80% to 100%
                scaleY = 0.8f + (animatedValue * 0.2f)
                alpha = animatedValue
            }

            AnimationType.FADE_SCALE_IN -> {
                scaleX = 0.9f + (animatedValue * 0.1f)  // Subtle scale
                scaleY = 0.9f + (animatedValue * 0.1f)
                alpha = animatedValue
            }

            AnimationType.FADE_SLIDE_IN -> {
                translationY = (1f - animatedValue) * 30f  // Subtle slide
                alpha = animatedValue
            }

            AnimationType.NONE -> {
                // No transformation
            }
        }
    }
}

/**
 * Resolve easing enum to Compose easing function.
 */
private fun resolveEasing(easing: Easing): androidx.compose.animation.core.Easing {
    return when (easing) {
        Easing.LINEAR -> LinearEasing
        Easing.EASE_IN -> FastOutLinearInEasing
        Easing.EASE_OUT -> LinearOutSlowInEasing
        Easing.EASE_IN_OUT -> FastOutSlowInEasing
        Easing.EASE_IN_BACK -> EaseInBack
        Easing.EASE_OUT_BACK -> EaseOutBack
        Easing.SPRING -> LinearEasing  // Spring handled differently
    }
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
                // Compose Color(Long) expects 0xAARRGGBB format (ARGB)
                Color(hex.toLong(16))
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

/**
 * Resolve horizontal arrangement strategy for Row containers.
 * Maps ArrangementStrategy enum to Compose Arrangement.Horizontal.
 */
private fun resolveHorizontalArrangement(arrangement: ChildArrangement?): Arrangement.Horizontal {
    if (arrangement == null) {
        return Arrangement.spacedBy(0.dp)
    }
    
    return when (arrangement.strategy) {
        ArrangementStrategy.SPACED -> {
            val spacing = arrangement.spacing ?: 0f
            when (arrangement.spacingUnit) {
                DimensionUnit.DP -> Arrangement.spacedBy(spacing.dp)
                else -> Arrangement.spacedBy(spacing.dp) // Default to DP for other units
            }
        }
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Start
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.End
    }
}

/**
 * Resolve vertical arrangement strategy for Column containers.
 * Maps ArrangementStrategy enum to Compose Arrangement.Vertical.
 */
private fun resolveVerticalArrangement(arrangement: ChildArrangement?): Arrangement.Vertical {
    if (arrangement == null) {
        return Arrangement.spacedBy(0.dp)
    }
    
    return when (arrangement.strategy) {
        ArrangementStrategy.SPACED -> {
            val spacing = arrangement.spacing ?: 0f
            when (arrangement.spacingUnit) {
                DimensionUnit.DP -> Arrangement.spacedBy(spacing.dp)
                else -> Arrangement.spacedBy(spacing.dp) // Default to DP for other units
            }
        }
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Top
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.Bottom
    }
}
