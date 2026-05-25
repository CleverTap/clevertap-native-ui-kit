import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../widgets/json_loader.dart';

const _testFiles = [
  'test-001-vertical-simple.json',
  'test-002-horizontal-simple.json',
  'test-003-box-simple.json',
  'test-004-stack-simple.json',
  'test-005-gallery-simple.json',
  'test-006-vertical-empty.json',
  'test-007-vertical-single-child.json',
  'test-008-vertical-3-children.json',
  'test-009-vertical-5-children.json',
  'test-010-vertical-10-children.json',
  'test-011-horizontal-empty.json',
  'test-012-horizontal-single-child.json',
  'test-013-horizontal-3-children.json',
  'test-014-horizontal-5-children.json',
  'test-015-horizontal-10-children.json',
  'test-016-box-empty.json',
  'test-017-box-single-child.json',
  'test-018-box-3-children.json',
  'test-019-box-5-children.json',
  'test-020-stack-empty.json',
  'test-021-stack-single-child.json',
  'test-022-stack-3-children.json',
  'test-023-stack-5-children.json',
  'test-024-gallery-empty.json',
  'test-025-gallery-single-child.json',
  'test-026-gallery-3-children-snapping.json',
  'test-027-gallery-5-children-snapping.json',
  'test-028-gallery-10-children-snapping.json',
  'test-029-gallery-3-children-free-flow.json',
  'test-030-gallery-3-children-free-flow-grid.json',
  'test-031-vertical-spaced.json',
  'test-032-vertical-space-between.json',
  'test-033-vertical-space-evenly.json',
  'test-034-vertical-space-around.json',
  'test-035-horizontal-start.json',
  'test-036-horizontal-center.json',
  'test-037-horizontal-end.json',
  'test-038-vertical-spacing-0.json',
  'test-039-vertical-spacing-8.json',
  'test-040-vertical-spacing-16.json',
  'test-041-vertical-spacing-32.json',
  'test-042-vertical-padding-uniform.json',
  'test-043-vertical-padding-individual.json',
  'test-044-horizontal-padding-asymmetric.json',
  'test-045-box-padding-large.json',
  'test-046-vertical-wrap-content.json',
  'test-047-horizontal-percent-width.json',
  'test-048-vertical-mixed-units.json',
  'test-049-nested-mixed-arrangements.json',
  'test-050-gallery-spacing-variations.json',
  'test-051-all-text-elements.json',
  'test-052-all-image-elements.json',
  'test-053-all-button-elements.json',
  'test-054-all-video-elements.json',
  'test-055-all-spacer-elements.json',
  'test-056-all-divider-elements.json',
  'test-057-product-card.json',
  'test-058-login-form.json',
  'test-059-profile-header.json',
  'test-060-media-player.json',
  'test-061-article-layout.json',
  'test-062-action-sheet.json',
  'test-063-stats-card.json',
  'test-064-gallery-item.json',
  'test-065-notification.json',
  'test-066-pricing-card.json',
  'test-067-hero-banner.json',
  'test-068-social-post.json',
  'test-069-settings-row.json',
  'test-070-feature-showcase.json',
  'test-071-text-colors.json',
  'test-072-font-sizes.json',
  'test-073-font-weights.json',
  'test-074-text-alignment.json',
  'test-075-text-decoration.json',
  'test-076-line-height.json',
  'test-077-font-families.json',
  'test-078-border-radius.json',
  'test-079-border-width-color.json',
  'test-080-shadows-light.json',
  'test-081-shadows-medium.json',
  'test-082-shadows-heavy.json',
  'test-083-opacity-variations.json',
  'test-084-combined-visual-styles.json',
  'test-085-text-style-inheritance.json',
  'test-086-style-class-usage.json',
  'test-087-inline-vs-inherited.json',
  'test-088-theme-default-styles.json',
  'test-089-styled-product-card.json',
  'test-090-styled-profile-card.json',
  'test-091-offset-percent-box-basic.json',
  'test-092-offset-percent-stack-layers.json',
  'test-093-offset-percent-negative.json',
  'test-094-offset-percent-overflow.json',
  'test-095-offset-percent-zero.json',
  'test-096-offset-percent-responsive.json',
  'test-097-offset-mixed-units.json',
  'test-098-offset-percent-nested.json',
  'test-099-offset-percent-with-padding.json',
  'test-100-offset-percent-gallery-peek.json',
  'test-101-aspect-ratio-square-fixed-width.json',
  'test-102-aspect-ratio-16-9-fixed-width.json',
  'test-103-aspect-ratio-4-3-fixed-width.json',
  'test-104-aspect-ratio-fixed-height.json',
  'test-105-aspect-ratio-percent-width.json',
  'test-106-aspect-ratio-wrap-content.json',
  'test-107-aspect-ratio-match-parent.json',
  'test-108-aspect-ratio-extreme-wide.json',
  'test-109-aspect-ratio-extreme-tall.json',
  'test-110-aspect-ratio-mixed-container.json',
  'test-111-combined-aspect-offset-box.json',
  'test-112-combined-nested-complex.json',
  'test-113-combined-gallery-aspect-peek.json',
  'test-114-combined-product-grid.json',
  'test-115-combined-showcase-all.json',
  'test-116-match-parent-comprehensive.json',
  'test-117-wrap-content-comprehensive.json',
  'test-118-mixed-special-dimensions.json',
  'test-119-match-parent-stack-box.json',
  'test-120-wrap-content-constraints.json',
  'test-121-16x9-ar-image-text-button.json',
  'test-122-1x1-ar-image-badge-rounded.json',
  'test-123-9x16-ar-video-caption.json',
  'test-124-4x3-ar-text-weights.json',
  'test-125-2x1-ar-image-split-button.json',
  'test-126-text-font-weights.json',
  'test-127-text-font-sizes.json',
  'test-128-text-alignment.json',
  'test-129-text-decoration-italic.json',
  'test-130-text-maxlines-overflow.json',
  'test-131-text-gradient.json',
  'test-132-image-fit-crop-contain.json',
  'test-133-image-gif-rounded.json',
  'test-134-image-border-radius.json',
  'test-135-images-z-order.json',
  'test-136-video-autoplay-muted.json',
  'test-137-video-with-controls.json',
  'test-138-9x16-video-button.json',
  'test-139-button-centered.json',
  'test-140-button-primary-secondary.json',
  'test-141-button-size-variants.json',
  'test-142-cta-card.json',
  'test-143-button-rounded-text.json',
  'test-144-rounded-box-text.json',
  'test-145-nested-rounded-boxes.json',
  'test-146-image-overlay-rounded.json',
  'test-147-hero-banner-complex.json',
  'test-148-product-card-complex.json',
  'test-149-notification-card.json',
  'test-150-dashboard-widget.json',
  'test-151-video-player-card.json',
  'test-152-text-corners.json',
  'test-153-image-clipped.json',
  'test-154-nested-box-deep.json',
  'test-155-all-element-types.json',
  'test-156-button-backgrounds.json',
  'test-157-gallery-box-freeflow-indicators-navbtns.json',
  'test-158-gallery-box-freeflow-indicators-only.json',
  'test-159-gallery-box-freeflow-navbtns-only.json',
  'test-160-gallery-box-freeflow-minimal.json',
  'test-161-gallery-box-freeflow-tall-images.json',
  'test-162-gallery-box-freeflow-video-items.json',
  'test-163-gallery-box-freeflow-button-items.json',
  'test-164-gallery-box-freeflow-5items.json',
  'test-165-gallery-box-grid2col-indicators-navbtns.json',
  'test-166-gallery-box-grid2col-indicators-only.json',
  'test-167-gallery-box-grid2col-navbtns-only.json',
  'test-168-gallery-box-grid2col-minimal.json',
  'test-169-gallery-box-grid3col-indicators.json',
  'test-170-gallery-box-grid3col-navbtns.json',
  'test-171-gallery-box-grid2col-video.json',
  'test-172-gallery-box-grid2col-vertical.json',
  'test-173-gallery-box-snapping-indicators-navbtns.json',
  'test-174-gallery-box-snapping-indicators-only.json',
  'test-175-gallery-box-snapping-navbtns-only.json',
  'test-176-gallery-box-snapping-minimal.json',
  'test-177-html-inline-basic.json',
  'test-178-html-with-javascript.json',
  'test-179-html-transparent-bg.json',
  'test-180-html-scrollable-content.json',
  'test-172-video-fullscreen-openurl.json',
];

