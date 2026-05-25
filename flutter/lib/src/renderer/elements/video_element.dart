import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import '../../evaluator/variable_evaluator.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../root_height_scope.dart';
import '../style_applier.dart';

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

  String get _url => widget.evaluator.evaluateString(widget.node.bindings['url'] ?? '');
  bool get _autoPlay => widget.node.bindings['autoPlay'] == 'true';
  bool get _loop => widget.node.bindings['loop'] == 'true';
  bool get _muted => widget.node.bindings['muted'] == 'true';
  bool get _showControls => widget.node.bindings['showControls'] != 'false';

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
    await controller.initialize();
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
    final rootHeight = RootHeightScope.of(context);

    Widget content;
    if (!_initialized || _controller == null) {
      content = const SizedBox.shrink();
    } else {
      Widget video = AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );

      if (_showControls) {
        video = Stack(
          alignment: Alignment.center,
          children: [
            video,
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: _controller!.value.isPlaying
                  ? const SizedBox.shrink()
                  : const Icon(IconData(0xe037, fontFamily: 'MaterialIcons'),
                      size: 48, color: Color(0xCCFFFFFF)),
            ),
          ],
        );
      }
      content = video;
    }

    return StyleApplier.apply(
      content,
      widget.style,
      rootHeight: rootHeight,
      padding: widget.node.layout?.padding,
    );
  }
}
