import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../widgets/json_loader.dart';
import '../widgets/error_widget.dart';

const _demos = [
  ('Container Fade', 'assets/configs/animation_container_fade.json',
      'Entire container fades in (500ms). All children appear together.'),
  ('Staggered Children', 'assets/configs/animation_staggered_children.json',
      'Each child slides in from left with 100ms stagger delay.'),
  ('Container + Children', 'assets/configs/animation_container_and_children.json',
      'Container fades in first, then children animate in sequence.'),
];

class AnimationDemoScreen extends StatefulWidget {
  const AnimationDemoScreen({super.key});

  @override
  State<AnimationDemoScreen> createState() => _AnimationDemoScreenState();
}

class _AnimationDemoScreenState extends State<AnimationDemoScreen> {
  int _selectedDemo = 0;
  NativeDisplayConfig? _config;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDemo(0);
  }

  Future<void> _loadDemo(int index) async {
    setState(() {
      _config = null;
      _error = null;
      _selectedDemo = index;
    });
    final config = await JsonLoader.loadFromAsset(_demos[index].$2);
    if (!mounted) return;
    setState(() {
      if (config == null) {
        _error = 'Failed to load ${_demos[index].$1}';
      } else {
        _config = config;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animations')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_demos.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_demos[i].$1),
                    selected: _selectedDemo == i,
                    onSelected: (_) => _loadDemo(i),
                  ),
                );
              }),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFE65100), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _demos[_selectedDemo].$3,
                    style: const TextStyle(color: Color(0xFFE65100), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: _error != null
                  ? Center(child: ErrorDisplay(message: _error!))
                  : _config == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: NativeDisplayView(
                            key: ValueKey(_selectedDemo),
                            config: _config!,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
