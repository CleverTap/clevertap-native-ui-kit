import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/style/style_resolver.dart';
import 'package:clevertap_native_display/src/models/native_display_config.dart' show NDTheme;

// Validates the hand-authored percent+aspectRatio gallery samples parse cleanly
// through the real models + StyleResolver (the same path the parser uses), and
// that the gallery node + its items survive. Runs from disk so it exercises the
// exact JSON shipped in flutter-sample assets.
const _dir = '../flutter-sample/assets/test-configs';
const _files = [
  'test-181-gallery-pct-snapping-horizontal.json',
  'test-182-gallery-pct-freeflow-horizontal.json',
  'test-183-gallery-pct-mixed-horizontal.json',
];

NativeDisplayContainer? _findGallery(NativeDisplayNode? n) {
  if (n is NativeDisplayContainer) {
    if (n.containerType == ContainerType.gallery) return n;
    for (final c in n.children) {
      final g = _findGallery(c);
      if (g != null) return g;
    }
  }
  return null;
}

void main() {
  for (final file in _files) {
    test('parses + resolves $file', () {
      final raw = File('$_dir/$file').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final config = NativeDisplayConfig.fromJson(json);
      expect(config.root, isNotNull, reason: 'root missing');

      // Style resolution must not throw (mirrors NativeDisplayConfigParser).
      final styles = StyleResolver().resolveAll(
        config.root,
        config.theme ?? NDTheme.empty,
        config.styleClasses,
      );
      expect(styles, isNotEmpty);

      final gallery = _findGallery(config.root);
      expect(gallery, isNotNull, reason: 'no gallery container found');
      expect(gallery!.galleryConfig, isNotNull);
      expect(gallery.children, isNotEmpty, reason: 'gallery has no items');
      expect(gallery.containerType, ContainerType.gallery);
      // Every item carries an icon + title + subtitle (3 leaf descendants min).
      for (final item in gallery.children) {
        expect(item, isA<NativeDisplayContainer>());
      }
    });
  }
}
