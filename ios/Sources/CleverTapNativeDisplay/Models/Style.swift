// MARK: - Style Models
// Style configuration for the Native Display System

import Foundation

/// Style properties for visual appearance.
///
/// Cascading properties (inherited by children):
/// - textColor, fontSize, fontFamily, fontWeight, lineHeight
///
/// Non-cascading properties (container-only):
/// - background, backgroundColor, borderRadius, shadowRadius, etc.
public struct Style: Codable, Equatable {
    // Text properties (cascading)
    public let textColor: String?
    public let fontSize: CGFloat?
    public let fontFamily: String?
    public let fontWeight: FontWeight?
    public let lineHeight: CGFloat?
    public let textDecoration: TextDecoration?
    public let textAlign: String?  // "left", "center", "right"
    
    // Background (non-cascading)
    public let background: Background?  // Rich background support
    public let backgroundColor: String?  // Legacy: Simple color (backward compatible)
    
    // Border (non-cascading)
    public let borderRadius: CGFloat?
    public let borderWidth: CGFloat?
    public let borderColor: String?
    
    // Shadow (non-cascading)
    public let shadowColor: String?
    public let shadowRadius: CGFloat?
    public let shadowOffsetX: CGFloat?
    public let shadowOffsetY: CGFloat?
    
    // Opacity (cascading)
    public let opacity: CGFloat?
    
    public init(
        textColor: String? = nil,
        fontSize: CGFloat? = nil,
        fontFamily: String? = nil,
        fontWeight: FontWeight? = nil,
        lineHeight: CGFloat? = nil,
        textDecoration: TextDecoration? = nil,
        textAlign: String? = nil,
        background: Background? = nil,
        backgroundColor: String? = nil,
        borderRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        borderColor: String? = nil,
        shadowColor: String? = nil,
        shadowRadius: CGFloat? = nil,
        shadowOffsetX: CGFloat? = nil,
        shadowOffsetY: CGFloat? = nil,
        opacity: CGFloat? = nil
    ) {
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.lineHeight = lineHeight
        self.textDecoration = textDecoration
        self.textAlign = textAlign
        self.background = background
        self.backgroundColor = backgroundColor
        self.borderRadius = borderRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffsetX = shadowOffsetX
        self.shadowOffsetY = shadowOffsetY
        self.opacity = opacity
    }
    
    /// Merge this style with another, giving priority to this style's values.
    /// Used for style resolution: inline > class > inherited > theme
    public func mergedWith(_ other: Style?) -> Style {
        guard let other = other else { return self }
        
        return Style(
            textColor: textColor ?? other.textColor,
            fontSize: fontSize ?? other.fontSize,
            fontFamily: fontFamily ?? other.fontFamily,
            fontWeight: fontWeight ?? other.fontWeight,
            lineHeight: lineHeight ?? other.lineHeight,
            textDecoration: textDecoration ?? other.textDecoration,
            textAlign: textAlign ?? other.textAlign,
            background: background ?? other.background,
            backgroundColor: backgroundColor ?? other.backgroundColor,
            borderRadius: borderRadius ?? other.borderRadius,
            borderWidth: borderWidth ?? other.borderWidth,
            borderColor: borderColor ?? other.borderColor,
            shadowColor: shadowColor ?? other.shadowColor,
            shadowRadius: shadowRadius ?? other.shadowRadius,
            shadowOffsetX: shadowOffsetX ?? other.shadowOffsetX,
            shadowOffsetY: shadowOffsetY ?? other.shadowOffsetY,
            opacity: opacity ?? other.opacity
        )
    }
    
    /// Extract only cascading properties (for inheritance).
    public func cascadingOnly() -> Style {
        Style(
            textColor: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: fontWeight,
            lineHeight: lineHeight,
            textDecoration: textDecoration,
            textAlign: textAlign,
            opacity: opacity
        )
    }
    
    public static let empty = Style()
}

/// Named style class that can be referenced by elements.
public struct StyleClass: Codable, Equatable {
    public let name: String
    public let style: Style
    
    public init(name: String, style: Style) {
        self.name = name
        self.style = style
    }
}

/// Theme containing default styles and color palette.
public struct Theme: Codable, Equatable {
    public let id: String
    public let defaultStyle: Style
    public let colors: [String: String]
    
    public init(
        id: String,
        defaultStyle: Style = .empty,
        colors: [String: String] = [:]
    ) {
        self.id = id
        self.defaultStyle = defaultStyle
        self.colors = colors
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? "default"
        self.defaultStyle = try container.decodeIfPresent(Style.self, forKey: .defaultStyle) ?? .empty
        self.colors = try container.decodeIfPresent([String: String].self, forKey: .colors) ?? [:]
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, defaultStyle, colors
    }
    
    /// Get a color from the theme palette.
    public func getColor(_ name: String) -> String? {
        colors[name]
    }
    
    public static let `default` = Theme(
        id: "default",
        defaultStyle: Style(
            textColor: "#000000",
            fontSize: 14,
            fontWeight: .normal
        )
    )
}
