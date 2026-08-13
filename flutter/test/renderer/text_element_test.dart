import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/elements/text_element.dart';
import 'package:clevertap_native_display/src/evaluator/variable_evaluator.dart';
import 'package:clevertap_native_display/src/renderer/root_height_scope.dart';
import 'package:clevertap_native_display/src/renderer/resolved_styles_scope.dart';

void main() {
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
        TextElement(node: node, style: Style.empty, evaluator: VariableEvaluator({})),
      ));

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('evaluates variable template in text', (tester) async {
      final node = makeTextElement(text: 'Hi {{name}}');
      await tester.pumpWidget(wrap(
        TextElement(
          node: node,
          style: Style.empty,
          evaluator: VariableEvaluator({'name': 'Alice'}),
        ),
      ));

      expect(find.text('Hi Alice'), findsOneWidget);
    });

    testWidgets('applies fontWeight bold', (tester) async {
      final style = Style.fromJson({'fontWeight': 'bold'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('applies fontWeight light', (tester) async {
      final style = Style.fromJson({'fontWeight': 'light'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontWeight, FontWeight.w300);
    });

    testWidgets('wraps with ShaderMask when textGradient set', (tester) async {
      final style = Style.fromJson({
        'textGradient': {
          'colors': ['#FF0000', '#0000FF'],
          'angle': 90.0,
        },
      });
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: VariableEvaluator({})),
      ));

      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('textAlign center maps correctly', (tester) async {
      final style = Style.fromJson({'textAlign': 'center'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('textColor applied to TextStyle', (tester) async {
      final style = Style.fromJson({'textColor': '#FF0000'});
      final node = makeTextElement();

      await tester.pumpWidget(wrap(
        TextElement(node: node, style: style, evaluator: VariableEvaluator({})),
      ));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color?.toARGB32(), 0xFFFF0000);
    });
  });
}
