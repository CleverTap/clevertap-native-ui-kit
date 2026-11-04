import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display_video/clevertap_native_display_video.dart';

// Tests for the custom VIDEO controls overlay (parity with Android/iOS).
//
// Behaviour model: tapping the video surface toggles the control-overlay
// visibility (NOT play/pause directly). The overlay carries play/pause, mute
// and fullscreen-expand controls, fades via AnimatedOpacity, and auto-hides
// after 3 seconds.
//
// Real playback needs a platform backend, so we install a fake
// VideoPlayerPlatform that reports the player as initialized. That lets the
// controls overlay build and lets us drive/observe state through taps.
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

  Widget wrap(Widget w) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: NativeDisplayScope(
            rootHeight: 200,
            styles: const {},
            unitId: null,
            onClicked: null,
            child: Center(child: SizedBox(width: 320, height: 240, child: w)),
          ),
        ),
      );

  NativeDisplayElement videoNode({Map<String, String> extra = const {}}) => NativeDisplayElement(
        id: 'video',
        elementType: ElementType.video,
        bindings: {'url': 'https://example.com/v.mp4', ...extra},
      );

  // Finds the full-area surface GestureDetector (opaque, full-area) — the tap
  // layer that toggles overlay visibility. It is the only GestureDetector with
  // no Key (the control buttons each carry a Key).
  Finder surfaceTap() => find.byWidgetPredicate(
        (w) => w is GestureDetector && w.key == null && w.behavior == HitTestBehavior.opaque,
      );

  // Reads the opacity of the inline controls bar (there may be several
  // AnimatedOpacity widgets in fullscreen; inline has exactly one).
  double overlayOpacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity;

  // Flushes the pending 3s auto-hide Timer so the test ends cleanly.
  Future<void> drainTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('controls overlay uses an opaque full-area GestureDetector', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    await tester.pumpAndSettle();

    final gd = tester.widget<GestureDetector>(surfaceTap());
    expect(gd.behavior, HitTestBehavior.opaque,
        reason: 'the surface tap target must win over the video texture');
    expect(gd.onTap, isNotNull);

    await drainTimers(tester);
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

  testWidgets('tapping the surface toggles controls, then play/pause works', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    await tester.pumpAndSettle();

    // Controls hidden initially.
    expect(overlayOpacity(tester), 0.0, reason: 'overlay hidden until surface tap');

    // Tap surface → controls fade in.
    await tester.tap(surfaceTap());
    await tester.pumpAndSettle();
    expect(overlayOpacity(tester), 1.0, reason: 'overlay visible after surface tap');

    // Paused initially → play glyph shown.
    final playBtn = find.byKey(const Key(ndVideoTestTagPlay));
    expect(playBtn, findsOneWidget);
    expect(
      tester.widget<Icon>(find.descendant(of: playBtn, matching: find.byType(Icon))).icon,
      Icons.play_arrow,
    );

    // Tap play → playing → pause glyph.
    await tester.tap(playBtn);
    await tester.pump();
    expect(
      tester.widget<Icon>(find.descendant(of: playBtn, matching: find.byType(Icon))).icon,
      Icons.pause,
    );

    // Tap again → paused → play glyph.
    await tester.tap(playBtn);
    await tester.pump();
    expect(
      tester.widget<Icon>(find.descendant(of: playBtn, matching: find.byType(Icon))).icon,
      Icons.play_arrow,
    );

    await drainTimers(tester);
  });

  testWidgets('mute toggle flips the icon', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    await tester.pumpAndSettle();

    await tester.tap(surfaceTap());
    await tester.pumpAndSettle();

    final muteBtn = find.byKey(const Key(ndVideoTestTagMute));
    expect(muteBtn, findsOneWidget);
    // Not muted by default → volume_up.
    expect(
      tester.widget<Icon>(find.descendant(of: muteBtn, matching: find.byType(Icon))).icon,
      Icons.volume_up,
    );

    await tester.tap(muteBtn);
    await tester.pump();
    expect(
      tester.widget<Icon>(find.descendant(of: muteBtn, matching: find.byType(Icon))).icon,
      Icons.volume_off,
    );

    await drainTimers(tester);
  });

  testWidgets('tapping expand pushes a fullscreen route with a close control', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    await tester.pumpAndSettle();

    await tester.tap(surfaceTap());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key(ndVideoTestTagClose)), findsNothing);

    await tester.tap(find.byKey(const Key(ndVideoTestTagExpand)));
    await tester.pumpAndSettle();

    // Fullscreen route pushed — its close + collapse controls are present.
    expect(find.byKey(const Key(ndVideoTestTagClose)), findsOneWidget);
    expect(find.byKey(const Key(ndVideoTestTagCollapse)), findsOneWidget);

    // Collapse pops back to inline.
    await tester.tap(find.byKey(const Key(ndVideoTestTagCollapse)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key(ndVideoTestTagClose)), findsNothing);

    await drainTimers(tester);
  });

  testWidgets('overlay auto-hides after 3 seconds', (tester) async {
    await tester.pumpWidget(wrap(VideoElement(
      node: videoNode(),
      style: Style.empty,
      evaluator: VariableEvaluator({}),
    )));
    await tester.pumpAndSettle();

    await tester.tap(surfaceTap());
    await tester.pumpAndSettle();
    expect(overlayOpacity(tester), 1.0);

    // Fire the auto-hide timer, then settle the fade.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(overlayOpacity(tester), 0.0, reason: 'overlay auto-hides after 3s');
  });
}
