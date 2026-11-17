# Flutter Rendering Pipeline

## Build → Layout → Paint → Composite

Flutter renders in four sequential phases per frame:

```
1. BUILD        Widget.build() called → Widget tree produced
2. LAYOUT       Constraints down, sizes up — O(n) single pass
3. PAINT        RenderObject.paint() → layer tree
4. COMPOSITE    Scene assembled → GPU rasterization (Skia/Impeller)
```

For the Native Display SDK, phases 1 and 2 are most relevant.

---

## Container Rendering

### VERTICAL → Column

```dart
Widget renderVertical(NativeDisplayContainer node, List<Widget> children, Style style) {
  final arrangement = node.layout.arrangement;
  final spacing = arrangement.spacing ?? 0.0;

  return Column(
    mainAxisAlignment: arrangementToMain(arrangement.strategy),
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: mainAxisSize(node.layout.height),
    children: arrangement.strategy == ArrangementStrategy.spaced
        ? _insertSpacers(children, spacing, axis: Axis.vertical)
        : children,
  );
}
```

### HORIZONTAL → Row

```dart
Widget renderHorizontal(NativeDisplayContainer node, List<Widget> children) {
  final arrangement = node.layout.arrangement;
  return Row(
    mainAxisAlignment: arrangementToMain(arrangement.strategy),
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: mainAxisSize(node.layout.width),
    children: arrangement.strategy == ArrangementStrategy.spaced
        ? _insertSpacers(children, arrangement.spacing ?? 0, axis: Axis.horizontal)
        : children,
  );
}
```

### BOX → Stack

```dart
Widget renderBox(NativeDisplayContainer node, List<Widget> children, Style style) {
  return Stack(
    clipBehavior: Clip.hardEdge,
    children: children.map((child) {
      final offset = child.node.layout.offset;
      if (offset == null) return child.widget;
      return Positioned(left: offset.x, top: offset.y, child: child.widget);
    }).toList(),
  );
}
```

### GALLERY → PageView (SNAPPING) / SingleChildScrollView (FREE_FLOW) / GridView (FREE_FLOW_GRID)

```dart
Widget renderGallery(NativeDisplayContainer node, List<Widget> children, GalleryConfig config) {
  return switch (config.mode) {
    GalleryMode.snapping => _buildPageView(node, children, config),
    GalleryMode.freeFlow => _buildScrollView(node, children, config),
    GalleryMode.freeFlowGrid => _buildGridView(node, children, config),
  };
}

Widget _buildPageView(NativeDisplayContainer node, List<Widget> children, GalleryConfig config) {
  return LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: constraints.maxHeight,
      child: PageView(
        controller: PageController(viewportFraction: config.peeking ? 0.85 : 1.0),
        children: children.map((c) => RepaintBoundary(child: c)).toList(),
      ),
    ),
  );
}
```

---

## Element Rendering

### TEXT

```dart
Widget renderText(NativeDisplayElement node, Style style) {
  final text = evaluator.evaluateString(node.bindings['text'] ?? ''); // VariableEvaluator
  // `style` is the already-resolved style for this node (parent text cascade applied at resolve time)

  return Text(
    text,
    maxLines: style.maxLines,
    overflow: _toOverflow(style.overflow),
    style: const TextStyle().copyWith(
      color: style.textColor != null ? parseColor(style.textColor!) : null,
      fontSize: style.fontSize?.resolve(rootHeight),
      fontWeight: _toFontWeight(style.fontWeight),
      fontStyle: _toFontStyle(style.fontStyle),
      height: style.lineHeight?.resolve(rootHeight) != null
          ? style.lineHeight!.resolve(rootHeight)! / style.fontSize!.resolve(rootHeight)!
          : null,
      letterSpacing: style.letterSpacing,
      decoration: _toDecoration(style.textDecoration),
    ),
    textAlign: _toTextAlign(style.textAlign),
  );
}
```

**lineHeight note**: Flutter's `TextStyle.height` is a multiplier on fontSize (e.g., `height: 1.5`), not an absolute value. Convert: `height = lineHeight / fontSize`.

### IMAGE

