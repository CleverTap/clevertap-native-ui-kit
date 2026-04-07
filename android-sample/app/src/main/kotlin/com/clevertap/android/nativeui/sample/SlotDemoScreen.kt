package com.clevertap.android.nativeui.sample

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.placement.NativeDisplaySlot
import com.clevertap.android.sdk.CleverTapAPI

// --- Data models ---

data class AppContentItem(
    val id: Int,
    val title: String,
    val subtitle: String,
    val imageUrl: String
)

sealed class SlotDemoItem {
    data class AppContent(val item: AppContentItem) : SlotDemoItem()
    data class SlotPlaceholder(val slotId: String) : SlotDemoItem()
}

// --- Hardcoded content ---

private val appItems = listOf(
    AppContentItem(1, "Morning Yoga Flow", "30 min \u00B7 Beginner friendly", "https://yavuzceliker.github.io/sample-images/image-1.jpg"),
    AppContentItem(2, "Mediterranean Salad", "Quick & healthy lunch recipe", "https://yavuzceliker.github.io/sample-images/image-5.jpg"),
    AppContentItem(3, "Productivity Hacks", "5 tips for focused work", "https://yavuzceliker.github.io/sample-images/image-10.jpg"),
    AppContentItem(4, "Trail Running Guide", "Best routes near you", "https://yavuzceliker.github.io/sample-images/image-15.jpg"),
    AppContentItem(5, "Indoor Plants 101", "Low-maintenance greenery", "https://yavuzceliker.github.io/sample-images/image-20.jpg"),
    AppContentItem(6, "Weekend Getaways", "Top 10 road trip destinations", "https://yavuzceliker.github.io/sample-images/image-25.jpg"),
    AppContentItem(7, "Budget Meal Prep", "Save time and money", "https://yavuzceliker.github.io/sample-images/image-30.jpg"),
    AppContentItem(8, "Home Workout", "No equipment needed", "https://yavuzceliker.github.io/sample-images/image-35.jpg"),
    AppContentItem(9, "Coffee Brewing", "Perfect pour-over technique", "https://yavuzceliker.github.io/sample-images/image-40.jpg"),
    AppContentItem(10, "Sleep Better", "Science-backed tips", "https://yavuzceliker.github.io/sample-images/image-45.jpg"),
    AppContentItem(11, "Digital Detox", "Unplug and recharge", "https://yavuzceliker.github.io/sample-images/image-50.jpg"),
    AppContentItem(12, "Book Club Picks", "This month's top reads", "https://yavuzceliker.github.io/sample-images/image-55.jpg"),
    AppContentItem(13, "Smoothie Recipes", "Fuel your morning", "https://yavuzceliker.github.io/sample-images/image-60.jpg"),
    AppContentItem(14, "Desk Stretches", "Relieve tension in 5 min", "https://yavuzceliker.github.io/sample-images/image-65.jpg"),
    AppContentItem(15, "Mindful Breathing", "Calm in 3 minutes", "https://yavuzceliker.github.io/sample-images/image-70.jpg"),
)

/**
 * Builds the interleaved list: 4 slot placeholders at fixed positions among 15 app items.
 *
 * Index mapping:
 *   0          -> slot_top
 *   1-3        -> app items 1-3
 *   4          -> slot_feed_1
 *   5-7        -> app items 4-6
 *   8          -> slot_feed_2
 *   9-17       -> app items 7-15
 *   18         -> slot_bottom
 */
private fun buildFeedItems(): List<SlotDemoItem> {
    val items = mutableListOf<SlotDemoItem>()

    items.add(SlotDemoItem.SlotPlaceholder("slot_top"))          // 0
    items.addAll(appItems.subList(0, 3).map { SlotDemoItem.AppContent(it) })  // 1-3
    items.add(SlotDemoItem.SlotPlaceholder("slot_feed_1"))       // 4
    items.addAll(appItems.subList(3, 6).map { SlotDemoItem.AppContent(it) })  // 5-7
    items.add(SlotDemoItem.SlotPlaceholder("slot_feed_2"))       // 8
    items.addAll(appItems.subList(6, 15).map { SlotDemoItem.AppContent(it) }) // 9-17
    items.add(SlotDemoItem.SlotPlaceholder("slot_bottom"))       // 18

    return items
}

// --- Screen ---

@Composable
fun SlotDemoScreen() {
    val context = LocalContext.current

    // Initialize bridge (same pattern as CleverTapIntegrationScreen)
    val bridge = remember { NativeDisplayBridge.initialize(context.applicationContext) }
    val cleverTapApi = remember { CleverTapAPI.getDefaultInstance(context.applicationContext) }

    val feedItems = remember { buildFeedItems() }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F5F5)),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Header section
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 4.dp)
            ) {
                Text(
                    text = "Slot Demo",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(bottom = 4.dp)
                )
                Text(
                    text = "This feed contains 4 NativeDisplaySlot views at fixed positions. " +
                            "Tap the button below to fire a CleverTap event that fetches real server data for the slots.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFF666666),
                    modifier = Modifier.padding(bottom = 12.dp)
                )
                Button(
                    onClick = {
                        cleverTapApi?.run {
                            pushEvent("Header1")
                            pushEvent("Header2")
                            pushEvent("Header3")
                            pushEvent("lalit")
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text("Fetch Slot Data")
                }
            }
        }

        // Feed items (19 total: 4 slots + 15 app content)
        itemsIndexed(feedItems) { _, item ->
            when (item) {
                is SlotDemoItem.SlotPlaceholder -> {
                    NativeDisplaySlot(
                        slotId = item.slotId,
                        modifier = Modifier.fillMaxWidth(),
                        loading = { EmptySlotPlaceholder() }
                    )
                }
                is SlotDemoItem.AppContent -> {
                    AppContentCard(item.item)
                }
            }
        }
    }
}

// --- Slot placeholder (shown before data arrives) ---

@Composable
private fun EmptySlotPlaceholder() {
    val dashedBorderColor = Color(0xFFBDBDBD)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp)
            .background(
                color = Color(0xFFF5F5F5),
                shape = RoundedCornerShape(8.dp)
            )
            .drawBehind {
                val strokeWidth = 1.dp.toPx()
                val pathEffect = PathEffect.dashPathEffect(
                    floatArrayOf(8.dp.toPx(), 4.dp.toPx()),
                    0f
                )
                drawRoundRect(
                    color = dashedBorderColor,
                    style = Stroke(
                        width = strokeWidth,
                        pathEffect = pathEffect
                    ),
                    cornerRadius = CornerRadius(8.dp.toPx())
                )
            },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "Ad",
            color = Color(0xFF9E9E9E),
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

// --- App content card ---

@Composable
private fun AppContentCard(item: AppContentItem) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column {
            AsyncImage(
                model = item.imageUrl,
                contentDescription = item.title,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
                    .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
            )
            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = item.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = item.subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFF888888),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}
