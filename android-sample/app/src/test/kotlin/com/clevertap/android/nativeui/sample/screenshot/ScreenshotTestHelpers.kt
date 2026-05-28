package com.clevertap.android.nativeui.sample.screenshot

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import coil.ImageLoader
import coil.decode.DataSource
import coil.intercept.Interceptor
import coil.request.ImageResult
import coil.request.SuccessResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import java.net.URL

/**
 * Companion-object level cache: downloaded once per JVM session, shared across all test methods.
 * Key = URL string, Value = decoded Bitmap.
 */
object ImagePrewarmCache {
    private val cache = mutableMapOf<String, Bitmap>()
    @Volatile private var _initialized = false
    val isInitialized: Boolean get() = _initialized

    fun initialize(urls: Collection<String>) {
        if (_initialized) return
        synchronized(this) {
            if (_initialized) return
            runBlocking {
                urls.map { url ->
                    async(Dispatchers.IO) {
                        try {
                            val bitmap = URL(url).openStream().use { BitmapFactory.decodeStream(it) }
                            if (bitmap != null) cache[url] = bitmap
                        } catch (_: Exception) { /* offline / unreachable — skip */ }
                    }
                }.awaitAll()
            }
            _initialized = true
        }
    }

    fun getBitmap(url: String): Bitmap? = cache[url]
}

/** Coil Interceptor: returns pre-downloaded bitmap synchronously; falls through for unknown URLs. */
private class PrewarmInterceptor : Interceptor {
    override suspend fun intercept(chain: Interceptor.Chain): ImageResult {
        val url = chain.request.data.toString()
        val bitmap = ImagePrewarmCache.getBitmap(url)
        return if (bitmap != null) {
            SuccessResult(
                drawable = BitmapDrawable(chain.request.context.resources, bitmap),
                request = chain.request,
                dataSource = DataSource.MEMORY_CACHE
            )
        } else {
            chain.proceed(chain.request)
        }
    }
}

/** Builds the test ImageLoader backed by pre-warmed in-memory bitmaps. */
fun buildPrewarmedImageLoader(context: Context): ImageLoader =
    ImageLoader.Builder(context)
        .components { add(PrewarmInterceptor()) }
        .memoryCache(null)
        .diskCache(null)
        .build()

/**
 * Extracts all concrete https:// image URLs from all test config JSON files in assets.
 * Skips template variable URLs ({{...}}).
 */
fun collectImageUrlsFromAssets(context: Context): Set<String> {
    val regex = Regex(""""url"\s*:\s*"(https?://[^"]+)"""")
    return context.assets.list("test-configs")
        ?.flatMap { filename ->
            val json = context.assets.open("test-configs/$filename").bufferedReader().readText()
            regex.findAll(json).map { it.groupValues[1] }
        }
        ?.filter { !it.contains("{{") }
        ?.toSet()
        ?: emptySet()
}

/** Stub video player composable for static screenshot captures. */
@Composable
fun StubVideoPlayer(
    videoUrl: String,
    autoPlay: Boolean,
    loop: Boolean,
    muted: Boolean,
    showControls: Boolean,
    showFullscreen: Boolean,
    openUrl: String? = null,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier.background(Color(0xFF1A1A2E)),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "▶  ${videoUrl.takeLast(35)}",
            color = Color.White,
            fontSize = 10.sp
        )
    }
}

/**
 * A @Composable lambda delegating to StubVideoPlayer, compatible with LocalVideoPlayerFactory.provides().
 * Kotlin does not support function references (::) to @Composable functions.
 */
val stubVideoPlayerFactory: @Composable (String, Boolean, Boolean, Boolean, Boolean, Boolean, String?, Modifier) -> Unit =
    @Composable { videoUrl, autoPlay, loop, muted, showControls, showFullscreen, openUrl, modifier ->
        StubVideoPlayer(videoUrl, autoPlay, loop, muted, showControls, showFullscreen, openUrl, modifier)
    }
