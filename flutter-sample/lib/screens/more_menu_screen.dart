import 'package:flutter/material.dart';

import 'banner_showcase_screen.dart';
import 'arrangement_demo_screen.dart';
import 'animation_demo_screen.dart';
import 'home_screen_demo.dart';
import 'bridge_integration_screen.dart';
import 'slot_demo_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  static const _items = [
    (Icons.image_outlined, 'Banner Showcase', 'Browse all 10 pre-defined banners'),
    (Icons.align_horizontal_left, 'Arrangements', 'Explore all 7 arrangement strategies'),
    (Icons.auto_awesome, 'Animations', 'Container and element animations'),
    (Icons.house_outlined, 'Home Screen', 'Example home screen layout'),
    (Icons.link, 'Bridge Integration', 'Core SDK bridge demo with mock data'),
    (Icons.pin_drop_outlined, 'Slot Demo', 'Mixed content feed with native display slots'),
  ];

  Widget _destinationFor(String title) {
    return switch (title) {
      'Banner Showcase' => const _FullScreenShell(title: 'Banner Showcase', child: BannerShowcaseScreen()),
      'Arrangements' => const ArrangementDemoScreen(),
      'Animations' => const AnimationDemoScreen(),
      'Home Screen' => const _FullScreenShell(title: 'Home Screen', child: _HomeScreenShell()),
      'Bridge Integration' => const BridgeIntegrationScreen(),
      'Slot Demo' => const SlotDemoScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length + 1, // +1 for section header
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Developer Tools',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: const Color(0xFF666666)),
              ),
            );
          }
          final (icon, title, description) = _items[i - 1];
          return ListTile(
            tileColor: Colors.white,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => _destinationFor(title)),
              );
            },
          );
        },
      ),
    );
  }
}

/// Wraps a widget without its own Scaffold in a Scaffold with an AppBar.
class _FullScreenShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _FullScreenShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}

class _HomeScreenShell extends StatelessWidget {
  const _HomeScreenShell();

  @override
  Widget build(BuildContext context) => const HomeScreenDemo();
}
