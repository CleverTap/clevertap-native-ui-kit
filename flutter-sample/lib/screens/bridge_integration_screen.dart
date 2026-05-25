import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../widgets/json_loader.dart';
import '../widgets/error_widget.dart';

class BridgeIntegrationScreen extends StatelessWidget {
  const BridgeIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bridge Integration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bridge Integration Demo',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Demonstrates how NativeDisplayBridge.fetchConfig() retrieves configs from '
              'the native CleverTap Core SDK. The cards below load mock JSON configs '
              'from the local assets folder to simulate bridge payloads.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF666666)),
            ),
            const Divider(height: 32),
            _ConfigSection(
              title: 'Mock Product Unit',
              description: 'Simulates a product display unit delivered by the Core SDK.',
              assetPath: 'assets/configs/bridge_mock_product.json',
            ),
            const SizedBox(height: 24),
            _ConfigSection(
              title: 'Mock Notification Unit',
              description: 'Simulates a notification-style display unit.',
              assetPath: 'assets/configs/bridge_mock_notification.json',
            ),
            const SizedBox(height: 32),
            _ApiInfoCard(),
          ],
        ),
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final String title;
  final String description;
  final String assetPath;

  const _ConfigSection({
    required this.title,
    required this.description,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 4),
        Text(description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF666666))),
        const SizedBox(height: 12),
        FutureBuilder<NativeDisplayConfig?>(
          future: JsonLoader.loadFromAsset(assetPath),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
            }
            if (snap.data == null) {
              return ErrorDisplay(message: 'Failed to load $assetPath');
            }
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: NativeDisplayView(config: snap.data!),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ApiInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const snippet = '''// Fetch a config from the Core SDK by unit ID
final config = await NativeDisplayBridge.fetchConfig('my-unit-id');
if (config != null) {
  // Pass directly to NativeDisplayView
  NativeDisplayView(config: config)
}

// Report analytics events
await NativeDisplayBridge.pushViewedEvent(unitId);
await NativeDisplayBridge.pushClickedEvent(unitId, elementId: nodeId);''';

    return Card(
      elevation: 0,
      color: const Color(0xFFF0F4FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bridge API',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1565C0))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                snippet,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF1565C0),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
