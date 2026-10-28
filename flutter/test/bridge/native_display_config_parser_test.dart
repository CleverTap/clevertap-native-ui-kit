import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter_test/flutter_test.dart';

// Guards the raw display-unit → NativeDisplayUnit parse contract, including the
// container/style/padding shape the sample Slot Demo injects. A regression here
// previously dropped whole units silently (padding given as nested {value,unit}
// objects instead of flat numbers), so nothing rendered.

Map<String, dynamic> _banner({Object? padding}) => {
      'wzrk_id': 'u1',
      'slot_id': 'slot_top',
      'native_display_config': {
        'root': {
          'type': 'container',
          'id': 'banner_root',
          'containerType': 'vertical',
          'layout': {
            'width': {'value': 100, 'unit': 'percent'},
            'height': {'value': 96, 'unit': 'dp'},
            if (padding != null) 'padding': padding,
            'arrangement': {'strategy': 'center'},
          },
          'style': {'backgroundColor': '#1565C0', 'borderRadius': 8},
          'children': [
            {
              'type': 'element',
              'id': 'banner_title',
              'elementType': 'text',
              'bindings': {'text': 'Summer Sale is live'},
              'style': {
                'textColor': '#FFFFFF',
                'fontSize': 16,
                'fontWeight': 'bold',
                'lineHeight': 20,
              },
              'layout': {
                'width': {'special': 'wrap_content'},
                'height': {'special': 'wrap_content'},
              },
            },
          ],
        },
      },
    };

void main() {
  group('NativeDisplayConfigParser', () {
    test('parses a banner container with flat-number padding', () async {
      final units = await NativeDisplayConfigParser.parseAll([
        _banner(padding: {'all': 16, 'unit': 'dp'}),
      ]);

      expect(units, hasLength(1));
      expect(units.single.unitId, 'u1');
      expect(units.single.slotId, 'slot_top');
      expect(units.single.config.root, isNotNull);
      // Styles are pre-resolved during parse.
      expect(units.single.resolvedStyles, isNotEmpty);
    });

    test('parses padding given as per-side flat numbers', () async {
      final units = await NativeDisplayConfigParser.parseAll([
        _banner(padding: {'top': 6, 'bottom': 6, 'left': 14, 'right': 14, 'unit': 'dp'}),
      ]);

      expect(units, hasLength(1));
    });

    test('drops (does not throw on) a unit with nested {value,unit} padding', () async {
      // Spacing.fromJson expects flat numbers; nested objects are unsupported.
      // The parser must swallow the error and return an empty list rather than
      // throwing — but it now logs a warning so the drop is visible.
      final units = await NativeDisplayConfigParser.parseAll([
        _banner(padding: {
          'top': {'value': 16, 'unit': 'dp'},
        }),
      ]);

      expect(units, isEmpty);
    });

    test('tryParse returns null for a non-map payload', () async {
      expect(await NativeDisplayConfigParser.tryParse('not a map'), isNull);
    });
  });
}
