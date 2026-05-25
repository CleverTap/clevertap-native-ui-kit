import 'native_display_node.dart';
import 'style.dart';

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
                ?.map((k, v) => MapEntry(k, v as String)) ??
            const {},
      );
}

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
}

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
}

// Resolved config — used after StyleResolver fills in all cascading values
class ResolvedConfig {
  final NDTheme theme;
  final List<StyleClass> styleClasses;
  final Map<String, dynamic> variables;
  final NativeDisplayNode root;

  const ResolvedConfig({
    this.theme = NDTheme.empty,
    this.styleClasses = const [],
    this.variables = const {},
    required this.root,
  });
}
