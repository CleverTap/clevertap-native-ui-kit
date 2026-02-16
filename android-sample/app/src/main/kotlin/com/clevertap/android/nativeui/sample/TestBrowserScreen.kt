package com.clevertap.android.nativeui.sample

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView

/**
 * TestBrowserScreen - Cycles through test JSON configurations for automated screenshot testing.
 *
 * Features:
 * - Previous/Next navigation buttons at the top
 * - Cycles through all test JSON files (test-001 through test-030)
 * - Shows current test number and filename
 * - Scrollable content area for rendered UI
 * - Loop navigation (wraps around at start/end)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TestBrowserScreen() {
    val context = LocalContext.current

    // List of all test configuration files (120 tests)
    val testFiles = remember {
        listOf(
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
            "test-120-wrap-content-constraints.json"
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            "Test Browser",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Text(
                            "Test ${currentIndex + 1}/${testFiles.size}: ${testFiles[currentIndex]}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Navigation Controls
            NavigationControls(
                currentIndex = currentIndex,
                totalTests = testFiles.size,
                onPrevious = ::goToPrevious,
                onNext = ::goToNext,
                modifier = Modifier.fillMaxWidth()
            )

            // Content Area
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xFFF5F5F5))
            ) {
                if (currentConfig != null) {
                    // Scrollable content
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                    ) {
                        NativeDisplayView(
                            config = currentConfig,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                } else {
                    // Error state
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
}

/**
 * Navigation controls bar with Previous and Next buttons
 */
@Composable
private fun NavigationControls(
    currentIndex: Int,
    totalTests: Int,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        color = MaterialTheme.colorScheme.surface,
        shadowElevation = 4.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Previous Button
            Button(
                onClick = onPrevious,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = "Previous Test",
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Previous")
            }

            // Counter Display
            Surface(
                modifier = Modifier
                    .padding(horizontal = 16.dp),
                color = MaterialTheme.colorScheme.primaryContainer,
                shape = MaterialTheme.shapes.small
            ) {
                Text(
                    text = "${currentIndex + 1} / $totalTests",
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Bold
                    ),
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }

            // Next Button
            Button(
                onClick = onNext,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Text("Next")
                Spacer(modifier = Modifier.width(8.dp))
                Icon(
                    imageVector = Icons.Default.ArrowForward,
                    contentDescription = "Next Test",
                    modifier = Modifier.size(20.dp)
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
                text = "⚠️ Error",
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
