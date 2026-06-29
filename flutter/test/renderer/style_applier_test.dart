import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/renderer/style_applier.dart';

void main() {
  Widget wrap(Widget w) => Directionality(
        textDirection: TextDirection.ltr,
        child: w,
      );

  group('StyleApplier', () {
    testWidgets('applies SolidBackground as BoxDecoration color', (tester) async {
      final style = Style.fromJson({
        'background': {'type': 'solid', 'color': '#FF0000'},
      });

      await tester.pumpWidget(wrap(
        StyleApplier.apply(
          const SizedBox(width: 100, height: 50),
          style,
          rootHeight: 200,
        ),
      ));

      final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decorated.decoration as BoxDecoration;
      expect(decoration.color?.toARGB32(), 0xFFFF0000);
    });

    testWidgets('applies LinearGradient', (tester) async {
      final style = Style.fromJson({
        'background': {
          'type': 'linear_gradient',
          'angle': 90.0,
          'colors': ['#FF0000', '#0000FF'],
        },
      });

      await tester.pumpWidget(wrap(
        StyleApplier.apply(
          const SizedBox(width: 100, height: 50),
          style,
          rootHeight: 200,
        ),
      ));

      final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decorated.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('animated background renders transparent and no crash', (tester) async {
      final style = Style.fromJson({
        'background': {
          'type': 'shimmer',
          'base_color': '#E0E0E0',
          'highlight_color': '#F5F5F5',
        },
      });

      await tester.pumpWidget(wrap(
        StyleApplier.apply(
          const SizedBox(width: 100, height: 50),
          style,
          rootHeight: 200,
        ),
      ));

      // No crash — animated bg deferred to v2, renders nothing special
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('applies border via BorderColor', (tester) async {
      final style = Style.fromJson({
        'borderColor': '#00FF00',
        'borderWidth': 2.0,
      });

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 100,
          child: StyleApplier.apply(
            const SizedBox.expand(),
            style,
            rootHeight: 200,
          ),
        ),
      ));

      final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decorated.decoration as BoxDecoration;
      expect(decoration.border, isA<Border>());
    });

    testWidgets('applies opacity', (tester) async {
      final style = Style.fromJson({'opacity': 0.5});

      await tester.pumpWidget(wrap(
        StyleApplier.apply(
          const SizedBox(width: 100, height: 50),
          style,
          rootHeight: 200,
        ),
      ));

      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, 0.5);
    });

    testWidgets('no decoration when style is empty', (tester) async {
      await tester.pumpWidget(wrap(
        StyleApplier.apply(
          const SizedBox(width: 100, height: 50),
          Style.empty,
          rootHeight: 200,
        ),
      ));

      expect(find.byType(DecoratedBox), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('applies shadow via BoxShadow', (tester) async {
      final style = Style.fromJson({
        'shadowColor': '#000000',
        'shadowRadius': 8.0,
        'shadowOffsetX': 2.0,
        'shadowOffsetY': 4.0,
      });

      await tester.pumpWidget(wrap(
        StyleApplier.apply(
          const SizedBox(width: 100, height: 50),
          style,
          rootHeight: 200,
        ),
      ));

      final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decorated.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('backgroundColor (no background obj) applies color', (tester) async {
      final style = Style.fromJson({'backgroundColor': '#0000FF'});

      await tester.pumpWidget(wrap(
        StyleApplier.apply(
          const SizedBox(width: 100, height: 50),
          style,
          rootHeight: 200,
        ),
      ));

      final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decorated.decoration as BoxDecoration;
      expect(decoration.color?.toARGB32(), 0xFF0000FF);
    });
  });
}
