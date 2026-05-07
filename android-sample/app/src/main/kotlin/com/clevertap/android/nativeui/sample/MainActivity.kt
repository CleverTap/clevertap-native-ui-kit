package com.clevertap.android.nativeui.sample

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.zIndex
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.fragment.app.FragmentActivity
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.clevertap.android.nativedisplay.models.ArrangementStrategy
import com.clevertap.android.nativedisplay.models.ChildArrangement
import com.clevertap.android.nativedisplay.models.NativeDisplayContainer
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.clevertap.android.nativeui.sample.samples.*

class MainActivity : FragmentActivity() {
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
        val navController = rememberNavController()

        // Bottom navigation selected tab index (0=Events, 1=Slots, 2=XML Test, 3=Browser, 4=More)
        var selectedTab by remember { mutableStateOf(0) }

        NavHost(
            navController = navController,
            startDestination = "main"
        ) {
            // Main screen with bottom navigation
            composable("main") {
                Scaffold(
                    bottomBar = {
                        NavigationBar {
                            NavigationBarItem(
                                selected = selectedTab == 0,
                                onClick = { selectedTab = 0 },
                                icon = { Text("📡") },
                                label = { Text("Events") }
                            )
                            NavigationBarItem(
                                selected = selectedTab == 1,
                                onClick = { selectedTab = 1 },
                                icon = { Text("🎰") },
                                label = { Text("Slots") }
                            )
                            NavigationBarItem(
                                selected = selectedTab == 2,
                                onClick = { selectedTab = 2 },
                                icon = { Text("🖥️") },
                                label = { Text("XML Test") }
                            )
                            NavigationBarItem(
                                selected = selectedTab == 3,
                                onClick = { selectedTab = 3 },
                                icon = { Text("🧪") },
                                label = { Text("Browser") }
                            )
                            NavigationBarItem(
                                selected = selectedTab == 4,
                                onClick = { selectedTab = 4 },
                                icon = { Text("⚙️") },
                                label = { Text("More") }
                            )
                        }
                    }
                ) { paddingValues ->
                    Box(modifier = Modifier.padding(paddingValues).fillMaxSize()) {
                        TabContent(visible = selectedTab == 0) { CleverTapIntegrationScreen() }
                        TabContent(visible = selectedTab == 1) { SlotDemoScreen() }
                        TabContent(visible = selectedTab == 2) { XmlFeedScreen(modifier = Modifier.fillMaxSize()) }
                        TabContent(visible = selectedTab == 3) { TestBrowserScreen() }
                        TabContent(visible = selectedTab == 4) {
                            MoreMenuScreen(onNavigate = { route -> navController.navigate(route) })
                        }
                    }
                }
            }

            // Banner Detail Screen (navigated from Banners in More tab)
            composable(
                route = "banner_detail/{bannerId}?filename={filename}",
                arguments = listOf(
                    navArgument("bannerId") { type = NavType.StringType },
                    navArgument("filename") {
                        type = NavType.StringType
                        nullable = true
                    }
                )
            ) { backStackEntry ->
                val bannerId = backStackEntry.arguments?.getString("bannerId") ?: ""
                val filename = backStackEntry.arguments?.getString("filename")
                BannerDetailScreen(
                    navController = navController,
                    bannerId = bannerId,
                    filename = filename
                )
            }

            // JSON Viewer Screen
            composable(route = "json_viewer") {
                val jsonString = remember { JSONViewerStorage.getJsonString() }
                JSONViewerScreen(navController = navController, jsonString = jsonString)
            }

            // Demo Screens (accessed via More tab)
            composable(
                route = "demo_screen/{demoType}",
                arguments = listOf(navArgument("demoType") { type = NavType.StringType })
            ) { backStackEntry ->
                val demoType = backStackEntry.arguments?.getString("demoType") ?: "home"
                DemoScreenContainer(navController = navController, demoType = demoType)
            }

            // Banner Showcase (accessed via More tab)
            composable("banner_showcase") {
                DemoScreenContainer(navController = navController, demoType = "banners")
            }
        }
    }
}

@Composable
private fun TabContent(visible: Boolean, content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .zIndex(if (visible) 1f else 0f)
            .graphicsLayer { alpha = if (visible) 1f else 0f }
            .then(
                if (!visible) Modifier.pointerInput(Unit) {
                    awaitPointerEventScope {
                        while (true) {
                            awaitPointerEvent(PointerEventPass.Initial)
                                .changes.forEach { it.consume() }
                        }
                    }
                } else Modifier
            )
    ) { content() }
}

