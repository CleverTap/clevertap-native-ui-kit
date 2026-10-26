import 'package:flutter/material.dart';

import 'screens/clevertap_integration_screen.dart';
import 'screens/slot_demo_screen.dart';
import 'screens/test_browser_screen.dart';
import 'screens/more_menu_screen.dart';

class NativeDisplaySampleApp extends StatelessWidget {
  const NativeDisplaySampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8));
    return MaterialApp(
      title: 'Native Display Sample',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        // Make the top bar read like the native samples rather than a bold
        // Material primary block: a flat, surface-coloured bar with a centred
        // inline title — mirroring iOS's `.navigationBarTitleDisplayMode(.inline)`
        // and staying unobtrusive on Android (whose main tabs have no bar at all).
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          CleverTapIntegrationScreen(),
          SlotDemoScreen(),
          TestBrowserScreen(),
          MoreMenuScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wifi_tethering), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.view_stream), label: 'Slots'),
          NavigationDestination(icon: Icon(Icons.science), label: 'Browser'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