```dart
Widget renderImage(NativeDisplayElement node, Style style) {
  final url = evaluator.evaluateString(node.bindings['url'] ?? ''); // VariableEvaluator
  final fit = _toBoxFit(style.imageFit);

  // GIF detection: explicit flag, .gif extension, known hosts, path patterns
  final isGif = node.imageConfig?.animated == true
      || url.toLowerCase().endsWith('.gif')
      || _isKnownGifHost(url);

  // Flutter's Image.network handles animated GIFs natively via codec
  return Image.network(
    url,
    fit: fit,
    loadingBuilder: (ctx, child, progress) {
      if (progress == null) return child;
      return const SizedBox.shrink(); // or shimmer
    },
    errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
  );
}
```

### BUTTON

```dart
Widget renderButton(NativeDisplayElement node, Style style) {
  final text = evaluator.evaluateString(node.bindings['text'] ?? ''); // VariableEvaluator

  return GestureDetector(
    onTap: () => actionListener?.onAction(node.action),
    child: Container(
      decoration: _buildDecoration(style),
      padding: _buildPadding(node.layout.padding),
      child: Text(text, style: _buildTextStyle(style)),
    ),
  );
}
```

---

## Dimension Resolution

Every node's width and height must be resolved against parent constraints. There is no
`DimensionCalculator` class — resolution is done inline in the renderers/containers against the
`Dimension` model (enum-typed `unit`/`special`), using `LayoutBuilder`/`BoxConstraints` to supply
`parentSize`:

```dart
// Dimension (src/models/layout.dart): value (double), unit (DimensionUnit), special (SpecialDimension?)
double? resolveDimension(Dimension? dim, double parentSize) {
  if (dim == null) return null;
  if (dim.special == SpecialDimension.matchParent) return parentSize;
  if (dim.special == SpecialDimension.wrapContent) return null; // null → intrinsic size
  if (dim.unit == DimensionUnit.percent) return parentSize * dim.value / 100;
  return dim.value; // dp/sp/px — treat as logical pixels
}
```

## Root Sizing — aspectRatio Precedence Rule

**When `aspectRatio` is set on the root, it uses full available parent width and ignores any `width.percent` value.**

This matches Android (Compose `aspectRatio` modifier locks `{W=parentWidth, H=parentWidth/ratio}` before `fillMaxWidth(fraction)` applies) and iOS (explicit guard returning `parentWidth` for percent when AR set).

### Implementation in `NativeDisplayView`

```dart
// _effectiveWidth: AR present → full width, percent ignored
double _effectiveWidth(Layout? layout, double availableWidth) {
  final ar = layout?.aspectRatio;
  if (ar != null && ar > 0) return availableWidth;          // AR wins, ignore percent
  final w = layout?.width;
  if (w != null && w.special == null && w.unit == DimensionUnit.percent && w.value > 0) {
    return availableWidth * w.value / 100.0;
  }
  return availableWidth;
}

// _computeRootHeight: AR → fullWidth / AR (not percentWidth / AR)
double _computeRootHeight(Layout? layout, double effectiveRootWidth, BoxConstraints constraints, double screenHeight) {
  if (layout == null) return screenHeight;
  final ar = layout.aspectRatio;
  if (ar != null && ar > 0) return effectiveRootWidth / ar;  // effectiveRootWidth = fullWidth when AR set
  final h = layout.height;
  if (h != null && h.special == null && h.value > 0) {
    if (h.unit == DimensionUnit.percent) return screenHeight * h.value / 100.0;
    return h.value;
  }
  if (!constraints.maxHeight.isInfinite) return constraints.maxHeight;
  return screenHeight;
}

// _applyRootSizing: AR → return child unchanged; AspectRatio widget handles visual constraint
Widget _applyRootSizing(Widget child, Layout? layout, ...) {
  if (layout == null) return child;
  final ar = layout.aspectRatio;
  if (ar != null && ar > 0) return child;    // AR takes full width; no Align+SizedBox wrapper
  // ... percent width/height sizing applied only when no AR ...
}
```

### aspectRatio sizing priority (all nodes, all platforms)

