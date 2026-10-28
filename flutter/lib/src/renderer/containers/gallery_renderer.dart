import 'dart:async';

import 'package:flutter/widgets.dart' hide Orientation;

import '../../evaluator/variable_evaluator.dart';
import '../../models/enums.dart';
import '../../models/gallery_config.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../../utils/color_parser.dart';
import '../native_display_renderer.dart';
import '../native_display_scope.dart';
import '../style_applier.dart';

class GalleryRenderer extends StatefulWidget {
  final NativeDisplayContainer node;
  final Style style;
  final VariableEvaluator evaluator;
  final void Function(String, String, Map<String, dynamic>?)? actionListener;
  final bool Function(String, String, Map<String, dynamic>?)? componentListener;

  const GalleryRenderer({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
    this.actionListener,
    this.componentListener,
  });

  @override
  State<GalleryRenderer> createState() => _GalleryRendererState();
}

class _GalleryRendererState extends State<GalleryRenderer> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  // Current page as a ValueNotifier so page changes only rebuild the indicator
  // dots (via ValueListenableBuilder) instead of the whole gallery/PageView.
  late final ValueNotifier<int> _currentPage;
  late int _childCount;

  GalleryConfig get _config => widget.node.galleryConfig ?? const GalleryConfig();

  @override
  void initState() {
    super.initState();
    _childCount = widget.node.children.length;
    final initialPage =
        _config.initialPage.clamp(0, _childCount == 0 ? 0 : _childCount - 1);
    _currentPage = ValueNotifier<int>(initialPage);
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: _viewportFraction,
    );
    _startAutoScroll();
  }

  double get _viewportFraction {
    final items = _config.effectiveItemsPerView;
    if (items <= 0) return 1.0;
    return 1.0 / items;
  }

  void _startAutoScroll() {
    final interval = _config.autoScrollInterval;
    if (interval <= 0 || _childCount <= 1) return;
    _autoScrollTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      final current = _currentPage.value;
      if (_config.infiniteScroll) {
        // Infinite mode: keep advancing the live controller page unbounded
        // (itemBuilder maps index % children.length to content). Never modulo
        // the controller page itself or the carousel snaps back to the start.
        _pageController.animateToPage(
          current + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        final nextPage = current + 1 < _childCount ? current + 1 : current;
        if (nextPage != current) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void didUpdateWidget(GalleryRenderer old) {
    super.didUpdateWidget(old);
    final oldConfig = old.node.galleryConfig ?? const GalleryConfig();
    final newConfig = _config;
    final newChildCount = widget.node.children.length;

    final structuralChange = newChildCount != _childCount ||
        oldConfig.autoScrollInterval != newConfig.autoScrollInterval ||
        oldConfig.infiniteScroll != newConfig.infiniteScroll ||
        oldConfig.initialPage != newConfig.initialPage ||
        oldConfig.effectiveItemsPerView != newConfig.effectiveItemsPerView;

    if (!structuralChange) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _pageController.dispose();

    _childCount = newChildCount;
    final maxPage = _childCount == 0 ? 0 : _childCount - 1;
    final clampedPage = _currentPage.value.clamp(0, maxPage);
    _currentPage.value = clampedPage;

    final initialPage = newConfig.initialPage.clamp(0, maxPage);
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: _viewportFraction,
    );
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Empty gallery: nothing to page through. Guards against `index % 0` in the
    // infinite-scroll itemBuilder when there are no children.
    if (widget.node.children.isEmpty) return const SizedBox.shrink();

    final rootHeight = NativeDisplayScope.rootHeightOf(context);
    final config = _config;
    final children = widget.node.children;

    // PageView requires bounded height. Use LayoutBuilder; fall back to 200 if parent is unbounded.
    Widget gallery = LayoutBuilder(
      builder: (ctx, constraints) {
        final h = constraints.maxHeight.isInfinite || constraints.maxHeight == 0
            ? 200.0
            : constraints.maxHeight;
        return SizedBox(
          height: h,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: config.orientation == Orientation.vertical
                ? Axis.vertical
                : Axis.horizontal,
            onPageChanged: (page) => _currentPage.value = page,
            itemCount: config.infiniteScroll ? null : children.length,
            itemBuilder: (context, index) {
              final child = children[index % children.length];
              Widget item = NativeDisplayRenderer(
                node: child,
                evaluator: widget.evaluator,
                actionListener: widget.actionListener,
                componentListener: widget.componentListener,
              );
              if (config.spacing > 0) {
                final isVertical = config.orientation == Orientation.vertical;
                item = Padding(
                  padding: isVertical
                      ? EdgeInsets.symmetric(vertical: config.spacing / 2)
                      : EdgeInsets.symmetric(horizontal: config.spacing / 2),
                  child: item,
                );
              }
              // Stable key per item: in infinite mode the same child repeats
              // across indices (index % len), so key by index there; in finite
              // mode key by the child's node id. Both are collision-free.
              return RepaintBoundary(
                key: ValueKey(config.infiniteScroll ? index : child.id),
                child: item,
              );
            },
          ),
        );
      },
    );

    if (config.showIndicators && children.isNotEmpty) {
      final style = config.indicatorStyle ?? const IndicatorStyle();
      gallery = Stack(
        alignment: _indicatorAlignment(style.position),
        children: [
          gallery,
          // Only the dots rebuild as the page changes (ValueListenableBuilder) —
          // the PageView above is not rebuilt on scroll.
          ValueListenableBuilder<int>(
            valueListenable: _currentPage,
            builder: (_, page, __) =>
                _buildIndicators(style, children.length, page),
          ),
        ],
      );
    }

    return StyleApplier.apply(
      gallery,
      widget.style,
      rootHeight: rootHeight,
      padding: widget.node.layout?.padding,
    );
  }

  Alignment _indicatorAlignment(String position) => switch (position.toLowerCase()) {
        'top' => Alignment.topCenter,
        'left' => Alignment.centerLeft,
        'right' => Alignment.centerRight,
        _ => Alignment.bottomCenter,
      };

  Widget _buildIndicators(IndicatorStyle style, int count, int currentPage) {
    final activeColor = ColorParser.parse(style.activeColor) ?? const Color(0xFF2196F3);
    final inactiveColor = ColorParser.parse(style.inactiveColor) ?? const Color(0xFFBDBDBD);
    final isVertical = _config.orientation == Orientation.vertical;

    final dots = List.generate(count, (i) {
      final isActive = i == currentPage % count;
      return Container(
        width: style.size,
        height: style.size,
        margin: EdgeInsets.all(style.spacing / 2),
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          shape: style.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(8),
      child: isVertical
          ? Column(mainAxisSize: MainAxisSize.min, children: dots)
          : Row(mainAxisSize: MainAxisSize.min, children: dots),
    );
  }
}
