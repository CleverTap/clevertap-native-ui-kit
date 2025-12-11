package com.clevertap.android.nativeui.sample

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.clevertap.android.nativedisplay.samples.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            NativeUIKitSampleApp()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NativeUIKitSampleApp() {
    MaterialTheme {
        var selectedTabIndex by remember { mutableStateOf(0) }
        
        val tabs = listOf(
            "Simple Card",
            "Product Card",
            "Nested",
            "All Elements",
            "Dividers",
            "Simple Gallery",
            "Full Gallery",
            "Free Gallery",
            "Combined",
            "Linear Grad",
            "Radial/Sweep",
            "Animated",
            "Patterns",
            "Layered",
            "🛍️ E-commerce",
            "👤 Social",
            "📊 Dashboard"
        )
        
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { 
                        Text(
                            "Native Display Kit",
                            style = MaterialTheme.typography.titleLarge
                        ) 
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
                // Tabs
                ScrollableTabRow(
                    selectedTabIndex = selectedTabIndex,
                    modifier = Modifier.fillMaxWidth(),
                    edgePadding = 8.dp
                ) {
                    tabs.forEachIndexed { index, title ->
                        Tab(
                            selected = selectedTabIndex == index,
                            onClick = { selectedTabIndex = index },
                            text = { Text(title) }
                        )
                    }
                }
                
                // Content
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color(0xFFF5F5F5))
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    when (selectedTabIndex) {
                        0 -> SimpleGreetingCardSample()
                        1 -> ProductCardSample()
                        2 -> NestedContainersSample()
                        3 -> AllElementsSample()
                        4 -> DividerDemoSample()
                        5 -> SimpleGallerySample()
                        6 -> FullFeaturedGallerySample()
                        7 -> FreeFlowGallerySample()
                        8 -> CombinedDemoSample()
                        9 -> LinearGradientsScreen()
                        10 -> RadialSweepGradientsScreen()
                        11 -> AnimatedBackgroundsScreen()
                        12 -> PatternBackgroundsScreen()
                        13 -> LayeredBackgroundsScreen()
                        14 -> EcommerceShowcaseScreen()
                        15 -> SocialProfileShowcaseScreen()
                        16 -> DashboardShowcaseScreen()
                    }
                }
            }
        }
    }
}

/**
 * Tab 9: Linear Gradients Demo
 */
@Composable
fun LinearGradientsScreen() {
    val config = BackgroundSamples.linearGradientsSample()
    NativeDisplayView(
        config = config,
        modifier = Modifier.fillMaxWidth()
    )
}

/**
 * Tab 10: Radial & Sweep Gradients Demo
 */
@Composable
fun RadialSweepGradientsScreen() {
    val config = BackgroundSamples.radialAndSweepGradientsSample()
    NativeDisplayView(
        config = config,
        modifier = Modifier.fillMaxWidth()
    )
}

/**
 * Tab 11: Animated Backgrounds Demo
 */
@Composable
fun AnimatedBackgroundsScreen() {
    val config = BackgroundSamples.animatedBackgroundsSample()
    NativeDisplayView(
        config = config,
        modifier = Modifier.fillMaxWidth()
    )
}

/**
 * Tab 12: Pattern Backgrounds Demo
 */
@Composable
fun PatternBackgroundsScreen() {
    val config = BackgroundSamples.patternBackgroundsSample()
    NativeDisplayView(
        config = config,
        modifier = Modifier.fillMaxWidth()
    )
}

/**
 * Tab 13: Layered & Complex Backgrounds Demo
 */
@Composable
fun LayeredBackgroundsScreen() {
    val config = BackgroundSamples.layeredBackgroundsSample()
    NativeDisplayView(
        config = config,
        modifier = Modifier.fillMaxWidth()
    )
}

/**
 * Tab 14: JSON Test (Simple)
 * Minimal JSON example to verify structure works
 */
@Composable
fun JsonTestScreen() {
    val context = LocalContext.current
    val config = remember {
        JsonLoader.loadFromAssets(context, "test_simple.json")
    }
    
    Column(modifier = Modifier.fillMaxWidth()) {
        if (config != null) {
            Text(
                "✅ JSON loaded successfully!",
                style = MaterialTheme.typography.bodyLarge,
                color = Color(0xFF4CAF50),
                modifier = Modifier.padding(bottom = 16.dp)
            )
            NativeDisplayView(
                config = config,
                modifier = Modifier.fillMaxWidth()
            )
        } else {
            ErrorMessage("Failed to load test_simple.json")
        }
    }
}

/**
 * Tab 15: E-commerce Product Showcase (JSON)
 * Demonstrates: Layered backgrounds, multiple text styles, buttons, badges, animations
 */
@Composable
fun EcommerceShowcaseScreen() {
    val context = LocalContext.current
    val config = remember {
        JsonLoader.loadFromAssets(context, "showcase_ecommerce_product.json")
    }
    
    if (config != null) {
        NativeDisplayView(
            config = config,
            modifier = Modifier.fillMaxWidth()
        )
    } else {
        ErrorMessage("Failed to load E-commerce showcase")
    }
}

/**
 * Tab 16: Social Profile Showcase (JSON)
 * Demonstrates: Hero section, badges, avatar, stats, buttons, tags
 */
@Composable
fun SocialProfileShowcaseScreen() {
    val context = LocalContext.current
    val config = remember {
        JsonLoader.loadFromAssets(context, "showcase_social_profile.json")
    }
    
    if (config != null) {
        NativeDisplayView(
            config = config,
            modifier = Modifier.fillMaxWidth()
        )
    } else {
        ErrorMessage("Failed to load Social Profile showcase")
    }
}

/**
 * Tab 17: Dashboard Showcase (JSON)
 * Demonstrates: Header card, metrics, activity feed, quick actions
 */
@Composable
fun DashboardShowcaseScreen() {
    val context = LocalContext.current
    val config = remember {
        JsonLoader.loadFromAssets(context, "showcase_dashboard.json")
    }
    
    if (config != null) {
        NativeDisplayView(
            config = config,
            modifier = Modifier.fillMaxWidth()
        )
    } else {
        ErrorMessage("Failed to load Dashboard showcase")
    }
}

/**
 * Error message composable
 */
@Composable
fun ErrorMessage(message: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp)
            .background(Color(0xFFFFEBEE), shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp))
            .padding(24.dp)
    ) {
        Text(
            text = message,
            color = Color(0xFFC62828),
            style = MaterialTheme.typography.bodyMedium
        )
    }
}
