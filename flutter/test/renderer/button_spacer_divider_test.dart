import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/elements/button_element.dart';
import 'package:clevertap_native_display/src/renderer/elements/spacer_element.dart';
import 'package:clevertap_native_display/src/renderer/elements/divider_element.dart';
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

void main() {
  group('ButtonElement', () {
    testWidgets('renders GestureDetector wrapping content', (tester) async {
      final node = NativeDisplayElement(
        id: 'btn',
        elementType: ElementType.button,
        bindings: {'text': 'Click Me'},
      );

      await tester.pumpWidget(wrap(ButtonElement(
        node: node,
        style: Style.empty,
        evaluator: VariableEvaluator({}),
      )));

      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('fires actionListener on tap', (tester) async {
      String? capturedAction;
      String? capturedNodeId;

      final action = NDAction.fromJson({'type': 'custom', 'key': 'test'});
      final node = NativeDisplayElement(
        id: 'btn',
        elementType: ElementType.button,
        bindings: {'text': 'Tap'},
        actions: {'onClick': action},
      );

      await tester.pumpWidget(wrap(ButtonElement(
        node: node,
        style: Style.empty,
        evaluator: VariableEvaluator({}),
        actionListener: (action, nodeId, params) {
          capturedAction = action;
          capturedNodeId = nodeId;
        },
      )));

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(capturedAction, 'action');
      expect(capturedNodeId, 'btn');
    });

    testWidgets('no actionListener called when no onClick action', (tester) async {
      bool called = false;
      final node = NativeDisplayElement(
        id: 'btn',
        elementType: ElementType.button,
        bindings: {'text': 'Tap'},
      );

      await tester.pumpWidget(wrap(ButtonElement(
        node: node,
        style: Style.empty,
        evaluator: VariableEvaluator({}),
        actionListener: (_, __, ___) => called = true,
      )));

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(called, false);
    });
  });

  group('SpacerElement', () {
    testWidgets('match_parent width returns Spacer widget', (tester) async {
      final node = NativeDisplayElement(
        id: 'spacer',
        elementType: ElementType.spacer,
        layout: Layout.fromJson({
          'width': {'special': 'match_parent'},
        }),
      );

      await tester.pumpWidget(wrap(Row(children: [
        SpacerElement(node: node, style: Style.empty),
      ])));

      expect(find.byType(Spacer), findsOneWidget);
    });

    testWidgets('match_parent height returns Spacer widget', (tester) async {
      final node = NativeDisplayElement(
        id: 'spacer',
        elementType: ElementType.spacer,
        layout: Layout.fromJson({
          'height': {'special': 'match_parent'},
        }),
      );

      await tester.pumpWidget(wrap(Column(children: [
        SpacerElement(node: node, style: Style.empty),
      ])));

      expect(find.byType(Spacer), findsOneWidget);
    });

    testWidgets('fixed dimensions return SizedBox', (tester) async {
      final node = NativeDisplayElement(
        id: 'spacer',
        elementType: ElementType.spacer,
        layout: Layout.fromJson({
          'width': {'value': 16, 'unit': 'dp'},
          'height': {'value': 8, 'unit': 'dp'},
        }),
      );

      await tester.pumpWidget(wrap(SpacerElement(node: node, style: Style.empty)));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 16);
      expect(sizedBox.height, 8);
    });
  });

  group('DividerElement', () {
    testWidgets('horizontal divider has infinite width and configured thickness', (tester) async {
      final node = NativeDisplayElement(
        id: 'divider',
        elementType: ElementType.divider,
        dividerConfig: DividerConfig.fromJson({
          'orientation': 'horizontal',
          'thickness': 2.0,
          'color': '#FF0000',
        }),
      );

      await tester.pumpWidget(wrap(
        SizedBox(width: 200, child: DividerElement(node: node, style: Style.empty)),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).last);
      expect(sizedBox.height, 2.0);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('vertical divider has infinite height and configured thickness', (tester) async {
      final node = NativeDisplayElement(
        id: 'divider',
        elementType: ElementType.divider,
        dividerConfig: DividerConfig.fromJson({
          'orientation': 'vertical',
          'thickness': 3.0,
          'color': '#0000FF',
        }),
      );

      await tester.pumpWidget(wrap(
        SizedBox(height: 200, child: DividerElement(node: node, style: Style.empty)),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).last);
      expect(sizedBox.width, 3.0);
      expect(sizedBox.height, double.infinity);
    });

    testWidgets('default divider uses 1.0 thickness and #E0E0E0 color', (tester) async {
      final node = NativeDisplayElement(
        id: 'divider',
        elementType: ElementType.divider,
      );

      await tester.pumpWidget(wrap(
        SizedBox(width: 200, child: DividerElement(node: node, style: Style.empty)),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).last);
      expect(sizedBox.height, 1.0);
    });
  });
}
