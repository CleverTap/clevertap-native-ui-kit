package com.clevertap.android.nativeui.sample

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.clevertap.android.sdk.CleverTapAPI
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * CleverTap Integration Screen
 *
 * Real integration with CleverTap Core SDK. No mock data.
 *
 * Flow:
 * 1. Gets CleverTapAPI default instance
 * 2. Initializes NativeDisplayBridge and binds to CleverTap
 * 3. Requests Native Display units from server via fetchNativeDisplays()
 * 4. Renders received units in a scrollable canvas
 * 5. Allows firing custom events to trigger server-side campaigns
 */
@Composable
fun CleverTapIntegrationScreen() {
    val context = LocalContext.current

    // --- State ---
    var statusText by remember { mutableStateOf("Initializing...") }
    var receivedUnits by remember { mutableStateOf<List<NativeDisplayUnit>>(emptyList()) }
    var logMessages by remember { mutableStateOf(listOf<String>()) }
    var eventName by remember { mutableStateOf("") }

    val timeFormat = remember { SimpleDateFormat("HH:mm:ss", Locale.US) }

    fun log(message: String) {
        val timestamp = timeFormat.format(Date())
        val entry = "[$timestamp] $message"
        Log.d("CleverTapIntegration", entry)
        logMessages = logMessages + entry
    }

    // --- Action Listener: logs system events and actions ---
    val actionListener = remember {
        object : NativeDisplayActionListener {
            override fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean {
                log("ACTION openUrl: $url")
                return true
            }

            override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
                log("ACTION custom: $key=$value")
            }

            override fun onNavigate(destination: String, params: Map<String, String>?) {
                log("ACTION navigate: $destination")
            }

            override fun onTrackEvent(eventName: String, properties: Map<String, Any?>?) {
                val propsStr = properties?.entries?.joinToString(", ") { "${it.key}=${it.value}" } ?: ""
                log("EVENT $eventName $propsStr")
            }

            override fun onActionError(action: Action, error: Throwable) {
                log("ERROR ${error.message}")
            }
        }
    }

    // --- Bridge Listener ---
    val bridgeListener = remember {
        object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                receivedUnits = units
                log("Received ${units.size} Native Display unit(s)")
                for (unit in units) {
                    log("  Unit: ${unit.unitId}")
                }
            }
        }
    }

    // --- Auto-initialize on screen load ---
    val cleverTapApi = remember {
        CleverTapAPI.getDefaultInstance(context.applicationContext)
    }

    val bridge = remember { NativeDisplayBridge.initialize(context.applicationContext) }

    DisposableEffect(bridge) {
        bridge.addListener(bridgeListener)

        if (cleverTapApi != null) {
            bridge.bind(cleverTapApi)
            bridge.fetchNativeDisplays(cleverTapApi)
            statusText = "Connected to CleverTap"
            Log.d("CleverTapIntegration", "Bridge bound and fetch requested")
        } else {
            statusText = "CleverTap not available (default instance is null)"
            Log.w("CleverTapIntegration", "CleverTapAPI.getDefaultInstance() returned null")
        }

        onDispose {
            bridge.removeListener(bridgeListener)
        }
    }

    // --- UI ---
    Column(modifier = Modifier.fillMaxSize()) {

        // -- Header area (non-scrollable) --
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Status
            Text(
                text = "CleverTap Integration",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = statusText,
                style = MaterialTheme.typography.bodyMedium,
                color = if (cleverTapApi != null) Color(0xFF2E7D32) else Color(0xFFD32F2F)
            )

            HorizontalDivider()

            // Fire Event Section
            Text(
                text = "Fire Event",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = eventName,
                    onValueChange = { eventName = it },
                    placeholder = { Text("Enter event name") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    textStyle = MaterialTheme.typography.bodyMedium
                )
                Button(
                    onClick = {
                        val name = eventName.trim()
                        if (name.isNotEmpty() && cleverTapApi != null) {
                            cleverTapApi.pushEvent(name)
                            log("Fired event: $name")
                            eventName = ""
                        }
                    },
                    enabled = eventName.isNotBlank() && cleverTapApi != null
                ) {
                    Text("Send Event")
                }
            }

            HorizontalDivider()

            Text(
                text = "Native Display Canvas",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
        }

        // -- Native Display Canvas (takes remaining space) --
        if (receivedUnits.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Waiting for Native Display response...",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFF999999)
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(receivedUnits, key = { it.unitId }) { unit ->
                    NativeDisplayView(
                        config = unit.config,
                        modifier = Modifier.fillMaxWidth(),
                        actionListener = actionListener
                    )
                }
            }
        }

        // -- Event Log (fixed at bottom) --
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 8.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            HorizontalDivider()
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Event Log",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                if (logMessages.isNotEmpty()) {
                    TextButton(onClick = { logMessages = emptyList() }) {
                        Text("Clear", fontSize = 12.sp)
                    }
                }
            }
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 80.dp, max = 160.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF263238)),
                shape = RoundedCornerShape(8.dp)
            ) {
                val logListState = rememberLazyListState()

                LaunchedEffect(logMessages.size) {
                    if (logMessages.isNotEmpty()) {
                        logListState.animateScrollToItem(logMessages.size - 1)
                    }
                }

                LazyColumn(
                    state = logListState,
                    modifier = Modifier.padding(10.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    if (logMessages.isEmpty()) {
                        item {
                            Text(
                                text = "No events yet",
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = FontFamily.Monospace,
                                color = Color(0xFF607D8B)
                            )
                        }
                    } else {
                        items(logMessages) { msg ->
                            Text(
                                text = msg,
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = FontFamily.Monospace,
                                color = when {
                                    "EVENT" in msg -> Color(0xFFFFD54F)
                                    "ACTION" in msg -> Color(0xFF81D4FA)
                                    "ERROR" in msg -> Color(0xFFEF9A9A)
                                    "Received" in msg -> Color(0xFFA5D6A7)
                                    else -> Color(0xFF80CBC4)
                                },
                                lineHeight = 16.sp
                            )
                        }
                    }
                }
            }
        }
    }
}
