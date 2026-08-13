import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../bridge/native_display_bridge.dart';
import '../../handler/action_attribution_extras.dart';
import '../../models/action.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/node_config.dart';
import '../../models/style.dart';
import '../root_height_scope.dart';
import '../style_applier.dart';
import '../unit_id_scope.dart';

class ImageElement extends StatelessWidget {
  final NativeDisplayElement node;
  final Style style;
  final void Function(String, String, Map<String, dynamic>?)? actionListener;

  const ImageElement({
    super.key,
    required this.node,
    required this.style,
    this.actionListener,
  });

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
      // Flutter's image codec handles animated GIFs natively via Image.network.
      // CachedNetworkImage may not preserve frame timing for animated GIFs.
      imageWidget = Image.network(
        url,
        fit: fit,
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : const SizedBox.shrink(),
        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (ctx, url) => const SizedBox.shrink(),
        errorWidget: (ctx, url, err) => const SizedBox.shrink(),
      );
    }

    Widget styled = StyleApplier.apply(
      imageWidget,
      style,
      rootHeight: rootHeight,
      padding: node.layout?.padding,
    );

    // Fire "Notification Clicked" attribution when an IMAGE element with an
    // onClick action is tapped. Matches Android/iOS SDK-5862 behaviour:
    // attribution only fires when there is an explicit onClick — never when
    // only a componentListener is attached.
    final onClick = node.actions?[ActionTriggers.onClick];
    if (onClick != null) {
      final unitId = UnitIdScope.of(context);
      styled = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          actionListener?.call('action', node.id, _onClickPayload(onClick));
          if (unitId != null && unitId.isNotEmpty) {
            final extras = ActionAttributionExtras.sanitize(
              ActionAttributionExtras.from(onClick),
            );
            NativeDisplayBridge.pushClickedEvent(unitId, elementId: node.id, extras: extras);
          }
        },
        child: styled,
      );
    }

    return RepaintBoundary(child: styled);
  }

  // Mirror the attribution payload Android/iOS pass to pushClickedEvent —
  // action.metadata carries wzrk_element_id / wzrk_c2a / wzrk_act / wzrk_data
  // injected by the backend; surface them to the host listener as well.
  Map<String, dynamic>? _onClickPayload(NDAction onClick) {
    if (onClick is OpenUrlAction && onClick.metadata != null) return {...onClick.metadata!};
    if (onClick is CustomAction && onClick.metadata != null) return {...onClick.metadata!};
    return null;
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
