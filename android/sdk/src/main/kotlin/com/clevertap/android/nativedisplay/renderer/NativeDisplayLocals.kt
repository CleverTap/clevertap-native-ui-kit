package com.clevertap.android.nativedisplay.renderer

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Modifier
import coil.ImageLoader

/** Overrides the Coil ImageLoader for IMAGE elements. Null = production singleton (no-op). */
val LocalImageLoader = compositionLocalOf<((Context) -> ImageLoader)?> { null }

/** Overrides the video player composable for VIDEO elements. Null = real VideoPlayer (no-op). */
val LocalVideoPlayerFactory = compositionLocalOf<
    (@Composable (videoUrl: String, autoPlay: Boolean, loop: Boolean, muted: Boolean,
                  showControls: Boolean, showFullscreen: Boolean, modifier: Modifier) -> Unit)?
> { null }
