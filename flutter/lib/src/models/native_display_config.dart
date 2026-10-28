import 'package:flutter/foundation.dart';

import 'native_display_node.dart';
import 'style.dart';

// Order-independent hash for a nullable map — pairs with mapEquals.
int _mapHash(Map<Object?, Object?>? map) {
  if (map == null) return null.hashCode;
  var h = 0;
  for (final e in map.entries) {
    h ^= Object.hash(e.key, e.value);
  }
  return Object.hash(map.length, h);
}

@immutable
class NDTheme {
  final String id;
  final Style defaultStyle;
  final Map<String, String> colors;

  const NDTheme({
    required this.id,
    this.defaultStyle = Style.empty,
    this.colors = const {},
  });

  static const empty = NDTheme(id: 'default');

  String? getColor(String name) => colors[name];

  factory NDTheme.fromJson(Map<String, dynamic> json) => NDTheme(
        id: json['id'] as String? ?? 'default',
        defaultStyle: json['defaultStyle'] != null
            ? Style.fromJson(json['defaultStyle'] as Map<String, dynamic>)
            : Style.empty,
        colors: (json['colors'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v?.toString() ?? '')) ??
            const {},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NDTheme &&
          other.id == id &&
          other.defaultStyle == defaultStyle &&
          mapEquals(other.colors, colors);

  @override
  int get hashCode => Object.hash(id, defaultStyle, _mapHash(colors));
}

@immutable
class StyleClass {
  final String name;
  final Style style;

  const StyleClass({required this.name, required this.style});

  factory StyleClass.fromJson(Map<String, dynamic> json) => StyleClass(
        name: json['name'] as String? ?? '',
        style: json['style'] != null
            ? Style.fromJson(json['style'] as Map<String, dynamic>)
            : Style.empty,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StyleClass && other.name == name && other.style == style;

  @override
  int get hashCode => Object.hash(name, style);
}

@immutable
class NativeDisplayConfig {
  final String version;
  final NDTheme? theme;
  final List<StyleClass> styleClasses;
  final Map<String, dynamic> variables;
  final NativeDisplayNode? root;

  const NativeDisplayConfig({
    this.version = '1.0',
    this.theme,
    this.styleClasses = const [],
    this.variables = const {},
    this.root,
  });

  factory NativeDisplayConfig.fromJson(Map<String, dynamic> json) => NativeDisplayConfig(
        version: json['version'] as String? ?? '1.0',
        theme: json['theme'] != null
            ? NDTheme.fromJson(json['theme'] as Map<String, dynamic>)
            : null,
        styleClasses: (json['styleClasses'] as List?)
                ?.map((e) => StyleClass.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        variables: json['variables'] as Map<String, dynamic>? ?? const {},
        root: json['root'] != null
            ? NativeDisplayNode.fromJson(json['root'] as Map<String, dynamic>)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeDisplayConfig &&
          other.version == version &&
          other.theme == theme &&
          listEquals(other.styleClasses, styleClasses) &&
          mapEquals(other.variables, variables) &&
          other.root == root;

  @override
  int get hashCode => Object.hash(
        version,
        theme,
        Object.hashAll(styleClasses),
        _mapHash(variables),
        root,
      );
}
