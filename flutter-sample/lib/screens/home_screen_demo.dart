import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../widgets/json_loader.dart';
import '../widgets/error_widget.dart';

class HomeScreenDemo extends StatefulWidget {
  const HomeScreenDemo({super.key});

  @override
  State<HomeScreenDemo> createState() => _HomeScreenDemoState();
}

class _HomeScreenDemoState extends State<HomeScreenDemo> {
  NativeDisplayConfig? _config;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await JsonLoader.loadFromAsset('assets/configs/home_screen.json');
    if (!mounted) return;
    setState(() {
      _config = config;
      _error = config == null ? 'Failed to load home_screen.json' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: ErrorDisplay(message: _error!));
    if (_config == null) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      child: NativeDisplayView(
        config: _config!,
        actionListener: (action, nodeId, params) {
          debugPrint('[HomeScreen] action=$action nodeId=$nodeId params=$params');
        },
        componentListener: (event, nodeId, params) {
          debugPrint('[HomeScreen] event=$event nodeId=$nodeId');
          return false;
        },
      ),
    );
  }
}
