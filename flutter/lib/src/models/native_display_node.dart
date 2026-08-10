import 'action.dart';
import 'enums.dart';
import 'gallery_config.dart';
import 'layout.dart';
import 'node_config.dart';
import 'style.dart';

// Binding values arrive as String / bool / int / double depending on the source
// (dashboard emits strings; programmatic JSON often uses native types). Coerce
// non-string scalars to their canonical string form so downstream consumers
// (VariableEvaluator, renderers) can treat bindings as Map<String,String>.
String _coerceBindingValue(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is bool) return v ? 'true' : 'false';
  return v.toString();
}

sealed class NativeDisplayNode {
  final String id;
  final Layout? layout;
  final Style? style;
  final String? styleClass;
  final String? visible;
  final Map<String, NDAction>? actions;
  final NDAnimation? animation;

  const NativeDisplayNode({
    required this.id,
    this.layout,
    this.style,
    this.styleClass,
    this.visible,
    this.actions,
    this.animation,
  });

  factory NativeDisplayNode.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'element';
    return switch (type) {
      'container' => NativeDisplayContainer.fromJson(json),
      _ => NativeDisplayElement.fromJson(json),
    };
  }
}

class NativeDisplayContainer extends NativeDisplayNode {
  final ContainerType containerType;
  final List<NativeDisplayNode> children;
  final GalleryConfig? galleryConfig;
  final DividerConfig? dividerConfig;

  const NativeDisplayContainer({
    required super.id,
    required this.containerType,
    this.children = const [],
    super.layout,
    super.style,
    super.styleClass,
    super.visible,
    super.actions,
    super.animation,
    this.galleryConfig,
    this.dividerConfig,
  });

  factory NativeDisplayContainer.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'] as Map<String, dynamic>?;
    return NativeDisplayContainer(
      id: json['id'] as String? ?? '',
      containerType: ContainerType.fromJson(json['containerType'] as String? ?? 'box'),
      children: (json['children'] as List?)
              ?.map((e) => NativeDisplayNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      layout: json['layout'] != null
          ? Layout.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
      style: json['style'] != null ? Style.fromJson(json['style'] as Map<String, dynamic>) : null,
      styleClass: json['styleClass'] as String?,
      visible: json['visible'] as String?,
      actions: rawActions?.map(
        (k, v) => MapEntry(k, NDAction.fromJson(v as Map<String, dynamic>)),
      ),
      animation: json['animation'] != null
          ? NDAnimation.fromJson(json['animation'] as Map<String, dynamic>)
          : null,
      galleryConfig: json['galleryConfig'] != null
          ? GalleryConfig.fromJson(json['galleryConfig'] as Map<String, dynamic>)
          : null,
      dividerConfig: json['dividerConfig'] != null
          ? DividerConfig.fromJson(json['dividerConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}

class NativeDisplayElement extends NativeDisplayNode {
  final ElementType elementType;
  final Map<String, String> bindings;
  final DividerConfig? dividerConfig;
  final ImageConfig? imageConfig;
  final HtmlConfig? htmlConfig;

  const NativeDisplayElement({
    required super.id,
    required this.elementType,
    this.bindings = const {},
    super.layout,
    super.style,
    super.styleClass,
    super.visible,
    super.actions,
    super.animation,
    this.dividerConfig,
    this.imageConfig,
    this.htmlConfig,
  });

  factory NativeDisplayElement.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'] as Map<String, dynamic>?;
    return NativeDisplayElement(
      id: json['id'] as String? ?? '',
      elementType: ElementType.fromJson(json['elementType'] as String? ?? 'text'),
      bindings: (json['bindings'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, _coerceBindingValue(v))) ??
          const {},
      layout: json['layout'] != null
          ? Layout.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
      style: json['style'] != null ? Style.fromJson(json['style'] as Map<String, dynamic>) : null,
      styleClass: json['styleClass'] as String?,
      visible: json['visible'] as String?,
      actions: rawActions?.map(
        (k, v) => MapEntry(k, NDAction.fromJson(v as Map<String, dynamic>)),
      ),
      animation: json['animation'] != null
          ? NDAnimation.fromJson(json['animation'] as Map<String, dynamic>)
          : null,
      dividerConfig: json['dividerConfig'] != null
          ? DividerConfig.fromJson(json['dividerConfig'] as Map<String, dynamic>)
          : null,
      imageConfig: json['imageConfig'] != null
          ? ImageConfig.fromJson(json['imageConfig'] as Map<String, dynamic>)
          : null,
      htmlConfig: json['htmlConfig'] != null
          ? HtmlConfig.fromJson(json['htmlConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}
