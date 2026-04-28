package com.clevertap.android.nativeui.sample

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
<<<<<<< HEAD
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
=======
import androidx.compose.foundation.layout.*
>>>>>>> origin/task/SDK-5399_ios
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
<<<<<<< HEAD
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
=======
import androidx.compose.material.icons.filled.MoreVert
>>>>>>> origin/task/SDK-5399_ios
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
<<<<<<< HEAD
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
=======
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
>>>>>>> origin/task/SDK-5399_ios
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
import com.clevertap.android.nativedisplay.samples.*

<<<<<<< HEAD
class MainActivity : FragmentActivity() {
=======
class MainActivity : ComponentActivity() {
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD

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
=======
        var showMenu by remember { mutableStateOf(false) }

        NavHost(
            navController = navController,
            startDestination = "banner_showcase"
        ) {
            // Main Screen: Banner Showcase
            composable("banner_showcase") {
                Scaffold(
                    topBar = {
                        TopAppBar(
                            title = {
                                Text(
                                    "Native Display Kit",
                                    style = MaterialTheme.typography.titleLarge
                                )
                            },
                            actions = {
                                // Menu Button (3 dots)
                                IconButton(onClick = { showMenu = true }) {
                                    Icon(
                                        imageVector = Icons.Default.MoreVert,
                                        contentDescription = "Menu",
                                        tint = MaterialTheme.colorScheme.onPrimary
                                    )
                                }

                                // Dropdown Menu
                                DropdownMenu(
                                    expanded = showMenu,
                                    onDismissRequest = { showMenu = false }
                                ) {
                                    DropdownMenuItem(
                                        text = { Text("🏠 Home") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/home")
                                        }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("📏 Arrangements") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/arrangements")
                                        }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("🎬 Animations") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/animations")
                                        }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("🧪 Test Browser") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/test_browser")
                                        }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("🔗 Bridge Integration") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/bridge")
                                        }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("📡 CleverTap Integration") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/clevertap")
                                        }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("\uD83D\uDCCC Slot Demo") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/slots")
                                        }
                                    )
                                    DropdownMenuItem(
                                        text = { Text("🔤 Font Customization") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/fonts")
                                        }
                                    )
                                    HorizontalDivider()
                                    DropdownMenuItem(
                                        text = { Text("Other Demos") },
                                        onClick = {
                                            showMenu = false
                                            navController.navigate("demo_screen/other")
                                        }
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
                    Box(modifier = Modifier.padding(paddingValues)) {
                        BannerShowcaseScreen(navController = navController)
>>>>>>> origin/task/SDK-5399_ios
                    }
                }
            }

<<<<<<< HEAD
            // Banner Detail Screen (navigated from Banners in More tab)
=======
            // Banner Detail Screen
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
                val jsonString = remember { JSONViewerStorage.getJsonString() }
                JSONViewerScreen(navController = navController, jsonString = jsonString)
            }

            // Demo Screens (accessed via More tab)
=======
                // Use remember to prevent the value from being cleared on recomposition
                val jsonString = remember {
                    JSONViewerStorage.getJsonString()
                }
                JSONViewerScreen(
                    navController = navController,
                    jsonString = jsonString
                )
            }

            // Demo Screens (accessed via menu)
>>>>>>> origin/task/SDK-5399_ios
            composable(
                route = "demo_screen/{demoType}",
                arguments = listOf(navArgument("demoType") { type = NavType.StringType })
            ) { backStackEntry ->
                val demoType = backStackEntry.arguments?.getString("demoType") ?: "home"
<<<<<<< HEAD
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
=======
                DemoScreenContainer(
                    navController = navController,
                    demoType = demoType
                )
            }
>>>>>>> origin/task/SDK-5399_ios
        }
    }
}

/**
<<<<<<< HEAD
 * Container for demo screens accessed via More tab — keeps TopAppBar + back
=======
 * Container for demo screens accessed via menu
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
                            "slots" -> "🎰 Slot Demo"
                            "fonts" -> "🔤 Font Customization"
                            "banners" -> "🖼️ Banner Showcase"
=======
                            "slots" -> "\uD83D\uDCCC Slot Demo"
                            "fonts" -> "🔤 Font Customization"
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
                    if (demoType == "home" || demoType == "test_browser" || demoType == "bridge" ||
                        demoType == "clevertap" || demoType == "slots" || demoType == "fonts" ||
                        demoType == "banners"
                    ) {
=======
                    // No vertical scroll for Home screen and Test Browser
                    if (demoType == "home" || demoType == "test_browser" || demoType == "bridge" || demoType == "clevertap" || demoType == "slots" || demoType == "fonts") {
>>>>>>> origin/task/SDK-5399_ios
                        Modifier
                    } else {
                        Modifier.verticalScroll(rememberScrollState())
                    }
                )
                .padding(
<<<<<<< HEAD
                    if (demoType == "home" || demoType == "test_browser" || demoType == "bridge" ||
                        demoType == "clevertap" || demoType == "slots" || demoType == "fonts" ||
                        demoType == "banners"
                    ) 0.dp else 16.dp
=======
                    // No padding for Home screen and Test Browser to allow edge-to-edge design
                    if (demoType == "home" || demoType == "test_browser" || demoType == "bridge" || demoType == "clevertap" || demoType == "slots" || demoType == "fonts") 0.dp else 16.dp
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
                "banners" -> BannerShowcaseScreen(navController = navController)
=======
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
=======
        // Tabs
>>>>>>> origin/task/SDK-5399_ios
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

<<<<<<< HEAD
=======
        // Content
>>>>>>> origin/task/SDK-5399_ios
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

<<<<<<< HEAD
=======
/**
 * Tab 0: Home Screen (NEW)
 * Modern e-commerce home page with:
 * - Auto-scrolling banner carousel
 * - Full-screen promotional banner
 * - Product grid with cards
 * - Category tags
 * - Quick actions
 */
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
=======
                // Listen to ALL components by returning null
