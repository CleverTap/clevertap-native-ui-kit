package com.clevertap.android.nativedisplay.internal

import android.content.Context
import coil.ImageLoader
import coil.decode.GifDecoder
import coil.decode.ImageDecoderDecoder
import android.os.Build

/**
 * Internal singleton ImageLoader for the Native Display SDK.
 * Configured with GIF animation support via coil-gif.
 *
 * This is used internally by the SDK to load images without requiring
 * host apps to configure their ImageLoader.
 */
internal object ImageLoaderProvider {

    private const val TAG = "NativeDisplay.ImageLoader"

    @Volatile
    private var imageLoader: ImageLoader? = null

    /**
     * Get or create the internal ImageLoader instance.
     * Thread-safe lazy initialization with GIF decoder support.
     */
    fun getImageLoader(context: Context): ImageLoader {
        return imageLoader ?: synchronized(this) {
            imageLoader ?: createImageLoader(context).also {
                imageLoader = it
                NDLogger.d(TAG, "ImageLoader created with GIF support")
            }
        }
    }

    private fun createImageLoader(context: Context): ImageLoader {
        return ImageLoader.Builder(context.applicationContext)
            .components {
                // Add GIF decoder support
                // Use ImageDecoderDecoder for Android P+ (better performance and native support)
                // Use GifDecoder for older Android versions
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    add(ImageDecoderDecoder.Factory())
                    NDLogger.d(TAG, "Using ImageDecoderDecoder for GIF support (Android P+)")
                } else {
                    add(GifDecoder.Factory())
                    NDLogger.d(TAG, "Using GifDecoder for GIF support (Android < P)")
                }
            }
            .build()
    }
}
