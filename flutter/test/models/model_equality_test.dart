import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter_test/flutter_test.dart';

// Verifies value equality + hashCode on the exported model value types:
// two instances parsed from identical JSON must be `==` with equal hashCode,
// and must differ when any single field changes. Covers a representative mix of
// scalar, nested, List, and Map fields across the model layer.
void main() {
  group('Style', () {
    Map<String, dynamic> json() => {
          'textColor': '#FF0000',
          'fontSize': 16,
          'fontWeight': 'bold',
          'maxLines': 2,
          'backgroundColor': '#00FF00',
          'textGradient': {
            'type': 'linear',
            'colors': ['#111111', '#222222'],
            'stops': [0.0, 1.0],
          },
        };

    test('equal JSON → equal + same hashCode', () {
      final a = Style.fromJson(json());
      final b = Style.fromJson(json());
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when a scalar field changes', () {
      final a = Style.fromJson(json());
      final b = Style.fromJson(json()..['textColor'] = '#0000FF');
      expect(a, isNot(equals(b)));
    });

    test('differs when a nested gradient color changes', () {
      final a = Style.fromJson(json());
      final mutated = json();
      (mutated['textGradient'] as Map<String, dynamic>)['colors'] = ['#111111', '#333333'];
      final b = Style.fromJson(mutated);
      expect(a, isNot(equals(b)));
    });
  });

  group('Dimension', () {
    test('equal JSON → equal + same hashCode', () {
      final a = Dimension.fromJson(const {'value': 50, 'unit': 'percent'});
      final b = Dimension.fromJson(const {'value': 50, 'unit': 'percent'});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs on value and on unit', () {
      final base = Dimension.fromJson(const {'value': 50, 'unit': 'percent'});
      expect(base, isNot(equals(Dimension.fromJson(const {'value': 60, 'unit': 'percent'}))));
      expect(base, isNot(equals(Dimension.fromJson(const {'value': 50, 'unit': 'dp'}))));
    });
  });

  group('TextDimension', () {
    test('equal JSON → equal + same hashCode', () {
      final a = TextDimension.fromJson(const {'value': 5, 'unit': 'percent'});
      final b = TextDimension.fromJson(const {'value': 5, 'unit': 'percent'});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('raw number equals itself but differs from percent', () {
      expect(TextDimension.fromJson(14), equals(TextDimension.fromJson(14)));
      expect(TextDimension.fromJson(14),
          isNot(equals(TextDimension.fromJson(const {'value': 14, 'unit': 'percent'}))));
    });
  });

  group('Layout', () {
    Map<String, dynamic> json() => {
          'width': {'value': 100, 'unit': 'percent'},
          'height': {'value': 40, 'unit': 'dp'},
          'aspectRatio': 1.5,
          'padding': {'all': 8},
          'arrangement': {'strategy': 'spaced', 'spacing': 12},
        };

    test('equal JSON → equal + same hashCode', () {
      final a = Layout.fromJson(json());
      final b = Layout.fromJson(json());
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when aspectRatio changes', () {
      final a = Layout.fromJson(json());
      final b = Layout.fromJson(json()..['aspectRatio'] = 2.0);
      expect(a, isNot(equals(b)));
    });

    test('differs when a nested dimension changes', () {
      final a = Layout.fromJson(json());
      final mutated = json();
      (mutated['width'] as Map<String, dynamic>)['value'] = 50;
      final b = Layout.fromJson(mutated);
      expect(a, isNot(equals(b)));
    });
  });

  group('GalleryConfig', () {
    Map<String, dynamic> json() => {
          'mode': 'snapping',
          'itemsPerView': 1.5,
          'autoScrollInterval': 3000,
          'infiniteScroll': true,
          'indicatorStyle': {'size': 10, 'activeColor': '#FF0000'},
        };

    test('equal JSON → equal + same hashCode', () {
      final a = GalleryConfig.fromJson(json());
      final b = GalleryConfig.fromJson(json());
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when a scalar field changes', () {
      final a = GalleryConfig.fromJson(json());
      final b = GalleryConfig.fromJson(json()..['infiniteScroll'] = false);
      expect(a, isNot(equals(b)));
    });

    test('differs when a nested indicatorStyle field changes', () {
      final a = GalleryConfig.fromJson(json());
      final mutated = json();
      (mutated['indicatorStyle'] as Map<String, dynamic>)['activeColor'] = '#00FF00';
      final b = GalleryConfig.fromJson(mutated);
      expect(a, isNot(equals(b)));
    });
  });

  group('NativeDisplayConfig', () {
    Map<String, dynamic> json() => {
          'version': '1.0',
          'theme': {
            'id': 'default',
            'colors': {'primary': '#FF0000'},
          },
          'styleClasses': [
            {
              'name': 'title',
              'style': {'fontSize': 20, 'fontWeight': 'bold'},
            },
          ],
          'variables': {'name': 'World'},
          'root': {
            'type': 'container',
            'id': 'root',
            'containerType': 'vertical',
            'children': <dynamic>[
              {
                'type': 'element',
                'id': 't1',
                'elementType': 'text',
                'bindings': {'text': 'Hello {{name}}'},
              },
            ],
          },
        };

    test('equal JSON → equal + same hashCode', () {
      final a = NativeDisplayConfig.fromJson(json());
      final b = NativeDisplayConfig.fromJson(json());
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when a variable changes', () {
      final a = NativeDisplayConfig.fromJson(json());
      final b = NativeDisplayConfig.fromJson(json()..['variables'] = {'name': 'There'});
      expect(a, isNot(equals(b)));
    });

    test('differs when a deeply nested child binding changes', () {
      final a = NativeDisplayConfig.fromJson(json());
      final mutated = json();
      final root = mutated['root'] as Map<String, dynamic>;
      final child = (root['children'] as List).first as Map<String, dynamic>;
      (child['bindings'] as Map<String, dynamic>)['text'] = 'Goodbye {{name}}';
      final b = NativeDisplayConfig.fromJson(mutated);
      expect(a, isNot(equals(b)));
    });
  });
}
