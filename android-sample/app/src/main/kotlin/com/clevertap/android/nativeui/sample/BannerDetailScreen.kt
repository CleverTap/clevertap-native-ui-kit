package com.clevertap.android.nativeui.sample

import android.util.Log
import java.util.concurrent.atomic.AtomicReference
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Build
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.clevertap.android.nativedisplay.listener.InteractionType
import kotlinx.coroutines.launch
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import java.text.SimpleDateFormat
import java.util.*

/**
 * Singleton to temporarily store JSON string for JSON viewer navigation
 */
object JSONViewerStorage {
    private val jsonString = AtomicReference<String?>(null)

    fun setJsonString(json: String) {
        jsonString.set(json)
    }

    fun getJsonString(): String? {
        return jsonString.getAndSet(null) // Get and clear
    }
}

/**
 * Data class representing an interaction log entry
 */
data class InteractionLog(
    val timestamp: Long,
    val nodeId: String?,
    val interactionType: InteractionType?,
    val actionData: String
) {
    val formattedTime: String
        get() {
            val sdf = SimpleDateFormat("HH:mm:ss.SSS", Locale.getDefault())
            return sdf.format(Date(timestamp))
        }

    val interactionTypeString: String
        get() = interactionType?.name ?: "ACTION"

    val isActionExecution: Boolean
        get() = nodeId == null
}

/**
 * BannerDetailScreen - Displays a banner with 70/30 split layout
 *
 * Features:
 * - Top 70%: NativeDisplayView showing the banner (scrollable)
 * - Bottom 30%: Interaction log view (scrollable LazyColumn)
 * - TopAppBar with back button
 * - Logs ALL component interactions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BannerDetailScreen(
    navController: NavController,
    bannerId: String,
    filename: String?
) {
    val context = LocalContext.current

    // State for interaction logs
    var interactionLogs by remember { mutableStateOf<List<InteractionLog>>(emptyList()) }
    val logsListState = rememberLazyListState()

    // Auto-scroll to bottom when new logs are added
    LaunchedEffect(interactionLogs.size) {
        if (interactionLogs.isNotEmpty()) {
            logsListState.animateScrollToItem(interactionLogs.size - 1)
        }
    }

    // Load banner configuration and JSON string
    val configData: Pair<ResolvedConfig?, String?> = remember(bannerId, filename) {
        if (filename == "custom") {
            // Load from custom storage
            val config = CustomBannerStorage.getConfig()
            val jsonString = CustomBannerStorage.getJsonString()
            Pair(config, jsonString)
        } else if (filename != null) {
            try {
                // Load config
                val config = JsonLoader.loadFromAssets(context, filename)

                // Load JSON string
                val jsonString = try {
                    context.assets.open(filename).bufferedReader().use { it.readText() }
                } catch (e: Exception) {
                    Log.e("BannerDetailScreen", "Failed to load JSON string: $filename", e)
                    null
                }

                Pair(config, jsonString)
            } catch (e: Exception) {
                Log.e("BannerDetailScreen", "Failed to load banner: $filename", e)
                Pair(null, null)
            }
        } else {
            Pair(null, null)
        }
    }

    val config = configData.first
    val jsonString = configData.second

    // Component listener that logs ALL interactions
    val componentListener = remember {
        object : NativeDisplayComponentListener {
            // Return null to listen to ALL components
            override fun getInterestedNodeIds(): Set<String>? = null

            override fun onComponentInteraction(
                nodeId: String,
                interactionType: InteractionType,
                hasServerAction: Boolean
            ): Boolean {
                // Create log entry
                val actionText = if (hasServerAction) "Has Server Action" else "No Server Action"
                val logEntry = InteractionLog(
                    timestamp = System.currentTimeMillis(),
                    nodeId = nodeId,
                    interactionType = interactionType,
                    actionData = actionText
                )

                // Add to logs
                interactionLogs = interactionLogs + logEntry

                // Log to console
                Log.d(
                    "BannerDetailScreen",
                    "Interaction: nodeId=$nodeId, type=$interactionType, hasServerAction=$hasServerAction"
                )

                // Auto-scroll to bottom will be handled in LaunchedEffect

                // Don't consume the event, let server actions proceed
                return false
            }
        }
    }

    // Action listener that logs ALL action executions
    val actionListener = remember {
        object : com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener {
            override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
                val actionData = "Custom Action: $key\nValue: $value"
                val logEntry = InteractionLog(
                    timestamp = System.currentTimeMillis(),
                    nodeId = null,
                    interactionType = null,
                    actionData = actionData
                )
                interactionLogs = interactionLogs + logEntry
                Log.d("BannerDetailScreen", "📱 Custom Action: key=$key, value=$value")
            }

            override fun onNavigate(destination: String, params: Map<String, String>?) {
                val actionData = "Navigate: $destination\nParams: $params"
                val logEntry = InteractionLog(
                    timestamp = System.currentTimeMillis(),
                    nodeId = null,
                    interactionType = null,
                    actionData = actionData
                )
                interactionLogs = interactionLogs + logEntry
                Log.d("BannerDetailScreen", "📱 Navigate: destination=$destination, params=$params")
            }

            override fun onTrackEvent(eventName: String, properties: Map<String, Any?>?) {
                val actionData = "Track Event: $eventName\nProperties: $properties"
                val logEntry = InteractionLog(
                    timestamp = System.currentTimeMillis(),
                    nodeId = null,
                    interactionType = null,
                    actionData = actionData
                )
                interactionLogs = interactionLogs + logEntry
                Log.d("BannerDetailScreen", "📱 Track Event: event=$eventName, properties=$properties")
            }

            override fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean {
                val actionData = "Open URL: $url\nIn Browser: $openInBrowser"
                val logEntry = InteractionLog(
                    timestamp = System.currentTimeMillis(),
                    nodeId = null,
                    interactionType = null,
                    actionData = actionData
                )
                interactionLogs = interactionLogs + logEntry
                Log.d("BannerDetailScreen", "📱 Open URL: url=$url, openInBrowser=$openInBrowser")
                return false // Use default behavior
            }

            override fun onActionError(action: com.clevertap.android.nativedisplay.models.Action, error: Throwable) {
                val actionData = "Action Error: ${error.message}\nAction: $action"
                val logEntry = InteractionLog(
                    timestamp = System.currentTimeMillis(),
                    nodeId = null,
                    interactionType = null,
                    actionData = actionData
                )
                interactionLogs = interactionLogs + logEntry
                Log.e("BannerDetailScreen", "❌ Action Error: ${error.message}")
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Banner Detail",
                            style = MaterialTheme.typography.titleMedium
                        )
                        if (config != null) {
                            Text(
                                text = "Banner ID: $bannerId",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                            )
                        }
                    }
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
                actions = {
                    // View JSON button
                    IconButton(
                        onClick = {
                            if (jsonString != null) {
                                // Navigate to JSON viewer - need to encode the JSON string
                                // For simplicity, we'll use a shared singleton
                                JSONViewerStorage.setJsonString(jsonString)
                                navController.navigate("json_viewer")
                            }
                        },
                        enabled = jsonString != null
                    ) {
                        Icon(
                            imageVector = Icons.Default.Build,
                            contentDescription = "View JSON",
                            tint = if (jsonString != null) {
                                MaterialTheme.colorScheme.onPrimary
                            } else {
                                MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.3f)
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
        if (config != null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .background(Color(0xFFF5F5F5))
            ) {
                // Top 70%: Banner View (Scrollable)
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(0.7f)
                        .background(Color.White)
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    NativeDisplayView(
                        config = config,
                        modifier = Modifier.fillMaxWidth(),
                        actionListener = actionListener,
                        componentListener = componentListener
                    )
                }

                // Divider
                HorizontalDivider(
                    thickness = 2.dp,
                    color = Color(0xFFE0E0E0)
                )

                // Bottom 30%: Interaction Log
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(0.3f)
                        .background(Color(0xFFFAFAFA))
                ) {
                    // Log Header
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        color = Color(0xFFEEEEEE),
                        shadowElevation = 2.dp
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Interaction Logs",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF333333)
                            )
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = if (interactionLogs.isEmpty()) Color(0xFFE0E0E0) else MaterialTheme.colorScheme.primary
                            ) {
                                Text(
                                    text = "${interactionLogs.size}",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = if (interactionLogs.isEmpty()) Color(0xFF666666) else MaterialTheme.colorScheme.onPrimary,
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                )
                            }
                        }
                    }

                    // Log List
                    if (interactionLogs.isEmpty()) {
                        // Empty state
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(24.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = "👆",
                                    fontSize = 32.sp
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = "Tap on banner elements",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color(0xFF999999)
                                )
                                Text(
                                    text = "to see interactions here",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color(0xFF999999)
                                )
                            }
                        }
                    } else {
                        LazyColumn(
                            state = logsListState,
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(8.dp),
                            verticalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            items(interactionLogs) { log ->
                                InteractionLogItem(log = log)
                            }
                        }
                    }
                }
            }
        } else {
            // Error state
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .background(Color(0xFFF5F5F5)),
                contentAlignment = Alignment.Center
            ) {
                ErrorMessage("Failed to load banner: $filename")
            }
        }
    }
}

/**
 * Individual interaction log item
 */
