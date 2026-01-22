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

    // List of all test configuration files (Phase 1, 2, and 3)
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
            "test-050-gallery-spacing-variations.json"
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
