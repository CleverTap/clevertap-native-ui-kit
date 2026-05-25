import 'package:flutter/widgets.dart';

import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/node_config.dart';
import '../../models/style.dart';
import '../root_height_scope.dart';
import '../style_applier.dart';

class ImageElement extends StatelessWidget {
  final NativeDisplayElement node;
  final Style style;

  const ImageElement({super.key, required this.node, required this.style});

  @override
  Widget build(BuildContext context) {
    final rootHeight = RootHeightScope.of(context);
    final url = node.bindings['url'] ?? '';
    if (url.isEmpty) {
      return StyleApplier.apply(
        const SizedBox.shrink(),
        style,
        rootHeight: rootHeight,
        padding: node.layout?.padding,
      );
    }

    final isGif = _isGif(url, node.imageConfig);
    final imageFit = node.imageConfig?.fit ?? ImageFit.crop;
    final isTile = imageFit == ImageFit.tile;
    final fit = _resolveBoxFit(imageFit);

    Widget imageWidget;
    if (isTile) {
      imageWidget = Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(url),
            repeat: ImageRepeat.repeat,
          ),
        ),
      );
    } else if (isGif) {
      // Flutter natively handles animated GIFs via Image.network
      imageWidget = Image.network(
        url,
        fit: fit,
        loadingBuilder: (ctx, child, progress) => progress == null ? child : const SizedBox.shrink(),
        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
      );
    } else {
      imageWidget = Image.network(
        url,
        fit: fit,
        loadingBuilder: (ctx, child, progress) => progress == null ? child : const SizedBox.shrink(),
        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
      );
    }

    return StyleApplier.apply(
      imageWidget,
      style,
      rootHeight: rootHeight,
      padding: node.layout?.padding,
    );
  }

  bool _isGif(String url, ImageConfig? config) {
    if (config?.animated == true) return true;
    if (config?.animated == false) return false;
    final lower = url.toLowerCase();
    if (lower.endsWith('.gif')) return true;
    for (final host in ['giphy.com', 'tenor.com', 'gfycat.com', 'imgur.com']) {
      if (lower.contains(host)) return true;
    }
    return false;
  }

  BoxFit _resolveBoxFit(ImageFit fit) => switch (fit) {
        ImageFit.crop => BoxFit.cover,
        ImageFit.contain => BoxFit.contain,
        ImageFit.fill => BoxFit.fill,
        ImageFit.tile => BoxFit.none,
      };
}
