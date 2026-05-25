import 'package:flutter/widgets.dart' hide Orientation;

import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../../utils/color_parser.dart';

class DividerElement extends StatelessWidget {
  final NativeDisplayElement node;
  final Style style;

  const DividerElement({super.key, required this.node, required this.style});

  @override
  Widget build(BuildContext context) {
    final config = node.dividerConfig;
    final isHorizontal = config?.orientation != Orientation.vertical;
    final thickness = config?.thickness ?? 1.0;
    final color = ColorParser.parse(config?.color) ?? const Color(0xFFE0E0E0);

    return isHorizontal
        ? SizedBox(
            width: double.infinity,
            height: thickness,
            child: ColoredBox(color: color),
          )
        : SizedBox(
            width: thickness,
            height: double.infinity,
            child: ColoredBox(color: color),
          );
  }
}
