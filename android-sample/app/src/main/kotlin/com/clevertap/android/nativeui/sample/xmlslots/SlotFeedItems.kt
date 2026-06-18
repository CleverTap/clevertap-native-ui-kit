package com.clevertap.android.nativeui.sample.xmlslots

import android.content.res.Resources
import android.graphics.Rect
import android.view.View
import androidx.recyclerview.widget.RecyclerView

/**
 * Hardcoded app-content items shown between Native Display slots.
 *
 * Mirrors `appItems` in `SlotDemoScreen.kt` exactly so the XML and Compose
 * demos render identical feeds.
 */
private val appItems: List<SlotFeedItem.AppContent> = listOf(
    SlotFeedItem.AppContent(1, "Morning Yoga Flow", "30 min · Beginner friendly", "https://yavuzceliker.github.io/sample-images/image-1.jpg"),
    SlotFeedItem.AppContent(2, "Mediterranean Salad", "Quick & healthy lunch recipe", "https://yavuzceliker.github.io/sample-images/image-5.jpg"),
    SlotFeedItem.AppContent(3, "Productivity Hacks", "5 tips for focused work", "https://yavuzceliker.github.io/sample-images/image-10.jpg"),
    SlotFeedItem.AppContent(4, "Trail Running Guide", "Best routes near you", "https://yavuzceliker.github.io/sample-images/image-15.jpg"),
    SlotFeedItem.AppContent(5, "Indoor Plants 101", "Low-maintenance greenery", "https://yavuzceliker.github.io/sample-images/image-20.jpg"),
    SlotFeedItem.AppContent(6, "Weekend Getaways", "Top 10 road trip destinations", "https://yavuzceliker.github.io/sample-images/image-25.jpg"),
    SlotFeedItem.AppContent(7, "Budget Meal Prep", "Save time and money", "https://yavuzceliker.github.io/sample-images/image-30.jpg"),
    SlotFeedItem.AppContent(8, "Home Workout", "No equipment needed", "https://yavuzceliker.github.io/sample-images/image-35.jpg"),
    SlotFeedItem.AppContent(9, "Coffee Brewing", "Perfect pour-over technique", "https://yavuzceliker.github.io/sample-images/image-40.jpg"),
    SlotFeedItem.AppContent(10, "Sleep Better", "Science-backed tips", "https://yavuzceliker.github.io/sample-images/image-45.jpg"),
    SlotFeedItem.AppContent(11, "Digital Detox", "Unplug and recharge", "https://yavuzceliker.github.io/sample-images/image-50.jpg"),
    SlotFeedItem.AppContent(12, "Book Club Picks", "This month's top reads", "https://yavuzceliker.github.io/sample-images/image-55.jpg"),
    SlotFeedItem.AppContent(13, "Smoothie Recipes", "Fuel your morning", "https://yavuzceliker.github.io/sample-images/image-60.jpg"),
    SlotFeedItem.AppContent(14, "Desk Stretches", "Relieve tension in 5 min", "https://yavuzceliker.github.io/sample-images/image-65.jpg"),
    SlotFeedItem.AppContent(15, "Mindful Breathing", "Calm in 3 minutes", "https://yavuzceliker.github.io/sample-images/image-70.jpg"),
)

/**
 * Builds the 20-row feed used by the XML Slots demo: a header card followed by
 * the same 19-row interleave as `SlotDemoScreen.buildFeedItems()`.
 *
 * Index mapping:
 *   0          -> Header (title + description + "Fetch Slot Data" button)
 *   1          -> slot_top
 *   2-4        -> app items 1-3
 *   5          -> slot_feed_1
 *   6-8        -> app items 4-6
 *   9          -> slot_feed_2
 *  10-18       -> app items 7-15
 *  19          -> slot_bottom
 */
fun buildSlotFeedItems(): List<SlotFeedItem> {
    val items = mutableListOf<SlotFeedItem>()

    items.add(SlotFeedItem.Header)                                // 0
    items.add(SlotFeedItem.SlotPlaceholder("slot_top"))           // 1
    items.addAll(appItems.subList(0, 3))                          // 2-4
    items.add(SlotFeedItem.SlotPlaceholder("slot_feed_1"))        // 5
    items.addAll(appItems.subList(3, 6))                          // 6-8
    items.add(SlotFeedItem.SlotPlaceholder("slot_feed_2"))        // 9
    items.addAll(appItems.subList(6, 15))                         // 10-18
    items.add(SlotFeedItem.SlotPlaceholder("slot_bottom"))        // 19

    return items
}

/**
 * RecyclerView ItemDecoration that adds [spacingDp] dp bottom-margin to every
 * row except the last. Matches the 12dp gap between items in
 * `SlotDemoScreen` (`Arrangement.spacedBy(12.dp)`).
 */
class VerticalSpacingItemDecoration(private val spacingDp: Int) : RecyclerView.ItemDecoration() {

    private val spacingPx: Int = (spacingDp * Resources.getSystem().displayMetrics.density).toInt()

    override fun getItemOffsets(
        outRect: Rect,
        view: View,
        parent: RecyclerView,
        state: RecyclerView.State
    ) {
        val position = parent.getChildAdapterPosition(view)
        val itemCount = state.itemCount
        outRect.bottom = if (position == RecyclerView.NO_POSITION || position == itemCount - 1) 0 else spacingPx
    }
}
