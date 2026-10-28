import 'dart:ui';

import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/style/style_resolver.dart';
import 'package:clevertap_native_display/src/utils/color_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StyleResolver', () {
    final resolver = StyleResolver();

    test('cascades text properties from parent to child', () {
      final config = NativeDisplayConfig.fromJson(const {
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
      final config = NativeDisplayConfig.fromJson(const {
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
      final config = NativeDisplayConfig.fromJson(const {
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
      final config = NativeDisplayConfig.fromJson(const {
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
      const evaluator = VariableEvaluator({'name': 'Alice'});
      expect(evaluator.evaluateString('Hello {{name}}!'), 'Hello Alice!');
    });

    test('object.key lookup', () {
      const evaluator = VariableEvaluator({
        'user': {'first': 'Bob', 'last': 'Smith'}
      });
      expect(evaluator.evaluateString('{{user.first}} {{user.last}}'), 'Bob Smith');
    });

    test('ternary expression', () {
      const evaluator = VariableEvaluator({'premium': 'true'});
      expect(evaluator.evaluateString("{{premium ? 'Pro' : 'Free'}}"), 'Pro');
    });

    test('comparison expression', () {
      const evaluator = VariableEvaluator({'score': '100'});
      expect(evaluator.evaluateBoolean("{{score >= 50}}"), true);
      expect(evaluator.evaluateBoolean("{{score < 50}}"), false);
    });

    test('equality comparison', () {
      const evaluator = VariableEvaluator({'status': 'active'});
      expect(evaluator.evaluateBoolean("{{status == 'active'}}"), true);
    });

    test('unknown variable returns empty string', () {
      const evaluator = VariableEvaluator({});
      expect(evaluator.evaluateString('{{unknown}}'), '');
    });

    test('literal true/false', () {
      const evaluator = VariableEvaluator({});
      expect(evaluator.evaluateBoolean('true'), true);
      expect(evaluator.evaluateBoolean('false'), false);
    });

    test('null returns true (visible by default)', () {
      const evaluator = VariableEvaluator({});
      expect(evaluator.evaluateBoolean(null), true);
    });

    // #54 parity: numeric-boolean evaluation. Literal binding values (as strings,
    // since bindings/visible are coerced to String at parse time) must evaluate
    // to the correct bool. Matches Android (`toIntOrNull() != 0`) and iOS.
    group('numeric boolean literals', () {
      const evaluator = VariableEvaluator({});

      test('"1" is true', () => expect(evaluator.evaluateBoolean('1'), true));
      test('"1.0" is true', () => expect(evaluator.evaluateBoolean('1.0'), true));
      test('"0" is false', () => expect(evaluator.evaluateBoolean('0'), false));
      test('"0.0" is false', () => expect(evaluator.evaluateBoolean('0.0'), false));
      test('"2" (non-zero) is true', () => expect(evaluator.evaluateBoolean('2'), true));
      test('"-1" (non-zero) is true', () => expect(evaluator.evaluateBoolean('-1'), true));
      test('"true" is true', () => expect(evaluator.evaluateBoolean('true'), true));
      test('"false" is false', () => expect(evaluator.evaluateBoolean('false'), false));
      test('"True" (mixed case) is true', () => expect(evaluator.evaluateBoolean('True'), true));
      test('"FALSE" (upper case) is false', () => expect(evaluator.evaluateBoolean('FALSE'), false));
    });

    // A variable that resolves to a numeric/bool value (from `variables`, which
    // is Map<String, dynamic> and may hold raw JSON numbers/bools) must not
    // throw and must coerce sensibly.
    test('numeric variable value coerces to bool without throwing', () {
      const evaluator = VariableEvaluator({'flag': 1, 'off': 0, 'yes': true, 'no': false});
      expect(evaluator.evaluateBoolean('{{flag}}'), true);
      expect(evaluator.evaluateBoolean('{{off}}'), false);
      expect(evaluator.evaluateBoolean('{{yes}}'), true);
      expect(evaluator.evaluateBoolean('{{no}}'), false);
    });

    test('non-string variable value interpolates without throwing', () {
      const evaluator = VariableEvaluator({'count': 42, 'ratio': 1.5, 'enabled': true});
      expect(evaluator.evaluateString('n={{count}} r={{ratio}} e={{enabled}}'),
          'n=42 r=1.5 e=true');
    });
  });

  // #54 parity: non-string JSON binding values must not throw at parse time and
  // must coerce to their canonical string form (Map<String,String> invariant),
  // mirroring Android/iOS which normalise binding values to strings.
  group('binding value coercion', () {
    NativeDisplayElement parseElement(Map<String, dynamic> bindings) {
      return NativeDisplayElement.fromJson({
        'type': 'element',
        'id': 'e',
        'elementType': 'text',
        'bindings': bindings,
      });
    }

    test('int binding coerces to string', () {
      expect(parseElement({'text': 42}).bindings['text'], '42');
    });

    test('double binding coerces to string', () {
      expect(parseElement({'text': 1.5}).bindings['text'], '1.5');
    });

    test('bool binding coerces to canonical true/false', () {
      expect(parseElement({'autoPlay': true}).bindings['autoPlay'], 'true');
      expect(parseElement({'muted': false}).bindings['muted'], 'false');
    });

    test('null binding coerces to empty string', () {
      expect(parseElement({'text': null}).bindings['text'], '');
    });

    test('string binding passes through unchanged', () {
      expect(parseElement({'text': 'hello'}).bindings['text'], 'hello');
    });

    test('mixed non-string bindings all parse without throwing', () {
      final el = parseElement({'a': 1, 'b': 2.0, 'c': true, 'd': 'x', 'e': null});
      expect(el.bindings, {'a': '1', 'b': '2.0', 'c': 'true', 'd': 'x', 'e': ''});
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

  // The former DimensionCalculator was inlined into HtmlElement (its only
  // caller); percent/dp/sp/px + wrap/match sizing is exercised via the widget
  // tests (container_test, text_element_test, native_display_view_test).
}