@Composable
private fun InteractionLogItem(log: InteractionLog) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = Color.White
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        shape = RoundedCornerShape(8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f)
            ) {
                // Header with type
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Interaction/Action Type Badge
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = if (log.isActionExecution) {
                            Color(0xFF4CAF50) // Green for actions
                        } else {
                            when (log.interactionType) {
                                InteractionType.CLICK -> Color(0xFF2196F3)
                                InteractionType.LONG_PRESS -> Color(0xFFFF9800)
                                InteractionType.DOUBLE_TAP -> Color(0xFF9C27B0)
                                else -> Color(0xFF666666)
                            }
                        }
                    ) {
                        Text(
                            text = log.interactionTypeString,
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.White,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    // Action Executed Badge
                    if (log.isActionExecution) {
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = Color(0xFF00C853)
                        ) {
                            Text(
                                text = "EXECUTED",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color.White,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Node ID (if present)
                log.nodeId?.let { nodeId ->
                    Text(
                        text = "Node: $nodeId",
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF333333)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                }

                // Action data
                Text(
                    text = log.actionData,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF666666),
                    maxLines = 3
                )

                Spacer(modifier = Modifier.height(4.dp))

                // Timestamp
                Text(
                    text = log.formattedTime,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF999999)
                )
            }

            // Interaction Icon
            Text(
                text = if (log.isActionExecution) {
                    "⚡"
                } else {
                    when (log.interactionType) {
                        InteractionType.CLICK -> "👆"
                        InteractionType.LONG_PRESS -> "⏱️"
                        InteractionType.DOUBLE_TAP -> "👆👆"
                        else -> "❓"
                    }
                },
                fontSize = 20.sp
            )
        }
    }
}
