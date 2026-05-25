import 'package:flutter/widgets.dart';

import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';

class SpacerElement extends StatelessWidget {
  final NativeDisplayElement node;
  final Style style;

  const SpacerElement({super.key, required this.node, required this.style});

  @override
  Widget build(BuildContext context) {
    final layout = node.layout;
    final isFlexible = layout?.width?.special == SpecialDimension.matchParent ||
        layout?.height?.special == SpecialDimension.matchParent;
    if (isFlexible) return const Spacer();
    final w = layout?.width?.special == null ? layout?.width?.value : null;
    final h = layout?.height?.special == null ? layout?.height?.value : null;
    return SizedBox(width: w, height: h);
  }
}
