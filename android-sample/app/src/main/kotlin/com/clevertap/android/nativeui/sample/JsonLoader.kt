package com.clevertap.android.nativeui.sample

import android.content.Context
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.samples.JsonSampleLoader

/**
 * Utility class for loading JSON showcase examples from assets.
 */
object JsonLoader {
    
    /**
     * Load a JSON file from assets and parse it into a ResolvedConfig.
     */
    fun loadFromAssets(context: Context, filename: String): ResolvedConfig? {
        return JsonSampleLoader.loadFromAssets(context, filename)
    }
}
