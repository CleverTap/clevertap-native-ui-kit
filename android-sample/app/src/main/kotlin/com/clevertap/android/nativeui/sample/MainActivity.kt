package com.clevertap.android.nativeui.sample

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.models.ArrangementStrategy
import com.clevertap.android.nativedisplay.models.ChildArrangement
import com.clevertap.android.nativedisplay.models.NativeDisplayContainer
import com.clevertap.android.nativedisplay.models.ResolvedConfig
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
            "📏 Arrangements",    // NEW - Arrangement strategies demo
            "🎬 Animations",      // NEW - Animation demos
            "🧪 Test Browser",    // NEW - Test automation browser
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
                        .then(
                            // No vertical scroll for Home screen and Test Browser
                            if (selectedTabIndex == 0 || selectedTabIndex == 3) {
                                Modifier
                            } else {
                                Modifier.verticalScroll(rememberScrollState())
                            }
                        )
                        .padding(
                            // No padding for Home screen and Test Browser to allow edge-to-edge design
                            if (selectedTabIndex == 0 || selectedTabIndex == 3) 0.dp else 16.dp
                        )
                ) {
                    when (selectedTabIndex) {
                        0 -> HomeScreen()
                        1 -> ArrangementDemoScreen()
                        2 -> AnimationDemoScreen()
                        3 -> TestBrowserScreen()
                        4 -> SimpleGreetingCardSample()
                        5 -> ProductCardSample()
                        6 -> NestedContainersSample()
                        7 -> AllElementsSample()
                        8 -> DividerDemoSample()
                        9 -> SimpleGallerySample()
                        10 -> FullFeaturedGallerySample()
                        11 -> FreeFlowGallerySample()
                        12 -> CombinedDemoSample()
                        13 -> LinearGradientsScreen()
                        14 -> RadialSweepGradientsScreen()
                        15 -> AnimatedBackgroundsScreen()
                        16 -> PatternBackgroundsScreen()
                        17 -> LayeredBackgroundsScreen()
                        18 -> EcommerceShowcaseScreen()
                        19 -> SocialProfileShowcaseScreen()
                        20 -> DashboardShowcaseScreen()
                        21 -> GalleryShowcaseScreen()
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
            modifier = Modifier.fillMaxWidth(),
            componentListener = object : com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener {
                // Listen to ALL components by returning null
                override fun getInterestedNodeIds(): Set<String>? = null
                
                override fun onComponentInteraction(
                    nodeId: String,
                    interactionType: com.clevertap.android.nativedisplay.listener.InteractionType,
                    hasServerAction: Boolean
                ): Boolean {
                    // Log every interaction
                    Log.d(
                        "HomeScreen_Click",
                        "Component: $nodeId | Type: $interactionType | HasServerAction: $hasServerAction"
                    )
                    
                    // Don't consume, let server actions proceed
                    return false
                }
            }
        )
    } else {
        ErrorMessage("Failed to load Home Screen")
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ArrangementDemoScreen() {
    val context = LocalContext.current

    // 1. Initial configuration state loaded from JSON
    val initialConfig = remember {
        JsonLoader.loadFromAssets(context, "arrangement_demo.json")
    }

    // 2. State for the current configuration to allow dynamic updates
    var currentConfig: ResolvedConfig? by remember(initialConfig) { mutableStateOf(initialConfig) }

    // 3. Define the available strategies based on your ChildArrangement model
    val strategies = remember {
        listOf(
            "SPACED" to ChildArrangement(spacing = 16f, strategy = ArrangementStrategy.SPACED),
            "BETWEEN" to ChildArrangement(strategy = ArrangementStrategy.SPACE_BETWEEN),
            "EVENLY" to ChildArrangement(strategy = ArrangementStrategy.SPACE_EVENLY),
            "AROUND" to ChildArrangement(strategy = ArrangementStrategy.SPACE_AROUND),
            "START" to ChildArrangement(strategy = ArrangementStrategy.START),
            "CENTER" to ChildArrangement(strategy = ArrangementStrategy.CENTER),
            "END" to ChildArrangement(strategy = ArrangementStrategy.END)
        )
    }

    var selectedStrategyName by remember { mutableStateOf("SPACED") }

    Column(modifier = Modifier.fillMaxSize()) {
        // 4. Horizontal Picker
        LazyRow(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(strategies) { (name, arrangement) ->
                FilterChip(
                    selected = selectedStrategyName == name,
                    onClick = {
                        selectedStrategyName = name
                        // 5. Logic to update the configuration deep inside the root
                        currentConfig = currentConfig?.let { config ->
                            updateRootArrangement(config, arrangement)
                        }
                    },
                    label = { Text(name) }
                )
            }
        }

        // 6. Display View
        if (currentConfig != null) {
            NativeDisplayView(
                config = currentConfig!!,
                modifier = Modifier
                    .fillMaxWidth()
            )
        } else {
            ErrorMessage("Loading Arrangement Demo...")
        }
    }
}

/**
 * Helper to update the arrangement strategy in your root container.
 * This assumes your root is a NativeDisplayContainer.
 */
private fun updateRootArrangement(
    config: ResolvedConfig,
    newArrangement: ChildArrangement
): ResolvedConfig {
    val root = config.root
    if (root is NativeDisplayContainer) {
        val updatedRoot = root.copy(
            layout = root.layout?.copy(arrangement = newArrangement)
        )
        return config.copy(root = updatedRoot)
    }
    return config
}

/**
 * Tab 2: Animation Demos (NEW)
 * Shows three animation examples:
 * 1. Container with fade animation
 * 2. Staggered children animations (manual delays)
 * 3. Container + children combined animations
 */
@Composable
fun AnimationDemoScreen() {
    val context = LocalContext.current
    
    // Three demo configurations
    val demos = remember {
        listOf(
            "Container Fade" to "animation_container_fade.json",
            "Staggered Children" to "animation_staggered_children.json",
            "Container + Children" to "animation_container_and_children.json"
        )
    }
    
    var selectedDemo by remember { mutableStateOf(0) }
    val currentConfig = remember(selectedDemo) {
        JsonLoader.loadFromAssets(context, demos[selectedDemo].second)
    }
    
    Column(modifier = Modifier.fillMaxSize()) {
        // Demo Selector
        LazyRow(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(demos.size) { index ->
                FilterChip(
                    selected = selectedDemo == index,
                    onClick = { selectedDemo = index },
                    label = { Text(demos[index].first) }
                )
            }
        }
        
        // Info Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color(0xFFFFF3E0)
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = when (selectedDemo) {
                        0 -> "💡 Entire container fades in (500ms). All children appear together."
                        1 -> "💡 Each child slides in from left with 100ms stagger delay (0ms, 100ms, 200ms, 300ms, 400ms)."
                        2 -> "💡 Container fades in first (0ms), then image scales (400ms delay), text slides (600ms, 800ms delay), features fade-scale (1000-1200ms delay), button springs (1400ms)."
                        else -> ""
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFFE65100)
                )
            }
        }
        
        // Animation Demo View
        if (currentConfig != null) {
            NativeDisplayView(
                config = currentConfig,
                modifier = Modifier.fillMaxWidth()
            )
        } else {
            ErrorMessage("Failed to load ${demos[selectedDemo].second}")
        }
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
            .background(
                Color(0xFFFFEBEE),
                shape = RoundedCornerShape(12.dp)
            )
            .padding(24.dp)
    ) {
        Text(
            text = message,
            color = Color(0xFFC62828),
            style = MaterialTheme.typography.bodyMedium
        )
    }
}
