package com.clevertap.android.nativedisplay.utils

import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.nativedisplay.view.NativeDisplayViewGroup

/**
 * Base adapter for mixing native and SDUI content in RecyclerView.
 *
 * Provides common functionality for handling both view types.
 *
 * Usage:
 * ```kotlin
 * sealed class FeedItem {
 *     data class Native(val data: MyData) : FeedItem()
 *     data class SDUI(val config: ResolvedConfig) : FeedItem()
 * }
 *
 * class MyAdapter : MixedContentAdapter<FeedItem>() {
 *     // Implement abstract methods
 * }
 * ```
 */
abstract class MixedContentAdapter<T : Any>(
    diffCallback: DiffUtil.ItemCallback<T>
) : ListAdapter<T, RecyclerView.ViewHolder>(diffCallback) {

    companion object {
        const val VIEW_TYPE_NATIVE = 0
        const val VIEW_TYPE_SDUI = 1
    }

    /**
     * Determine if an item should be rendered as SDUI.
     *
     * @param item The item to check
     * @return true if item should use SDUI rendering
     */
    abstract fun isSDUIItem(item: T): Boolean

    /**
     * Create ViewHolder for native content.
     *
     * @param parent Parent ViewGroup
     * @return ViewHolder for native content
     */
    abstract fun onCreateNativeViewHolder(parent: ViewGroup): RecyclerView.ViewHolder

    /**
     * Bind native content to ViewHolder.
     *
     * @param holder The native ViewHolder
     * @param item The item to bind
     */
    abstract fun onBindNativeViewHolder(holder: RecyclerView.ViewHolder, item: T)

    /**
     * Create ViewHolder for SDUI content.
     *
     * Override this if you need custom SDUI ViewHolder behavior.
     *
     * @param parent Parent ViewGroup
     * @return ViewHolder for SDUI content
     */
    open fun onCreateSDUIViewHolder(parent: ViewGroup): SDUIViewHolder {
        return SDUIViewHolder(NativeDisplayViewGroup(parent.context))
    }

    /**
     * Bind SDUI content to ViewHolder.
     *
     * Override this if you need custom SDUI binding behavior.
     *
     * @param holder The SDUI ViewHolder
     * @param item The item to bind
     */
    abstract fun onBindSDUIViewHolder(holder: SDUIViewHolder, item: T)

    override fun getItemViewType(position: Int): Int {
        return if (isSDUIItem(getItem(position))) {
            VIEW_TYPE_SDUI
        } else {
            VIEW_TYPE_NATIVE
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            VIEW_TYPE_SDUI -> onCreateSDUIViewHolder(parent)
            VIEW_TYPE_NATIVE -> onCreateNativeViewHolder(parent)
            else -> throw IllegalArgumentException("Unknown view type: $viewType")
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val item = getItem(position)
        when (holder) {
            is SDUIViewHolder -> onBindSDUIViewHolder(holder, item)
            else -> onBindNativeViewHolder(holder, item)
        }
    }

    override fun onViewRecycled(holder: RecyclerView.ViewHolder) {
        super.onViewRecycled(holder)
        if (holder is SDUIViewHolder) {
            holder.onRecycled()
        }
    }

    override fun onViewAttachedToWindow(holder: RecyclerView.ViewHolder) {
        super.onViewAttachedToWindow(holder)
        if (holder is SDUIViewHolder) {
            holder.onAttached()
        }
    }

    /**
     * Standard ViewHolder for SDUI content.
     */
    class SDUIViewHolder(itemView: NativeDisplayViewGroup) : RecyclerView.ViewHolder(itemView) {
        private val sduiView = itemView

        fun bind(
            config: ResolvedConfig,
            actionListener: NativeDisplayActionListener? = null
        ) {
            sduiView.setConfig(config, actionListener)
        }

        fun onRecycled() {
            sduiView.onRecycled()
        }

        fun onAttached() {
            sduiView.onAttached()
        }
    }
}