| Scenario | Result |
|---|---|
| Both width AND height fixed (dp/sp/px) | `aspectRatio` skipped |
| Only height fixed (dp/sp/px) | width = `fixedHeight × AR` |
| Only width fixed (dp/sp/px) | height = `fixedWidth / AR` |
| width is percent + AR | **percent ignored**; uses full parent width; height = `parentWidth / AR` |
| height is percent + AR | AR-derived height; percent height ignored |
| No explicit width or height | full parent width; height = `parentWidth / AR` |
```

---

## Style Application — Decorator Pattern

Apply style as a widget decoration chain:

```dart
Widget applyStyle(Widget child, Style style, Layout layout) {
  // 1. Apply padding (inside decoration)
  if (layout.padding != null) {
    child = Padding(padding: _buildEdgeInsets(layout.padding!), child: child);
  }

  // 2. Apply background, border, border-radius as BoxDecoration
  final decoration = _buildBoxDecoration(style);
  if (decoration != null) {
    child = DecoratedBox(decoration: decoration, child: child);
  }

  // 3. Apply opacity
  if (style.opacity != null && style.opacity != 1.0) {
    child = Opacity(opacity: style.opacity!, child: child);
  }

  // 4. Apply shadow (via DecoratedBox — already in step 2 via boxShadow)

  // 5. Apply clip (for borderRadius)
  if (style.borderRadius != null) {
    child = ClipRRect(
      borderRadius: BorderRadius.circular(_resolveRadius(style.borderRadius!, rootHeight)),
      child: child,
    );
  }

  return child;
}
```

---

## Text Style Cascading at Resolve Time

Text properties cascade from parent containers to all descendants. This cascade is computed **once**
in `StyleResolver` — not via a runtime InheritedWidget — so renderers read a flat, already-merged
style per node:

```dart
// StyleResolver (src/style/style_resolver.dart) merges parent cascading-only props into each node:
final cascadedParent = parentStyle.cascadingOnly(); // text props only; visual props excluded
final finalStyle = mergedFromConfig.merge(cascadedParent); // inline/class win over parent cascade
// → result stored in Map<String, Style> (nodeId → resolvedStyle); renderers do O(1) lookup
```

Only visual render context (rootHeight, the resolved styles map, unitId, callbacks, client font) is
carried down the tree via the `NativeDisplayScope` InheritedWidget — not a cascading `TextStyle`.
Separately, the ND root is wrapped in a hermetic `DefaultTextStyle` (`inherit: false`) so unset text
props reset to engine defaults instead of leaking from the host app's Material theme.

---

## Background Rendering

```dart
BoxDecoration _buildBoxDecoration(Style style) {
  return BoxDecoration(
    color: style.backgroundColor != null ? parseColor(style.backgroundColor!) : null,
    gradient: _buildGradient(style.background),
    image: _buildDecorationImage(style.background),
    borderRadius: style.borderRadius != null
        ? BorderRadius.circular(_resolveRadius(style.borderRadius!, rootHeight))
        : null,
    border: style.borderWidth != null
        ? Border.all(
            color: parseColor(style.borderColor ?? '#000000'),
            width: rootHeight * (style.borderWidth ?? 0) / 1000,
          )
        : null,
    boxShadow: _buildBoxShadow(style),
  );
}
```

---

## Video Element Pipeline

> **Add-on, not core.** VIDEO (and HTML) renderers live in the optional `clevertap_native_display_video`
> / `clevertap_native_display_webview` packages and register into `NativeDisplayRenderers`
> (`nd_element_registry.dart`). The core does NOT depend on `video_player` / `webview_flutter`.
> If no builder is registered for VIDEO/HTML the element renders `SizedBox.shrink()` and logs a
> warning. The pattern below is what such an add-on's builder implements.

```dart
// StatefulWidget required for lifecycle management
class VideoElement extends StatefulWidget { ... }

class _VideoElementState extends State<VideoElement> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      if (widget.autoPlay) _controller!.play();
      if (widget.loop) _controller!.setLooping(true);
      _controller!.setVolume(widget.muted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
```
