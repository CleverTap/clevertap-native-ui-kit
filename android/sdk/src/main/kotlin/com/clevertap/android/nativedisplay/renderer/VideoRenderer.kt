package com.clevertap.android.nativedisplay.renderer

import android.content.Intent
import android.net.Uri

import android.view.LayoutInflater
import androidx.annotation.OptIn
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.DeviceInfo
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Metadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.Timeline
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.text.Cue
import androidx.media3.common.text.CueGroup
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.clevertap.android.nativedisplay.internal.NDLogger
import com.clevertap.android.nativeui.R
import kotlinx.coroutines.delay
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight

/**
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
 * Video player composable with custom controls.
 * Supports Media3 ExoPlayer with runtime detection and graceful degradation.
 */
@OptIn(UnstableApi::class)
@Composable
internal fun VideoPlayer(
    videoUrl: String,
    autoPlay: Boolean = false,
    loop: Boolean = false,
    muted: Boolean = false,
    showControls: Boolean = true,
    showFullscreen: Boolean = true,
    openUrl: String? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    // Single runtime check for Media3 availability
    val isMedia3Available = remember {
        runCatching {
            Class.forName("androidx.media3.exoplayer.ExoPlayer")
        }.onSuccess {
            NDLogger.d("VideoPlayer", "Media3 is available")
        }.onFailure {
            NDLogger.w("VideoPlayer", "Media3 not found - add androidx.media3 dependencies")
        }.isSuccess
    }

    if (!isMedia3Available) {
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

    VideoPlayerWithMedia3(
        context = context,
        videoUrl = videoUrl,
        autoPlay = autoPlay,
        loop = loop,
        muted = muted,
        showControls = showControls,
        showFullscreen = showFullscreen,
        openUrl = openUrl,
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
 *
 * Fullscreen is implemented via a Compose Dialog with usePlatformDefaultWidth=false
 * so it fills the screen. The ExoPlayer instance is transferred between the inline
 * PlayerView and the fullscreen PlayerView — the inactive surface sets player=null
 * to detach cleanly.
 */
@UnstableApi // added due to media3 overrides.
@Composable
internal fun VideoPlayerWithMedia3(
    context: android.content.Context,
    videoUrl: String,
    autoPlay: Boolean,
    loop: Boolean,
    muted: Boolean,
    showControls: Boolean,
    showFullscreen: Boolean,
    openUrl: String?,
    modifier: Modifier
) {
    val lifecycleOwner = LocalLifecycleOwner.current

    var showControlsUI by remember { mutableStateOf(false) }
    var isPlaying by remember { mutableStateOf(autoPlay) }
    var isMuted by remember { mutableStateOf(muted) }
    var isEnded by remember { mutableStateOf(false) }
    var isFullscreen by remember { mutableStateOf(false) }
    var errorMessage by remember(videoUrl) { mutableStateOf<String?>(null) }

    val exoPlayer = remember(videoUrl) {
        runCatching {
            ExoPlayer.Builder(context)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(C.USAGE_MEDIA)
                        .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                        .build(),
                    /* handleAudioFocus= */ true
                )
                .build().apply {
                    setMediaItem(MediaItem.fromUri(videoUrl))
                    prepare()
                    playWhenReady = autoPlay
                    repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
                    volume = if (muted) 0f else 1f
                }.also {
                    NDLogger.d("VideoPlayer", "Player created for: $videoUrl")
                }
        }.onFailure { e ->
            errorMessage = "Failed to create player: ${e.message}"
            NDLogger.e("VideoPlayer", "Player creation failed", e)
        }.getOrNull()
    }

    DisposableEffect(lifecycleOwner, exoPlayer) {
        exoPlayer?.let { player ->
            val observer = LifecycleEventObserver { _, event ->
                when (event) {
                    Lifecycle.Event.ON_PAUSE -> player.pause()
                    Lifecycle.Event.ON_RESUME -> if (autoPlay) player.play()
                    else -> Unit
                }
            }
            val listener = object : Media3PlayerListener() {
                override fun onIsPlayingChanged(playing: Boolean) { isPlaying = playing }
                override fun onVolumeChanged(volume: Float) { isMuted = volume == 0f }
                override fun onPlaybackStateChanged(state: Int) {
                    isEnded = state == Player.STATE_ENDED
                    if (state == Player.STATE_READY) errorMessage = null
                }
                override fun onPlayerError(error: PlaybackException) {
                    errorMessage = "Video playback failed"
                    NDLogger.e("VideoPlayer", "Playback error (${error.errorCodeName})", error)
                }
            }
            lifecycleOwner.lifecycle.addObserver(observer)
            player.addListener(listener)
            onDispose {
                lifecycleOwner.lifecycle.removeObserver(observer)
                player.removeListener(listener)
                player.release()
                NDLogger.d("VideoPlayer", "Player released")
            }
        } ?: onDispose { }
    }

    LaunchedEffect(showControlsUI) {
        if (showControlsUI) {
            delay(3000)
            showControlsUI = false
        }
    }

    // Hoist painter references to avoid repeated resource lookups inside recomposing lambdas
    val playPainter = painterResource(if (isPlaying) R.drawable.ct_ic_pause else R.drawable.ct_ic_play)
    val mutePainter = painterResource(if (isMuted) R.drawable.ct_ic_volume_off_tint else R.drawable.ct_ic_volume_on_tint)
    val expandPainter = painterResource(R.drawable.ct_ic_expand)
    val actionPainter = painterResource(R.drawable.ct_ic_action)

    Box(modifier = modifier) {
        when {
            errorMessage != null -> {
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.DarkGray),
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
                // Removed from the tree entirely while fullscreen is active — no need to
                // null out player on the view; the fullscreen PlayerView takes ownership.
                // Inflated from XML so surface_type="texture_view" is applied at construction.
                if (!isFullscreen) {
                    AndroidView(
                        factory = { ctx ->
                            (LayoutInflater.from(ctx).inflate(
                                R.layout.ct_player_view, null
                            ) as PlayerView).apply {
                                player = exoPlayer
                            }
                        },
                        update = { view ->
                            view.player = exoPlayer
                            view.setOnClickListener {
                                if (showControls) showControlsUI = !showControlsUI
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
            else -> {
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.Black),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Loading...", color = Color.White, fontSize = 14.sp)
                }
            }
        }

        // Inline controls overlay — bottom-start aligned, fades in/out
        if (showControls && exoPlayer != null) {
            AnimatedVisibility(
                visible = showControlsUI,
                enter = fadeIn(animationSpec = tween(300)),
                exit = fadeOut(animationSpec = tween(300)),
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
                            // isMuted is updated by Player.Listener.onVolumeChanged
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
                        // isMuted is updated by Player.Listener.onVolumeChanged
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
                (LayoutInflater.from(ctx).inflate(
                    R.layout.ct_player_view, null
                ) as PlayerView).apply {
                    player = exoPlayer
                }
            },
            update = { view -> view.player = exoPlayer },
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
        }
    }


}

@UnstableApi
/**
 * This class addresses an AbstractMethodError because of the Java 8 feature of default methods in interfaces.
 * Default methods are somewhat not supported if minSDKVersion < 24
 */
open class Media3PlayerListener : Player.Listener {
    override fun onSurfaceSizeChanged(width: Int, height: Int) {}
    override fun onRenderedFirstFrame() {}
    @Deprecated("Deprecated in Java")
    override fun onCues(cues: MutableList<Cue>) {}
    override fun onCues(cueGroup: CueGroup) {}
    override fun onMetadata(metadata: Metadata) {}
    override fun onEvents(player: Player, events: Player.Events) {}
    override fun onTimelineChanged(timeline: Timeline, reason: Int) {}
    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {}
    override fun onTracksChanged(tracks: Tracks) {}
    override fun onMediaMetadataChanged(mediaMetadata: MediaMetadata) {}
    override fun onPlaylistMetadataChanged(mediaMetadata: MediaMetadata) {}
    override fun onIsLoadingChanged(isLoading: Boolean) {}
    override fun onAvailableCommandsChanged(availableCommands: Player.Commands) {}
    override fun onTrackSelectionParametersChanged(parameters: TrackSelectionParameters) {}
    override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {}
    override fun onPlaybackSuppressionReasonChanged(playbackSuppressionReason: Int) {}
    override fun onIsPlayingChanged(isPlaying: Boolean) {}
    override fun onRepeatModeChanged(repeatMode: Int) {}
    override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {}
    override fun onPlayerError(error: PlaybackException) {}
    override fun onPlayerErrorChanged(error: PlaybackException?) {}
    override fun onPositionDiscontinuity(
        oldPosition: Player.PositionInfo,
        newPosition: Player.PositionInfo,
        reason: Int
    ) {}
    override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {}
    override fun onSeekBackIncrementChanged(seekBackIncrementMs: Long) {}
    override fun onSeekForwardIncrementChanged(seekForwardIncrementMs: Long) {}
    override fun onMaxSeekToPreviousPositionChanged(maxSeekToPreviousPositionMs: Long) {}
    override fun onAudioSessionIdChanged(audioSessionId: Int) {}
    override fun onAudioAttributesChanged(audioAttributes: AudioAttributes) {}
    override fun onVolumeChanged(volume: Float) {}
    override fun onSkipSilenceEnabledChanged(skipSilenceEnabled: Boolean) {}
    override fun onDeviceInfoChanged(deviceInfo: DeviceInfo) {}
    override fun onDeviceVolumeChanged(volume: Int, muted: Boolean) {}
    override fun onVideoSizeChanged(videoSize: VideoSize) {}
}
