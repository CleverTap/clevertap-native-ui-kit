import '../models/native_display_config.dart';
import '../models/native_display_node.dart';
import '../models/style.dart';

class StyleResolver {
  Map<String, Style> resolveAll(
    NativeDisplayNode? root,
    NDTheme theme,
    List<StyleClass> styleClasses,
  ) {
    if (root == null) return const {};
    final classMap = {for (final sc in styleClasses) sc.name: sc.style};
    final resolved = <String, Style>{};
    _traverse(root, theme.defaultStyle, classMap, theme, resolved);
    return resolved;
  }

  void _traverse(
    NativeDisplayNode node,
    Style parentStyle,
    Map<String, Style> classMap,
    NDTheme theme,
    Map<String, Style> out,
  ) {
    final baseStyle = _resolveColors(theme.defaultStyle, theme);
    final classStyle = node.styleClass != null
        ? _resolveColors(classMap[node.styleClass] ?? Style.empty, theme)
        : Style.empty;
    final inlineStyle = _resolveColors(node.style ?? Style.empty, theme);

    final mergedFromConfig = inlineStyle.merge(classStyle).merge(baseStyle);
    final cascadedParent = parentStyle.cascadingOnly();
    final finalStyle = mergedFromConfig.merge(cascadedParent);

    out[node.id] = finalStyle;

    if (node is NativeDisplayContainer) {
      for (final child in node.children) {
        _traverse(child, finalStyle, classMap, theme, out);
      }
    }
  }

  Style _resolveColors(Style style, NDTheme theme) {
    return Style(
      textColor: _resolveColor(style.textColor, theme),
      backgroundColor: _resolveColor(style.backgroundColor, theme),
      borderColor: _resolveColor(style.borderColor, theme),
      fontSize: style.fontSize,
      fontFamily: style.fontFamily,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      lineHeight: style.lineHeight,
      letterSpacing: style.letterSpacing,
      textDecoration: style.textDecoration,
      textAlign: style.textAlign,
      maxLines: style.maxLines,
      overflow: style.overflow,
      textShadow: style.textShadow,
      textGradient: style.textGradient,
      opacity: style.opacity,
      borderRadius: style.borderRadius,
      borderWidth: style.borderWidth,
      shadowColor: _resolveColor(style.shadowColor, theme),
      shadowOffsetX: style.shadowOffsetX,
      shadowOffsetY: style.shadowOffsetY,
      shadowRadius: style.shadowRadius,
      background: style.background,
    );
  }

  String? _resolveColor(String? color, NDTheme theme) {
    if (color == null) return null;
    if (color.startsWith('#')) return color;
    return theme.getColor(color) ?? color;
  }
}
