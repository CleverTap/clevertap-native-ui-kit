import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import 'json_loader.dart';
import 'error_widget.dart';
import '../screens/json_viewer_screen.dart';

class NdDemoCard extends StatelessWidget {
  final String assetPath;
  final String title;

  const NdDemoCard({super.key, required this.assetPath, required this.title});

  void _showJsonViewer(BuildContext context, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JsonViewerScreen(assetPath: assetPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NativeDisplayConfig?>(
      future: JsonLoader.loadFromAsset(assetPath),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == null) {
          return ErrorDisplay(message: 'Failed to load $assetPath');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  tooltip: 'View JSON',
                  onPressed: () => _showJsonViewer(context, assetPath),
                ),
              ],
            ),
            NativeDisplayView(config: snap.data!),
          ],
        );
      },
    );
  }
}
