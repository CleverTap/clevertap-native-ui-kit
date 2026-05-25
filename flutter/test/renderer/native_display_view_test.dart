import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/root_height_scope.dart';
import 'package:clevertap_native_display/src/renderer/resolved_styles_scope.dart';

void main() {
  group('NativeDisplayView', () {
    testWidgets('renders SizedBox.shrink when root is null', (tester) async {
      final config = NativeDisplayConfig.fromJson({});
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NativeDisplayView(config: config),
        ),
      );
      // No crash is enough — no root means shrink
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('widget tree contains RootHeightScope and ResolvedStylesScope', (tester) async {
      final config = NativeDisplayConfig.fromJson({
        'root': {
          'type': 'element',
          'id': 'root',
          'elementType': 'text',
          'layout': {
            'width': {'value': 200, 'unit': 'dp'},
            'height': {'value': 100, 'unit': 'dp'},
          },
        },
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NativeDisplayView(config: config),
        ),
      );

      expect(find.byType(RootHeightScope), findsOneWidget);
      expect(find.byType(ResolvedStylesScope), findsOneWidget);
    });

    testWidgets('uses LayoutBuilder for percent dimensions', (tester) async {
      final config = NativeDisplayConfig.fromJson({
        'root': {
          'type': 'element',
          'id': 'root',
          'elementType': 'text',
          'layout': {
            'width': {'value': 100, 'unit': 'percent'},
            'height': {'value': 50, 'unit': 'percent'},
          },
        },
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: NativeDisplayView(config: config),
          ),
        ),
      );

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('uses LayoutBuilder for aspectRatio', (tester) async {
      final config = NativeDisplayConfig.fromJson({
        'root': {
          'type': 'element',
          'id': 'root',
          'elementType': 'text',
          'layout': {
            'aspectRatio': 1.5,
          },
        },
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: NativeDisplayView(config: config),
          ),
        ),
      );

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('uses SizedBox with fixed dimensions when no percent/aspectRatio', (tester) async {
      final config = NativeDisplayConfig.fromJson({
        'root': {
          'type': 'element',
          'id': 'root',
          'elementType': 'text',
          'layout': {
            'width': {'value': 200, 'unit': 'dp'},
            'height': {'value': 100, 'unit': 'dp'},
          },
        },
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NativeDisplayView(config: config),
        ),
      );

      // No LayoutBuilder — uses SizedBox directly
      expect(find.byType(LayoutBuilder), findsNothing);
    });
  });
}
