package com.clevertap.android.nativeui.sample

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle

/**
 * TestBrowserScreen - Cycles through test JSON configurations for automated screenshot testing.
 *
 * Features:
 * - Navigation row with prev/next icon buttons, filename, and counter (e.g. "26/156")
 * - Scrollable chip strip for quick test selection
 * - Scrollable content area for rendered UI
 * - Loop navigation (wraps around at start/end)
 */
@Composable
fun TestBrowserScreen() {
    val context = LocalContext.current

    // List of all test configuration files. The first entries are repro fixtures
    // that live at the top of RN's `configRegistry.ts` (see
    // react-native/example/testConfigs/configRegistry.ts) - mirrored here so the
    // Browser tab opens the same fixture at the same index on both platforms.
    val testFiles = remember {
        listOf(
            // Production CleverTap response fixtures - real native_display_config
            // payloads captured from server logs, transcribed verbatim into JSON.
            "prod-001-box-1x1-2buttons.json",
            "prod-002-box-16x9-video.json",
            "prod-003-box-16x9-buttons.json",
            "prod-004-box-9x16-buttons.json",
            "prod-005-box-3x4-images.json",
            "prod-006-box-16x9-yes-no.json",
            "prod-007-box-16x9-flower-rainbow.json",
            "prod-008-box-3x4-lorem-ipsum.json",
            "test-178-error-boundary-smoke-test.json",
            "test-177-button-stroke-text-clip-repro.json",
            "image-fit-test.json",
            "test-001-vertical-simple.json",
            "test-002-horizontal-simple.json",
            "test-003-box-simple.json",
            "test-004-stack-simple.json",
            "test-005-gallery-simple.json",
            "test-006-vertical-empty.json",
            "test-007-vertical-single-child.json",
            "test-008-vertical-3-children.json",
            "test-009-vertical-5-children.json",
            "test-010-vertical-10-children.json",
            "test-011-horizontal-empty.json",
            "test-012-horizontal-single-child.json",
            "test-013-horizontal-3-children.json",
            "test-014-horizontal-5-children.json",
            "test-015-horizontal-10-children.json",
            "test-016-box-empty.json",
            "test-017-box-single-child.json",
            "test-018-box-3-children.json",
            "test-019-box-5-children.json",
            "test-020-stack-empty.json",
            "test-021-stack-single-child.json",
            "test-022-stack-3-children.json",
            "test-023-stack-5-children.json",
            "test-024-gallery-empty.json",
            "test-025-gallery-single-child.json",
            "test-026-gallery-3-children-snapping.json",
            "test-027-gallery-5-children-snapping.json",
            "test-028-gallery-10-children-snapping.json",
            "test-029-gallery-3-children-free-flow.json",
            "test-030-gallery-3-children-free-flow-grid.json",
            "test-031-vertical-spaced.json",
            "test-032-vertical-space-between.json",
            "test-033-vertical-space-evenly.json",
            "test-034-vertical-space-around.json",
            "test-035-horizontal-start.json",
            "test-036-horizontal-center.json",
            "test-037-horizontal-end.json",
            "test-038-vertical-spacing-0.json",
            "test-039-vertical-spacing-8.json",
            "test-040-vertical-spacing-16.json",
            "test-041-vertical-spacing-32.json",
            "test-042-vertical-padding-uniform.json",
            "test-043-vertical-padding-individual.json",
            "test-044-horizontal-padding-asymmetric.json",
            "test-045-box-padding-large.json",
            "test-046-vertical-wrap-content.json",
            "test-047-horizontal-percent-width.json",
            "test-048-vertical-mixed-units.json",
            "test-049-nested-mixed-arrangements.json",
            "test-050-gallery-spacing-variations.json",
            "test-051-all-text-elements.json",
            "test-052-all-image-elements.json",
            "test-053-all-button-elements.json",
            "test-054-all-video-elements.json",
            "test-055-all-spacer-elements.json",
            "test-056-all-divider-elements.json",
            "test-057-product-card.json",
            "test-058-login-form.json",
            "test-059-profile-header.json",
            "test-060-media-player.json",
            "test-061-article-layout.json",
            "test-062-action-sheet.json",
            "test-063-stats-card.json",
            "test-064-gallery-item.json",
            "test-065-notification.json",
            "test-066-pricing-card.json",
            "test-067-hero-banner.json",
            "test-068-social-post.json",
            "test-069-settings-row.json",
            "test-070-feature-showcase.json",
            "test-071-text-colors.json",
            "test-072-font-sizes.json",
            "test-073-font-weights.json",
            "test-074-text-alignment.json",
            "test-075-text-decoration.json",
            "test-076-line-height.json",
            "test-077-font-families.json",
            "test-078-border-radius.json",
            "test-079-border-width-color.json",
            "test-080-shadows-light.json",
            "test-081-shadows-medium.json",
            "test-082-shadows-heavy.json",
            "test-083-opacity-variations.json",
            "test-084-combined-visual-styles.json",
            "test-085-text-style-inheritance.json",
            "test-086-style-class-usage.json",
            "test-087-inline-vs-inherited.json",
            "test-088-theme-default-styles.json",
            "test-089-styled-product-card.json",
            "test-090-styled-profile-card.json",
            "test-091-offset-percent-box-basic.json",
            "test-092-offset-percent-stack-layers.json",
            "test-093-offset-percent-negative.json",
            "test-094-offset-percent-overflow.json",
            "test-095-offset-percent-zero.json",
            "test-096-offset-percent-responsive.json",
            "test-097-offset-mixed-units.json",
            "test-098-offset-percent-nested.json",
            "test-099-offset-percent-with-padding.json",
            "test-100-offset-percent-gallery-peek.json",
            "test-101-aspect-ratio-square-fixed-width.json",
            "test-102-aspect-ratio-16-9-fixed-width.json",
            "test-103-aspect-ratio-4-3-fixed-width.json",
            "test-104-aspect-ratio-fixed-height.json",
            "test-105-aspect-ratio-percent-width.json",
            "test-106-aspect-ratio-wrap-content.json",
            "test-107-aspect-ratio-match-parent.json",
            "test-108-aspect-ratio-extreme-wide.json",
            "test-109-aspect-ratio-extreme-tall.json",
            "test-110-aspect-ratio-mixed-container.json",
            "test-111-combined-aspect-offset-box.json",
            "test-112-combined-nested-complex.json",
            "test-113-combined-gallery-aspect-peek.json",
            "test-114-combined-product-grid.json",
            "test-115-combined-showcase-all.json",
            "test-116-match-parent-comprehensive.json",
            "test-117-wrap-content-comprehensive.json",
            "test-118-mixed-special-dimensions.json",
            "test-119-match-parent-stack-box.json",
            "test-120-wrap-content-constraints.json",
            "test-121-16x9-ar-image-text-button.json",
            "test-122-1x1-ar-image-badge-rounded.json",
            "test-123-9x16-ar-video-caption.json",
            "test-124-4x3-ar-text-weights.json",
            "test-125-2x1-ar-image-split-button.json",
            "test-126-text-font-weights.json",
            "test-127-text-font-sizes.json",
            "test-128-text-alignment.json",
            "test-129-text-decoration-italic.json",
            "test-130-text-maxlines-overflow.json",
            "test-131-text-gradient.json",
            "test-132-image-fit-crop-contain.json",
            "test-133-image-gif-rounded.json",
            "test-134-image-border-radius.json",
            "test-135-images-z-order.json",
            "test-136-video-autoplay-muted.json",
            "test-137-video-with-controls.json",
            "test-138-9x16-video-button.json",
            "test-139-button-centered.json",
            "test-140-button-primary-secondary.json",
            "test-141-button-size-variants.json",
            "test-142-cta-card.json",
            "test-143-button-rounded-text.json",
            "test-144-rounded-box-text.json",
            "test-145-nested-rounded-boxes.json",
            "test-146-image-overlay-rounded.json",
            "test-147-hero-banner-complex.json",
            "test-148-product-card-complex.json",
            "test-149-notification-card.json",
            "test-150-dashboard-widget.json",
            "test-151-video-player-card.json",
            "test-152-text-corners.json",
            "test-153-image-clipped.json",
            "test-154-nested-box-deep.json",
            "test-155-all-element-types.json",
            "test-156-button-backgrounds.json",
            "test-157-gallery-box-freeflow-indicators-navbtns.json",
            "test-158-gallery-box-freeflow-indicators-only.json",
            "test-159-gallery-box-freeflow-navbtns-only.json",
            "test-160-gallery-box-freeflow-minimal.json",
            "test-161-gallery-box-freeflow-tall-images.json",
            "test-162-gallery-box-freeflow-video-items.json",
            "test-163-gallery-box-freeflow-button-items.json",
            "test-164-gallery-box-freeflow-5items.json",
            "test-165-gallery-box-grid2col-indicators-navbtns.json",
            "test-166-gallery-box-grid2col-indicators-only.json",
            "test-167-gallery-box-grid2col-navbtns-only.json",
            "test-168-gallery-box-grid2col-minimal.json",
            "test-169-gallery-box-grid3col-indicators.json",
            "test-170-gallery-box-grid3col-navbtns.json",
            "test-171-gallery-box-grid2col-video.json",
            "test-172-gallery-box-grid2col-vertical.json",
            "test-173-gallery-box-snapping-indicators-navbtns.json",
            "test-174-gallery-box-snapping-indicators-only.json",
            "test-175-gallery-box-snapping-navbtns-only.json",
            "test-176-gallery-box-snapping-minimal.json",
            // HTML element tests
            "test-177-html-inline-basic.json",
            "test-178-html-with-javascript.json",
            "test-179-html-transparent-bg.json",
            "test-180-html-scrollable-content.json",
            // Video fullscreen + openUrl binding
            "test-172-video-fullscreen-openurl.json"
        )
    }

    // Current test index state
    var currentIndex by remember { mutableIntStateOf(0) }

    // Load current test configuration
    val currentConfig = remember(currentIndex) {
        try {
            JsonLoader.loadFromAssets(context, "test-configs/${testFiles[currentIndex]}")
        } catch (e: Exception) {
            null
        }
    }

    // Navigation functions
    fun goToPrevious() {
        currentIndex = if (currentIndex > 0) currentIndex - 1 else testFiles.size - 1
    }

    fun goToNext() {
        currentIndex = if (currentIndex < testFiles.size - 1) currentIndex + 1 else 0
    }

    // Chip strip state
    val chipListState = rememberLazyListState()
    val screenWidthDp = LocalConfiguration.current.screenWidthDp
    val density = LocalDensity.current

    // Auto-scroll chip strip when currentIndex changes
    LaunchedEffect(currentIndex) {
        val chipWidthPx = with(density) { 44.dp.toPx() }
        val screenWidthPx = with(density) { screenWidthDp.dp.toPx() }
        val scrollOffset = -(screenWidthPx / 2 - chipWidthPx / 2).toInt()
        chipListState.animateScrollToItem(currentIndex, scrollOffset)
    }

    // Current filename without extension
    val currentFilename = remember(currentIndex) {
        testFiles[currentIndex].removeSuffix(".json")
    }

    // Counter label e.g. "26/156"
    val counterLabel = remember(currentIndex) {
        "${currentIndex + 1}/${testFiles.size}"
    }

    Column(modifier = Modifier.fillMaxSize()) {
            // Navigation row
            NavigationRow(
                filename = currentFilename,
                counter = counterLabel,
                onPrevious = ::goToPrevious,
                onNext = ::goToNext,
                modifier = Modifier.fillMaxWidth()
            )

            // Chip strip
            ChipStrip(
                testCount = testFiles.size,
                currentIndex = currentIndex,
                listState = chipListState,
                onChipSelected = { index -> currentIndex = index },
                modifier = Modifier.fillMaxWidth()
            )

            // Content Area
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f)
                    .background(Color(0xFFF5F5F5))
            ) {
                if (currentConfig != null) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            // Cyan tint so any space around the NativeDisplayView
                            // is obvious. Mirrors the RN contentScroll background.
                            .background(Color(0xFF80DEEA))
                    ) {
                        NativeDisplayView(
                            config = currentConfig,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                } else {
                    ErrorIndicator(
                        message = "Failed to load ${testFiles[currentIndex]}",
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp)
                            .align(Alignment.Center)
                    )
                }
            }
        }
}

