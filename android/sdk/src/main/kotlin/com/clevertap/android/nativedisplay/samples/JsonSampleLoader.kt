package com.clevertap.android.nativedisplay.samples

import android.content.Context
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import kotlinx.serialization.json.Json
import java.io.IOException

/**
 * Utility to load Native Display configurations from JSON assets.
 * Demonstrates end-to-end server-driven UI flow.
 */
object JsonSampleLoader {
    
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        prettyPrint = true
    }
    
    /**
     * Load a JSON configuration from assets folder.
     * 
     * @param context Android context
     * @param fileName Name of the JSON file in assets folder
     * @return ResolvedConfig parsed from JSON
     */
    fun loadFromAssets(context: Context, fileName: String): ResolvedConfig? {
        return try {
            val jsonString = context.assets.open(fileName).bufferedReader().use { it.readText() }
            json.decodeFromString<ResolvedConfig>(jsonString)
        } catch (e: IOException) {
            e.printStackTrace()
            null
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    /**
     * Load the showcase profile screen example.
     * This demonstrates a complex real-world UI with:
     * - Multiple background types (layered, gradient, pattern, animated, etc.)
     * - Multiple buttons with different styles
     * - Images with opacity and styling
     * - Text elements with varied fonts, colors, and opacity
     * - Complex nested layouts
     */
    fun loadShowcaseProfileScreen(context: Context): ResolvedConfig? {
        return loadFromAssets(context, "showcase_profile_screen.json")
    }
}
