# Flutter SDK Performance Guide

## Core Rule: Build Phase Must Be Fast

Flutter's `build()` method can run 60+ times per second. Every unnecessary computation in build causes frame drops.

---

## 1. Pre-Resolve Styles Before Build

**Critical**: resolve all styles once in `NativeDisplayView`'s constructor — never inside `build()` or inside any widget's build method.

```dart
class NativeDisplayView extends StatelessWidget {
  final NativeDisplayConfig config;
  // Pre-computed in constructor — O(n) traversal happens once
  final Map<String, Style> _resolvedStyles;

  NativeDisplayView({super.key, required this.config})
      : _resolvedStyles = StyleResolver.resolve(config);

  @override
  Widget build(BuildContext context) {
    // _resolvedStyles already computed — just pass through
    return NativeDisplayRenderer(config: config, resolvedStyles: _resolvedStyles);
  }
}
```

Lookup during render: `_resolvedStyles[node.id] ?? Style.empty` — O(1).

---

## 2. Use `const` Constructors Everywhere Possible

Flutter short-circuits rebuild work for `const` widgets — they are identical across rebuilds and reuse the same element.

```dart
// ✅ const where all fields are compile-time constants
const SizedBox(height: 16)
const Padding(padding: EdgeInsets.all(8), child: Text('Hello'))

// ✅ Mark leaf widgets const when they have no dynamic data
const NativeDisplayTextStyle(textStyle: TextStyle(), child: SizedBox())
```

Our model widgets (containers, elements) will rarely be `const` since they take dynamic data — but their sub-widgets (separators, empty states, loading indicators) should be `const`.

---

## 3. RepaintBoundary Around Gallery Items

Gallery items animate independently. Wrapping each in `RepaintBoundary` isolates repaint so only the active item repaints, not the entire gallery.

```dart
Widget _buildGalleryItem(NativeDisplayNode item, Map<String, Style> resolvedStyles) {
  return RepaintBoundary(
    child: NativeDisplayRenderer(node: item, resolvedStyles: resolvedStyles),
  );
}
```

---

## 4. ListView.builder / PageView for Long Galleries

Never render all gallery items at once with `Column` or `children: [...]` for large galleries.

```dart
// ✅ Lazy — only visible items are built
PageView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => RepaintBoundary(
    child: NativeDisplayRenderer(node: items[index], resolvedStyles: resolvedStyles),
  ),
)

// ❌ Eagerly builds all items
PageView(children: items.map((item) => NativeDisplayRenderer(...)).toList())
```

For `FREE_FLOW_GRID`, use `SliverGrid` / `GridView.builder` with a fixed `SliverGridDelegate`.

---

## 5. Avoid Unnecessary `Opacity` Widget

`Opacity` triggers an offscreen render pass (`saveLayer()`), which is expensive.

```dart
// ✅ Apply opacity directly to Color — no saveLayer
Color.fromRGBO(255, 0, 0, 0.5)   // Dart
parseColor('#FF000080')            // RGBA #RRGGBBAA with 50% alpha

// ✅ For images, use colorBlendMode on the Image widget
Image.network(url, color: Colors.black.withOpacity(0.5), colorBlendMode: BlendMode.dstATop)

// ❌ Only use Opacity widget when there is no alternative (e.g. animating opacity)
Opacity(opacity: 0.5, child: ComplexWidget())
```

When opacity comes from the style and is static, apply it directly to the color. Only use the `Opacity` widget if animating.

---

## 6. Avoid `saveLayer()` — Minimize Shader/ColorFilter Usage

These widgets always call `saveLayer()` and are expensive:
- `ShaderMask` — only use for gradient text (unavoidable)
- `ColorFilter` — only for image color tinting
- `BackdropFilter` — only for blur effects

Gradient backgrounds via `BoxDecoration.gradient` are fine — they do not trigger `saveLayer()`.

---

## 7. Fixed-Size Grid Delegates Avoid Intrinsic Passes

For `FREE_FLOW_GRID` gallery mode, always specify a fixed cross-axis count or extent:

```dart
// ✅ No intrinsic pass — sizes are known up front
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.5,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: items.length,
  itemBuilder: (context, i) => NativeDisplayRenderer(node: items[i], resolvedStyles: styles),
)

// ❌ Forces intrinsic pass — measures all items to determine uniform size
GridView(children: items.map(...).toList())
```

---

## 8. `LayoutBuilder` — Use Sparingly

`LayoutBuilder` forces a layout pass to provide constraints. Use it only where percent dimensions or aspect ratios are present.

```dart
// Only wrap in LayoutBuilder if the node actually has percent dimensions
bool _needsLayoutBuilder(Layout layout) {
  return layout.width?.unit == 'percent'
      || layout.height?.unit == 'percent'
      || layout.width?.aspectRatio != null;
}

Widget buildNode(NativeDisplayNode node) {
  if (_needsLayoutBuilder(node.layout)) {
    return LayoutBuilder(builder: (ctx, constraints) => _buildWithConstraints(node, constraints));
  }
  return _buildFixed(node);
}
```

---

## 9. Image Caching

Flutter's `Image.network` uses an in-memory `ImageCache` (1000 images, 100MB limit). For production, use `cached_network_image` for disk caching:

```dart
CachedNetworkImage(
  imageUrl: url,
  fit: BoxFit.cover,
  placeholder: (ctx, url) => const ColoredBox(color: Color(0xFFE0E0E0)),
  errorWidget: (ctx, url, err) => const SizedBox.shrink(),
)
```

Pre-warming the cache before the widget renders eliminates loading flicker:
```dart
precacheImage(NetworkImage(url), context);
```

---

## 10. Immutable Models — No `==` Override on Widgets

All data classes (`NativeDisplayConfig`, `NativeDisplayNode`, `Style`, `Layout`, etc.) should be immutable (final fields, no setters). This is not just for correctness — it ensures Flutter's element diffing can rely on object identity.

**Do not** override `operator ==` on widget classes — Flutter's framework caches widget configurations using object identity, and custom `==` can interfere.

---

## Profiling

Measure in **profile mode** (`flutter run --profile`) on a real device (or the lowest-spec emulator/simulator you target):

```bash
flutter run --profile
# Then press 'P' in terminal to launch DevTools performance view
```

Key DevTools views:
- **Timeline**: frame build time, identify janky frames (>16ms at 60Hz, >8ms at 120Hz)
- **Widget rebuild information**: shows unnecessary rebuilds (enable in IDE Flutter plugin)
- **Memory**: check for leaked VideoPlayerControllers, ImageProviders

Target: build phase < 8ms, render phase < 8ms for 60fps apps.
