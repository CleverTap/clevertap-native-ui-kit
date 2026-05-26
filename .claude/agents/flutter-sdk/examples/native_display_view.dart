// Example: NativeDisplayView entry point — pure Dart renderer
//
// Usage:
//   final config = NativeDisplayConfig.fromJson(jsonDecode(jsonString));
//   NativeDisplayView(config: config)

import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../models/native_display_config.dart';
import '../models/native_display_node.dart';
import '../models/style.dart';
import '../renderer/container_renderer.dart';
import '../renderer/element_renderer.dart';
import '../style/style_resolver.dart';
import '../style/native_display_text_style.dart';
import '../evaluator/template_evaluator.dart';

/// Public entry point for rendering a Native Display configuration.
class NativeDisplayView extends StatelessWidget {
  final NativeDisplayConfig config;
  final NativeDisplayActionListener? actionListener;

  // Styles are pre-resolved once in constructor — never inside build()
  final Map<String, Style> _resolvedStyles;

  NativeDisplayView({
    super.key,
    required this.config,
    this.actionListener,
  }) : _resolvedStyles = StyleResolver.resolve(config);

  @override
  Widget build(BuildContext context) {
    return _NativeDisplayRenderer(
      node: config.root,
      config: config,
      resolvedStyles: _resolvedStyles,
      actionListener: actionListener,
    );
  }
}

/// Convenience constructor — parse JSON string and render.
class NativeDisplayViewFromJson extends StatefulWidget {
  final String jsonString;
  final NativeDisplayActionListener? actionListener;

  const NativeDisplayViewFromJson({
    super.key,
    required this.jsonString,
    this.actionListener,
  });

  @override
  State<NativeDisplayViewFromJson> createState() => _NativeDisplayViewFromJsonState();
}

class _NativeDisplayViewFromJsonState extends State<NativeDisplayViewFromJson> {
  late NativeDisplayConfig _config;

  @override
  void initState() {
    super.initState();
    _config = NativeDisplayConfig.fromJson(jsonDecode(widget.jsonString));
  }

  @override
  void didUpdateWidget(NativeDisplayViewFromJson oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonString != widget.jsonString) {
      _config = NativeDisplayConfig.fromJson(jsonDecode(widget.jsonString));
    }
  }

  @override
  Widget build(BuildContext context) =>
      NativeDisplayView(config: _config, actionListener: widget.actionListener);
}

// ---------------------------------------------------------------------------
// Internal renderer — not part of public API
// ---------------------------------------------------------------------------

class _NativeDisplayRenderer extends StatelessWidget {
  final NativeDisplayNode node;
  final NativeDisplayConfig config;
  final Map<String, Style> resolvedStyles;
  final NativeDisplayActionListener? actionListener;

  const _NativeDisplayRenderer({
    required this.node,
    required this.config,
    required this.resolvedStyles,
    this.actionListener,
  });

  @override
  Widget build(BuildContext context) {
    final style = resolvedStyles[node.id] ?? Style.empty;
    final variables = config.variables ?? {};

    final Widget content = switch (node) {
      ContainerNode() => ContainerRenderer(
          node: node as ContainerNode,
          resolvedStyles: resolvedStyles,
          config: config,
          actionListener: actionListener,
        ),
      ElementNode() => ElementRenderer(
          node: node as ElementNode,
          style: style,
          variables: variables,
          actionListener: actionListener,
        ),
    };

    // Wrap container with text style cascade if container has text style properties
    if (node is ContainerNode && _hasTextStyle(style)) {
      return NativeDisplayTextStyle(
        textStyle: _buildTextStyle(style),
        child: content,
      );
    }

    return content;
  }

  bool _hasTextStyle(Style style) =>
      style.textColor != null ||
      style.fontSize != null ||
      style.fontFamily != null ||
      style.fontWeight != null;

  TextStyle _buildTextStyle(Style style) => const TextStyle(); // full impl in style_resolver.dart
}

/// Callback interface for user interactions (taps on BUTTON elements, etc.)
abstract class NativeDisplayActionListener {
  void onAction(NodeAction? action);
  void onViewed(String nodeId);
  void onClicked(String nodeId);
}
