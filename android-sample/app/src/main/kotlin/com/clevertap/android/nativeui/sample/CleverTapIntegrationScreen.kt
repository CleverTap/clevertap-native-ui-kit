package com.clevertap.android.nativeui.sample

import android.util.Log
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridgeListener
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.listener.InteractionType
import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * CleverTap Integration Demo Screen
 *
 * Demonstrates the EXPLICIT integration pattern where the client uses the CleverTap
 * Core SDK directly alongside the Native Display SDK.
 *
 * This screen shows:
 * 1. CleverTap setup and bridge binding code snippets
 * 2. Fetching and rendering Native Displays via the bridge with mock JSON
 * 3. System events (Notification Viewed, Notification Clicked) flowing through
 *    the NativeDisplayActionListener.onTrackEvent() callback
 * 4. A timestamped event log capturing all interactions
 *
 * In a real app, `bridge.bind(cleverTapApi)` would auto-wire the Core SDK.
 * Here we use `bridge.processDisplayUnits()` with mock JSON from assets.
 */
@Composable
fun CleverTapIntegrationScreen() {
    val context = LocalContext.current

    // --- Load mock JSON strings from assets ---
    val mockProductJson = remember {
        context.assets.open("bridge_mock_product.json").bufferedReader().readText()
    }
    val mockNotificationJson = remember {
        context.assets.open("bridge_mock_notification.json").bufferedReader().readText()
    }

    // --- State ---
    val bridge = remember { NativeDisplayBridge.create() }
    var receivedUnits by remember { mutableStateOf<List<NativeDisplayUnit>>(emptyList()) }
    var logMessages by remember { mutableStateOf(listOf<String>()) }
    var bridgeReady by remember { mutableStateOf(false) }
    var dataFetched by remember { mutableStateOf(false) }

    val timeFormat = remember { SimpleDateFormat("HH:mm:ss.SSS", Locale.US) }

    // Helper to append timestamped log messages
    fun log(message: String) {
        val timestamp = timeFormat.format(Date())
        val entry = "[$timestamp] $message"
        Log.d("CleverTapDemo", entry)
        logMessages = logMessages + entry
    }

    // --- Action Listener: receives system events and custom actions ---
    // In a real CleverTap integration, onTrackEvent() receives system events like
    // "Notification Viewed" and "Notification Clicked" that should be forwarded
    // to CleverTap for analytics tracking.
    val actionListener = remember {
        object : NativeDisplayActionListener {
            override fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean {
                log("ACTION onOpenUrl: $url (browser=$openInBrowser)")
                return true // consumed
            }

            override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
                log("ACTION onCustomAction: key=$key value=$value")
            }

            override fun onNavigate(destination: String, params: Map<String, String>?) {
                log("ACTION onNavigate: $destination params=$params")
            }

            override fun onTrackEvent(eventName: String, properties: Map<String, Any?>?) {
                // This is where system events flow through.
                // In a real app, you would forward these to CleverTap:
                //   cleverTapApi.pushEvent(eventName, properties)
                val propsStr = properties?.entries?.joinToString(", ") { "${it.key}=${it.value}" } ?: "none"
                log("EVENT $eventName | props: $propsStr")
            }

            override fun onActionError(action: Action, error: Throwable) {
                log("ERROR action failed: ${error.message}")
            }
        }
    }

    // --- Component Listener: logs all component interactions ---
    val componentListener = remember {
        object : NativeDisplayComponentListener {
            override fun getInterestedNodeIds(): Set<String>? = null // listen to all

            override fun onComponentInteraction(
                nodeId: String,
                interactionType: InteractionType,
                hasServerAction: Boolean
            ): Boolean {
                log("INTERACTION $nodeId | type=$interactionType | hasAction=$hasServerAction")
                return false // don't consume, let server actions proceed
            }
        }
    }

    // --- Bridge Listener: receives parsed display units ---
    val bridgeListener = remember {
        object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                receivedUnits = units
                log("Bridge delivered ${units.size} unit(s)")
                for (unit in units) {
                    log("  Unit: ${unit.unitId} | extras: ${unit.customExtras}")
                }
            }
        }
    }

    // Clean up bridge on dispose
    DisposableEffect(bridge) {
        onDispose {
            bridge.removeListener(bridgeListener)
            bridge.clear()
        }
    }

    // --- UI ---
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Title
        Text(
            text = "CleverTap Integration Demo",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = "Demonstrates the explicit integration pattern: CleverTap Core SDK " +
                "provides display units, the Native Display SDK renders them, and system " +
                "events (Notification Viewed/Clicked) flow back through onTrackEvent().",
            style = MaterialTheme.typography.bodyMedium,
            color = Color(0xFF666666)
        )

        HorizontalDivider()

        // --- Section 1: CleverTap Setup ---
        CTSectionCard(
            title = "1. CleverTap Setup",
            description = "Initialize CleverTap, create the bridge, and bind them together. " +
                "The bind() call auto-wires the Core SDK's DisplayUnitListener to the bridge.",
            codeSnippet = """// In Application.onCreate()
val cleverTap = CleverTapAPI.getDefaultInstance(this)!!
val bridge = NativeDisplayBridge.initialize(this)

// Bind bridge to CleverTap instance
bridge.bind(cleverTap)

// Register your listener
bridge.addListener(myBridgeListener)""",
            enabled = !bridgeReady
        ) {
            Button(
                onClick = {
                    bridge.addListener(bridgeListener)
                    bridgeReady = true
                    log("Bridge created and listener registered")
                    log("In production: bridge.bind(cleverTapApi) auto-wires the Core SDK")
                },
                enabled = !bridgeReady
            ) {
                Text(if (bridgeReady) "Bridge Ready" else "Setup Bridge")
            }
        }

        // --- Section 2: Fetch & Render ---
        CTSectionCard(
            title = "2. Fetch & Render Display Units",
            description = "In production, display units arrive automatically after bind(). " +
                "You can also request a server fetch. Here we simulate with mock JSON.",
            codeSnippet = """// Option A: Units arrive automatically via bind()
// Option B: Explicit fetch from server
bridge.fetchNativeDisplays(cleverTapApi)

// Option C: Manual feed (used in this demo)
bridge.processDisplayUnits(jsonStrings)""",
            enabled = bridgeReady && !dataFetched
        ) {
            Button(
                onClick = {
                    log("Simulating server fetch with mock display units...")
                    bridge.processDisplayUnits(listOf(mockProductJson, mockNotificationJson))
                    dataFetched = true
                },
                enabled = bridgeReady && !dataFetched
            ) {
                Text(if (dataFetched) "Units Loaded" else "Fetch Display Units")
            }
        }

        // --- Section 3: System Events ---
        CTSectionCard(
            title = "3. System Events via onTrackEvent()",
            description = "The NativeDisplayActionListener receives system events like " +
                "\"Notification Viewed\" and \"Notification Clicked\". In production, forward " +
                "these to CleverTap for analytics. Tap the rendered units below to see events " +
                "appear in the log.",
            codeSnippet = """override fun onTrackEvent(
    eventName: String,
    properties: Map<String, Any?>?
) {
    // Forward system events to CleverTap
    cleverTapApi.pushEvent(eventName, properties)
    // e.g. "Notification Viewed", "Notification Clicked"
}"""
        )

        // --- Rendered Display Units ---
        AnimatedVisibility(
            visible = receivedUnits.isNotEmpty(),
            enter = fadeIn() + expandVertically()
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                HorizontalDivider()
                Text(
                    text = "Rendered Display Units",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Each unit is rendered with both an actionListener (for system events) " +
                        "and a componentListener (for interaction tracking). Tap on components " +
                        "to see events in the log below.",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF666666)
                )

                // Render each received unit with both listeners
                for (unit in receivedUnits) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            // Unit metadata header
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Unit: ${unit.unitId}",
                                    style = MaterialTheme.typography.labelLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                if (unit.customExtras.isNotEmpty()) {
                                    Text(
                                        text = unit.customExtras.entries.joinToString(", ") {
                                            "${it.key}=${it.value}"
                                        },
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color(0xFF999999)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            // Render with actionListener and componentListener
                            NativeDisplayView(
                                config = unit.config,
                                modifier = Modifier.fillMaxWidth(),
                                actionListener = actionListener,
                                componentListener = componentListener
                            )
                        }
                    }
                }
            }
        }

        // --- Section 4: Event Log ---
        AnimatedVisibility(
            visible = logMessages.isNotEmpty(),
            enter = fadeIn() + expandVertically()
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                HorizontalDivider()
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Event Log",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    TextButton(onClick = { logMessages = emptyList() }) {
                        Text("Clear", fontSize = 12.sp)
                    }
                }
                Text(
                    text = "System events, custom actions, and component interactions " +
                        "are logged here with timestamps.",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF666666)
                )
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF263238)),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        for (msg in logMessages) {
                            Text(
                                text = "> $msg",
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = FontFamily.Monospace,
                                color = when {
                                    "EVENT" in msg -> Color(0xFFFFD54F) // yellow for system events
                                    "ACTION" in msg -> Color(0xFF81D4FA) // blue for actions
                                    "INTERACTION" in msg -> Color(0xFFA5D6A7) // green for interactions
                                    "ERROR" in msg -> Color(0xFFEF9A9A) // red for errors
                                    else -> Color(0xFF80CBC4) // teal for general log
                                },
                                lineHeight = 18.sp
                            )
                        }
                    }
                }
            }
        }

        // Bottom spacing
        Spacer(modifier = Modifier.height(32.dp))
    }
}

/**
 * Reusable card for each demo section with a title, description, code snippet, and action.
 * Local to this screen to avoid coupling with BridgeIntegrationScreen's private SectionCard.
 */
@Composable
private fun CTSectionCard(
    title: String,
    description: String,
    codeSnippet: String,
    enabled: Boolean = true,
    action: @Composable () -> Unit = {}
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (enabled) Color.White else Color(0xFFF5F5F5)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = if (enabled) 2.dp else 0.dp),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = if (enabled) MaterialTheme.colorScheme.primary else Color(0xFF999999)
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = if (enabled) Color(0xFF444444) else Color(0xFF999999)
            )
            // Code snippet
            Text(
                text = codeSnippet,
                style = MaterialTheme.typography.bodySmall,
                fontFamily = FontFamily.Monospace,
                color = if (enabled) Color(0xFF1565C0) else Color(0xFFBBBBBB),
                lineHeight = 18.sp,
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        if (enabled) Color(0xFFE3F2FD) else Color(0xFFEEEEEE),
                        shape = RoundedCornerShape(8.dp)
                    )
                    .padding(12.dp)
            )
            action()
        }
    }
}
