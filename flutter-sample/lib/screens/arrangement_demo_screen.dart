import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../widgets/json_loader.dart';
import '../widgets/error_widget.dart';

class _Strategy {
  final String label;
  final ArrangementStrategy strategy;
  final double? spacing;

  const _Strategy(this.label, this.strategy, {this.spacing});
}

const _strategies = [
  _Strategy('SPACED', ArrangementStrategy.spaced, spacing: 16),
  _Strategy('BETWEEN', ArrangementStrategy.spaceBetween),
  _Strategy('EVENLY', ArrangementStrategy.spaceEvenly),
  _Strategy('AROUND', ArrangementStrategy.spaceAround),
  _Strategy('START', ArrangementStrategy.start),
  _Strategy('CENTER', ArrangementStrategy.center),
  _Strategy('END', ArrangementStrategy.end),
];

class ArrangementDemoScreen extends StatefulWidget {
  const ArrangementDemoScreen({super.key});

  @override
  State<ArrangementDemoScreen> createState() => _ArrangementDemoScreenState();
}

class _ArrangementDemoScreenState extends State<ArrangementDemoScreen> {
  NativeDisplayConfig? _baseConfig;
  NativeDisplayConfig? _displayConfig;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await JsonLoader.loadFromAsset('assets/configs/arrangement_demo.json');
    if (config == null) {
      setState(() => _error = 'Failed to load arrangement_demo.json');
      return;
    }
    setState(() {
      _baseConfig = config;
      _displayConfig = config;
    });
  }

  void _applyStrategy(int index) {
    final s = _strategies[index];
    final base = _baseConfig;
    if (base == null) return;

    final root = base.root;
    if (root == null || root is! NativeDisplayContainer) {
      setState(() {
        _selectedIndex = index;
        _displayConfig = base;
      });
      return;
    }

    final newArrangement = ChildArrangement(
      spacing: s.spacing,
      strategy: s.strategy,
    );

    final updatedLayout = Layout(
      width: root.layout?.width,
      height: root.layout?.height,
      aspectRatio: root.layout?.aspectRatio,
      offset: root.layout?.offset,
      padding: root.layout?.padding,
      arrangement: newArrangement,
    );

    final updatedRoot = NativeDisplayContainer(
      id: root.id,
      containerType: root.containerType,
      children: root.children,
      layout: updatedLayout,
      style: root.style,
      styleClass: root.styleClass,
      visible: root.visible,
      actions: root.actions,
      animation: root.animation,
      galleryConfig: root.galleryConfig,
      dividerConfig: root.dividerConfig,
    );

    setState(() {
      _selectedIndex = index;
      _displayConfig = NativeDisplayConfig(
        version: base.version,
        theme: base.theme,
        styleClasses: base.styleClasses,
        variables: base.variables,
        root: updatedRoot,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arrangements')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_strategies.length, (i) {
                final s = _strategies[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.label),
                    selected: _selectedIndex == i,
                    onSelected: (_) => _applyStrategy(i),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: _error != null
                  ? Center(child: ErrorDisplay(message: _error!))
                  : _displayConfig == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: NativeDisplayView(config: _displayConfig!),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
