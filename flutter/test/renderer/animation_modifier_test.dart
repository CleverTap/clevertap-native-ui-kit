import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/src/renderer/animation_modifier.dart';
import 'package:clevertap_native_display/src/models/node_config.dart';
import 'package:clevertap_native_display/src/models/enums.dart';

Widget wrap(Widget w) => Directionality(
      textDirection: TextDirection.ltr,
      child: w,
    );

NDAnimation makeAnim(AnimationType type, {int duration = 300, int delay = 0}) =>
    NDAnimation(type: type, duration: duration, delay: delay);

void main() {
  group('AnimationModifier', () {
    testWidgets('none type returns child directly without transitions', (tester) async {
      const child = SizedBox(key: ValueKey('child'), width: 50, height: 50);

      await tester.pumpWidget(wrap(AnimationModifier(
        animation: makeAnim(AnimationType.none),
        child: child,
      )));

      expect(find.byKey(const ValueKey('child')), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(ScaleTransition), findsNothing);
    });

    testWidgets('fadeIn type wraps in FadeTransition', (tester) async {
      await tester.pumpWidget(wrap(AnimationModifier(
        animation: makeAnim(AnimationType.fadeIn),
        child: const SizedBox(width: 50, height: 50),
      )));

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(ScaleTransition), findsNothing);
    });

    testWidgets('slideInLeft type wraps in SlideTransition', (tester) async {
      await tester.pumpWidget(wrap(AnimationModifier(
        animation: makeAnim(AnimationType.slideInLeft),
        child: const SizedBox(width: 50, height: 50),
      )));

      expect(find.byType(SlideTransition), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
    });

    testWidgets('scaleIn type wraps in ScaleTransition', (tester) async {
      await tester.pumpWidget(wrap(AnimationModifier(
        animation: makeAnim(AnimationType.scaleIn),
        child: const SizedBox(width: 50, height: 50),
      )));

      expect(find.byType(ScaleTransition), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
    });

    testWidgets('fadeScaleIn wraps in both FadeTransition and ScaleTransition', (tester) async {
      await tester.pumpWidget(wrap(AnimationModifier(
        animation: makeAnim(AnimationType.fadeScaleIn),
        child: const SizedBox(width: 50, height: 50),
      )));

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);
    });

    testWidgets('fadeSlideIn wraps in both FadeTransition and SlideTransition', (tester) async {
      await tester.pumpWidget(wrap(AnimationModifier(
        animation: makeAnim(AnimationType.fadeSlideIn),
        child: const SizedBox(width: 50, height: 50),
      )));

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);
    });

    testWidgets('animation completes after pump', (tester) async {
      await tester.pumpWidget(wrap(AnimationModifier(
        animation: makeAnim(AnimationType.fadeIn, duration: 100),
        child: const SizedBox(width: 50, height: 50),
      )));

      await tester.pumpAndSettle();
      // No exception = animation completed cleanly
      expect(find.byType(FadeTransition), findsOneWidget);
    });
  });
}
