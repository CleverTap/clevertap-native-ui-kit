import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display_webview/clevertap_native_display_webview.dart';

void main() {
  setUp(NativeDisplayRenderers.clear);
  tearDown(NativeDisplayRenderers.clear);

  test('registerClevertapHtmlRenderer registers a builder for ElementType.html', () {
    expect(NativeDisplayRenderers.builderFor(ElementType.html), isNull);
    registerClevertapHtmlRenderer();
    expect(NativeDisplayRenderers.builderFor(ElementType.html), isNotNull);
  });
}
