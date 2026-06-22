package com.clevertap.android.nativeui.sample.xmlslots

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import coil.load
import com.clevertap.android.nativedisplay.placement.NativeDisplaySlotView
import com.clevertap.android.nativeui.sample.R

/**
 * Data model for one row in the XML slot feed.
 *
 * Mirrors `SlotDemoScreen.kt` so the XML demo renders the exact same UI: a
 * scrolling list of 20 rows = 1 header + 4 slots + 15 app content cards.
 */
sealed class SlotFeedItem {
    /** Title + description + "Fetch Slot Data" button — first row of the feed. */
    object Header : SlotFeedItem()

    data class AppContent(
        val id: Int,
        val title: String,
        val subtitle: String,
        val imageUrl: String
    ) : SlotFeedItem()

    data class SlotPlaceholder(val slotId: String) : SlotFeedItem()
}

/**
 * RecyclerView adapter for the XML Slots demo.
 *
 * Three view types:
 *  - [TYPE_HEADER]      — title + description + "Fetch Slot Data" button. Click
 *                         is delegated to [onFetchClick].
 *  - [TYPE_APP_CONTENT] — first-party product card rendered by the host app.
 *  - [TYPE_SLOT]        — a `NativeDisplaySlotView` that self-registers with
 *                         the SDK in `onAttachedToWindow`. The adapter just
 *                         pushes `setSlotId(...)` on bind.
 *
 * Stable ids are enabled so scrolling does not re-bind (and therefore does
 * not re-register) slot view holders unnecessarily.
 */
class SlotFeedAdapter(
    private val items: List<SlotFeedItem>,
    private val onFetchClick: () -> Unit
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val TYPE_HEADER = 0
        private const val TYPE_APP_CONTENT = 1
        private const val TYPE_SLOT = 2

        private const val ID_HEADER = -1L
    }

    init {
        setHasStableIds(true)
    }

    override fun getItemCount(): Int = items.size

    override fun getItemViewType(position: Int): Int = when (items[position]) {
        is SlotFeedItem.Header -> TYPE_HEADER
        is SlotFeedItem.AppContent -> TYPE_APP_CONTENT
        is SlotFeedItem.SlotPlaceholder -> TYPE_SLOT
    }

    override fun getItemId(position: Int): Long = when (val item = items[position]) {
        is SlotFeedItem.Header -> ID_HEADER
        is SlotFeedItem.AppContent -> "content_${item.id}".hashCode().toLong()
        is SlotFeedItem.SlotPlaceholder -> item.slotId.hashCode().toLong()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val inflater = LayoutInflater.from(parent.context)
        return when (viewType) {
            TYPE_HEADER -> HeaderViewHolder(
                inflater.inflate(R.layout.item_slot_feed_header, parent, false),
                onFetchClick
            )
            TYPE_APP_CONTENT -> AppContentViewHolder(
                inflater.inflate(R.layout.item_slot_feed_app_content, parent, false)
            )
            TYPE_SLOT -> NDSlotViewHolder(
                inflater.inflate(R.layout.item_slot_feed_slot, parent, false)
            )
            else -> error("Unknown view type: $viewType")
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (val item = items[position]) {
            is SlotFeedItem.Header -> Unit // static content; click wired in HeaderViewHolder init.
            is SlotFeedItem.AppContent -> (holder as AppContentViewHolder).bind(item)
            is SlotFeedItem.SlotPlaceholder -> (holder as NDSlotViewHolder).bind(item)
        }
    }

    // --- View holders ---

    class HeaderViewHolder(itemView: View, onFetchClick: () -> Unit) : RecyclerView.ViewHolder(itemView) {
        init {
            itemView.findViewById<Button>(R.id.fetchSlotDataButton).setOnClickListener { onFetchClick() }
        }
    }

    class AppContentViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val image: ImageView = itemView.findViewById(R.id.contentImage)
        private val title: TextView = itemView.findViewById(R.id.contentTitle)
        private val subtitle: TextView = itemView.findViewById(R.id.contentSubtitle)

        fun bind(item: SlotFeedItem.AppContent) {
            title.text = item.title
            subtitle.text = item.subtitle
            image.load(item.imageUrl) {
                crossfade(true)
                placeholder(android.R.color.darker_gray)
            }
        }
    }

    class NDSlotViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val slotView: NativeDisplaySlotView = itemView.findViewById(R.id.slotView)

        fun bind(item: SlotFeedItem.SlotPlaceholder) {
            slotView.setSlotId(item.slotId)
        }
    }
}
