import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/elements/text_element.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => Directionality(
        textDirection: TextDirection.ltr,
        child: NativeDisplayScope(
          rootHeight: 200,
          styles: const {},
          unitId: null,
          onClicked: null,
          child: w,
        ),
      );

  NativeDisplayElement makeTextElement({
    String id = 'text1',
    String text = 'Hello',
    Style? style,
  }) {
    return NativeDisplayElement(
      id: id,
      elementType: ElementType.text,
      bindings: {'text': text},
      style: style,
    );
  }

  group('TextElement', () {
    testWidgets('renders Text widget with text from bindings', (tester) async {
      final node = makeTextElement(text: 'Hello World');
      await tester.pumpWidget(wrap(
        TextElement(node: node, style: Style.empty, evaluator: const VariableEvaluator({})),
      ));

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('evaluates variable template in text', (tester) async {
      final node = makeTextElement(text: 'Hi {{name}}');
      await tester.pumpWidget(wrap(
        TextElement(
          node: node,
          style: Style.empty,
          evaluator: const VariableEvaluator({'name': 'Alice'}),
        ),
      ));

      expect(find.text('Hi Alice'), findsOneWidget);
    });

    testWidgets('applies fontWeight bold', (tester) async {
      final style = Style.fromJson(const {'fontWeight': 'bold'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: const VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('applies fontWeight light', (tester) async {
      final style = Style.fromJson(const {'fontWeight': 'light'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: const VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontWeight, FontWeight.w300);
    });

    testWidgets('wraps with ShaderMask when textGradient set', (tester) async {
      final style = Style.fromJson(const {
        'textGradient': {
          'colors': ['#FF0000', '#0000FF'],
          'angle': 90.0,
        },
      });
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: const VariableEvaluator({})),
      ));

      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('textAlign center maps correctly', (tester) async {
      final style = Style.fromJson(const {'textAlign': 'center'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: const VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('textColor applied to TextStyle', (tester) async {
      final style = Style.fromJson(const {'textColor': '#FF0000'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: const VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color?.toARGB32(), 0xFFFF0000);
    });
  });
}
