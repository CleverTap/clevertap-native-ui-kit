import 'package:flutter/material.dart';

import 'screens/banner_showcase_screen.dart';
import 'screens/test_browser_screen.dart';
import 'screens/other_demos_screen.dart';
import 'screens/more_menu_screen.dart';

class NativeDisplaySampleApp extends StatelessWidget {
  const NativeDisplaySampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Display Sample',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    BannerShowcaseScreen(),
    TestBrowserScreen(),
    OtherDemosScreen(),
    MoreMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.image), label: 'Banners'),
          NavigationDestination(icon: Icon(Icons.science), label: 'Browser'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Demos'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
