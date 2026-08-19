import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/containers/box_container.dart';
import 'package:clevertap_native_display/src/evaluator/variable_evaluator.dart';
import 'package:clevertap_native_display/src/renderer/native_display_scope.dart';

// Regression tests locking in #54 BOX hit-testing parity: a non-interactive
// child stacked in a BOX must not swallow taps destined for an interactive
// sibling — the pointer falls through the non-interactive node. Android
// (Compose Box) and iOS (SwiftUI ZStack) behave the same; this guards against
// Flutter's Stack regressing (e.g. someone wrapping children in an opaque
// GestureDetector or ignore-pointer barrier).
void main() {
  Widget wrap(Widget w) => Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: NativeDisplayScope(
          rootHeight: 200,
          styles: const {},
          unitId: null,
          onClicked: null,
          child: w,
        ),
        ),
      );

  testWidgets('non-interactive top child does not swallow the tap to a lower button',
      (tester) async {
    var lowerTaps = 0;

    // Lower interactive BUTTON + top non-interactive TEXT in the same BOX.
    final lower = NativeDisplayElement(
      id: 'lower',
      elementType: ElementType.button,
      bindings: const {'text': 'tap-me'},
      actions: {ActionTriggers.onClick: const CustomAction(key: 'lower_click')},
    );
    final top = NativeDisplayElement(
      id: 'top',
      elementType: ElementType.text,
      bindings: const {'text': 'overlay'},
    );

    final node = NativeDisplayContainer(
      id: 'box',
      containerType: ContainerType.box,
      children: [lower, top],
    );

    await tester.pumpWidget(wrap(BoxContainer(
      node: node,
      style: Style.empty,
      evaluator: VariableEvaluator({}),
      actionListener: (action, nodeId, params) {
        if (nodeId == 'lower') lowerTaps++;
      },
    )));

    // The TEXT renderer is non-interactive (no GestureDetector), so the tap on
    // the lower button's label must register.
    expect(find.byType(GestureDetector), findsOneWidget,
        reason: 'only the interactive BUTTON contributes a gesture target');
    await tester.tap(find.text('tap-me'), warnIfMissed: false);
    await tester.pump();

    expect(lowerTaps, 1,
        reason: 'the non-interactive TEXT sibling must not swallow the tap');
  });

  testWidgets('topmost interactive child wins over a lower interactive child',
      (tester) async {
    var lowerTaps = 0;
    var topTaps = 0;

    final lower = NativeDisplayElement(
      id: 'lower',
      elementType: ElementType.button,
      bindings: const {'text': 'lower-btn'},
      actions: {ActionTriggers.onClick: const CustomAction(key: 'lower_click')},
    );
    final top = NativeDisplayElement(
      id: 'top',
      elementType: ElementType.button,
      bindings: const {'text': 'top-btn'},
      actions: {ActionTriggers.onClick: const CustomAction(key: 'top_click')},
    );

    final node = NativeDisplayContainer(
      id: 'box',
      containerType: ContainerType.box,
      children: [lower, top],
    );

    await tester.pumpWidget(wrap(BoxContainer(
      node: node,
      style: Style.empty,
      evaluator: VariableEvaluator({}),
      actionListener: (action, nodeId, params) {
        if (nodeId == 'lower') lowerTaps++;
        if (nodeId == 'top') topTaps++;
      },
    )));

    // Tapping the top button's own label hits the top button only.
    await tester.tap(find.text('top-btn'), warnIfMissed: false);
    await tester.pump();

    expect(topTaps, 1);
    expect(lowerTaps, 0);
  });
}
