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
            // Element highlights (box+offset; spacer/divider are flow demos)
            "test-126-text-font-weights.json",           // TEXT (consolidated)
            "test-132-image-fit-crop-contain.json",      // IMAGE
            "test-140-button-primary-secondary.json",    // BUTTON
            "test-137-video-with-controls.json",         // VIDEO
            "test-177-html-inline-basic.json",           // HTML
            "test-055-all-spacer-elements.json",         // SPACER (vertical)
            "test-056-all-divider-elements.json",        // DIVIDER (vertical)
            // Container-type demos
            "test-001-vertical-simple.json",             // VERTICAL
            "test-002-horizontal-simple.json",           // HORIZONTAL
            // aspectRatio sizing (box)
            "test-121-16x9-ar-image-text-button.json",
            "test-122-1x1-ar-image-badge-rounded.json",
            "test-108-aspect-ratio-extreme-wide.json",
            // composition / effects (box)
            "test-145-nested-rounded-boxes.json",
            "test-135-images-z-order.json",
            "test-098-offset-percent-nested.json",
            "prod-007-box-16x9-flower-rainbow.json",
            "test-067-hero-banner.json",
            "test-004-stack-simple.json",
            "test-119-match-parent-stack-box.json",
            // catch-all / regression (box)
            "test-155-all-element-types.json",
            "test-178-error-boundary-smoke-test.json",
            // galleries (box+offset items)
            "test-173-gallery-box-snapping-indicators-navbtns.json",
            "test-157-gallery-box-freeflow-indicators-navbtns.json",
            "test-165-gallery-box-grid2col-indicators-navbtns.json",
            // Real-world galleries (inspired by production apps)
            "rw-01-restaurant-deals.json",
            "rw-02-dining-hero.json",
            "rw-03-cuisines.json",
            "rw-04-brand-tiles.json",
            "rw-05-service-grid.json",
            "rw-06-promo-banner.json",
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
