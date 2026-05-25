import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

// GIF detection unit tests — pure logic, no widgets
void main() {
  group('ImageElement GIF detection logic', () {
    test('explicit animated=true overrides all', () {
      expect(_testIsGif('https://example.com/photo.png', ImageConfig(animated: true)), true);
    });

    test('explicit animated=false overrides .gif extension', () {
      expect(_testIsGif('https://example.com/image.gif', ImageConfig(animated: false)), false);
    });

    test('.gif extension detected', () {
      expect(_testIsGif('https://example.com/image.gif', null), true);
    });

    test('giphy.com host detected', () {
      expect(_testIsGif('https://media.giphy.com/abc', null), true);
    });

    test('tenor.com host detected', () {
      expect(_testIsGif('https://tenor.com/view/abc', null), true);
    });

    test('gfycat.com host detected', () {
      expect(_testIsGif('https://gfycat.com/abc', null), true);
    });

    test('imgur.com host detected', () {
      expect(_testIsGif('https://imgur.com/abc.mp4', null), true);
    });

    test('regular jpg not detected as GIF', () {
      expect(_testIsGif('https://example.com/photo.jpg', null), false);
    });

    test('uppercase .GIF extension detected', () {
      expect(_testIsGif('https://example.com/IMAGE.GIF', null), true);
    });
  });

  group('ImageElement BoxFit mapping logic', () {
    test('ImageFit.crop → BoxFit.cover', () {
      expect(_testBoxFit(ImageFit.crop), BoxFit.cover);
    });

    test('ImageFit.contain → BoxFit.contain', () {
      expect(_testBoxFit(ImageFit.contain), BoxFit.contain);
    });

    test('ImageFit.fill → BoxFit.fill', () {
      expect(_testBoxFit(ImageFit.fill), BoxFit.fill);
    });

    test('ImageFit.tile → BoxFit.none', () {
      expect(_testBoxFit(ImageFit.tile), BoxFit.none);
    });
  });
}

// Replicates ImageElement._isGif logic for unit testing
bool _testIsGif(String url, ImageConfig? config) {
  if (config?.animated == true) return true;
  if (config?.animated == false) return false;
  final lower = url.toLowerCase();
  if (lower.endsWith('.gif')) return true;
  for (final host in ['giphy.com', 'tenor.com', 'gfycat.com', 'imgur.com']) {
    if (lower.contains(host)) return true;
  }
  return false;
}

// Replicates ImageElement._resolveBoxFit logic
BoxFit _testBoxFit(ImageFit fit) => switch (fit) {
      ImageFit.crop => BoxFit.cover,
      ImageFit.contain => BoxFit.contain,
      ImageFit.fill => BoxFit.fill,
      ImageFit.tile => BoxFit.none,
    };
