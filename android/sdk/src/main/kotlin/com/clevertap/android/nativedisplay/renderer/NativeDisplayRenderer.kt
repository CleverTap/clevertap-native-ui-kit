package com.clevertap.android.nativedisplay.renderer

// Media3 imports (compileOnly - available at compile time, provided at runtime by host app)
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.EaseInBack
import androidx.compose.animation.core.EaseOutBack
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.internal.ImageLoaderProvider
import com.clevertap.android.nativedisplay.listener.InteractionType
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.models.ActionTriggers
import com.clevertap.android.nativedisplay.models.Animation
import com.clevertap.android.nativedisplay.models.AnimationType
import com.clevertap.android.nativedisplay.models.ArrangementStrategy
import com.clevertap.android.nativedisplay.models.ArrowStyle
import com.clevertap.android.nativedisplay.models.ChildArrangement
import com.clevertap.android.nativedisplay.models.ContainerType
import com.clevertap.android.nativedisplay.models.DimensionUnit
import com.clevertap.android.nativedisplay.models.DividerConfig
import com.clevertap.android.nativedisplay.models.Easing
import com.clevertap.android.nativedisplay.models.ElementType
import com.clevertap.android.nativedisplay.models.FontWeight
import com.clevertap.android.nativedisplay.models.GalleryConfig
import com.clevertap.android.nativedisplay.models.GalleryMode
import com.clevertap.android.nativedisplay.models.ImageFit
import com.clevertap.android.nativedisplay.models.IndicatorStyle
import com.clevertap.android.nativedisplay.models.Layout
import com.clevertap.android.nativedisplay.models.NativeDisplayContainer
import com.clevertap.android.nativedisplay.models.NativeDisplayElement
import com.clevertap.android.nativedisplay.models.NativeDisplayNode
import com.clevertap.android.nativedisplay.models.Orientation
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.models.SpecialDimension
import com.clevertap.android.nativedisplay.models.Style
import com.clevertap.android.nativedisplay.style.StyleResolver
import kotlinx.collections.immutable.PersistentMap
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.ui.text.font.FontStyle as ComposeFontStyle
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight
import androidx.compose.ui.text.style.TextOverflow as ComposeTextOverflow

/**
 * Convenience overload that pre-resolves styles internally.
 * Use this when calling NativeDisplayView directly without going through NativeDisplayViewGroup.
 */
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    modifier: Modifier = Modifier,
    actionListener: NativeDisplayActionListener? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val resolvedStyles = remember(config) {
        StyleResolver(config.theme, config.styleClasses).resolveAll(config.root)
    }
    NativeDisplayView(
        config = config,
        resolvedStyles = resolvedStyles,
        modifier = modifier,
        actionListener = actionListener,
        componentListener = componentListener,
    )
}

/**
 * Main entry point for rendering native display UI.
 */
