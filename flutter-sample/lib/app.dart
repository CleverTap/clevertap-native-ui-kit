import 'package:flutter/material.dart';

import 'screens/clevertap_integration_screen.dart';
import 'screens/slot_demo_screen.dart';
import 'screens/test_browser_screen.dart';
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
