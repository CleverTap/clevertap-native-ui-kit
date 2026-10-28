import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(NativeDisplayRenderers.clear);
  tearDown(NativeDisplayRenderers.clear);

  NativeDisplayConfig videoConfig() => NativeDisplayConfig.fromJson({
        'root': {
          'type': 'element',
          'id': 'root',
          'elementType': 'video',
          'bindings': {'url': 'https://example.com/v.mp4'},
          'layout': {
            'width': {'value': 200, 'unit': 'dp'},
            'height': {'value': 100, 'unit': 'dp'},
          },
        },
      });

  group('pluggable VIDEO/HTML renderers', () {
    testWidgets('unregistered VIDEO renders nothing and does not crash', (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: NativeDisplayView(config: videoConfig()),
      ));
      expect(tester.takeException(), isNull);
      expect(NativeDisplayRenderers.builderFor(ElementType.video), isNull);
    });

    testWidgets('registered VIDEO builder is used', (tester) async {
      NativeDisplayRenderers.register(
        ElementType.video,
        (node, style, evaluator) =>
            const Text('VIDEO-HERE', textDirection: TextDirection.ltr),
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: NativeDisplayView(config: videoConfig()),
      ));
      expect(find.text('VIDEO-HERE'), findsOneWidget);
    });

    test('register / builderFor / unregister / clear', () {
      expect(NativeDisplayRenderers.builderFor(ElementType.html), isNull);
      NativeDisplayRenderers.register(ElementType.html, (n, s, e) => const SizedBox());
      expect(NativeDisplayRenderers.builderFor(ElementType.html), isNotNull);
      NativeDisplayRenderers.unregister(ElementType.html);
      expect(NativeDisplayRenderers.builderFor(ElementType.html), isNull);
    });
  });
}
