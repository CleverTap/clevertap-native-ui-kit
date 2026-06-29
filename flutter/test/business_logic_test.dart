import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/style/style_resolver.dart';
import 'package:clevertap_native_display/src/evaluator/variable_evaluator.dart';
import 'package:clevertap_native_display/src/utils/color_parser.dart';
import 'package:clevertap_native_display/src/utils/dimension_calculator.dart';

void main() {
  group('StyleResolver', () {
    final resolver = StyleResolver();

    test('cascades text properties from parent to child', () {
      final config = NativeDisplayConfig.fromJson({
        'root': {
          'type': 'container',
          'id': 'root',
          'containerType': 'vertical',
          'style': {'textColor': '#FF0000', 'backgroundColor': '#0000FF'},
          'children': [
            {
              'type': 'element',
              'id': 'child',
              'elementType': 'text',
            }
          ],
        }
      });

      final resolved = resolver.resolveAll(
        config.root,
        config.theme ?? NDTheme.empty,
        config.styleClasses,
      );

      // textColor cascades
      expect(resolved['child']?.textColor, '#FF0000');
      // backgroundColor does NOT cascade
      expect(resolved['child']?.backgroundColor, isNull);
    });

    test('visual props do NOT cascade', () {
      final config = NativeDisplayConfig.fromJson({
        'root': {
          'type': 'container',
          'id': 'root',
          'containerType': 'box',
          'style': {'borderColor': '#00FF00', 'shadowColor': '#FF00FF'},
          'children': [
            {
              'type': 'element',
              'id': 'child',
              'elementType': 'text',
            }
          ],
        }
      });

      final resolved = resolver.resolveAll(
        config.root,
        config.theme ?? NDTheme.empty,
        config.styleClasses,
      );

      expect(resolved['child']?.borderColor, isNull);
      expect(resolved['child']?.shadowColor, isNull);
    });

    test('inline > styleClass > theme priority', () {
      final config = NativeDisplayConfig.fromJson({
        'theme': {
          'id': 'default',
          'defaultStyle': {'textColor': '#111111'},
        },
        'styleClasses': [
          {'name': 'myClass', 'style': {'textColor': '#222222'}},
        ],
        'root': {
          'type': 'element',
          'id': 'root',
          'elementType': 'text',
          'style': {'textColor': '#333333'},
          'styleClass': 'myClass',
        }
      });

      final resolved = resolver.resolveAll(
        config.root,
        config.theme ?? NDTheme.empty,
        config.styleClasses,
      );

      // Inline (#333333) wins over class (#222222) and theme (#111111)
      expect(resolved['root']?.textColor, '#333333');
    });

    test('styleClass applied when no inline style', () {
      final config = NativeDisplayConfig.fromJson({
        'theme': {
          'id': 'default',
          'defaultStyle': {'textColor': '#111111'},
        },
        'styleClasses': [
          {'name': 'myClass', 'style': {'textColor': '#222222'}},
        ],
        'root': {
          'type': 'element',
          'id': 'root',
          'elementType': 'text',
          'styleClass': 'myClass',
        }
      });

      final resolved = resolver.resolveAll(
        config.root,
        config.theme ?? NDTheme.empty,
        config.styleClasses,
      );

      // Class (#222222) wins over theme (#111111)
      expect(resolved['root']?.textColor, '#222222');
    });
  });

  group('VariableEvaluator', () {
    test('simple variable substitution', () {
      final evaluator = VariableEvaluator({'name': 'Alice'});
      expect(evaluator.evaluateString('Hello {{name}}!'), 'Hello Alice!');
    });

    test('object.key lookup', () {
      final evaluator = VariableEvaluator({
        'user': {'first': 'Bob', 'last': 'Smith'}
      });
      expect(evaluator.evaluateString('{{user.first}} {{user.last}}'), 'Bob Smith');
    });

    test('ternary expression', () {
      final evaluator = VariableEvaluator({'premium': 'true'});
      expect(evaluator.evaluateString("{{premium ? 'Pro' : 'Free'}}"), 'Pro');
    });

    test('comparison expression', () {
      final evaluator = VariableEvaluator({'score': '100'});
      expect(evaluator.evaluateBoolean("{{score >= 50}}"), true);
      expect(evaluator.evaluateBoolean("{{score < 50}}"), false);
    });

    test('equality comparison', () {
      final evaluator = VariableEvaluator({'status': 'active'});
      expect(evaluator.evaluateBoolean("{{status == 'active'}}"), true);
    });

    test('unknown variable returns empty string', () {
      final evaluator = VariableEvaluator({});
      expect(evaluator.evaluateString('{{unknown}}'), '');
    });

    test('literal true/false', () {
      final evaluator = VariableEvaluator({});
      expect(evaluator.evaluateBoolean('true'), true);
      expect(evaluator.evaluateBoolean('false'), false);
    });

    test('null returns true (visible by default)', () {
      final evaluator = VariableEvaluator({});
      expect(evaluator.evaluateBoolean(null), true);
    });
  });

  group('ColorParser', () {
    test('6-char hex → opaque color', () {
      final color = ColorParser.parse('#FF0000');
      expect(color?.toARGB32(), 0xFFFF0000);
    });

    test('8-char hex → RGBA to ARGB byte swap', () {
      // #FF000080 → RGBA: R=FF, G=00, B=00, A=80
      // Flutter ARGB: 0x80FF0000
      final color = ColorParser.parse('#FF000080');
      expect(color?.toARGB32(), 0x80FF0000);
    });

    test('null input returns null', () {
      expect(ColorParser.parse(null), isNull);
    });

    test('empty string returns null', () {
      expect(ColorParser.parse(''), isNull);
    });

    test('invalid hex returns null', () {
      expect(ColorParser.parse('#ZZZZZZ'), isNull);
    });

    test('no hash prefix still parses', () {
      final color = ColorParser.parse('00FF00');
      expect(color?.toARGB32(), 0xFF00FF00);
    });

    test('parseWithDefault returns default on null', () {
      const defaultColor = Color(0xFFFFFFFF);
      final result = ColorParser.parseWithDefault(null, defaultColor);
      expect(result, defaultColor);
    });

    test('opaque white correctly parsed', () {
      final color = ColorParser.parse('#FFFFFFFF');
      // RGBA: R=FF, G=FF, B=FF, A=FF → ARGB: 0xFFFFFFFF
      expect(color?.toARGB32(), 0xFFFFFFFF);
    });
  });

  group('DimensionCalculator', () {
    test('percent dimension resolves relative to parent', () {
      final dim = Dimension.fromJson({'value': 50, 'unit': 'percent'});
      final result = DimensionCalculator.resolve(dim, parentSize: 200);
      expect(result, 100.0);
    });

    test('dp dimension returns value directly', () {
      final dim = Dimension.fromJson({'value': 24, 'unit': 'dp'});
      final result = DimensionCalculator.resolve(dim, parentSize: 200);
      expect(result, 24.0);
    });

    test('sp dimension returns value directly', () {
      final dim = Dimension.fromJson({'value': 16, 'unit': 'sp'});
      final result = DimensionCalculator.resolve(dim, parentSize: 200);
      expect(result, 16.0);
    });

    test('px dimension returns value directly', () {
      final dim = Dimension.fromJson({'value': 32, 'unit': 'px'});
      final result = DimensionCalculator.resolve(dim, parentSize: 200);
      expect(result, 32.0);
    });

    test('wrap_content returns null', () {
      final result = DimensionCalculator.resolve(Dimension.wrapContent, parentSize: 200);
      expect(result, isNull);
    });

    test('match_parent returns null', () {
      final result = DimensionCalculator.resolve(Dimension.matchParent, parentSize: 200);
      expect(result, isNull);
    });

    test('null dimension returns null', () {
      final result = DimensionCalculator.resolve(null, parentSize: 200);
      expect(result, isNull);
    });
  });
}
