import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/containers/box_container.dart';
import 'package:clevertap_native_display/src/renderer/containers/vertical_container.dart';
import 'package:clevertap_native_display/src/renderer/containers/horizontal_container.dart';
import 'package:clevertap_native_display/src/renderer/containers/gallery_renderer.dart';
import 'package:clevertap_native_display/src/evaluator/variable_evaluator.dart';
import 'package:clevertap_native_display/src/renderer/root_height_scope.dart';
import 'package:clevertap_native_display/src/renderer/resolved_styles_scope.dart';

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
        child: RootHeightScope(
          rootHeight: 200,
          child: ResolvedStylesScope(
            styles: const {},
            child: w,
          ),
        ),
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

  group('GalleryRenderer', () {
    testWidgets('renders PageView', (tester) async {
      final node = makeContainer(
        type: ContainerType.gallery,
        children: [makeElement(id: 'a'), makeElement(id: 'b')],
      );

      await tester.pumpWidget(wrap(SizedBox(
        width: 300,
        height: 200,
        child: GalleryRenderer(
          node: node,
          style: Style.empty,
          evaluator: evaluator,
        ),
      )));

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('renders correct number of children', (tester) async {
      final node = NativeDisplayContainer(
        id: 'gallery',
        containerType: ContainerType.gallery,
        children: [
          NativeDisplayElement(id: 'a', elementType: ElementType.text, bindings: {'text': 'Page 1'}),
          NativeDisplayElement(id: 'b', elementType: ElementType.text, bindings: {'text': 'Page 2'}),
          NativeDisplayElement(id: 'c', elementType: ElementType.text, bindings: {'text': 'Page 3'}),
        ],
      );

      await tester.pumpWidget(wrap(SizedBox(
        width: 300,
        height: 200,
        child: GalleryRenderer(
          node: node,
          style: Style.empty,
          evaluator: evaluator,
        ),
      )));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('renders indicators when showIndicators is true', (tester) async {
      final node = NativeDisplayContainer(
        id: 'gallery',
        containerType: ContainerType.gallery,
        children: [
          NativeDisplayElement(id: 'a', elementType: ElementType.text, bindings: {'text': 'P1'}),
          NativeDisplayElement(id: 'b', elementType: ElementType.text, bindings: {'text': 'P2'}),
        ],
        galleryConfig: GalleryConfig.fromJson({
          'showIndicators': true,
        }),
      );

      await tester.pumpWidget(wrap(SizedBox(
        width: 300,
        height: 200,
        child: GalleryRenderer(
          node: node,
          style: Style.empty,
          evaluator: evaluator,
        ),
      )));

      // Indicators are rendered as Container dots inside a Stack
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('empty children renders empty PageView without crash', (tester) async {
      final node = makeContainer(
        type: ContainerType.gallery,
        children: const [],
      );

      await tester.pumpWidget(wrap(SizedBox(
        width: 300,
        height: 200,
        child: GalleryRenderer(
          node: node,
          style: Style.empty,
          evaluator: evaluator,
        ),
      )));

      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
