// MARK: - Style Models
// Style configuration for the Native Display System

import Foundation

/// Style properties for visual appearance.
///
/// ## Internal SDK Usage
///
/// For SDK developers rendering elements, use extraction methods instead of direct property access:
/// - `extractTextProperties()` - Get text styling (color, size, weight, etc.) for TEXT/BUTTON elements
/// - `extractVisualProperties()` - Get background and opacity for all elements
/// - `extractBorderProperties()` - Get border styling for visual decorations
/// - `extractShadowProperties()` - Get shadow styling for visual decorations
///
/// ## Property Grouping
///
/// **Text Properties (cascading):**
/// - textColor, fontSize, fontFamily, fontWeight, lineHeight, textDecoration, textAlign
/// - Used by: TEXT, BUTTON elements
/// - Inherited by child elements in the hierarchy
///
/// **Visual Properties (non-cascading):**
/// - background, backgroundColor
/// - Used by: All elements and containers
/// - Not inherited by children
///
/// **Border Properties (non-cascading):**
/// - borderRadius, borderWidth, borderColor
/// - Used by: Visual decorations on all elements
/// - Not inherited by children
///
/// **Shadow Properties (non-cascading):**
/// - shadowColor, shadowRadius, shadowOffsetX, shadowOffsetY
/// - Used by: Visual decorations on all elements
/// - Not inherited by children
///
/// **Universal:**
/// - opacity (cascades to children)
///
/// ## JSON Compatibility
///
/// This struct maintains full backward compatibility with existing JSON configurations.
/// All properties are optional.
public struct Style: Codable, Equatable {
    // ==================== TEXT PROPERTIES (Cascading) ====================

    public let textColor: String?
    public let fontSize: CGFloat?
    public let fontFamily: String?
    public let fontWeight: FontWeight?
    public let lineHeight: CGFloat?
    public let textDecoration: TextDecoration?
    public let textAlign: String?  // "left", "center", "right", "justify"

    // ==================== VISUAL PROPERTIES (Non-cascading) ====================

    public let background: Background?  // Rich background support (gradients, images, animations)
    public let backgroundColor: String?  // Simple solid color (backward compatible)

    // ==================== BORDER PROPERTIES (Non-cascading) ====================

    public let borderRadius: CGFloat?
    public let borderWidth: CGFloat?
    public let borderColor: String?

    // ==================== SHADOW PROPERTIES (Non-cascading) ====================

    public let shadowColor: String?
    public let shadowRadius: CGFloat?
    public let shadowOffsetX: CGFloat?
    public let shadowOffsetY: CGFloat?

    // ==================== UNIVERSAL PROPERTIES ====================

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

    // ==================== PROPERTY EXTRACTION METHODS ====================

    /// Extract text properties for rendering text elements.
    ///
    /// Use this method in TEXT and BUTTON renderers to get all text-related styling
    /// in a single grouped object, making the code clearer and more maintainable.
    ///
    /// Example:
    /// ```swift
    /// let textProps = resolvedStyle.extractTextProperties()
    /// Text(text)
    ///     .foregroundColor(parseColor(textProps.color) ?? .black)
    ///     .font(.system(size: textProps.size ?? 14))
    ///     .fontWeight(resolveFontWeight(textProps.weight))
    /// ```
    ///
    /// - Returns: TextProperties containing all text styling values
    public func extractTextProperties() -> TextProperties {
        TextProperties(
            color: textColor,
            size: fontSize,
            family: fontFamily,
            weight: fontWeight,
            lineHeight: lineHeight,
            decoration: textDecoration,
            align: textAlign,
            opacity: opacity
        )
    }

    /// Extract visual properties for rendering backgrounds.
    ///
    /// Use this method to get background and opacity properties for any element.
    /// This is used by all elements and containers for background rendering.
    ///
    /// Example:
    /// ```swift
    /// let visualProps = resolvedStyle.extractVisualProperties()
    /// if let background = visualProps.background {
    ///     view.applyBackground(background)
    /// } else if let backgroundColor = visualProps.backgroundColor {
    ///     view.background(parseColor(backgroundColor))
    /// }
    /// ```
    ///
    /// - Returns: VisualProperties containing background and opacity values
    public func extractVisualProperties() -> VisualProperties {
        VisualProperties(
            background: background,
            backgroundColor: backgroundColor,
            opacity: opacity
        )
    }

    /// Extract border properties for rendering borders.
    ///
    /// Use this method in decoration application to get all border-related styling
    /// in a single grouped object.
    ///
    /// Example:
    /// ```swift
    /// let borderProps = style.extractBorderProperties()
    /// if let width = borderProps.width, width > 0 {
    ///     view.overlay(
    ///         RoundedRectangle(cornerRadius: borderProps.radius ?? 0)
    ///             .stroke(parseColor(borderProps.color) ?? .gray, lineWidth: width)
    ///     )
    /// }
    /// ```
    ///
    /// - Returns: BorderProperties containing border styling values
    public func extractBorderProperties() -> BorderProperties {
        BorderProperties(
            radius: borderRadius,
            width: borderWidth,
            color: borderColor
        )
    }

    /// Extract shadow properties for rendering shadows.
    ///
    /// Use this method in decoration application to get all shadow-related styling
    /// in a single grouped object.
    ///
    /// Example:
    /// ```swift
    /// let shadowProps = style.extractShadowProperties()
    /// if let radius = shadowProps.radius, radius > 0 {
    ///     view.shadow(
    ///         color: parseColor(shadowProps.color) ?? .black.opacity(0.25),
    ///         radius: radius,
    ///         x: shadowProps.offsetX ?? 0,
    ///         y: shadowProps.offsetY ?? 0
    ///     )
    /// }
    /// ```
    ///
    /// - Returns: ShadowProperties containing shadow styling values
    public func extractShadowProperties() -> ShadowProperties {
        ShadowProperties(
            color: shadowColor,
            radius: shadowRadius,
            offsetX: shadowOffsetX,
            offsetY: shadowOffsetY
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
