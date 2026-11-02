import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:clevertap_native_display/clevertap_native_display.dart';

// ---------------------------------------------------------------------------
// Stable widget Key values applied to the VIDEO element's control buttons.
// Mirror Android's `ND_VIDEO_TEST_TAG_*` testTags / iOS's accessibility ids so
// a cross-platform test suite can target controls by the same identifier.
//
// Inline and fullscreen modes are mutually exclusive at any moment, so PLAY and
// MUTE re-use the same value across both — "tap play" works regardless of mode.
// ---------------------------------------------------------------------------
const String ndVideoTestTagPlay = 'nd_video_play';
const String ndVideoTestTagMute = 'nd_video_mute';
const String ndVideoTestTagExpand = 'nd_video_expand';
const String ndVideoTestTagClose = 'nd_video_close';
const String ndVideoTestTagCollapse = 'nd_video_collapse';

class VideoElement extends StatefulWidget {
  final NativeDisplayElement node;
  final Style style;
  final VariableEvaluator evaluator;

  const VideoElement({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
  });

  @override
  State<VideoElement> createState() => _VideoElementState();
}

class _VideoElementState extends State<VideoElement> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  String get _url =>
      widget.evaluator.evaluateString(widget.node.bindings['url'] ?? '');
  bool get _autoPlay => _boolBinding('autoPlay', defaultValue: false);
  bool get _loop => _boolBinding('loop', defaultValue: false);
  bool get _muted => _boolBinding('muted', defaultValue: false);
  bool get _showControls => _boolBinding('showControls', defaultValue: true);
  bool get _showFullscreen => _boolBinding('showFullscreen', defaultValue: true);

  // Template-evaluate boolean flags so {{var}} bindings resolve — parity with
  // Android/iOS, which run VIDEO flags through evaluateBoolean. An absent/empty
  // binding keeps the flag's default (evaluateBoolean(null) would return true,
  // which is wrong for e.g. autoPlay).
  bool _boolBinding(String key, {required bool defaultValue}) {
    final raw = widget.node.bindings[key];
    if (raw == null || raw.isEmpty) return defaultValue;
    return widget.evaluator.evaluateBoolean(raw);
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final url = _url;
    if (url.isEmpty) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    try {
      await controller.initialize();
    } catch (_) {
      // Error state is surfaced from controller.value.hasError in build().
    }
    if (!mounted) return;
    controller.setLooping(_loop);
    controller.setVolume(_muted ? 0.0 : 1.0);
    setState(() => _initialized = true);
    if (_autoPlay) controller.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rootHeight = NativeDisplayScope.rootHeightOf(context);
    final url = _url;

    Widget content;
    final controller = _controller;
    if (url.isEmpty) {
      return const SizedBox.shrink();
    } else if (controller != null && controller.value.hasError) {
      // Error state — mirrors Android VideoRenderer lines 318-329: dark-grey box
      // filling the area with white 12px centered errorDescription text.
      content = _VideoMessageBox(
        background: const Color(0xFF444444),
        child: Text(
          controller.value.errorDescription ?? 'Unknown error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else if (!_initialized || controller == null) {
      // Loading state — mirrors Android lines 361-367: black box, white 14px.
      content = const _VideoMessageBox(
        background: Colors.black,
        child: Text(
          'Loading...',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    } else {
      content = _InlineVideo(
        controller: controller,
        showControls: _showControls,
        showFullscreen: _showFullscreen,
      );
    }

    return RepaintBoundary(
      child: StyleApplier.apply(
        content,
        widget.style,
        rootHeight: rootHeight,
        padding: widget.node.layout?.padding,
      ),
    );
  }
}

/// Simple centered message box (loading / error states).
class _VideoMessageBox extends StatelessWidget {
  final Color background;
  final Widget child;

  const _VideoMessageBox({required this.background, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Inline video surface with tap-to-toggle custom controls overlay.
class _InlineVideo extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final bool showFullscreen;

  const _InlineVideo({
    required this.controller,
    required this.showControls,
    required this.showFullscreen,
  });

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  bool _showControlsUI = false;
  Timer? _hideTimer;

  VideoPlayerController get _controller => widget.controller;

  @override
  void dispose() {
    // Critical: a pending auto-hide Timer fails widget tests ("Timer still
    // pending") and leaks after unmount.
    _hideTimer?.cancel();
    super.dispose();
  }

  void _toggleControlsUI() {
    setState(() => _showControlsUI = !_showControlsUI);
    _scheduleAutoHide();
  }

  // Starts/resets a 3-second auto-hide whenever the overlay is shown.
  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    if (!_showControlsUI) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControlsUI = false);
    });
  }

  void _togglePlayPause() {
    final value = _controller.value;
    if (value.isPlaying) {
      _controller.pause();
    } else {
      // If playback has ended, restart from the beginning before playing.
      if (value.position >= value.duration && value.duration > Duration.zero) {
        _controller.seekTo(Duration.zero);
      }
      _controller.play();
    }
  }

  void _toggleMute() {
    _controller.setVolume(_controller.value.volume == 0 ? 1.0 : 0.0);
  }

  // TODO(openUrl): native renders an action-url control that launches the
  // configured URL. Deferred on Flutter — opening an external URL requires a
  // launch mechanism (e.g. url_launcher) and we add no new dependencies here.

  void _openFullscreen() {
    _hideTimer?.cancel();
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _FullscreenVideo(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds overlay glyphs (play/pause, mute) as the shared
    // controller's value changes.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final video = Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        );

        if (!widget.showControls) {
          return video;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            video,
            // Full-area tap target — toggles overlay visibility. Opaque so the
            // gesture wins over the underlying VideoPlayer texture.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControlsUI,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ControlsBar(
                visible: _showControlsUI,
                children: [
                  _VideoControlIcon(
                    buttonKey: const Key(ndVideoTestTagPlay),
                    icon: _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    onTap: _togglePlayPause,
                  ),
                  _VideoControlIcon(
                    buttonKey: const Key(ndVideoTestTagMute),
                    icon: _controller.value.volume == 0
                        ? Icons.volume_off
                        : Icons.volume_up,
                    onTap: _toggleMute,
                  ),
                  if (widget.showFullscreen)
                    _VideoControlIcon(
                      buttonKey: const Key(ndVideoTestTagExpand),
                      icon: Icons.fullscreen,
                      onTap: _openFullscreen,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fullscreen page. Shares the SAME [VideoPlayerController] as the inline view —
/// it never creates nor disposes a controller; the inline element owns its
/// lifecycle. Close and collapse both pop back to inline.
class _FullscreenVideo extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideo({required this.controller});

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  bool _showControlsUI = true;
  Timer? _hideTimer;

  VideoPlayerController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    // Intentionally does NOT dispose _controller — owned by the inline element.
    super.dispose();
  }

  void _toggleControlsUI() {
    setState(() => _showControlsUI = !_showControlsUI);
    _scheduleAutoHide();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    if (!_showControlsUI) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControlsUI = false);
    });
  }

  void _togglePlayPause() {
    final value = _controller.value;
    if (value.isPlaying) {
      _controller.pause();
    } else {
      if (value.position >= value.duration && value.duration > Duration.zero) {
        _controller.seekTo(Duration.zero);
      }
      _controller.play();
    }
  }

  void _toggleMute() {
    _controller.setVolume(_controller.value.volume == 0 ? 1.0 : 0.0);
  }

  void _pop() {
    _hideTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControlsUI,
                ),
              ),
              // Close (X) — top end corner.
              Positioned(
                top: 12,
                right: 12,
                child: _ControlsBar(
                  visible: _showControlsUI,
                  children: [
                    _VideoControlIcon(
                      buttonKey: const Key(ndVideoTestTagClose),
                      icon: Icons.close,
                      onTap: _pop,
                    ),
                  ],
                ),
              ),
              // Bottom row: play/pause + mute + collapse.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ControlsBar(
                  visible: _showControlsUI,
                  children: [
                    _VideoControlIcon(
                      buttonKey: const Key(ndVideoTestTagPlay),
                      icon: _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      onTap: _togglePlayPause,
                    ),
                    _VideoControlIcon(
                      buttonKey: const Key(ndVideoTestTagMute),
                      icon: _controller.value.volume == 0
                          ? Icons.volume_off
                          : Icons.volume_up,
                      onTap: _toggleMute,
                    ),
                    _VideoControlIcon(
                      buttonKey: const Key(ndVideoTestTagCollapse),
                      icon: Icons.fullscreen_exit,
                      onTap: _pop,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bottom-left Row of control buttons with 12px padding, 12px spacing, and a
/// 300ms fade. Mirrors Android's AnimatedVisibility + bottom-start Row.
class _ControlsBar extends StatelessWidget {
  final bool visible;
  final List<Widget> children;

  const _ControlsBar({required this.visible, required this.children});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A ~32px white Material icon on a small semi-transparent rounded chip.
class _VideoControlIcon extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final VoidCallback onTap;

  const _VideoControlIcon({
    required this.buttonKey,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }
}
