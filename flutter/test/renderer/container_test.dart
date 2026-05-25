import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/containers/box_container.dart';
import 'package:clevertap_native_display/src/renderer/containers/vertical_container.dart';
import 'package:clevertap_native_display/src/renderer/containers/horizontal_container.dart';
import 'package:clevertap_native_display/src/renderer/containers/gallery_renderer.dart';
import 'package:clevertap_native_display/src/evaluator/variable_evaluator.dart';

NativeDisplayContainer makeContainer({
  String id = 'c',
  ContainerType type = ContainerType.box,
  List<NativeDisplayNode> children = const [],
}) {
  return NativeDisplayContainer(
    id: id,
    containerType: type,
    children: children,
  );
}

NativeDisplayElement makeElement({String id = 'e'}) {
  return NativeDisplayElement(id: id, elementType: ElementType.text);
}

void main() {
  final evaluator = VariableEvaluator({});

  Widget wrap(Widget w) => Directionality(
        textDirection: TextDirection.ltr,
        child: w,
      );

  group('BoxContainer', () {
    testWidgets('renders Stack', (tester) async {
      final node = makeContainer(
        type: ContainerType.box,
        children: [makeElement(id: 'a'), makeElement(id: 'b')],
      );

      await tester.pumpWidget(wrap(BoxContainer(
        node: node,
        style: Style.empty,
        evaluator: evaluator,
      )));

      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('children with dp offset are wrapped in Positioned', (tester) async {
      final child = NativeDisplayElement(
        id: 'child',
        elementType: ElementType.text,
        layout: Layout.fromJson({
          'offset': {'x': 10, 'y': 20, 'unit': 'dp'},
        }),
      );
      final node = makeContainer(type: ContainerType.box, children: [child]);

      await tester.pumpWidget(wrap(BoxContainer(
        node: node,
        style: Style.empty,
        evaluator: evaluator,
      )));

      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('children with percent offset use LayoutBuilder', (tester) async {
      final child = NativeDisplayElement(
        id: 'child',
        elementType: ElementType.text,
        layout: Layout.fromJson({
          'offset': {'x': 50, 'y': 25, 'unit': 'percent'},
        }),
      );
      final node = makeContainer(type: ContainerType.box, children: [child]);

      await tester.pumpWidget(wrap(SizedBox(
        width: 200,
        height: 100,
        child: BoxContainer(
          node: node,
          style: Style.empty,
          evaluator: evaluator,
        ),
      )));

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });
  });

  group('VerticalContainer', () {
    testWidgets('renders Column', (tester) async {
      final node = makeContainer(
        type: ContainerType.vertical,
        children: [makeElement(id: 'a'), makeElement(id: 'b')],
      );

      await tester.pumpWidget(wrap(VerticalContainer(
        node: node,
        style: Style.empty,
        evaluator: evaluator,
      )));

      expect(find.byType(Column), findsOneWidget);
    });
  });

  group('HorizontalContainer', () {
    testWidgets('renders Row', (tester) async {
      final node = makeContainer(
        type: ContainerType.horizontal,
        children: [makeElement(id: 'a'), makeElement(id: 'b')],
      );

      await tester.pumpWidget(wrap(HorizontalContainer(
        node: node,
        style: Style.empty,
        evaluator: evaluator,
      )));

      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('GalleryRenderer stub', () {
    testWidgets('renders without crash', (tester) async {
      final node = makeContainer(
        type: ContainerType.gallery,
        children: [makeElement(id: 'a')],
      );

      await tester.pumpWidget(wrap(GalleryRenderer(
        node: node,
        style: Style.empty,
        evaluator: evaluator,
      )));

      // No crash is the test
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
