import 'package:clevertap_native_display/src/utils/asset_url_collector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetUrlCollector.collect', () {
    test('extracts image element binding url', () {
      final config = {
        'root': {
          'type': 'element',
          'elementType': 'image',
          'bindings': {'url': 'https://cdn.example.com/a.jpeg'},
        },
      };
      expect(
        AssetUrlCollector.collect(config),
        ['https://cdn.example.com/a.jpeg'],
      );
    });

    test('extracts video element binding url', () {
      final config = {
        'root': {
          'type': 'element',
          'elementType': 'video',
          'bindings': {'url': 'https://cdn.example.com/clip.mp4'},
        },
      };
      expect(
        AssetUrlCollector.collect(config),
        ['https://cdn.example.com/clip.mp4'],
      );
    });

    test('extracts style background image url', () {
      final config = {
        'root': {
          'type': 'container',
          'style': {
            'background': {
              'type': 'image',
              'url': 'https://cdn.example.com/bg.jpg',
            },
          },
        },
      };
      expect(
        AssetUrlCollector.collect(config),
        ['https://cdn.example.com/bg.jpg'],
      );
    });

    test('extracts nested layered background image urls', () {
      final config = {
        'root': {
          'style': {
            'background': {
              'type': 'layered',
              'layers': [
                {'type': 'solid', 'color': '#fff'},
                {'type': 'image', 'url': 'https://cdn.example.com/layer.png'},
              ],
            },
          },
        },
      };
      expect(
        AssetUrlCollector.collect(config),
        ['https://cdn.example.com/layer.png'],
      );
    });

    test('walks children recursively and dedupes, preserving first-seen order', () {
      final config = {
        'root': {
          'type': 'container',
          'children': [
            {
              'type': 'element',
              'elementType': 'image',
              'bindings': {'url': 'https://cdn.example.com/1.jpeg'},
            },
            {
              'type': 'element',
              'elementType': 'image',
              'bindings': {'url': 'https://cdn.example.com/2.jpeg'},
            },
            {
              'type': 'element',
              'elementType': 'image',
              // duplicate of the first — should be dropped
              'bindings': {'url': 'https://cdn.example.com/1.jpeg'},
            },
          ],
        },
      };
      expect(AssetUrlCollector.collect(config), [
        'https://cdn.example.com/1.jpeg',
        'https://cdn.example.com/2.jpeg',
      ]);
    });

    test('skips template-variable urls', () {
      final config = {
        'root': {
          'bindings': {'url': 'https://{{host}}/img.jpg'},
        },
      };
      expect(AssetUrlCollector.collect(config), isEmpty);
    });

    test('skips non-http values and empty urls', () {
      final config = {
        'root': {
          'children': [
            {'bindings': {'url': ''}},
            {'bindings': {'url': 'file:///local.png'}},
            {'bindings': {'url': 'not-a-url'}},
            {'bindings': {'url': 'http://ok.example.com/x.png'}},
          ],
        },
      };
      expect(
        AssetUrlCollector.collect(config),
        ['http://ok.example.com/x.png'],
      );
    });

    test('handles non-string url binding (does not throw, skips)', () {
      final config = {
        'root': {
          'bindings': {'url': 42},
        },
      };
      expect(AssetUrlCollector.collect(config), isEmpty);
    });

    test('returns empty for null / non-map input', () {
      expect(AssetUrlCollector.collect(null), isEmpty);
      expect(AssetUrlCollector.collect('string'), isEmpty);
      expect(AssetUrlCollector.collect(123), isEmpty);
    });
  });

  group('AssetUrlCollector.collectAll', () {
    test('unions urls across units, deduped and ordered', () {
      final unit1 = {
        'wzrk_id': '1',
        'native_display_config': {
          'root': {
            'bindings': {'url': 'https://cdn.example.com/a.jpeg'},
          },
        },
      };
      final unit2 = {
        'wzrk_id': '2',
        'native_display_config': {
          'root': {
            'children': [
              {'bindings': {'url': 'https://cdn.example.com/a.jpeg'}}, // dup
              {'bindings': {'url': 'https://cdn.example.com/b.mp4'}},
            ],
          },
        },
      };
      expect(AssetUrlCollector.collectAll([unit1, unit2]), [
        'https://cdn.example.com/a.jpeg',
        'https://cdn.example.com/b.mp4',
      ]);
    });

    test('empty input yields empty list', () {
      expect(AssetUrlCollector.collectAll(const []), isEmpty);
    });
  });
}
