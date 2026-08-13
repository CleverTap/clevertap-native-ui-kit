import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/json_loader.dart';

class JsonViewerScreen extends StatelessWidget {
  final String assetPath;
  final String? rawJson;

  const JsonViewerScreen({super.key, required this.assetPath, this.rawJson});

  @override
  Widget build(BuildContext context) {
    if (rawJson != null) {
      return _JsonViewerScaffold(assetPath: assetPath, json: rawJson!);
    }
    return FutureBuilder<String?>(
      future: JsonLoader.loadStringFromAsset(assetPath),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final json = snap.data ?? 'Failed to load $assetPath';
        return _JsonViewerScaffold(assetPath: assetPath, json: json);
      },
    );
  }
}

class _JsonViewerScaffold extends StatelessWidget {
  final String assetPath;
  final String json;

  const _JsonViewerScaffold({required this.assetPath, required this.json});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          assetPath.split('/').last,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy JSON',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          json,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}