@Composable
fun NativeDisplayView(
    config: ResolvedConfig,
    resolvedStyles: PersistentMap<String, Style>,
    modifier: Modifier = Modifier,
    actionListener: NativeDisplayActionListener? = null,
    componentListener: NativeDisplayComponentListener? = null,
) {
    val context = LocalContext.current

    val actionHandler = remember(actionListener, componentListener) {
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

    val evaluator = remember(config.variables) {
        VariableEvaluator(variables = config.variables)
    }

    RenderNode(
        node = config.root,
        resolvedStyles = resolvedStyles,
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
    resolvedStyles: PersistentMap<String, Style>,
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
    val resolvedStyle = resolvedStyles[node.id] ?: Style.EMPTY

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
            componentListener = componentListener
        )
    }

    finalModifier = finalModifier.applyDecorations(resolvedStyle)

    // Render based on node type
    when (node) {
        is NativeDisplayContainer -> RenderContainer(
            container = node,
            resolvedStyles = resolvedStyles,
            evaluator = evaluator,
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
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
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
                        resolvedStyles = resolvedStyles,
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
                        resolvedStyles = resolvedStyles,
                        evaluator = evaluator,
                        modifier = Modifier,
                        actionHandler = actionHandler,
                        componentListener = componentListener
                    )
                }
            }
        }

        ContainerType.BOX -> {
            Box(modifier = containerModifier) {
                container.children.forEach { child ->
                    RenderNode(
                        node = child,
                        resolvedStyles = resolvedStyles,
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
                resolvedStyles = resolvedStyles,
                evaluator = evaluator,
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
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
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
                resolvedStyles = resolvedStyles,
                evaluator = evaluator,
                modifier = modifier,
                actionHandler = actionHandler,
                componentListener = componentListener,
            )
        }

        GalleryMode.FREE_FLOW -> {
            RenderFreeFlowGallery(
                container = container,
                config = config,
                resolvedStyles = resolvedStyles,
                evaluator = evaluator,
                modifier = modifier,
                actionHandler = actionHandler,
                componentListener = componentListener,
            )
        }

        GalleryMode.FREE_FLOW_GRID -> {
            RenderFreeFlowGridGallery(
                container = container,
                config = config,
                resolvedStyles = resolvedStyles,
                evaluator = evaluator,
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
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
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
                            resolvedStyles = resolvedStyles,
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
                            resolvedStyles = resolvedStyles,
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
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
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
            items(container.children, key = { it.id }) { child ->
                RenderNode(
                    node = child,
                    resolvedStyles = resolvedStyles,
                    evaluator = evaluator,
                    modifier = Modifier,
                    actionHandler = actionHandler,
                    componentListener = componentListener,
                )
            }
        }
    } else {
        LazyColumn(
            modifier = modifier.fillMaxHeight(),
            verticalArrangement = Arrangement.spacedBy(config.spacing.dp)
        ) {
            items(container.children, key = { it.id }) { child ->
                RenderNode(
                    node = child,
                    resolvedStyles = resolvedStyles,
                    evaluator = evaluator,
                    modifier = Modifier,
                    actionHandler = actionHandler,
                    componentListener = componentListener,
                )
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
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
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
                items(container.children, key = { it.id }) { child ->
                    Box(modifier = Modifier.width(itemWidth)) {
                        RenderNode(
                            node = child,
                            resolvedStyles = resolvedStyles,
                            evaluator = evaluator,
                            modifier = Modifier.fillMaxWidth(),
                            actionHandler = actionHandler,
                            componentListener = componentListener,
                        )
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
                items(container.children, key = { it.id }) { child ->
                    Box(modifier = Modifier.height(itemHeight)) {
                        RenderNode(
                            node = child,
                            resolvedStyles = resolvedStyles,
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

            val textProps = resolvedStyle.extractTextProperties()
            Text(
                text = text,
                modifier = elementModifier,
                color = parseColor(textProps.color) ?: Color.Black,
                fontSize = (textProps.size ?: 14f).sp,
                fontWeight = resolveFontWeight(textProps.weight),
                fontStyle = resolveFontStyle(textProps.style),
                letterSpacing = (textProps.letterSpacing ?: 0f).sp,
                textDecoration = resolveTextDecoration(textProps.decoration),
                textAlign = resolveTextAlign(textProps.align),
                lineHeight = textProps.lineHeight?.sp ?: (textProps.size?.times(1.5f) ?: 21f).sp,
                maxLines = textProps.maxLines ?: Int.MAX_VALUE,
                overflow = resolveTextOverflow(textProps.overflow)
            )
        }

        ElementType.IMAGE -> {
            val imageUrl = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            if (imageUrl.isNotEmpty()) {
                val context = LocalContext.current

                // Remember the ImageLoader to avoid creating it on every recomposition
                // The ImageLoaderProvider is a singleton, but we cache the reference here
                val imageLoader = remember(context) {
                    ImageLoaderProvider.getImageLoader(context)
                }

                // Map ImageFit to ContentScale
                val contentScale = when (element.imageConfig?.fit ?: ImageFit.CROP) {
                    ImageFit.CROP -> ContentScale.Crop        // Fill, may crop edges
                    ImageFit.CONTAIN -> ContentScale.Fit      // Fit within bounds
                    ImageFit.FILL -> ContentScale.FillBounds  // Stretch to fill
                    ImageFit.TILE -> ContentScale.Crop        // Tile not supported for single images
                }

                // Use SDK's internal ImageLoader with GIF support
                // This ensures GIF animation works without requiring host app configuration
                val imageRequest = ImageRequest.Builder(context)
                    .data(imageUrl)
                    .crossfade(true)
                    .build()

                AsyncImage(
                    model = imageRequest,
                    imageLoader = imageLoader,
                    contentDescription = element.bindings["contentDescription"]?.let {
                        evaluator.evaluateString(it)
                    },
                    modifier = elementModifier,
                    contentScale = contentScale
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

            val textProps = resolvedStyle.extractTextProperties()
            val visualProps = resolvedStyle.extractVisualProperties()
            val borderProps = resolvedStyle.extractBorderProperties()

            Button(
                onClick = { element.actions?.get(ActionTriggers.ON_CLICK)?.let { action ->
                    actionHandler?.handleAction(action = action, nodeId = element.id)
                } },
                modifier = elementModifier,
                contentPadding = PaddingValues(0.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = parseColor(visualProps.backgroundColor) ?: Color(0xFF007AFF),
                    contentColor = parseColor(textProps.color) ?: Color.White
                ),
                shape = RoundedCornerShape((borderProps.radius ?: 8f).dp)
            ) {
                Text(
                    text = buttonText,
                    fontSize = (textProps.size ?: 16f).sp,
                    lineHeight = textProps.lineHeight?.sp ?: (textProps.size?.times(1.5f) ?: 21f).sp,
                    fontWeight = resolveFontWeight(textProps.weight)
                )
            }
        }

        ElementType.VIDEO -> {
            val videoUrl = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            val autoPlay = element.bindings["autoPlay"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: false

            val loop = element.bindings["loop"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: false

            val muted = element.bindings["muted"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: false

            val showControls = element.bindings["showControls"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: true

            val showFullscreen = element.bindings["showFullscreen"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: true

            if (videoUrl.isNotEmpty()) {
                VideoPlayer(
                    videoUrl = videoUrl,
                    autoPlay = autoPlay,
                    loop = loop,
                    muted = muted,
                    showControls = showControls,
                    showFullscreen = showFullscreen,
                    modifier = elementModifier
                )
            } else {
                // Fallback for missing URL
                Box(
                    modifier = elementModifier.background(Color.DarkGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No Video URL", color = Color.Gray, fontSize = 12.sp)
                }
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

/**
 * Video player composable with custom controls.
 * Supports Media3 ExoPlayer with runtime detection and graceful degradation.
 */
@Composable
fun VideoPlayer(
    videoUrl: String,
    autoPlay: Boolean = false,
    loop: Boolean = false,
    muted: Boolean = false,
    showControls: Boolean = true,
    showFullscreen: Boolean = true,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    // Single runtime check for Media3 availability
    val isMedia3Available = remember {
        runCatching {
            Class.forName("androidx.media3.exoplayer.ExoPlayer")
        }.onSuccess {
            android.util.Log.d("VideoPlayer", "Media3 is available")
        }.onFailure {
            android.util.Log.w("VideoPlayer", "Media3 not found - add androidx.media3 dependencies")
        }.isSuccess
    }

    if (!isMedia3Available) {
        // Fallback UI when Media3 is not available
        Box(
            modifier = modifier.background(Color.DarkGray),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    "Video Player Unavailable",
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = ComposeFontWeight.Bold
                )
                Text(
                    "Add Media3 dependency to your app",
                    color = Color.LightGray,
                    fontSize = 11.sp,
                    textAlign = TextAlign.Center
                )
            }
        }
        return
    }

    // Media3 is available - render video player
    VideoPlayerWithMedia3(
        context = context,
        videoUrl = videoUrl,
        autoPlay = autoPlay,
        loop = loop,
        muted = muted,
        showControls = showControls,
        showFullscreen = showFullscreen,
        modifier = modifier
    )
}

/**
 * Internal video player implementation that uses Media3 directly.
 * Only called when Media3 is confirmed to be available.
 *
 * Uses direct ExoPlayer API calls (not reflection) since compileOnly makes classes
 * available at compile time. The class existence check in VideoPlayer() ensures
 * Media3 is available at runtime before this function is called.
 */
@Composable
private fun VideoPlayerWithMedia3(
    context: android.content.Context,
    videoUrl: String,
    autoPlay: Boolean,
    loop: Boolean,
    muted: Boolean,
    showControls: Boolean,
    showFullscreen: Boolean,
    modifier: Modifier
) {
    val lifecycleOwner = LocalLifecycleOwner.current

    // State for custom controls
    var showControlsUI by remember { mutableStateOf(false) }
    var isPlaying by remember { mutableStateOf(autoPlay) }
    var isMuted by remember { mutableStateOf(muted) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Create ExoPlayer instance - DIRECT API CALLS (no reflection after class check!)
    val exoPlayer = remember(videoUrl) {
        runCatching {
            // Direct ExoPlayer API usage - compiles because of compileOnly dependency
            ExoPlayer.Builder(context)
                .build()
                .apply {
                    setMediaItem(MediaItem.fromUri(videoUrl))
                    prepare()
                    playWhenReady = autoPlay
                    repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
                    volume = if (muted) 0f else 1f
                }
                .also {
                    android.util.Log.d("VideoPlayer", "✓ Player created for: $videoUrl")
                }
        }.onFailure { e ->
            errorMessage = "Failed to create player: ${e.message}"
            android.util.Log.e("VideoPlayer", "✗ Player creation failed", e)
        }.getOrNull()
    }

    // Lifecycle management - DIRECT method calls
    DisposableEffect(lifecycleOwner, exoPlayer) {
        exoPlayer?.let { player ->
            val observer = LifecycleEventObserver { _, event ->
                when (event) {
                    Lifecycle.Event.ON_PAUSE -> player.pause()
                    Lifecycle.Event.ON_RESUME -> if (autoPlay) player.play()
                    else -> Unit
                }
            }

            lifecycleOwner.lifecycle.addObserver(observer)

            onDispose {
                lifecycleOwner.lifecycle.removeObserver(observer)
                player.release()
                android.util.Log.d("VideoPlayer", "✓ Player released")
            }
        } ?: onDispose { }
    }

    // Poll player state - DIRECT property access
    LaunchedEffect(exoPlayer) {
        exoPlayer?.let { player ->
            while (true) {
                try {
                    isPlaying = player.isPlaying
                    isMuted = player.volume == 0f
                } catch (_: Exception) {
                    // Player might be released
                    break
                }
                delay(100)
            }
        }
    }

    // Auto-hide controls
    LaunchedEffect(showControlsUI) {
        if (showControlsUI) {
            delay(3000)
            showControlsUI = false
        }
    }

    // UI
    Box(
        modifier = modifier.clickable {
            if (showControls) {
                showControlsUI = !showControlsUI
            }
        }
    ) {
        when {
            errorMessage != null -> {
                // Error state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.DarkGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        errorMessage ?: "Unknown error",
                        color = Color.White,
                        fontSize = 12.sp,
                        textAlign = TextAlign.Center
                    )
                }
            }
            exoPlayer != null -> {
                // Video player view - DIRECT PlayerView API calls
                AndroidView(
                    factory = { ctx ->
                        PlayerView(ctx).apply {
                            player = exoPlayer
                            useController = false  // Disable default controls (we have custom ones)
                            android.util.Log.d("VideoPlayer", "✓ PlayerView created")
                        }
                    },
                    modifier = Modifier.fillMaxSize()
                )
            }
            else -> {
                // Loading state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Loading...",
                        color = Color.White,
                        fontSize = 14.sp
                    )
                }
            }
        }

        // Custom controls overlay
        if (showControls && exoPlayer != null) {
            AnimatedVisibility(
                visible = showControlsUI,
                enter = fadeIn(animationSpec = tween(300)),
                exit = fadeOut(animationSpec = tween(300)),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
            ) {
                Box(
                    modifier = Modifier
                        .background(Color.Black.copy(alpha = 0.5f))
                        .padding(16.dp)
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Play/Pause button - DIRECT method calls
                        IconButton(onClick = {
                            if (isPlaying) {
                                exoPlayer.pause()
                                android.util.Log.d("VideoPlayer", "⏸ Paused")
                            } else {
                                exoPlayer.play()
                                android.util.Log.d("VideoPlayer", "▶ Playing")
                            }
                        }) {
                            if (isPlaying) {
                                // Pause icon (two vertical bars)
                                Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Box(
                                        Modifier
                                            .width(4.dp)
                                            .height(16.dp)
                                            .background(Color.White)
                                    )
                                    Box(
                                        Modifier
                                            .width(4.dp)
                                            .height(16.dp)
                                            .background(Color.White)
                                    )
                                }
                            } else {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Play",
                                    tint = Color.White
                                )
                            }
                        }

                        // Mute/Unmute button - DIRECT method calls
                        IconButton(onClick = {
                            exoPlayer.volume = if (isMuted) 1f else 0f
                            isMuted = !isMuted
                            android.util.Log.d("VideoPlayer", "🔊 Volume: ${if (isMuted) "Muted" else "Unmuted"}")
                        }) {
                            Text(
                                text = if (isMuted) "\uD83D\uDD07" else "\uD83D\uDD0A",  // 🔇 🔊 emoji
                                fontSize = 20.sp,
                                color = Color.White
                            )
                        }

                        // Fullscreen button (if enabled)
                        if (showFullscreen) {
                            IconButton(onClick = {
                                // TODO: Implement fullscreen functionality
                                android.util.Log.d("VideoPlayer", "⛶ Fullscreen requested (not implemented)")
                            }) {
                                Text(
                                    text = "⛶",  // Fullscreen symbol
                                    fontSize = 20.sp,
                                    color = Color.White
                                )
                            }
                        }
                    }
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
        modifier = when (width.special) {
            SpecialDimension.MATCH_PARENT -> modifier.fillMaxWidth()
            SpecialDimension.WRAP_CONTENT -> modifier.wrapContentWidth()
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
        modifier = when (height.special) {
            SpecialDimension.MATCH_PARENT -> modifier.fillMaxHeight()
            SpecialDimension.WRAP_CONTENT -> modifier.wrapContentHeight()
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
 * - Absolute positioning within Box containers
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

    // Extract property groups for better code organization
    val borderProps = style.extractBorderProperties()
    val shadowProps = style.extractShadowProperties()
    val visualProps = style.extractVisualProperties()

    val shape = RoundedCornerShape((borderProps.radius ?: 0f).dp)

    // Apply shadow
    if (shadowProps.radius != null && shadowProps.radius > 0f) {
        modifier = modifier.shadow(
            elevation = shadowProps.radius.dp,
            shape = shape,
            spotColor = parseColor(shadowProps.color) ?: Color.Black.copy(alpha = 0.25f)
        )
    }

    // Apply clip
    if (borderProps.radius != null && borderProps.radius > 0f) {
        modifier = modifier.clip(shape)
    }

    // Apply background (new system takes precedence over old backgroundColor)
    if (visualProps.background != null) {
        modifier = modifier.applyBackground(visualProps.background)
    } else if (visualProps.backgroundColor != null) {
        modifier = modifier.background(
            color = parseColor(visualProps.backgroundColor) ?: Color.Transparent,
            shape = shape
        )
    }

    // Apply border
    if (borderProps.width != null && borderProps.width > 0f) {
        modifier = modifier.border(
            width = borderProps.width.dp,
            color = parseColor(borderProps.color) ?: Color.Gray,
            shape = shape
        )
    }

    // Apply opacity
    visualProps.opacity?.let { opacity ->
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
    } catch (_: Exception) {
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

/**
 * Resolve font style from model to Compose.
 */
private fun resolveFontStyle(fontStyle: com.clevertap.android.nativedisplay.models.FontStyle?): ComposeFontStyle {
    return when (fontStyle) {
        com.clevertap.android.nativedisplay.models.FontStyle.ITALIC -> ComposeFontStyle.Italic
        com.clevertap.android.nativedisplay.models.FontStyle.NORMAL, null -> ComposeFontStyle.Normal
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
 * Resolve text overflow from model to Compose.
 */
private fun resolveTextOverflow(overflow: com.clevertap.android.nativedisplay.models.TextOverflow?): ComposeTextOverflow {
    return when (overflow) {
        com.clevertap.android.nativedisplay.models.TextOverflow.CLIP -> ComposeTextOverflow.Clip
        com.clevertap.android.nativedisplay.models.TextOverflow.ELLIPSIS -> ComposeTextOverflow.Ellipsis
        com.clevertap.android.nativedisplay.models.TextOverflow.VISIBLE -> ComposeTextOverflow.Visible
        null -> ComposeTextOverflow.Clip
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
