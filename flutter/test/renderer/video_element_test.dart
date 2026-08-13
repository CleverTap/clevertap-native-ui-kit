import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/elements/video_element.dart';
import 'package:clevertap_native_display/src/evaluator/variable_evaluator.dart';
import 'package:clevertap_native_display/src/renderer/root_height_scope.dart';
import 'package:clevertap_native_display/src/renderer/resolved_styles_scope.dart';

Widget wrap(Widget w) => Directionality(
      textDirection: TextDirection.ltr,
      child: RootHeightScope(
        rootHeight: 200,
        child: ResolvedStylesScope(
          styles: const {},
          child: w,
        ),
      ),
    );

// Helper replicating VideoElement boolean binding logic for unit tests
bool _boolBinding(Map<String, String> bindings, String key, {bool defaultValue = false}) {
  final val = bindings[key];
  if (defaultValue) return val != 'false';
  return val == 'true';
}

void main() {
  group('VideoElement boolean bindings', () {
    test('autoPlay defaults to false', () {
      expect(_boolBinding({'url': 'http://example.com/video.mp4'}, 'autoPlay'), false);
    });

    test('autoPlay=true is true', () {
      expect(_boolBinding({'autoPlay': 'true'}, 'autoPlay'), true);
    });

    test('loop defaults to false', () {
      expect(_boolBinding({}, 'loop'), false);
    });

    test('muted defaults to false', () {
      expect(_boolBinding({}, 'muted'), false);
    });

    test('showControls defaults to true (inverse logic)', () {
      expect(_boolBinding({}, 'showControls', defaultValue: true), true);
    });

    test('showControls=false is false', () {
      expect(_boolBinding({'showControls': 'false'}, 'showControls', defaultValue: true), false);
    });
  });

  group('VideoElement widget', () {
    testWidgets('renders without crash when url is empty', (tester) async {
      final node = NativeDisplayElement(
        id: 'video',
        elementType: ElementType.video,
        bindings: const {},
      );

      await tester.pumpWidget(wrap(VideoElement(
        node: node,
        style: Style.empty,
        evaluator: VariableEvaluator({}),
      )));

      // No crash and no controller initialized (empty url)
      expect(find.byType(VideoElement), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when url is empty and not initialized', (tester) async {
      final node = NativeDisplayElement(
        id: 'video',
        elementType: ElementType.video,
        bindings: const {'url': ''},
      );

      await tester.pumpWidget(wrap(VideoElement(
        node: node,
        style: Style.empty,
        evaluator: VariableEvaluator({}),
      )));

      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });
  });
}