/**
 * Navigation row with prev/next icon buttons, centered filename, and counter.
 */
@Composable
private fun NavigationRow(
    filename: String,
    counter: String,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onPrevious) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Previous Test"
                )
            }

            Text(
                text = buildAnnotatedString {
                    append(filename)
                    append(" ")
                    withStyle(SpanStyle(
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                        fontSize = 11.sp
                    )) {
                        append("($counter)")
                    }
                },
                style = MaterialTheme.typography.bodySmall.copy(fontSize = 13.sp),
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )

            IconButton(onClick = onNext) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = "Next Test"
                )
            }
        }
    }
}

/**
 * Scrollable chip strip for quick test selection.
 */
@Composable
private fun ChipStrip(
    testCount: Int,
    currentIndex: Int,
    listState: androidx.compose.foundation.lazy.LazyListState,
    onChipSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyRow(
        state = listState,
        modifier = modifier
            .background(MaterialTheme.colorScheme.surface)
            .padding(vertical = 6.dp),
        contentPadding = PaddingValues(horizontal = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        itemsIndexed(List(testCount) { it }) { index, _ ->
            val isSelected = index == currentIndex
            val label = (index + 1).toString().padStart(3, '0')

            Box(
                modifier = Modifier
                    .height(32.dp)
                    .widthIn(min = 40.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(
                        if (isSelected) MaterialTheme.colorScheme.primary
                        else MaterialTheme.colorScheme.surfaceVariant
                    )
                    .clickable { onChipSelected(index) }
                    .padding(horizontal = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                        color = if (isSelected) MaterialTheme.colorScheme.onPrimary
                        else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            }
        }
    }
}

/**
 * Error indicator for failed JSON loading
 */
@Composable
private fun ErrorIndicator(
    message: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFFFFEBEE)
        )
    ) {
        Column(
            modifier = Modifier
                .padding(24.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Error",
                style = MaterialTheme.typography.titleLarge,
                color = Color(0xFFC62828),
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFFC62828)
            )
        }
    }
}
