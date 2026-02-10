// MARK: - Style Resolver
// Resolves styles with proper inheritance and priority

import Foundation

/// Resolves styles with proper cascading and priority.
///
/// Priority (highest to lowest):
/// 1. Inline style (node.style)
/// 2. Style class (node.styleClass)
/// 3. Theme default style
public class StyleResolver {
    
    private let theme: Theme
    private let styleClassMap: [String: StyleClass]
    
    public init(theme: Theme, styleClasses: [StyleClass]) {
        self.theme = theme
        self.styleClassMap = Dictionary(uniqueKeysWithValues: styleClasses.map { ($0.name, $0) })
    }
    
    /// Resolve the final style for a node.
    ///
    /// - Parameters:
    ///   - node: The node to resolve style for
    /// - Returns: Fully resolved style
    public func resolve(node: NativeDisplayNode) -> Style {
        // Start with theme default
        var resolvedStyle = theme.defaultStyle

        // Apply style class if specified (overrides theme)
        if let styleClassName = node.styleClass,
           let classStyle = styleClassMap[styleClassName]?.style {
            resolvedStyle = classStyle.mergedWith(resolvedStyle)
        }

        // Apply inline style (highest priority, overrides everything)
        if let nodeStyle = node.style {
            resolvedStyle = nodeStyle.mergedWith(resolvedStyle)
        }

        return resolvedStyle
    }
    
    /// Resolve style for an element with color palette support.
    /// Replaces color names with actual color values from theme.
    public func resolveWithColors(node: NativeDisplayNode) -> Style {
        let style = resolve(node: node)
        
        return Style(
            textColor: resolveColor(style.textColor),
            fontSize: style.fontSize,
            fontFamily: style.fontFamily,
            fontWeight: style.fontWeight,
            lineHeight: style.lineHeight,
            textDecoration: style.textDecoration,
            textAlign: style.textAlign,
            background: style.background,
            backgroundColor: resolveColor(style.backgroundColor),
            borderRadius: style.borderRadius,
            borderWidth: style.borderWidth,
            borderColor: resolveColor(style.borderColor),
            shadowColor: resolveColor(style.shadowColor),
            shadowRadius: style.shadowRadius,
            shadowOffsetX: style.shadowOffsetX,
            shadowOffsetY: style.shadowOffsetY,
            opacity: style.opacity
        )
    }
    
    /// Resolve a color value, checking theme palette if it's a named color.
    private func resolveColor(_ color: String?) -> String? {
        guard let color = color else { return nil }
        
        // If starts with #, it's already a hex color
        if color.hasPrefix("#") {
            return color
        }
        
        // Otherwise, try to get from theme palette
        return theme.getColor(color) ?? color
    }
}
