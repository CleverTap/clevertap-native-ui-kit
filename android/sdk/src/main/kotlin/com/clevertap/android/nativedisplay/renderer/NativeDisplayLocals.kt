package com.clevertap.android.nativedisplay.renderer

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import coil.ImageLoader

/**
 * Overrides the Coil ImageLoader for IMAGE elements. Null = production singleton (no-op).
 *
 * Public test override hook: production callers should not provide this; it exists so SDK tests
 * (and downstream consumers' own tests) can inject a deterministic ImageLoader (e.g. fake/offline
 * loader, fixed-bitmap loader) without touching the real Coil singleton. Not part of the
 * supported configuration surface for production apps.
 */
val LocalImageLoader = compositionLocalOf<((Context) -> ImageLoader)?> { null }

/** Client-provided default FontFamily. Null = system default. */
val LocalFontFamily = compositionLocalOf<FontFamily?> { null }

/** Client-provided resolver for JSON fontFamily strings. Null = no custom resolution. */
val LocalFontFamilyResolver = compositionLocalOf<((String) -> FontFamily?)?> { null }

/**
 * Overrides the video player composable for VIDEO elements. Null = real VideoPlayer (no-op).
 *
 * Public test override hook: lets tests substitute a stub composable in place of the real
 * Media3 ExoPlayer-backed VideoPlayer (which is hard to drive deterministically in screenshot
 * / unit tests). Not intended as a production extension point.
 */
val LocalVideoPlayerFactory = compositionLocalOf<
    (@Composable (videoUrl: String, autoPlay: Boolean, loop: Boolean, muted: Boolean,
                  showControls: Boolean, showFullscreen: Boolean, openUrl: String?,
                  modifier: Modifier) -> Unit)?
> { null }

/**
 * Overrides the HTML WebView composable for HTML elements. Null = real HtmlElementView (no-op).
 *
 * Public test override hook: lets tests substitute a stub composable in place of the real
 * WebView-backed HtmlElementView (WebView is non-deterministic and slow under test). Not
 * intended as a production extension point.
 */
val LocalHtmlViewFactory = compositionLocalOf<
    (@Composable (html: String?, url: String?, config: com.clevertap.android.nativedisplay.models.HtmlConfig,
                  modifier: Modifier) -> Unit)?
> { null }
