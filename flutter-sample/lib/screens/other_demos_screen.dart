import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../widgets/json_loader.dart';
import '../widgets/error_widget.dart';

class OtherDemosScreen extends StatelessWidget {
  const OtherDemosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Home Screen'),
              Tab(text: 'Gallery'),
              Tab(text: 'E-commerce'),
              Tab(text: 'Social'),
              Tab(text: 'Dashboard'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _JsonTab(assetPath: 'assets/configs/home_screen.json'),
                _JsonTab(assetPath: 'assets/configs/gallery_three_modes.json'),
                _JsonTab(assetPath: 'assets/configs/showcase_ecommerce_product.json'),
                _JsonTab(assetPath: 'assets/configs/showcase_social_profile.json'),
                _JsonTab(assetPath: 'assets/configs/showcase_dashboard.json'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonTab extends StatefulWidget {
  final String assetPath;

  const _JsonTab({required this.assetPath});

  @override
  State<_JsonTab> createState() => _JsonTabState();
}

class _JsonTabState extends State<_JsonTab> with AutomaticKeepAliveClientMixin {
  NativeDisplayConfig? _config;
  String? _error;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await JsonLoader.loadFromAsset(widget.assetPath);
    if (!mounted) return;
    setState(() {
      _config = config;
      _error = config == null ? 'Failed to load ${widget.assetPath}' : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: ErrorDisplay(message: _error!)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: NativeDisplayView(config: _config!),
    );
  }
}
