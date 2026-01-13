package com.clevertap.nativedisplay.utils

import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView

/**
 * Helper object to configure RecyclerView for optimal SDUI performance.
 * 
 * Usage:
 * ```kotlin
 * val recyclerView = findViewById<RecyclerView>(R.id.feed)
 * SDUIRecyclerViewConfig.configure(
 *     recyclerView = recyclerView,
 *     sduiViewTypes = listOf(VIEW_TYPE_SDUI),
 *     poolSize = 10
 * )
 * ```
 */
object SDUIRecyclerViewConfig {
    
    /**
     * Configure RecyclerView for optimal SDUI performance.
     * 
     * This method:
     * - Sets up view pool with appropriate size
     * - Enables prefetch for smoother scrolling
     * - Optimizes item view cache
     * 
     * @param recyclerView The RecyclerView to configure
     * @param sduiViewTypes List of view types that contain SDUI content
     * @param poolSize Number of views to keep in the recycled pool (default: 10)
     */
    fun configure(
        recyclerView: RecyclerView,
        sduiViewTypes: List<Int>,
        poolSize: Int = 10
    ) {
        // Set recycled view pool size
        val pool = RecyclerView.RecycledViewPool()
        sduiViewTypes.forEach { viewType ->
            pool.setMaxRecycledViews(viewType, poolSize)
        }
        recyclerView.setRecycledViewPool(pool)
        
        // Enable prefetch for smoother scrolling
        (recyclerView.layoutManager as? LinearLayoutManager)?.apply {
            isItemPrefetchEnabled = true
            initialPrefetchItemCount = 4
        }
        
        // Optimize drawing cache
        recyclerView.setItemViewCacheSize(4)
        recyclerView.setHasFixedSize(true)
        
        // Reduce overdraw
        recyclerView.clipToPadding = false
    }
    
    /**
     * Configure RecyclerView with default settings for single SDUI view type.
     * 
     * @param recyclerView The RecyclerView to configure
     * @param sduiViewType The view type for SDUI content (default: 1)
     * @param poolSize Number of views to keep in the recycled pool (default: 10)
     */
    fun configure(
        recyclerView: RecyclerView,
        sduiViewType: Int = 1,
        poolSize: Int = 10
    ) {
        configure(recyclerView, listOf(sduiViewType), poolSize)
    }
}