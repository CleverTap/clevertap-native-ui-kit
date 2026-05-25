import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../widgets/json_loader.dart';
import '../widgets/error_widget.dart';

class BannerDetailScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const BannerDetailScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<NativeDisplayConfig?>(
        future: JsonLoader.loadFromAsset(assetPath),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data == null) {
            return Center(child: ErrorDisplay(message: 'Failed to load $assetPath'));
          }
          return SingleChildScrollView(
            child: NativeDisplayView(config: snap.data!),
          );
        },
      ),
    );
  }
}
