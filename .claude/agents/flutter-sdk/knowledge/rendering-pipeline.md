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
Widget renderVertical(ContainerNode node, List<Widget> children, Style style) {
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
Widget renderHorizontal(ContainerNode node, List<Widget> children) {
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
Widget renderBox(ContainerNode node, List<Widget> children, Style style) {
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
Widget renderGallery(ContainerNode node, List<Widget> children, GalleryConfig config) {
  return switch (config.mode) {
    GalleryMode.snapping => _buildPageView(node, children, config),
    GalleryMode.freeFlow => _buildScrollView(node, children, config),
    GalleryMode.freeFlowGrid => _buildGridView(node, children, config),
  };
}

Widget _buildPageView(ContainerNode node, List<Widget> children, GalleryConfig config) {
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
Widget renderText(ElementNode node, Style style) {
  final text = TemplateEvaluator.evaluate(node.bindings['text'] ?? '', variables);
  final inherited = NativeDisplayTextStyle.of(context); // cascaded from parent

  return Text(
    text,
    maxLines: style.maxLines,
    overflow: _toOverflow(style.overflow),
    style: inherited.copyWith(
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
Widget renderImage(ElementNode node, Style style) {
  final url = TemplateEvaluator.evaluate(node.bindings['url'] ?? '', variables);
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
Widget renderButton(ElementNode node, Style style) {
  final text = TemplateEvaluator.evaluate(node.bindings['text'] ?? '', variables);

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

Every node's width and height must be resolved against parent constraints.

```dart
class DimensionCalculator {
  static double? resolve(Dimension? dim, double parentSize, double rootHeight) {
    if (dim == null) return null;
    if (dim.special == 'match_parent') return parentSize;
    if (dim.special == 'wrap_content') return null;   // null → intrinsic size
    if (dim.unit == 'percent') return parentSize * dim.value / 100;
    if (dim.aspectRatio != null) return null;          // caller handles aspect ratio
    return dim.value; // dp/sp/px — treat as logical pixels
  }
}

// Usage: always wrap in LayoutBuilder when percent dimensions are used
Widget buildConstrainedNode(NativeDisplayNode node, List<Widget>? children) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final w = DimensionCalculator.resolve(node.layout.width, constraints.maxWidth, rootHeight);
      final h = DimensionCalculator.resolve(node.layout.height, constraints.maxHeight, rootHeight);

      // Handle aspect ratio
      Widget child = buildContent(node, children);
      if (node.layout.width?.aspectRatio != null) {
        child = AspectRatio(
          aspectRatio: node.layout.width!.aspectRatio!,
          child: child,
        );
      }

      return SizedBox(width: w, height: h, child: child);
    },
  );
}
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

## Text Style Cascading via InheritedWidget

Text properties cascade from parent containers to all descendants. Wrap containers with the inherited widget:

```dart
// When rendering a container with a style that has text properties:
Widget wrapWithTextStyle(Widget child, Style style) {
  final inherited = NativeDisplayTextStyle.of(context);
  final merged = inherited.copyWith(
    color: style.textColor != null ? parseColor(style.textColor!) : null,
    fontSize: style.fontSize?.resolve(rootHeight),
    // ... other text properties
  );
  return NativeDisplayTextStyle(textStyle: merged, child: child);
}
```

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
