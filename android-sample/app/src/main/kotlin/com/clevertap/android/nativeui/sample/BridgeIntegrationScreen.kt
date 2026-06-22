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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridgeListener
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView

/**
 * Bridge Integration Demo Screen
 *
 * Demonstrates how clients integrate the NativeDisplayBridge to receive and render
 * Native Display units from the CleverTap Core SDK (or any JSON source).
 *
 * Since the sample app has no real Core SDK, this demo uses `processDisplayUnits()`
 * with mock JSON strings that wrap ResolvedConfig inside the display unit envelope.
 *
 * Demonstrates:
 * 1. Bridge initialization (create() for manual mode)
 * 2. Listener registration (NativeDisplayBridgeListener)
 * 3. Processing display units via processDisplayUnits()
 * 4. Rendering received NativeDisplayUnit configs
 * 5. Pull API: getAllNativeDisplays() and getNativeDisplayForId()
 */
@Composable
fun BridgeIntegrationScreen(
    viewModel: BridgeIntegrationViewModel = viewModel()
) {
    val context = LocalContext.current

    // --- Load mock JSON strings from assets ---
    // These files wrap a ResolvedConfig inside the Core SDK display unit envelope:
    //   { "wzrk_id": "...", "native_display_config": { ... }, "custom_kv": { ... } }
    val mockProductJson = remember {
        context.assets.open("bridge_mock_product.json").bufferedReader().readText()
    }
    val mockNotificationJson = remember {
        context.assets.open("bridge_mock_notification.json").bufferedReader().readText()
    }

    // --- Bridge state (survives rotation via ViewModel) ---
    // The bridge is held in the ViewModel so it is not recreated on rotation.
    val bridge = viewModel.bridge
    val receivedUnits by viewModel.receivedUnits.collectAsState()
    val logMessages by viewModel.logMessages.collectAsState()
    val listenerRegistered by viewModel.listenerRegistered.collectAsState()
    val dataProcessed by viewModel.dataProcessed.collectAsState()

    // Helper to append log messages
    fun log(message: String) {
        Log.d("BridgeDemo", message)
        viewModel.log(message)
    }

    // --- Step 1 & 2: Register listener ---
    // The listener receives parsed NativeDisplayUnit objects whenever
    // processDisplayUnits() or processDisplayUnit() is called on the bridge.
    val listener = remember {
        object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                // Called by the bridge after successfully parsing display unit JSON.
                // Each unit contains:
                //   - unitId: the wzrk_id from the payload
                //   - config: a ResolvedConfig ready for NativeDisplayView
                //   - customExtras: key-value pairs from custom_kv
                viewModel.onUnitsLoaded(units)
                viewModel.log("onNativeDisplaysLoaded: received ${units.size} unit(s)")
                for (unit in units) {
                    viewModel.log("  - ${unit.unitId} | extras: ${unit.customExtras}")
                }
            }
        }
    }

    // Re-register listener after rotation if already enabled (bridge survives in ViewModel,
    // but the listener object is recreated by remember on each Activity recreation).
    DisposableEffect(bridge, listenerRegistered) {
        if (listenerRegistered) {
            bridge.addListener(listener)
        }
        onDispose {
            bridge.removeListener(listener)
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
            text = "Bridge Integration Demo",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = "Demonstrates NativeDisplayBridge usage without a real Core SDK. " +
                "Mock JSON payloads simulate what the Core SDK would deliver.",
            style = MaterialTheme.typography.bodyMedium,
            color = Color(0xFF666666)
        )

        HorizontalDivider()

        // --- Step 1: Register Listener ---
        SectionCard(
            title = "Step 1: Register Listener",
            description = "Create the bridge in manual mode and register a NativeDisplayBridgeListener " +
                "to receive parsed display units.",
            codeSnippet = """val bridge = NativeDisplayBridge.create()
bridge.addListener(myListener)""",
            enabled = !listenerRegistered
        ) {
            Button(
                onClick = {
                    viewModel.markListenerRegistered()
                    log("Listener registered on bridge")
                },
                enabled = !listenerRegistered
            ) {
                Text(if (listenerRegistered) "Listener Registered" else "Register Listener")
            }
        }

        // --- Step 2: Process Display Units (simulates Core SDK callback) ---
        SectionCard(
            title = "Step 2: Process Display Units",
            description = "Feed mock JSON strings to the bridge via processDisplayUnits(). " +
                "In a real app, the Core SDK calls this automatically when display units arrive, " +
                "or you call it manually from your DisplayUnitListener.",
            codeSnippet = """// Option A: bind() — auto-wires to Core SDK
bridge.bind(CleverTapAPI.getDefaultInstance(ctx)!!)

// Option B: manual — you control the input
bridge.processDisplayUnits(jsonStrings)""",
            enabled = listenerRegistered && !dataProcessed
        ) {
            Button(
                onClick = {
                    // Simulate the Core SDK delivering display units.
                    // processDisplayUnits() replaces the entire cache and notifies listeners.
                    bridge.processDisplayUnits(listOf(mockProductJson, mockNotificationJson))
                    viewModel.markDataProcessed()
                },
                enabled = listenerRegistered && !dataProcessed
            ) {
                Text(if (dataProcessed) "Data Processed" else "Simulate Core SDK Response")
            }
        }

        // --- Step 3: Pull API ---
        AnimatedVisibility(
            visible = dataProcessed,
            enter = fadeIn() + expandVertically()
        ) {
            SectionCard(
                title = "Step 3: Pull API",
                description = "Retrieve cached units at any time without waiting for a callback.",
                codeSnippet = """val all = bridge.getAllNativeDisplays()
val unit = bridge.getNativeDisplayForId("demo_unit_product")"""
            ) {
                var pullResult by remember { mutableStateOf("") }

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = {
                            val all = bridge.getAllNativeDisplays()
                            pullResult = "getAllNativeDisplays() returned ${all.size} unit(s):\n" +
                                all.joinToString("\n") { "  - ${it.unitId}" }
                            log(pullResult)
                        }) {
                            Text("Get All", fontSize = 13.sp)
                        }
                        Button(onClick = {
                            val unit = bridge.getNativeDisplayForId("demo_unit_product")
                            pullResult = if (unit != null) {
                                "getNativeDisplayForId(\"demo_unit_product\") -> found! " +
                                    "Extras: ${unit.customExtras}"
                            } else {
                                "getNativeDisplayForId(\"demo_unit_product\") -> not found"
                            }
                            log(pullResult)
                        }) {
                            Text("Get By ID", fontSize = 13.sp)
                        }
                    }

                    if (pullResult.isNotEmpty()) {
                        Text(
                            text = pullResult,
                            style = MaterialTheme.typography.bodySmall,
                            fontFamily = FontFamily.Monospace,
                            color = Color(0xFF1B5E20),
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(
                                    Color(0xFFE8F5E9),
                                    shape = RoundedCornerShape(8.dp)
                                )
                                .padding(12.dp)
                        )
                    }
                }
            }
        }

        // --- Step 4: Rendered Units ---
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
                    text = "Each NativeDisplayUnit.config is a ResolvedConfig passed directly " +
                        "to NativeDisplayView for rendering.",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF666666)
                )

                // Render each received unit
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

                            // Render the unit's config using NativeDisplayView
                            NativeDisplayView(
                                config = unit.config,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                }
            }
        }

        // --- Log Output ---
        // Default to visible so humans see the log; tests can flip this via the toggle button.
        var logVisible by remember { mutableStateOf(true) }
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
                    IconButton(
                        onClick = { logVisible = !logVisible },
                        modifier = Modifier.testTag("event-log-toggle")
                    ) {
                        Icon(
                            imageVector = if (logVisible) Icons.Default.KeyboardArrowDown else Icons.Default.KeyboardArrowUp,
                            contentDescription = if (logVisible) "Hide event log" else "Show event log"
                        )
                    }
                }
                if (logVisible) {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("event-log-content"),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF263238)),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            for (msg in logMessages) {
                                Text(
                                    text = "> $msg",
                                    style = MaterialTheme.typography.bodySmall,
                                    fontFamily = FontFamily.Monospace,
                                    color = Color(0xFF80CBC4),
                                    lineHeight = 18.sp
                                )
                            }
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
 */
@Composable
private fun SectionCard(
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
