import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class PeekConfig {
  final double before;
  final double after;

  const PeekConfig({this.before = 0, this.after = 0});

  factory PeekConfig.fromJson(Map<String, dynamic> json) => PeekConfig(
        before: (json['before'] as num?)?.toDouble() ?? 0,
        after: (json['after'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeekConfig && other.before == before && other.after == after;

  @override
  int get hashCode => Object.hash(before, after);
}

@immutable
class IndicatorStyle {
  final double size;
  final double spacing;
  final String activeColor;
  final String inactiveColor;
  final String shape;
  final String position;

  const IndicatorStyle({
    this.size = 8,
    this.spacing = 8,
    this.activeColor = '#2196F3',
    this.inactiveColor = '#BDBDBD',
    this.shape = 'circle',
    this.position = 'bottom',
  });

  factory IndicatorStyle.fromJson(Map<String, dynamic> json) => IndicatorStyle(
        size: (json['size'] as num?)?.toDouble() ?? 8,
        spacing: (json['spacing'] as num?)?.toDouble() ?? 8,
        activeColor: json['activeColor'] as String? ?? '#2196F3',
        inactiveColor: json['inactiveColor'] as String? ?? '#BDBDBD',
        shape: json['shape'] as String? ?? 'circle',
        position: json['position'] as String? ?? 'bottom',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorStyle &&
          other.size == size &&
          other.spacing == spacing &&
          other.activeColor == activeColor &&
          other.inactiveColor == inactiveColor &&
          other.shape == shape &&
          other.position == position;

  @override
  int get hashCode =>
      Object.hash(size, spacing, activeColor, inactiveColor, shape, position);
}

@immutable
class ArrowStyle {
  final double size;
  final String color;
  final String? backgroundColor;
  final double padding;

  const ArrowStyle({
    this.size = 24,
    this.color = '#FFFFFF',
    this.backgroundColor,
    this.padding = 8,
  });

  factory ArrowStyle.fromJson(Map<String, dynamic> json) => ArrowStyle(
        size: (json['size'] as num?)?.toDouble() ?? 24,
        color: json['color'] as String? ?? '#FFFFFF',
        backgroundColor: json['backgroundColor'] as String?,
        padding: (json['padding'] as num?)?.toDouble() ?? 8,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowStyle &&
          other.size == size &&
          other.color == color &&
          other.backgroundColor == backgroundColor &&
          other.padding == padding;

  @override
  int get hashCode => Object.hash(size, color, backgroundColor, padding);
}

@immutable
class GalleryConfig {
  final GalleryMode mode;
  final Orientation orientation;
  final SnapBehavior snapBehavior;
  final PeekConfig peek;
  final double itemsPerView;
  final int? columns;
  final double spacing;
  final bool showIndicators;
  final IndicatorStyle? indicatorStyle;
  final int autoScrollInterval;
  final bool infiniteScroll;
  final bool showArrows;
  final ArrowStyle? arrowStyle;
  final int initialPage;

  const GalleryConfig({
    this.mode = GalleryMode.snapping,
    this.orientation = Orientation.horizontal,
    this.snapBehavior = SnapBehavior.center,
    this.peek = const PeekConfig(),
    this.itemsPerView = 1,
    this.columns,
    this.spacing = 8,
    this.showIndicators = false,
    this.indicatorStyle,
    this.autoScrollInterval = 0,
    this.infiniteScroll = false,
    this.showArrows = false,
    this.arrowStyle,
    this.initialPage = 0,
  });

  double get effectiveItemsPerView => columns?.toDouble() ?? itemsPerView;

  factory GalleryConfig.fromJson(Map<String, dynamic> json) => GalleryConfig(
        mode: GalleryMode.fromJson(json['mode'] as String? ?? 'snapping'),
        orientation: Orientation.fromJson(json['orientation'] as String? ?? 'horizontal'),
        snapBehavior: SnapBehavior.fromJson(json['snapBehavior'] as String? ?? 'center'),
        peek: json['peek'] != null
            ? PeekConfig.fromJson(json['peek'] as Map<String, dynamic>)
            : const PeekConfig(),
        itemsPerView: (json['itemsPerView'] as num?)?.toDouble() ?? 1,
        columns: (json['columns'] as num?)?.toInt(),
        spacing: (json['spacing'] as num?)?.toDouble() ?? 8,
        showIndicators: json['showIndicators'] as bool? ?? false,
        indicatorStyle: json['indicatorStyle'] != null
            ? IndicatorStyle.fromJson(json['indicatorStyle'] as Map<String, dynamic>)
            : null,
        autoScrollInterval: (json['autoScrollInterval'] as num?)?.toInt() ?? 0,
        infiniteScroll: json['infiniteScroll'] as bool? ?? false,
        showArrows: json['showArrows'] as bool? ?? false,
        arrowStyle: json['arrowStyle'] != null
            ? ArrowStyle.fromJson(json['arrowStyle'] as Map<String, dynamic>)
            : null,
        initialPage: (json['initialPage'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryConfig &&
          other.mode == mode &&
          other.orientation == orientation &&
          other.snapBehavior == snapBehavior &&
          other.peek == peek &&
          other.itemsPerView == itemsPerView &&
          other.columns == columns &&
          other.spacing == spacing &&
          other.showIndicators == showIndicators &&
          other.indicatorStyle == indicatorStyle &&
          other.autoScrollInterval == autoScrollInterval &&
          other.infiniteScroll == infiniteScroll &&
          other.showArrows == showArrows &&
          other.arrowStyle == arrowStyle &&
          other.initialPage == initialPage;

  @override
  int get hashCode => Object.hash(
        mode,
        orientation,
        snapBehavior,
        peek,
        itemsPerView,
        columns,
        spacing,
        showIndicators,
        indicatorStyle,
        autoScrollInterval,
        infiniteScroll,
        showArrows,
        arrowStyle,
        initialPage,
      );
}
