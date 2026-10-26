import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display_video/clevertap_native_display_video.dart';

// Regression test locking in #54 VIDEO controls tap reliability: the controls
// overlay is a full-area GestureDetector with HitTestBehavior.opaque so a tap
// anywhere over the video toggles play/pause instead of being swallowed by the
// underlying video texture. Matches Android/iOS tap-anywhere behaviour.
//
// Real playback needs a platform backend, so we install a fake
// VideoPlayerPlatform that reports the player as initialized. That lets the
// controls overlay build and lets us drive/observe play/pause through taps.
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform with MockPlatformInterfaceMixin {
  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    // Emit `initialized` as soon as the controller subscribes, so its
    // `initialize()` future completes deterministically. (A one-shot stream
    // avoids the broadcast race where an event fired before subscription is
    // dropped.)
    return Stream<VideoEvent>.fromIterable([
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 10),
        size: const Size(320, 240),
      ),
    ]);
  }

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) => const SizedBox.expand();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox.expand();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerPlatform original;

  setUp(() {
    original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
  });

  tearDown(() {
    VideoPlayerPlatform.instance = original;
  });

  Widget wrap(Widget w) => Directionality(
        textDirection: TextDirection.ltr,
        child: NativeDisplayScope(
          rootHeight: 200,
          styles: const {},
          unitId: null,
          onClicked: null,
          child: Center(child: SizedBox(width: 320, height: 240, child: w)),
        ),
      );

  NativeDisplayElement videoNode({Map<String, String> extra = const {}}) => NativeDisplayElement(
        id: 'video',
        elementType: ElementType.video,
        bindings: {'url': 'https://example.com/v.mp4', ...extra},
      );

  testWidgets('controls overlay uses an opaque full-area GestureDetector', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    // Let initialize() complete and rebuild with controls.
    await tester.pumpAndSettle();

    final gd = tester.widget<GestureDetector>(find.byType(GestureDetector));
    expect(gd.behavior, HitTestBehavior.opaque,
        reason: 'the controls tap target must win over the video texture');
    expect(gd.onTap, isNotNull);
  });

  testWidgets('tapping the controls overlay toggles play/pause', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    await tester.pumpAndSettle();

    // Paused initially (no autoPlay) → the play glyph is shown.
    expect(find.byType(Icon), findsOneWidget, reason: 'play glyph visible when paused');

    // Tap toggles to playing → the play glyph is hidden.
    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();
    expect(find.byType(Icon), findsNothing, reason: 'play glyph hidden when playing');

    // Tap again toggles back to paused → glyph returns.
    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();
    expect(find.byType(Icon), findsOneWidget, reason: 'play glyph visible again when paused');
  });

  testWidgets('showControls=false renders no gesture overlay', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(extra: const {'showControls': 'false'}),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    await tester.pumpAndSettle();

    expect(find.byType(GestureDetector), findsNothing);
  });
}
