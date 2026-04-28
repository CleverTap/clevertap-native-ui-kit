package com.clevertap.android.nativedisplay.renderer

<<<<<<< HEAD
import android.content.Intent
import android.net.Uri
=======
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
=======
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
=======
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
>>>>>>> origin/task/SDK-5399_ios
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
<<<<<<< HEAD
import com.clevertap.android.nativeui.R
=======
>>>>>>> origin/task/SDK-5399_ios
import kotlinx.coroutines.delay
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight

/**
<<<<<<< HEAD
 * Private helper composable to render a control icon using a vector drawable.
 *
 * Uses Image + Modifier.clickable instead of IconButton to avoid the 48dp minimum
 * touch target size and internal padding that IconButton enforces. The SVG assets
 * include their own semi-transparent rounded-square background, so no external
 * strip background is needed.
 */
@Composable
private fun VideoControlIcon(
    painter: Painter,
    contentDescription: String,
    size: Dp = 32.dp,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    androidx.compose.foundation.Image(
        painter = painter,
        contentDescription = contentDescription,
        modifier = modifier
            .size(size)
            .clickable(onClick = onClick)
    )
}

/**
=======
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
    openUrl: String? = null,
=======
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
=======
        // Fallback UI when Media3 is not available
>>>>>>> origin/task/SDK-5399_ios
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

<<<<<<< HEAD
=======
    // Media3 is available - render video player
>>>>>>> origin/task/SDK-5399_ios
    VideoPlayerWithMedia3(
        context = context,
        videoUrl = videoUrl,
        autoPlay = autoPlay,
        loop = loop,
        muted = muted,
        showControls = showControls,
        showFullscreen = showFullscreen,
<<<<<<< HEAD
        openUrl = openUrl,
=======
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
 *
 * Fullscreen is implemented via a Compose Dialog with usePlatformDefaultWidth=false
 * so it fills the screen. The ExoPlayer instance is transferred between the inline
 * PlayerView and the fullscreen PlayerView — the inactive surface sets player=null
 * to detach cleanly.
=======
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
    openUrl: String?,
=======
>>>>>>> origin/task/SDK-5399_ios
    modifier: Modifier
) {
    val lifecycleOwner = LocalLifecycleOwner.current

<<<<<<< HEAD
    var showControlsUI by remember { mutableStateOf(false) }
    var isPlaying by remember { mutableStateOf(autoPlay) }
    var isMuted by remember { mutableStateOf(muted) }
    var isEnded by remember { mutableStateOf(false) }
    var isFullscreen by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val exoPlayer = remember(videoUrl) {
        runCatching {
            ExoPlayer.Builder(context).build().apply {
                setMediaItem(MediaItem.fromUri(videoUrl))
                prepare()
                playWhenReady = autoPlay
                repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
                volume = if (muted) 0f else 1f
            }.also {
                android.util.Log.d("VideoPlayer", "✓ Player created for: $videoUrl")
            }
=======
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
>>>>>>> origin/task/SDK-5399_ios
        }.onFailure { e ->
            errorMessage = "Failed to create player: ${e.message}"
            android.util.Log.e("VideoPlayer", "✗ Player creation failed", e)
        }.getOrNull()
    }

<<<<<<< HEAD
=======
    // Lifecycle management - DIRECT method calls
>>>>>>> origin/task/SDK-5399_ios
    DisposableEffect(lifecycleOwner, exoPlayer) {
        exoPlayer?.let { player ->
            val observer = LifecycleEventObserver { _, event ->
                when (event) {
                    Lifecycle.Event.ON_PAUSE -> player.pause()
                    Lifecycle.Event.ON_RESUME -> if (autoPlay) player.play()
                    else -> Unit
                }
            }
<<<<<<< HEAD
            lifecycleOwner.lifecycle.addObserver(observer)
=======

            lifecycleOwner.lifecycle.addObserver(observer)

>>>>>>> origin/task/SDK-5399_ios
            onDispose {
                lifecycleOwner.lifecycle.removeObserver(observer)
                player.release()
                android.util.Log.d("VideoPlayer", "✓ Player released")
            }
        } ?: onDispose { }
    }

<<<<<<< HEAD
=======
    // Poll player state - DIRECT property access
>>>>>>> origin/task/SDK-5399_ios
    LaunchedEffect(exoPlayer) {
        exoPlayer?.let { player ->
            while (true) {
                try {
                    isPlaying = player.isPlaying
                    isMuted = player.volume == 0f
<<<<<<< HEAD
                    isEnded = player.playbackState == Player.STATE_ENDED
                } catch (_: Exception) {
=======
                } catch (_: Exception) {
                    // Player might be released
>>>>>>> origin/task/SDK-5399_ios
                    break
                }
                delay(100)
            }
        }
    }

<<<<<<< HEAD
=======
    // Auto-hide controls
>>>>>>> origin/task/SDK-5399_ios
    LaunchedEffect(showControlsUI) {
        if (showControlsUI) {
            delay(3000)
            showControlsUI = false
        }
    }

<<<<<<< HEAD
    // Hoist painter references to avoid repeated resource lookups inside recomposing lambdas
    val playPainter = painterResource(if (isPlaying) R.drawable.ct_ic_pause else R.drawable.ct_ic_play)
    val mutePainter = painterResource(if (isMuted) R.drawable.ct_ic_volume_off_tint else R.drawable.ct_ic_volume_on_tint)
    val expandPainter = painterResource(R.drawable.ct_ic_expand)
    val actionPainter = painterResource(R.drawable.ct_ic_action)

    Box(
        modifier = modifier.clickable {
            if (showControls) showControlsUI = !showControlsUI
=======
    // UI
    Box(
        modifier = modifier.clickable {
            if (showControls) {
                showControlsUI = !showControlsUI
            }
>>>>>>> origin/task/SDK-5399_ios
        }
    ) {
        when {
            errorMessage != null -> {
<<<<<<< HEAD
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.DarkGray),
=======
                // Error state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.DarkGray),
>>>>>>> origin/task/SDK-5399_ios
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
<<<<<<< HEAD
                // Inline PlayerView — detaches player when fullscreen is active
=======
                // Video player view - DIRECT PlayerView API calls
>>>>>>> origin/task/SDK-5399_ios
                AndroidView(
                    factory = { ctx ->
                        PlayerView(ctx).apply {
                            player = exoPlayer
<<<<<<< HEAD
                            useController = false
                        }
                    },
                    update = { view -> view.player = if (isFullscreen) null else exoPlayer },
=======
                            useController = false  // Disable default controls (we have custom ones)
                            android.util.Log.d("VideoPlayer", "✓ PlayerView created")
                        }
                    },
>>>>>>> origin/task/SDK-5399_ios
                    modifier = Modifier.fillMaxSize()
                )
            }
            else -> {
<<<<<<< HEAD
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.Black),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Loading...", color = Color.White, fontSize = 14.sp)
=======
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
>>>>>>> origin/task/SDK-5399_ios
                }
            }
        }

<<<<<<< HEAD
        // Inline controls overlay — bottom-start aligned, fades in/out
=======
        // Custom controls overlay
>>>>>>> origin/task/SDK-5399_ios
        if (showControls && exoPlayer != null) {
            AnimatedVisibility(
                visible = showControlsUI,
                enter = fadeIn(animationSpec = tween(300)),
                exit = fadeOut(animationSpec = tween(300)),
<<<<<<< HEAD
                modifier = Modifier.align(Alignment.BottomStart).fillMaxWidth()
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(12.dp)
                ) {
                    VideoControlIcon(
                        painter = playPainter,
                        contentDescription = if (isPlaying) "Pause" else "Play",
                        onClick = {
                            if (isPlaying) {
                                exoPlayer.pause()
                            } else {
                                if (isEnded) exoPlayer.seekTo(0)
                                exoPlayer.play()
                            }
                        }
                    )
                    if (!openUrl.isNullOrEmpty()) {
                        VideoControlIcon(
                            painter = actionPainter,
                            contentDescription = "Open URL",
                            onClick = {
                                runCatching {
                                    context.startActivity(
                                        Intent(Intent.ACTION_VIEW, Uri.parse(openUrl))
                                    )
                                }
                            }
                        )
                    }
                    VideoControlIcon(
                        painter = mutePainter,
                        contentDescription = if (isMuted) "Unmute" else "Mute",
                        onClick = {
                            exoPlayer.volume = if (isMuted) 1f else 0f
                            isMuted = !isMuted
                        }
                    )
                    if (showFullscreen) {
                        VideoControlIcon(
                            painter = expandPainter,
                            contentDescription = "Enter fullscreen",
                            onClick = { isFullscreen = true }
                        )
                    }
                }
            }
        }

        // Fullscreen Dialog — fills screen, transfers player from inline surface
        if (isFullscreen && exoPlayer != null) {
            Dialog(
                onDismissRequest = { isFullscreen = false },
                properties = DialogProperties(usePlatformDefaultWidth = false)
            ) {
                FullscreenVideoContent(
                    context = context,
                    exoPlayer = exoPlayer,
                    isPlaying = isPlaying,
                    isMuted = isMuted,
                    openUrl = openUrl,
                    onDismiss = { isFullscreen = false },
                    onTogglePlay = {
                        if (isPlaying) exoPlayer.pause()
                        else {
                            if (isEnded) exoPlayer.seekTo(0)
                            exoPlayer.play()
                        }
                    },
                    onToggleMute = {
                        exoPlayer.volume = if (isMuted) 1f else 0f
                        isMuted = !isMuted
                    }
                )
            }
        }
    }
}

/**
 * Fullscreen video content rendered inside a Dialog.
 * Attaches the shared ExoPlayer to its own PlayerView.
 * Close/collapse both call onDismiss to return to inline mode.
 */
