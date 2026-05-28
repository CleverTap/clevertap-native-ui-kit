package com.nativedisplay.sample.xml.ui

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import coil.load
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.nativedisplay.sample.xml.databinding.ItemProductNativeBinding
import com.nativedisplay.sample.xml.databinding.ItemProductSduiBinding
import com.nativedisplay.sample.xml.databinding.ItemProductGalleryBinding

class ProductAdapter(
    private val onProductClick: (String) -> Unit
) : ListAdapter<FeedItem, RecyclerView.ViewHolder>(DiffCallback()) {

    companion object {
        private const val VIEW_TYPE_NATIVE = 0
        private const val VIEW_TYPE_SDUI = 1
        private const val VIEW_TYPE_GALLERY = 2
    }

    override fun getItemViewType(position: Int): Int {
        return when (getItem(position)) {
            is NativeProduct -> VIEW_TYPE_NATIVE
            is SDUIProduct -> VIEW_TYPE_SDUI
            is SDUIGallery -> VIEW_TYPE_GALLERY
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            VIEW_TYPE_NATIVE -> {
                val binding = ItemProductNativeBinding.inflate(
                    LayoutInflater.from(parent.context),
                    parent,
                    false
                )
                NativeProductViewHolder(binding, onProductClick)
            }
            VIEW_TYPE_SDUI -> {
                val binding = ItemProductSduiBinding.inflate(
                    LayoutInflater.from(parent.context),
                    parent,
                    false
                )
                SDUIProductViewHolder(binding, onProductClick)
            }
            VIEW_TYPE_GALLERY -> {
                val binding = ItemProductGalleryBinding.inflate(
                    LayoutInflater.from(parent.context),
                    parent,
                    false
                )
                SDUIGalleryViewHolder(binding, onProductClick)
            }
            else -> throw IllegalArgumentException("Unknown view type: $viewType")
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (val item = getItem(position)) {
            is NativeProduct -> (holder as NativeProductViewHolder).bind(item)
            is SDUIProduct -> (holder as SDUIProductViewHolder).bind(item)
            is SDUIGallery -> (holder as SDUIGalleryViewHolder).bind(item)
        }
    }

    override fun onViewRecycled(holder: RecyclerView.ViewHolder) {
        super.onViewRecycled(holder)
        when (holder) {
            is SDUIProductViewHolder -> holder.onRecycled()
            is SDUIGalleryViewHolder -> holder.onRecycled()
        }
    }

    override fun onViewAttachedToWindow(holder: RecyclerView.ViewHolder) {
        super.onViewAttachedToWindow(holder)
        when (holder) {
            is SDUIProductViewHolder -> holder.onAttached()
            is SDUIGalleryViewHolder -> holder.onAttached()
        }
    }

    class NativeProductViewHolder(
        private val binding: ItemProductNativeBinding,
        private val onProductClick: (String) -> Unit
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(item: NativeProduct) {
            val product = item.product

            binding.productImage.load(product.thumbnail) {
                crossfade(true)
                placeholder(android.R.color.darker_gray)
            }

            binding.productTitle.text = product.title
            binding.productDescription.text = product.description
            binding.productPrice.text = "$${product.price}"
            binding.productRating.text = "⭐ ${product.rating}"

            binding.addToCartButton.setOnClickListener {
                onProductClick(product.id.toString())
            }
        }
    }

    class SDUIProductViewHolder(
        private val binding: ItemProductSduiBinding,
        private val onProductClick: (String) -> Unit
    ) : RecyclerView.ViewHolder(binding.root) {

        init {
            // Set composition strategy to dispose when detached from window
            // This is important for RecyclerView to properly clean up compose views
            binding.composeView.setViewCompositionStrategy(
                ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed
            )
        }

        fun bind(item: SDUIProduct) {
            binding.composeView.setContent {
                MaterialTheme {
                    NativeDisplayView(
                        config = item.config,
                        actionListener = null, // You can add action listener here if needed
                        componentListener = null // You can add component listener here if needed
                    )
                }
            }
        }

        fun onRecycled() {
            // Compose will handle cleanup automatically with the ViewCompositionStrategy
        }

        fun onAttached() {
            // No action needed - Compose handles this
        }
    }

    class SDUIGalleryViewHolder(
        private val binding: ItemProductGalleryBinding,
        private val onProductClick: (String) -> Unit
    ) : RecyclerView.ViewHolder(binding.root) {

        init {
            binding.composeView.setViewCompositionStrategy(
                ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed
            )
        }

        fun bind(item: SDUIGallery) {
            binding.composeView.setContent {
                MaterialTheme {
                    NativeDisplayView(
                        config = item.config,
                        actionListener = null,
                        componentListener = null
                    )
                }
            }
        }

        fun onRecycled() {
            // Compose handles cleanup
        }

        fun onAttached() {
            // No action needed
        }
    }

    private class DiffCallback : DiffUtil.ItemCallback<FeedItem>() {
        override fun areItemsTheSame(oldItem: FeedItem, newItem: FeedItem): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: FeedItem, newItem: FeedItem): Boolean {
            return oldItem == newItem
        }
    }
}
