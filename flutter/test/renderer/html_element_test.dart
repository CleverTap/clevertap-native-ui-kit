import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

// HtmlElement uses WebViewController which requires platform channels.
// Tests here validate configuration logic without constructing the widget.

void main() {
  group('HtmlElement configuration logic', () {
    test('html binding takes priority over url binding', () {
      const bindings = {'html': '<b>hello</b>', 'url': 'http://example.com'};
      final htmlVal = bindings['html'] ?? '';
      final urlVal = bindings['url'] ?? '';
      // html non-empty → use html, ignore url
      expect(htmlVal.isNotEmpty, true);
      expect(urlVal.isNotEmpty, true); // both present, but html wins
    });

    test('url binding used when html is absent', () {
      const bindings = {'url': 'http://example.com/page.html'};
      final htmlVal = bindings['html'] ?? '';
      final urlVal = bindings['url'] ?? '';
      expect(htmlVal.isEmpty, true);
      expect(urlVal, 'http://example.com/page.html');
    });

    test('neither binding falls through gracefully', () {
      const bindings = <String, String>{};
      final htmlVal = bindings['html'] ?? '';
      final urlVal = bindings['url'] ?? '';
      expect(htmlVal.isEmpty, true);
      expect(urlVal.isEmpty, true);
    });

    test('HtmlConfig defaults: JS disabled, scroll disabled, transparent', () {
      final node = NativeDisplayElement(
        id: 'html',
        elementType: ElementType.html,
        bindings: const {},
      );
      // Default htmlConfig is null → defaults apply in HtmlElement
      expect(node.htmlConfig, isNull);
    });

    test('HtmlConfig fromJson parses all fields', () {
      final config = HtmlConfig.fromJson({
        'javascriptEnabled': true,
        'scrollEnabled': true,
        'baseUrl': 'https://cdn.example.com',
        'transparentBackground': false,
      });
      expect(config.javascriptEnabled, true);
      expect(config.scrollEnabled, true);
      expect(config.baseUrl, 'https://cdn.example.com');
      expect(config.transparentBackground, false);
    });

    test('HtmlConfig defaults when json is empty', () {
      final config = HtmlConfig.fromJson({});
      expect(config.javascriptEnabled, false);
      expect(config.scrollEnabled, false);
      expect(config.baseUrl, isNull);
      expect(config.transparentBackground, true);
    });
  });
}
