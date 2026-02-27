package com.clevertap.android.nativedisplay.utils

import com.clevertap.nativedisplay.utils.SDUIRecyclerViewConfig
import android.content.Context
import android.util.TypedValue
import androidx.recyclerview.widget.RecyclerView
import com.clevertap.android.nativedisplay.view.NativeDisplayViewGroup

/**
 * Extension functions for easier SDUI integration.
 */

/**
 * Convert DP to pixels.
 */
fun Int.dpToPx(context: Context): Int {
    return TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        this.toFloat(),
        context.resources.displayMetrics
    ).toInt()
}

/**
 * Convert pixels to DP.
 */
fun Int.pxToDp(context: Context): Int {
    return (this / context.resources.displayMetrics.density).toInt()
}

/**
 * Quick configure RecyclerView for SDUI.
 */
fun RecyclerView.configureForSDUI(sduiViewType: Int = 1, poolSize: Int = 10) {
    SDUIRecyclerViewConfig.configure(this, sduiViewType, poolSize)
}

/**
 * Find all NativeDisplayViewGroup instances in RecyclerView.
 */
fun RecyclerView.findAllSDUIViews(): List<NativeDisplayViewGroup> {
    val views = mutableListOf<NativeDisplayViewGroup>()

    for (i in 0 until childCount) {
        val child = getChildAt(i)
        if (child is NativeDisplayViewGroup) {
            views.add(child)
        }
    }

    return views
}