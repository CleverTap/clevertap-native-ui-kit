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
            "🏠 Home",           // NEW - First position
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
            "📊 Dashboard",
            "Gallery"
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
                        .padding(
                            // No padding for Home screen to allow edge-to-edge design
                            if (selectedTabIndex == 0) 0.dp else 16.dp
                        )
                ) {
                    when (selectedTabIndex) {
                        0 -> HomeScreen()              // NEW
                        1 -> SimpleGreetingCardSample()
                        2 -> ProductCardSample()
                        3 -> NestedContainersSample()
                        4 -> AllElementsSample()
                        5 -> DividerDemoSample()
                        6 -> SimpleGallerySample()
                        7 -> FullFeaturedGallerySample()
                        8 -> FreeFlowGallerySample()
                        9 -> CombinedDemoSample()
                        10 -> LinearGradientsScreen()
                        11 -> RadialSweepGradientsScreen()
                        12 -> AnimatedBackgroundsScreen()
                        13 -> PatternBackgroundsScreen()
                        14 -> LayeredBackgroundsScreen()
                        15 -> EcommerceShowcaseScreen()
                        16 -> SocialProfileShowcaseScreen()
                        17 -> DashboardShowcaseScreen()
                        18 -> GalleryShowcaseScreen()
                    }
                }
            }
        }
    }
}

/**
 * Tab 0: Home Screen (NEW)
 * Modern e-commerce home page with:
 * - Auto-scrolling banner carousel
 * - Full-screen promotional banner
 * - Product grid with cards
 * - Category tags
 * - Quick actions
 */
@Composable
fun HomeScreen() {
    val context = LocalContext.current
    val config = remember {
        JsonLoader.loadFromAssets(context, "home_screen.json")
    }
    
    if (config != null) {
        NativeDisplayView(
            config = config,
            modifier = Modifier.fillMaxWidth()
        )
    } else {
        ErrorMessage("Failed to load Home Screen")
    }
}

/**
 * Tab 10: Linear Gradients Demo
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
 * Tab 11: Radial & Sweep Gradients Demo
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
 * Tab 12: Animated Backgrounds Demo
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
 * Tab 13: Pattern Backgrounds Demo
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
 * Tab 14: Layered & Complex Backgrounds Demo
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
 * Tab 15: JSON Test (Simple)
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
 * Tab 16: E-commerce Product Showcase (JSON)
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
 * Tab 17: Social Profile Showcase (JSON)
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
 * Tab 18: Dashboard Showcase (JSON)
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
 * Tab 19: Gallery Showcase (JSON)
 * Demonstrates: Galleries
 */
@Composable
fun GalleryShowcaseScreen() {
    val context = LocalContext.current
    val config = remember {
        JsonLoader.loadFromAssets(context, "gallery_three_modes.json")
    }

    if (config != null) {
        NativeDisplayView(
            config = config,
            modifier = Modifier.fillMaxWidth()
        )
    } else {
        ErrorMessage("Failed to load gallery showcase")
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