/**
 * More tab: LazyColumn navigation list replacing the old dropdown menu
 */
@Composable
fun MoreMenuScreen(onNavigate: (String) -> Unit) {
    val items = listOf(
        "🔗" to Pair("Bridge Integration", "demo_screen/bridge"),
        "🖼️" to Pair("Banner Showcase", "banner_showcase"),
        "📏" to Pair("Arrangements", "demo_screen/arrangements"),
        "🎬" to Pair("Animations", "demo_screen/animations"),
        "🔤" to Pair("Font Customization", "demo_screen/fonts"),
        "🏠" to Pair("Home Screen", "demo_screen/home"),
        "📦" to Pair("Other Demos", "demo_screen/other")
    )

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F5F5)),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        item {
            Text(
                text = "Developer Tools",
                style = MaterialTheme.typography.titleMedium,
                color = Color(0xFF666666),
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
            )
        }
        items(items) { (emoji, pair) ->
            val (label, route) = pair
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onNavigate(route) },
                color = Color.White
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(text = emoji, style = MaterialTheme.typography.titleLarge)
                    Spacer(modifier = Modifier.width(16.dp))
                    Text(
                        text = label,
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.weight(1f)
                    )
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        tint = Color(0xFFAAAAAA)
                    )
                }
            }
            HorizontalDivider(color = Color(0xFFF0F0F0))
        }
    }
}

/**
 * Container for demo screens accessed via More tab — keeps TopAppBar + back
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DemoScreenContainer(navController: androidx.navigation.NavController, demoType: String) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (demoType) {
                            "home" -> "🏠 Home"
                            "arrangements" -> "📏 Arrangements"
                            "animations" -> "🎬 Animations"
                            "test_browser" -> "🧪 Test Browser"
                            "bridge" -> "🔗 Bridge Integration"
                            "clevertap" -> "📡 CleverTap Integration"
                            "slots" -> "🎰 Slot Demo"
                            "fonts" -> "🔤 Font Customization"
                            "banners" -> "🖼️ Banner Showcase"
                            "other" -> "Other Demos"
                            else -> "Demo"
                        },
                        style = MaterialTheme.typography.titleLarge
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = MaterialTheme.colorScheme.onPrimary
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
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(Color(0xFFF5F5F5))
                .then(
                    if (demoType == "home" || demoType == "test_browser" || demoType == "bridge" ||
                        demoType == "clevertap" || demoType == "slots" || demoType == "fonts" ||
                        demoType == "banners"
                    ) {
                        Modifier
                    } else {
                        Modifier.verticalScroll(rememberScrollState())
                    }
                )
                .padding(
                    if (demoType == "home" || demoType == "test_browser" || demoType == "bridge" ||
                        demoType == "clevertap" || demoType == "slots" || demoType == "fonts" ||
                        demoType == "banners"
                    ) 0.dp else 16.dp
                )
        ) {
            when (demoType) {
                "home" -> HomeScreen()
                "arrangements" -> ArrangementDemoScreen()
                "animations" -> AnimationDemoScreen()
                "test_browser" -> TestBrowserScreen()
                "bridge" -> BridgeIntegrationScreen()
                "clevertap" -> CleverTapIntegrationScreen()
                "slots" -> SlotDemoScreen()
                "fonts" -> FontDemoScreen()
                "banners" -> BannerShowcaseScreen(navController = navController)
                "other" -> OtherDemosScreen()
            }
        }
    }
}

/**
 * Screen displaying all other demos
 */
@Composable
fun OtherDemosScreen() {
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
        "📊 Dashboard",
        "Gallery"
    )

    Column(modifier = Modifier.fillMaxSize()) {
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

        Box(
            modifier = Modifier
                .fillMaxSize()
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
                17 -> GalleryShowcaseScreen()
            }
        }
    }
}

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
                override fun getInterestedNodeIds(): Set<String>? = null

                override fun onComponentInteraction(
                    nodeId: String,
                    interactionType: com.clevertap.android.nativedisplay.listener.InteractionType,
                    hasServerAction: Boolean
                ): Boolean {
                    Log.d(
                        "HomeScreen_Click",
                        "Component: $nodeId | Type: $interactionType | HasServerAction: $hasServerAction"
                    )
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
    val initialConfig = remember { JsonLoader.loadFromAssets(context, "arrangement_demo.json") }
    var currentConfig: ResolvedConfig? by remember(initialConfig) { mutableStateOf(initialConfig) }

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
                        currentConfig = currentConfig?.let { config ->
                            updateRootArrangement(config, arrangement)
                        }
                    },
                    label = { Text(name) }
                )
            }
        }

        if (currentConfig != null) {
            NativeDisplayView(config = currentConfig!!, modifier = Modifier.fillMaxWidth())
        } else {
            ErrorMessage("Loading Arrangement Demo...")
        }
    }
}

