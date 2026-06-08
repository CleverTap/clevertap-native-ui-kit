package com.clevertap.android.nativeui.sample

import android.net.Uri
import java.util.concurrent.atomic.AtomicReference
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import kotlinx.serialization.json.Json
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Data class representing a banner item in the showcase
 */
data class BannerItem(
    val id: String,
    val emoji: String,
    val title: String,
    val description: String,
    val filename: String
)

/**
 * Singleton to temporarily store custom JSON config and source
 */
object CustomBannerStorage {
    private val customConfig = AtomicReference<ResolvedConfig?>(null)
    private val customJsonString = AtomicReference<String?>(null)

    fun setConfig(config: ResolvedConfig, jsonString: String) {
        customConfig.set(config)
        customJsonString.set(jsonString)
    }

    fun getConfig(): ResolvedConfig? {
        return customConfig.getAndSet(null) // Get and clear
    }

    fun getJsonString(): String? {
        return customJsonString.getAndSet(null) // Get and clear
    }
}

/**
 * BannerShowcaseScreen - Main screen displaying a list of pre-defined banners
 * with an "Upload Custom JSON" option at the top.
 *
 * Features:
 * - Upload Custom JSON card at the top with file picker
 * - List of 10 pre-defined banners
 * - Navigation to BannerDetailScreen on tap
 * - JSON validation for uploaded files
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BannerShowcaseScreen(onNavigateToBannerDetail: (bannerId: String, filename: String?) -> Unit) {
    val context = LocalContext.current

    // List of pre-defined banners (matching iOS implementation)
    val banners = remember {
        listOf(
            BannerItem(
                id = "banner-01",
                emoji = "🌞",
                title = "Summer Sale",
                description = "Hero banner with gradient",
                filename = "banners/banner-01-hero-summer-sale.json"
            ),
            BannerItem(
                id = "banner-02",
                emoji = "📱",
                title = "iPhone 15 Pro",
                description = "Product showcase",
                filename = "banners/banner-02-product-iphone.json"
            ),
            BannerItem(
                id = "banner-03",
                emoji = "🎉",
                title = "New Features",
                description = "App update announcement",
                filename = "banners/banner-03-announcement-update.json"
            ),
            BannerItem(
                id = "banner-04",
                emoji = "✈️",
                title = "Travel Deals",
                description = "Multi-button travel banner",
                filename = "banners/banner-04-travel-deals.json"
            ),
            BannerItem(
                id = "banner-05",
                emoji = "👗",
                title = "Fashion Collection",
                description = "Image banner",
                filename = "banners/banner-05-fashion-collection.json"
            ),
            BannerItem(
                id = "banner-06",
                emoji = "💳",
                title = "Cashback Offer",
                description = "Credit card with GIF",
                filename = "banners/banner-06-credit-card-offer.json"
            ),
            BannerItem(
                id = "banner-07",
                emoji = "⭐",
                title = "App Rating",
                description = "Social proof",
                filename = "banners/banner-07-app-rating.json"
            ),
            BannerItem(
                id = "banner-08",
                emoji = "⚡",
                title = "Flash Sale",
                description = "Urgency banner",
                filename = "banners/banner-08-flash-sale.json"
            ),
            BannerItem(
                id = "banner-09",
                emoji = "💎",
                title = "Go Premium",
                description = "Typography showcase",
                filename = "banners/banner-09-premium-subscription.json"
            ),
            BannerItem(
                id = "banner-10",
                emoji = "👋",
                title = "Welcome",
                description = "Onboarding banner",
                filename = "banners/banner-10-welcome-onboarding.json"
            )
        )
    }

    // State for error messages
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }

    // File picker launcher for custom JSON upload
    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        if (uri != null) {
            try {
                // Read and validate JSON
                val jsonString = context.contentResolver.openInputStream(uri)?.use { inputStream ->
                    BufferedReader(InputStreamReader(inputStream)).use { it.readText() }
                }

                if (jsonString != null) {
                    // Validate JSON structure
                    val config = validateAndParseJson(jsonString)
                    if (config != null) {
                        // Store config and JSON string in singleton
                        CustomBannerStorage.setConfig(config, jsonString)
                        // Navigate to detail screen
                        onNavigateToBannerDetail("custom", "custom")
                    } else {
                        errorMessage = "Invalid JSON: Unable to parse configuration"
                    }
                } else {
                    errorMessage = "Failed to read file"
                }
            } catch (e: Exception) {
                errorMessage = "Error reading file: ${e.message}"
            }
        }
    }

    // Show error snackbar when error occurs
    LaunchedEffect(errorMessage) {
        errorMessage?.let { message ->
            snackbarHostState.showSnackbar(
                message = message,
                duration = SnackbarDuration.Short
            )
            errorMessage = null
        }
    }

    Box {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF5F5F5)),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Upload Custom JSON Card
            item {
                UploadCustomJsonCard(
                    onClick = {
                        filePickerLauncher.launch(arrayOf("application/json", "text/plain"))
                    }
                )
            }

            // Section Header
            item {
                Text(
                    text = "Pre-defined Banners",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF333333),
                    modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
                )
            }

            // Banner List
            items(banners) { banner ->
                BannerListItem(
                    banner = banner,
                    onClick = {
                        onNavigateToBannerDetail(banner.id, banner.filename)
                    }
                )
            }
        }

        // Snackbar at the bottom
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(16.dp)
        )
    }
}

/**
 * Upload Custom JSON Card - Displays at the top of the list
 */
@Composable
fun UploadCustomJsonCard(onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                // Icon
                Surface(
                    modifier = Modifier.size(56.dp),
                    shape = RoundedCornerShape(28.dp),
                    color = MaterialTheme.colorScheme.primary
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Upload",
                            tint = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.width(16.dp))

                // Text
                Column {
                    Text(
                        text = "Upload Custom JSON",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Test your own banner configuration",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                    )
                }
            }

            // Chevron
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = "Navigate",
                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

/**
 * Banner List Item - Individual banner card in the list
 */
@Composable
fun BannerListItem(
    banner: BannerItem,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = Color.White
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                // Emoji Icon
                Surface(
                    modifier = Modifier.size(48.dp),
                    shape = RoundedCornerShape(24.dp),
                    color = Color(0xFFF5F5F5)
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Text(
                            text = banner.emoji,
                            fontSize = 24.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.width(16.dp))

                // Text
                Column {
                    Text(
                        text = banner.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF333333)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = banner.description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color(0xFF666666)
                    )
                }
            }

            // Chevron
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = "Navigate",
                tint = Color(0xFFCCCCCC),
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

/**
 * Validate and parse JSON string into ResolvedConfig
 */
fun validateAndParseJson(jsonString: String): ResolvedConfig? {
    return try {
        // Try to parse using the SDK's JSON parser
        val json = Json {
            ignoreUnknownKeys = true
            isLenient = true
        }
        // Basic validation - check if it's valid JSON
        json.parseToJsonElement(jsonString)

        // TODO: Add more specific validation for NativeDisplayConfig structure
        // For now, we'll just check if it's valid JSON
        // The actual parsing will happen in the detail screen

        json.decodeFromString<ResolvedConfig>(jsonString)
        //null // Return null for now, actual parsing will be done in detail screen
    } catch (e: Exception) {
        null
    }
}
