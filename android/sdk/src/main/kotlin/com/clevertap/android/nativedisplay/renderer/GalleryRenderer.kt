@file:OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)

package com.clevertap.android.nativedisplay.renderer

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
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
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
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
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
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
 *
 * Implementation note: this used to be built on `HorizontalPager` / `VerticalPager`
 * + `rememberPagerState`. Those APIs had an ABI break between compose-foundation
 * 1.6 and 1.7 (`beyondBoundsPageCount` → `beyondViewportPageCount`) — different
 * Kotlin mangled symbols, so the SDK's compiled bytecode crashed with
 * `NoSuchMethodError` against any client running a different Compose minor
 * version. To keep the SDK Compose-version-agnostic we rebuild the snapping
 * behavior on top of `LazyRow` / `LazyColumn` + `rememberSnapFlingBehavior`,
 * all of which have been signature-stable across compose-foundation 1.5+.
 *
 * Close-enough parity with Pager: snap timing/inertia differ slightly because
 * the fling behavior is the foundation snap fling, not Pager's custom decay.
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

    val pageCount = container.children.size
    val initialPage = config.initialPage.coerceIn(0, maxOf(0, pageCount - 1))
    val lazyListState = rememberLazyListState(initialFirstVisibleItemIndex = initialPage)
    val flingBehavior = rememberSnapFlingBehavior(lazyListState = lazyListState)
    val scope = rememberCoroutineScope()

    // "Current page" is the item whose extent covers the viewport center. With
    // peek enabled, the first visible index lags behind by one — using the
    // viewport-center calculation keeps indicator/arrow state correct for both
    // peek and non-peek configurations.
    val currentPage by remember(lazyListState) {
        derivedStateOf { lazyListState.currentPageByViewportCenter() }
    }

    Box(modifier = modifier) {
        val peekBefore = config.peek.before.dp
        val peekAfter = config.peek.after.dp
        val hasPeek = pageCount > 1 && (peekBefore > 0.dp || peekAfter > 0.dp)

        // Auto-scroll
        if (config.autoScrollInterval > 0 && pageCount > 1) {
            LaunchedEffect(currentPage) {
                delay(config.autoScrollInterval)
                val nextPage = if (config.infiniteScroll) {
                    (currentPage + 1) % pageCount
                } else {
                    (currentPage + 1).coerceAtMost(pageCount - 1)
                }
                if (nextPage != currentPage) {
                    lazyListState.animateScrollToItem(nextPage)
                }
            }
        }

        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            // Each "page" is sized to the container's full extent minus the
            // peek padding — exactly what `HorizontalPager` did automatically.
            val pageWidth = (maxWidth - peekBefore - peekAfter).coerceAtLeast(0.dp)
            val pageHeight = (maxHeight - peekBefore - peekAfter).coerceAtLeast(0.dp)

            if (config.orientation == Orientation.HORIZONTAL) {
                LazyRow(
                    state = lazyListState,
                    modifier = Modifier.fillMaxWidth(),
                    contentPadding = if (hasPeek) PaddingValues(start = peekBefore, end = peekAfter)
                                     else PaddingValues(0.dp),
                    horizontalArrangement = Arrangement.spacedBy(config.spacing.dp),
                    flingBehavior = flingBehavior,
                ) {
                    itemsIndexed(container.children, key = { _, child -> child.id }) { _, child ->
                        Box(modifier = Modifier.width(pageWidth)) {
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
                LazyColumn(
                    state = lazyListState,
                    modifier = Modifier.fillMaxHeight(),
                    contentPadding = if (hasPeek) PaddingValues(top = peekBefore, bottom = peekAfter)
                                     else PaddingValues(0.dp),
                    verticalArrangement = Arrangement.spacedBy(config.spacing.dp),
                    flingBehavior = flingBehavior,
                ) {
                    itemsIndexed(container.children, key = { _, child -> child.id }) { _, child ->
                        Box(modifier = Modifier.height(pageHeight)) {
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

            // Navigation arrows
            if (config.showArrows && pageCount > 1) {
                RenderGalleryArrows(
                    currentPage = currentPage,
                    pageCount = pageCount,
                    config = config,
                    onPrevious = {
                        scope.launch {
                            val prevPage = if (config.infiniteScroll && currentPage == 0) {
                                pageCount - 1
                            } else {
                                (currentPage - 1).coerceAtLeast(0)
                            }
                            lazyListState.animateScrollToItem(prevPage)
                        }
                    },
                    onNext = {
                        scope.launch {
                            val nextPage = if (config.infiniteScroll && currentPage == pageCount - 1) {
                                0
                            } else {
                                (currentPage + 1).coerceAtMost(pageCount - 1)
                            }
                            lazyListState.animateScrollToItem(nextPage)
                        }
                    },
                    modifier = Modifier.align(Alignment.Center)
                )
            }

            // Page indicators
            if (config.showIndicators && pageCount > 1) {
                RenderGalleryIndicators(
                    currentPage = currentPage,
                    pageCount = pageCount,
                    config = config,
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
 * The item whose extent covers the viewport center. Replaces
 * `PagerState.currentPage`, which Pager exposed but LazyListState doesn't.
 *
 * Falls back to `firstVisibleItemIndex` if the viewport is empty (e.g. while
 * the list is still measuring). Works for both horizontal and vertical
 * orientations because `LazyListItemInfo.offset` is in the scroll direction.
 */
private fun LazyListState.currentPageByViewportCenter(): Int {
    val info = layoutInfo
    val visible = info.visibleItemsInfo
    if (visible.isEmpty()) return firstVisibleItemIndex
    val viewportCenter = (info.viewportStartOffset + info.viewportEndOffset) / 2
    return visible.firstOrNull { item ->
        item.offset <= viewportCenter && item.offset + item.size > viewportCenter
    }?.index ?: firstVisibleItemIndex
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
 *
 * Takes `currentPage` + `pageCount` as plain Ints instead of a `PagerState` so
 * the snapping gallery can drive arrows from a `LazyListState`-derived index —
 * keeps this surface independent of which scroll-state primitive the parent
 * is using.
 */
@Composable
internal fun RenderGalleryArrows(
    currentPage: Int,
    pageCount: Int,
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
                enabled = config.infiniteScroll || currentPage > 0
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
                enabled = config.infiniteScroll || currentPage < pageCount - 1
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
                enabled = config.infiniteScroll || currentPage > 0
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
                enabled = config.infiniteScroll || currentPage < pageCount - 1
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
 *
 * Takes `currentPage` + `pageCount` as plain Ints — see companion comment on
 * `RenderGalleryArrows` for why.
 */
@Composable
internal fun RenderGalleryIndicators(
    currentPage: Int,
    pageCount: Int,
    config: GalleryConfig,
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
                            color = if (currentPage == index) activeColor else inactiveColor,
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
                            color = if (currentPage == index) activeColor else inactiveColor,
                            shape = if (indicatorStyle.shape == IndicatorShape.CIRCLE) CircleShape else RoundedCornerShape(
                                2.dp
                            )
                        )
                )
            }
        }
    }
}