class TestBrowserScreen extends StatefulWidget {
  const TestBrowserScreen({super.key});

  @override
  State<TestBrowserScreen> createState() => _TestBrowserScreenState();
}

class _TestBrowserScreenState extends State<TestBrowserScreen> {
  int _currentIndex = 0;
  NativeDisplayConfig? _config;
  bool _loading = false;
  final ScrollController _chipScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _chipScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    setState(() => _loading = true);
    // Test configs are not bundled in flutter-sample; attempt to load from configs
    // folder as a fallback — will show an error card if not found.
    final path = 'assets/test-configs/${_testFiles[_currentIndex]}';
    final config = await JsonLoader.loadFromAsset(path);
    if (!mounted) return;
    setState(() {
      _config = config;
      _loading = false;
    });
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _loadCurrent();
    // Scroll chip strip to the selected chip
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const chipWidth = 44.0;
      final offset = (_currentIndex * chipWidth) -
          (_chipScrollController.position.viewportDimension / 2 - chipWidth / 2);
      _chipScrollController.animateTo(
        offset.clamp(0, _chipScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filename = _testFiles[_currentIndex].replaceAll('.json', '');
    final counter = '${_currentIndex + 1}/${_testFiles.length}';

    return Column(
      children: [
        // Navigation row
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goTo(
                  _currentIndex > 0 ? _currentIndex - 1 : _testFiles.length - 1,
                ),
              ),
              Expanded(
                child: Text(
                  '$filename ($counter)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _goTo(
                  _currentIndex < _testFiles.length - 1 ? _currentIndex + 1 : 0,
                ),
              ),
            ],
          ),
        ),
        // Chip strip
        SizedBox(
          height: 44,
          child: ListView.builder(
            controller: _chipScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _testFiles.length,
            itemBuilder: (ctx, i) {
              final selected = i == _currentIndex;
              return GestureDetector(
                onTap: () => _goTo(i),
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}'.padLeft(3, '0'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Content
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _config != null
                    ? SingleChildScrollView(
                        child: NativeDisplayView(config: _config!),
                      )
                    : Center(
                        child: Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Could not load ${_testFiles[_currentIndex]}\n\nTest configs are not bundled with the sample app. This browser is available for development use only.',
                            style: const TextStyle(color: Color(0xFFC62828)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}
