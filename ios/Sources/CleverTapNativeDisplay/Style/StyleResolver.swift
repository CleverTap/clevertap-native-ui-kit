// MARK: - Style Resolver
// Resolves styles with proper inheritance and priority

import Foundation

/// Resolves styles with proper inheritance and priority.
///
/// Priority (highest to lowest):
/// 1. Inline style (node.style)
/// 2. Style class (node.styleClass)
/// 3. Inherited style (from parent - cascading properties only)
/// 4. Theme default style
public class StyleResolver {
    
    private let theme: Theme
    private let styleClassMap: [String: StyleClass]
    
    public init(theme: Theme, styleClasses: [StyleClass]) {
        self.theme = theme
        self.styleClassMap = Dictionary(uniqueKeysWithValues: styleClasses.map { ($0.name, $0) })
    }
    
    /// Resolve the final style for a node, considering inheritance.
    ///
    /// - Parameters:
    ///   - node: The node to resolve style for
    ///   - parentStyle: The parent's resolved style (for inheritance)
    /// - Returns: Fully resolved style
    public func resolve(node: NativeDisplayNode, parentStyle: Style? = nil) -> Style {
        // Start with theme default
        var resolvedStyle = theme.defaultStyle
        
        // Apply inherited cascading properties from parent
        if let parentStyle = parentStyle {
            resolvedStyle = resolvedStyle.mergedWith(parentStyle.cascadingOnly())
        }
        
        // Apply style class if specified
        if let styleClassName = node.styleClass,
           let classStyle = styleClassMap[styleClassName]?.style {
            resolvedStyle = resolvedStyle.mergedWith(classStyle)
        }
        
        // Apply inline style (highest priority)
        if let nodeStyle = node.style {
            resolvedStyle = resolvedStyle.mergedWith(nodeStyle)
        }
        
        return resolvedStyle
    }
    
    /// Resolve style for an element with color palette support.
    /// Replaces color names with actual color values from theme.
    public func resolveWithColors(node: NativeDisplayNode, parentStyle: Style? = nil) -> Style {
        let style = resolve(node: node, parentStyle: parentStyle)
        
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