>>>>>>> origin/task/SDK-5399_ios
                override fun getInterestedNodeIds(): Set<String>? = null

                override fun onComponentInteraction(
                    nodeId: String,
                    interactionType: com.clevertap.android.nativedisplay.listener.InteractionType,
                    hasServerAction: Boolean
                ): Boolean {
<<<<<<< HEAD
=======
                    // Log every interaction
>>>>>>> origin/task/SDK-5399_ios
                    Log.d(
                        "HomeScreen_Click",
                        "Component: $nodeId | Type: $interactionType | HasServerAction: $hasServerAction"
                    )
<<<<<<< HEAD
=======

                    // Don't consume, let server actions proceed
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
    val initialConfig = remember { JsonLoader.loadFromAssets(context, "arrangement_demo.json") }
    var currentConfig: ResolvedConfig? by remember(initialConfig) { mutableStateOf(initialConfig) }

=======

    // 1. Initial configuration state loaded from JSON
    val initialConfig = remember {
        JsonLoader.loadFromAssets(context, "arrangement_demo.json")
    }

    // 2. State for the current configuration to allow dynamic updates
    var currentConfig: ResolvedConfig? by remember(initialConfig) { mutableStateOf(initialConfig) }

    // 3. Define the available strategies based on your ChildArrangement model
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
=======
        // 4. Horizontal Picker
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
=======
                        // 5. Logic to update the configuration deep inside the root
>>>>>>> origin/task/SDK-5399_ios
                        currentConfig = currentConfig?.let { config ->
                            updateRootArrangement(config, arrangement)
                        }
                    },
                    label = { Text(name) }
                )
            }
        }

<<<<<<< HEAD
        if (currentConfig != null) {
            NativeDisplayView(config = currentConfig!!, modifier = Modifier.fillMaxWidth())
=======
        // 6. Display View
        if (currentConfig != null) {
            NativeDisplayView(
                config = currentConfig!!,
                modifier = Modifier
                    .fillMaxWidth()
            )
>>>>>>> origin/task/SDK-5399_ios
        } else {
            ErrorMessage("Loading Arrangement Demo...")
        }
    }
}

<<<<<<< HEAD
=======
/**
 * Helper to update the arrangement strategy in your root container.
 * This assumes your root is a NativeDisplayContainer.
 */
>>>>>>> origin/task/SDK-5399_ios
private fun updateRootArrangement(
    config: ResolvedConfig,
    newArrangement: ChildArrangement
): ResolvedConfig {
    val root = config.root
    if (root is NativeDisplayContainer) {
<<<<<<< HEAD
        val updatedRoot = root.copy(layout = root.layout?.copy(arrangement = newArrangement))
=======
        val updatedRoot = root.copy(
            layout = root.layout?.copy(arrangement = newArrangement)
        )
>>>>>>> origin/task/SDK-5399_ios
        return config.copy(root = updatedRoot)
    }
    return config
}

<<<<<<< HEAD
@Composable
fun AnimationDemoScreen() {
    val context = LocalContext.current
=======
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
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
=======
        // Demo Selector
>>>>>>> origin/task/SDK-5399_ios
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

<<<<<<< HEAD
=======
        // Info Card
>>>>>>> origin/task/SDK-5399_ios
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
<<<<<<< HEAD
            colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF3E0))
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = when (selectedDemo) {
                        0 -> "💡 Entire container fades in (500ms). All children appear together."
                        1 -> "💡 Each child slides in from left with 100ms stagger delay."
                        2 -> "💡 Container fades in first, then children animate in sequence."
=======
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
>>>>>>> origin/task/SDK-5399_ios
                        else -> ""
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFFE65100)
                )
            }
        }

<<<<<<< HEAD
        if (currentConfig != null) {
            NativeDisplayView(config = currentConfig, modifier = Modifier.fillMaxWidth())
=======
        // Animation Demo View
        if (currentConfig != null) {
            NativeDisplayView(
                config = currentConfig,
                modifier = Modifier.fillMaxWidth()
            )
>>>>>>> origin/task/SDK-5399_ios
        } else {
            ErrorMessage("Failed to load ${demos[selectedDemo].second}")
        }
    }
}

<<<<<<< HEAD
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

=======
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
>>>>>>> origin/task/SDK-5399_ios
@Composable
fun ErrorMessage(message: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp)
<<<<<<< HEAD
            .background(Color(0xFFFFEBEE), shape = RoundedCornerShape(12.dp))
            .padding(24.dp)
    ) {
        Text(text = message, color = Color(0xFFC62828), style = MaterialTheme.typography.bodyMedium)
=======
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
>>>>>>> origin/task/SDK-5399_ios
    }
}
