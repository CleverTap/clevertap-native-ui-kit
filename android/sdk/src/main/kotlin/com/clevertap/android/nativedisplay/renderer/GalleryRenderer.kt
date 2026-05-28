@file:OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)

package com.clevertap.android.nativedisplay.renderer

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.ArrowStyle
import com.clevertap.android.nativedisplay.models.GalleryConfig
import com.clevertap.android.nativedisplay.models.GalleryMode
import com.clevertap.android.nativedisplay.models.IndicatorPosition
import com.clevertap.android.nativedisplay.models.IndicatorShape
import com.clevertap.android.nativedisplay.models.IndicatorStyle
import com.clevertap.android.nativedisplay.models.NativeDisplayContainer
import com.clevertap.android.nativedisplay.models.Orientation
import com.clevertap.android.nativedisplay.models.Style
import kotlinx.collections.immutable.PersistentMap
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Main gallery renderer that routes to the appropriate implementation based on mode.
 */
@Composable
internal fun RenderGallery(
    container: NativeDisplayContainer,
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
    rootHeightPx: Float = 0f,
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
                rootHeightPx = rootHeightPx,
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
                rootHeightPx = rootHeightPx,
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
                rootHeightPx = rootHeightPx,
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
internal fun RenderSnappingGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
    rootHeightPx: Float = 0f,
) {
    if (container.children.isEmpty()) return

    val pagerState = rememberPagerState(
        initialPage = config.initialPage.coerceIn(0, maxOf(0, container.children.size - 1)),
        pageCount = { container.children.size }
    )
    val scope = rememberCoroutineScope()

    Box(modifier = modifier) {
        // Calculate peek padding from dp-based PeekConfig
        val peekBefore = config.peek.before.dp
        val peekAfter = config.peek.after.dp
        val hasPeek = container.children.size > 1 && (peekBefore > 0.dp || peekAfter > 0.dp)

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
                    contentPadding = if (hasPeek) PaddingValues(start = peekBefore, end = peekAfter)
                                     else PaddingValues(0.dp),
                    pageSpacing = config.spacing.dp,
                ) { page ->
                    container.children.getOrNull(page)?.let { child ->
                        RenderNode(
                            node = child,
                            resolvedStyles = resolvedStyles,
                            evaluator = evaluator,
                            modifier = Modifier.fillMaxWidth(),
                            actionHandler = actionHandler,
                            componentListener = componentListener,
                            rootHeightPx = rootHeightPx,
                        )
                    }
                }
            } else {
                VerticalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxHeight(),
                    contentPadding = if (hasPeek) PaddingValues(top = peekBefore, bottom = peekAfter)
                                     else PaddingValues(0.dp),
                    pageSpacing = config.spacing.dp,
                ) { page ->
                    container.children.getOrNull(page)?.let { child ->
                        RenderNode(
                            node = child,
                            resolvedStyles = resolvedStyles,
                            evaluator = evaluator,
                            modifier = Modifier.fillMaxHeight(),
                            actionHandler = actionHandler,
                            componentListener = componentListener,
                            rootHeightPx = rootHeightPx,
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
                            IndicatorPosition.TOP -> Alignment.TopCenter
                            IndicatorPosition.LEFT -> Alignment.CenterStart
                            IndicatorPosition.RIGHT -> Alignment.CenterEnd
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
internal fun RenderFreeFlowGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
    rootHeightPx: Float = 0f,
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
                    rootHeightPx = rootHeightPx,
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
                    rootHeightPx = rootHeightPx,
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
internal fun RenderFreeFlowGridGallery(
    container: NativeDisplayContainer,
    config: GalleryConfig,
    resolvedStyles: PersistentMap<String, Style>,
    evaluator: VariableEvaluator,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    componentListener: NativeDisplayComponentListener? = null,
    rootHeightPx: Float = 0f,
) {
    if (container.children.isEmpty()) return

    BoxWithConstraints(modifier = modifier) {
        val containerWidth = this.maxWidth
        val containerHeight = this.maxHeight

        if (config.orientation == Orientation.HORIZONTAL) {
            // Calculate item width based on itemsPerView
            val itemsPerView = config.effectiveItemsPerView.coerceAtLeast(0.1f)
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
                            rootHeightPx = rootHeightPx,
                        )
                    }
                }
            }
        } else {
            // Calculate item height based on itemsPerView
            val itemsPerView = config.effectiveItemsPerView.coerceAtLeast(0.1f)
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
                            rootHeightPx = rootHeightPx,
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
internal fun RenderGalleryArrows(
    pagerState: PagerState,
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
internal fun RenderGalleryIndicators(
    pagerState: PagerState,
    config: GalleryConfig,
    pageCount: Int,
    modifier: Modifier = Modifier
) {
    val indicatorStyle = config.indicatorStyle ?: IndicatorStyle()
    val activeColor = parseColor(indicatorStyle.activeColor) ?: Color.Blue
    val inactiveColor = parseColor(indicatorStyle.inactiveColor) ?: Color.LightGray

    val arrangement = Arrangement.spacedBy(indicatorStyle.spacing.dp)

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
                            shape = if (indicatorStyle.shape == IndicatorShape.CIRCLE) CircleShape else RoundedCornerShape(
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
                            shape = if (indicatorStyle.shape == IndicatorShape.CIRCLE) CircleShape else RoundedCornerShape(
                                2.dp
                            )
                        )
                )
            }
        }
    }
}