@Composable
private fun FullscreenVideoContent(
    context: android.content.Context,
    exoPlayer: ExoPlayer,
    isPlaying: Boolean,
    isMuted: Boolean,
    openUrl: String?,
    onDismiss: () -> Unit,
    onTogglePlay: () -> Unit,
    onToggleMute: () -> Unit
) {
    val closePainter = painterResource(R.drawable.ct_ic_close_pip)
    val playPainter = painterResource(if (isPlaying) R.drawable.ct_ic_pause else R.drawable.ct_ic_play)
    val mutePainter = painterResource(if (isMuted) R.drawable.ct_ic_volume_off_tint else R.drawable.ct_ic_volume_on_tint)
    val collapsePainter = painterResource(R.drawable.ct_ic_collapse)
    val actionPainter = painterResource(R.drawable.ct_ic_action)

    Box(
        modifier = Modifier.fillMaxSize().background(Color.Black)
    ) {
        // Fullscreen PlayerView — receives the player while Dialog is open
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                }
            },
            modifier = Modifier.fillMaxSize().align(Alignment.Center)
        )

        // Close (X) button — top end corner
        VideoControlIcon(
            painter = closePainter,
            contentDescription = "Close fullscreen",
            modifier = Modifier.align(Alignment.TopEnd).padding(12.dp),
            onClick = onDismiss
        )

        // Centered play/pause at 40dp for easier touch in fullscreen
        VideoControlIcon(
            painter = playPainter,
            contentDescription = if (isPlaying) "Pause" else "Play",
            size = 40.dp,
            modifier = Modifier.align(Alignment.Center),
            onClick = onTogglePlay
        )

        // Bottom row: action + mute + collapse
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(16.dp)
        ) {
            if (!openUrl.isNullOrEmpty()) {
                VideoControlIcon(
                    painter = actionPainter,
                    contentDescription = "Open URL",
                    onClick = {
                        runCatching {
                            context.startActivity(
                                Intent(Intent.ACTION_VIEW, Uri.parse(openUrl))
                            )
                        }
                    }
                )
            }
            VideoControlIcon(
                painter = mutePainter,
                contentDescription = if (isMuted) "Unmute" else "Mute",
                onClick = onToggleMute
            )
            VideoControlIcon(
                painter = collapsePainter,
                contentDescription = "Exit fullscreen",
                onClick = onDismiss
            )
=======
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
>>>>>>> origin/task/SDK-5399_ios
        }
    }
}
