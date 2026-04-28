package com.clevertap.android.nativedisplay.renderer

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import coil.ImageLoader

/** Overrides the Coil ImageLoader for IMAGE elements. Null = production singleton (no-op). */
val LocalImageLoader = compositionLocalOf<((Context) -> ImageLoader)?> { null }

/** Client-provided default FontFamily. Null = system default. */
val LocalFontFamily = compositionLocalOf<FontFamily?> { null }

/** Client-provided resolver for JSON fontFamily strings. Null = no custom resolution. */
val LocalFontFamilyResolver = compositionLocalOf<((String) -> FontFamily?)?> { null }

/** Overrides the video player composable for VIDEO elements. Null = real VideoPlayer (no-op). */
val LocalVideoPlayerFactory = compositionLocalOf<
    (@Composable (videoUrl: String, autoPlay: Boolean, loop: Boolean, muted: Boolean,
<<<<<<< HEAD
                  showControls: Boolean, showFullscreen: Boolean, openUrl: String?,
                  modifier: Modifier) -> Unit)?
=======
                  showControls: Boolean, showFullscreen: Boolean, modifier: Modifier) -> Unit)?
>>>>>>> origin/task/SDK-5399_ios
> { null }

/** Overrides the HTML WebView composable for HTML elements. Null = real HtmlElementView (no-op). */
val LocalHtmlViewFactory = compositionLocalOf<
    (@Composable (html: String?, url: String?, config: com.clevertap.android.nativedisplay.models.HtmlConfig,
                  modifier: Modifier) -> Unit)?
> { null }