private fun updateRootArrangement(
    config: ResolvedConfig,
    newArrangement: ChildArrangement
): ResolvedConfig {
    val root = config.root
    if (root is NativeDisplayContainer) {
        val updatedRoot = root.copy(layout = root.layout?.copy(arrangement = newArrangement))
        return config.copy(root = updatedRoot)
    }
    return config
}

@Composable
fun AnimationDemoScreen() {
    val context = LocalContext.current
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

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF3E0))
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = when (selectedDemo) {
                        0 -> "💡 Entire container fades in (500ms). All children appear together."
                        1 -> "💡 Each child slides in from left with 100ms stagger delay."
                        2 -> "💡 Container fades in first, then children animate in sequence."
                        else -> ""
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFFE65100)
                )
            }
        }

        if (currentConfig != null) {
            NativeDisplayView(config = currentConfig, modifier = Modifier.fillMaxWidth())
        } else {
            ErrorMessage("Failed to load ${demos[selectedDemo].second}")
        }
    }
}

@Composable
fun LinearGradientsScreen() {
    NativeDisplayView(config = BackgroundSamples.linearGradientsSample(), modifier = Modifier.fillMaxWidth())
}

@Composable
fun RadialSweepGradientsScreen() {
    NativeDisplayView(config = BackgroundSamples.radialAndSweepGradientsSample(), modifier = Modifier.fillMaxWidth())
}

@Composable
fun AnimatedBackgroundsScreen() {
    NativeDisplayView(config = BackgroundSamples.animatedBackgroundsSample(), modifier = Modifier.fillMaxWidth())
}

@Composable
fun PatternBackgroundsScreen() {
    NativeDisplayView(config = BackgroundSamples.patternBackgroundsSample(), modifier = Modifier.fillMaxWidth())
}

@Composable
fun LayeredBackgroundsScreen() {
    NativeDisplayView(config = BackgroundSamples.layeredBackgroundsSample(), modifier = Modifier.fillMaxWidth())
}

@Composable
fun EcommerceShowcaseScreen() {
    val context = LocalContext.current
    val config = remember { JsonLoader.loadFromAssets(context, "showcase_ecommerce_product.json") }
    if (config != null) NativeDisplayView(config = config, modifier = Modifier.fillMaxWidth())
    else ErrorMessage("Failed to load E-commerce showcase")
}

@Composable
fun SocialProfileShowcaseScreen() {
    val context = LocalContext.current
    val config = remember { JsonLoader.loadFromAssets(context, "showcase_social_profile.json") }
    if (config != null) NativeDisplayView(config = config, modifier = Modifier.fillMaxWidth())
    else ErrorMessage("Failed to load Social Profile showcase")
}

@Composable
fun DashboardShowcaseScreen() {
    val context = LocalContext.current
    val config = remember { JsonLoader.loadFromAssets(context, "showcase_dashboard.json") }
    if (config != null) NativeDisplayView(config = config, modifier = Modifier.fillMaxWidth())
    else ErrorMessage("Failed to load Dashboard showcase")
}

@Composable
fun GalleryShowcaseScreen() {
    val context = LocalContext.current
    val config = remember { JsonLoader.loadFromAssets(context, "gallery_three_modes.json") }
    if (config != null) NativeDisplayView(config = config, modifier = Modifier.fillMaxWidth())
    else ErrorMessage("Failed to load gallery showcase")
}

@Composable
fun ErrorMessage(message: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp)
            .background(Color(0xFFFFEBEE), shape = RoundedCornerShape(12.dp))
            .padding(24.dp)
    ) {
        Text(text = message, color = Color(0xFFC62828), style = MaterialTheme.typography.bodyMedium)
    }
}
