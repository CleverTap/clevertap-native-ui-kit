# Flutter Sample App Architecture

## Overview

The Flutter sample app (`flutter-sample/`) demonstrates the Native Display SDK with real JSON-driven UI examples. It is a standalone Flutter application, separate from the plugin package itself.

## Navigation Architecture

```
MaterialApp (GoRouter)
└── ShellRoute (NavigationBar)
    ├── /home                  → HomeScreen (demo grid)
    ├── /containers            → ContainersScreen
    │   ├── /containers/vertical
    │   ├── /containers/horizontal
    │   ├── /containers/box
    │   └── /containers/gallery
    ├── /elements              → ElementsScreen
    │   ├── /elements/text
    │   ├── /elements/image
    │   ├── /elements/button
    │   └── /elements/video
    └── /styles                → StylesScreen
        ├── /styles/theme
        ├── /styles/backgrounds
        └── /styles/typography
```

## File Structure

```
flutter-sample/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp + GoRouter setup
│   ├── navigation/
│   │   └── app_router.dart           # Route definitions
│   ├── screens/
│   │   ├── home_screen.dart          # Grid of DemoCards
│   │   ├── containers/
│   │   │   ├── containers_screen.dart   # List of container demos
│   │   │   ├── vertical_demo.dart
│   │   │   ├── horizontal_demo.dart
│   │   │   ├── box_demo.dart
│   │   │   └── gallery_demo.dart
│   │   ├── elements/
│   │   │   └── [element]_demo.dart
│   │   └── styles/
│   │       └── [style]_demo.dart
│   └── widgets/
│       ├── demo_card.dart            # Tile on HomeScreen
│       ├── demo_scaffold.dart        # Scaffold with "View JSON" button
│       └── json_viewer.dart          # Bottom sheet JSON viewer
├── assets/
│   └── configs/
│       ├── product_card.json
│       ├── gallery_carousel.json
│       └── ...
└── pubspec.yaml
```

## DemoScaffold — Standard Demo Wrapper

Every demo screen uses `DemoScaffold` to provide consistent chrome and the "View JSON" button:

```dart
class DemoScaffold extends StatelessWidget {
  final String title;
  final String assetPath;       // e.g. 'assets/configs/product_card.json'
  final Widget? child;          // pre-built NativeDisplayView

  const DemoScaffold({super.key, required this.title, required this.assetPath, this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'View JSON',
            onPressed: () => _showJson(context),
          ),
        ],
      ),
      body: child,
    );
  }

  void _showJson(BuildContext context) async {
    final json = await rootBundle.loadString(assetPath);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => JsonViewer(json: json),
    );
  }
}
```

## Asset Registration

All JSON files must be declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/configs/
```

Using a directory glob (`assets/configs/`) includes all files in the directory automatically.

## GoRouter Setup

```dart
final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/containers',
          builder: (_, __) => const ContainersScreen(),
          routes: [
            GoRoute(path: 'gallery', builder: (_, __) => const GalleryDemo()),
            GoRoute(path: 'vertical', builder: (_, __) => const VerticalDemo()),
          ],
        ),
        // ...
      ],
    ),
  ],
);
```

## Shared JSON Assets

JSON config files in `assets/configs/` should be identical to those in `android-sample/` and `ios-sample/`. When adding a new demo:
1. Create the JSON once
2. Copy to all three sample app asset directories
3. They render the same JSON — visual differences are expected (font rendering, shadows differ by platform)
