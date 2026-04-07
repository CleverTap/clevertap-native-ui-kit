package com.clevertap.android.nativedisplay.renderer

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import kotlinx.coroutines.delay
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight

/**
 * Video player composable with custom controls.
 * Supports Media3 ExoPlayer with runtime detection and graceful degradation.
 */
@Composable
fun VideoPlayer(
    videoUrl: String,
    autoPlay: Boolean = false,
    loop: Boolean = false,
    muted: Boolean = false,
    showControls: Boolean = true,
    showFullscreen: Boolean = true,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    // Single runtime check for Media3 availability
    val isMedia3Available = remember {
        runCatching {
            Class.forName("androidx.media3.exoplayer.ExoPlayer")
        }.onSuccess {
            android.util.Log.d("VideoPlayer", "Media3 is available")
        }.onFailure {
            android.util.Log.w("VideoPlayer", "Media3 not found - add androidx.media3 dependencies")
        }.isSuccess
    }

    if (!isMedia3Available) {
        // Fallback UI when Media3 is not available
        Box(
            modifier = modifier.background(Color.DarkGray),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    "Video Player Unavailable",
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = ComposeFontWeight.Bold
                )
                Text(
                    "Add Media3 dependency to your app",
                    color = Color.LightGray,
                    fontSize = 11.sp,
                    textAlign = TextAlign.Center
                )
            }
        }
        return
    }

    // Media3 is available - render video player
    VideoPlayerWithMedia3(
        context = context,
        videoUrl = videoUrl,
        autoPlay = autoPlay,
        loop = loop,
        muted = muted,
        showControls = showControls,
        showFullscreen = showFullscreen,
        modifier = modifier
    )
}

/**
 * Internal video player implementation that uses Media3 directly.
 * Only called when Media3 is confirmed to be available.
 *
 * Uses direct ExoPlayer API calls (not reflection) since compileOnly makes classes
 * available at compile time. The class existence check in VideoPlayer() ensures
 * Media3 is available at runtime before this function is called.
 */
@Composable
internal fun VideoPlayerWithMedia3(
    context: android.content.Context,
    videoUrl: String,
    autoPlay: Boolean,
    loop: Boolean,
    muted: Boolean,
    showControls: Boolean,
    showFullscreen: Boolean,
    modifier: Modifier
) {
    val lifecycleOwner = LocalLifecycleOwner.current

    // State for custom controls
    var showControlsUI by remember { mutableStateOf(false) }
    var isPlaying by remember { mutableStateOf(autoPlay) }
    var isMuted by remember { mutableStateOf(muted) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Create ExoPlayer instance - DIRECT API CALLS (no reflection after class check!)
    val exoPlayer = remember(videoUrl) {
        runCatching {
            // Direct ExoPlayer API usage - compiles because of compileOnly dependency
            ExoPlayer.Builder(context)
                .build()
                .apply {
                    setMediaItem(MediaItem.fromUri(videoUrl))
                    prepare()
                    playWhenReady = autoPlay
                    repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
                    volume = if (muted) 0f else 1f
                }
                .also {
                    android.util.Log.d("VideoPlayer", "✓ Player created for: $videoUrl")
                }
        }.onFailure { e ->
            errorMessage = "Failed to create player: ${e.message}"
            android.util.Log.e("VideoPlayer", "✗ Player creation failed", e)
        }.getOrNull()
    }

    // Lifecycle management - DIRECT method calls
    DisposableEffect(lifecycleOwner, exoPlayer) {
        exoPlayer?.let { player ->
            val observer = LifecycleEventObserver { _, event ->
                when (event) {
                    Lifecycle.Event.ON_PAUSE -> player.pause()
                    Lifecycle.Event.ON_RESUME -> if (autoPlay) player.play()
                    else -> Unit
                }
            }

            lifecycleOwner.lifecycle.addObserver(observer)

            onDispose {
                lifecycleOwner.lifecycle.removeObserver(observer)
                player.release()
                android.util.Log.d("VideoPlayer", "✓ Player released")
            }
        } ?: onDispose { }
    }

    // Poll player state - DIRECT property access
    LaunchedEffect(exoPlayer) {
        exoPlayer?.let { player ->
            while (true) {
                try {
                    isPlaying = player.isPlaying
                    isMuted = player.volume == 0f
                } catch (_: Exception) {
                    // Player might be released
                    break
                }
                delay(100)
            }
        }
    }

    // Auto-hide controls
    LaunchedEffect(showControlsUI) {
        if (showControlsUI) {
            delay(3000)
            showControlsUI = false
        }
    }

    // UI
    Box(
        modifier = modifier.clickable {
            if (showControls) {
                showControlsUI = !showControlsUI
            }
        }
    ) {
        when {
            errorMessage != null -> {
                // Error state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.DarkGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        errorMessage ?: "Unknown error",
                        color = Color.White,
                        fontSize = 12.sp,
                        textAlign = TextAlign.Center
                    )
                }
            }
            exoPlayer != null -> {
                // Video player view - DIRECT PlayerView API calls
                AndroidView(
                    factory = { ctx ->
                        PlayerView(ctx).apply {
                            player = exoPlayer
                            useController = false  // Disable default controls (we have custom ones)
                            android.util.Log.d("VideoPlayer", "✓ PlayerView created")
                        }
                    },
                    modifier = Modifier.fillMaxSize()
                )
            }
            else -> {
                // Loading state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Loading...",
                        color = Color.White,
                        fontSize = 14.sp
                    )
                }
            }
        }

        // Custom controls overlay
        if (showControls && exoPlayer != null) {
            AnimatedVisibility(
                visible = showControlsUI,
                enter = fadeIn(animationSpec = tween(300)),
                exit = fadeOut(animationSpec = tween(300)),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
            ) {
                Box(
                    modifier = Modifier
                        .background(Color.Black.copy(alpha = 0.5f))
                        .padding(16.dp)
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Play/Pause button - DIRECT method calls
                        IconButton(onClick = {
                            if (isPlaying) {
                                exoPlayer.pause()
                                android.util.Log.d("VideoPlayer", "⏸ Paused")
                            } else {
                                exoPlayer.play()
                                android.util.Log.d("VideoPlayer", "▶ Playing")
                            }
                        }) {
                            if (isPlaying) {
                                // Pause icon (two vertical bars)
                                Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                                    Box(
                                        Modifier
                                            .width(4.dp)
                                            .height(16.dp)
                                            .background(Color.White)
                                    )
                                    Box(
                                        Modifier
                                            .width(4.dp)
                                            .height(16.dp)
                                            .background(Color.White)
                                    )
                                }
                            } else {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Play",
                                    tint = Color.White
                                )
                            }
                        }

                        // Mute/Unmute button - DIRECT method calls
                        IconButton(onClick = {
                            exoPlayer.volume = if (isMuted) 1f else 0f
                            isMuted = !isMuted
                            android.util.Log.d("VideoPlayer", "🔊 Volume: ${if (isMuted) "Muted" else "Unmuted"}")
                        }) {
                            Text(
                                text = if (isMuted) "\uD83D\uDD07" else "\uD83D\uDD0A",  // 🔇 🔊 emoji
                                fontSize = 20.sp,
                                color = Color.White
                            )
                        }

                        // Fullscreen button (if enabled)
                        if (showFullscreen) {
                            IconButton(onClick = {
                                // TODO: Implement fullscreen functionality
                                android.util.Log.d("VideoPlayer", "⛶ Fullscreen requested (not implemented)")
                            }) {
                                Text(
                                    text = "⛶",  // Fullscreen symbol
                                    fontSize = 20.sp,
                                    color = Color.White
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
