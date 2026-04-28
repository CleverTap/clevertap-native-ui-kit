// MARK: - Style Models
// Style configuration for the Native Display System

import Foundation

/// Unit for text dimension values (fontSize, lineHeight).
public enum TextDimensionUnit: String, Codable, Equatable {
    case platform
    case percent
}

/// A text dimension that supports both platform units (points) and percentage-based sizing.
///
/// JSON format (backward compatible):
/// - Raw number → TextDimension(value, .platform): `"fontSize": 28`
/// - Object → decoded normally: `"fontSize": {"value": 28, "unit": "percent"}`
///
/// Percentage mode: `rootHeight * value / 1000` (always relative to root container)
public struct TextDimension: Codable, Equatable {
    public let value: CGFloat
    public let unit: TextDimensionUnit

    public init(value: CGFloat, unit: TextDimensionUnit = .platform) {
        self.value = value
        self.unit = unit
    }

    public func resolve(containerHeight rootHeight: CGFloat) -> CGFloat {
        switch unit {
        case .platform: return value
        case .percent:  return rootHeight * value / 1000
        }
    }

    // Custom decoder: handle both raw number and object
    public init(from decoder: Decoder) throws {
        // Try single value (raw number) first
        if let container = try? decoder.singleValueContainer(),
           let number = try? container.decode(CGFloat.self) {
            self.value = number
            self.unit = .platform
            return
        }
        // Otherwise decode as object
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decode(CGFloat.self, forKey: .value)
        self.unit = try container.decodeIfPresent(TextDimensionUnit.self, forKey: .unit) ?? .platform
    }

    public func encode(to encoder: Encoder) throws {
        if unit == .platform {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)
            try container.encode(unit, forKey: .unit)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case value, unit
    }
}

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
    public let fontSize: TextDimension?
    public let fontFamily: String?
    public let fontWeight: FontWeight?
    public let fontStyle: FontStyle?
    public let lineHeight: TextDimension?
    public let letterSpacing: CGFloat?
    public let textDecoration: TextDecoration?
    public let textAlign: String?  // "left", "center", "right", "justify"
    public let maxLines: Int?
    public let overflow: TextOverflow?
    public let textShadow: TextShadow?
    public let textGradient: TextGradient?

    // ==================== VISUAL PROPERTIES (Non-cascading) ====================

    public let background: Background?  // Rich background support (gradients, images, animations)
    public let backgroundColor: String?  // Simple solid color (backward compatible)

    // ==================== BORDER PROPERTIES (Non-cascading) ====================

    public let borderRadius: Dimension?
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
        fontSize: TextDimension? = nil,
        fontFamily: String? = nil,
        fontWeight: FontWeight? = nil,
        fontStyle: FontStyle? = nil,
        lineHeight: TextDimension? = nil,
        letterSpacing: CGFloat? = nil,
        textDecoration: TextDecoration? = nil,
        textAlign: String? = nil,
        maxLines: Int? = nil,
        overflow: TextOverflow? = nil,
        textShadow: TextShadow? = nil,
        textGradient: TextGradient? = nil,
        background: Background? = nil,
        backgroundColor: String? = nil,
        borderRadius: Dimension? = nil,
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
        self.fontStyle = fontStyle
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.textDecoration = textDecoration
        self.textAlign = textAlign
        self.maxLines = maxLines
        self.overflow = overflow
        self.textShadow = textShadow
        self.textGradient = textGradient
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
            fontStyle: fontStyle ?? other.fontStyle,
            lineHeight: lineHeight ?? other.lineHeight,
            letterSpacing: letterSpacing ?? other.letterSpacing,
            textDecoration: textDecoration ?? other.textDecoration,
            textAlign: textAlign ?? other.textAlign,
            maxLines: maxLines ?? other.maxLines,
            overflow: overflow ?? other.overflow,
            textShadow: textShadow ?? other.textShadow,
            textGradient: textGradient ?? other.textGradient,
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
            fontStyle: fontStyle,
            lineHeight: lineHeight,
            letterSpacing: letterSpacing,
            textDecoration: textDecoration,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            textShadow: textShadow,
            textGradient: textGradient,
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
            style: fontStyle,
            lineHeight: lineHeight,
            letterSpacing: letterSpacing,
            decoration: textDecoration,
            align: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            textShadow: textShadow,
            textGradient: textGradient,
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

    // Custom Decodable init for backward-compatible borderRadius parsing.
    // Accepts both raw number ("borderRadius": 12) and Dimension object
    // ("borderRadius": {"value": 50, "unit": "percent"}).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        textColor      = try container.decodeIfPresent(String.self,          forKey: .textColor)
        fontSize       = try container.decodeIfPresent(TextDimension.self,   forKey: .fontSize)
        fontFamily     = try container.decodeIfPresent(String.self,          forKey: .fontFamily)
        fontWeight     = try container.decodeIfPresent(FontWeight.self,      forKey: .fontWeight)
        fontStyle      = try container.decodeIfPresent(FontStyle.self,       forKey: .fontStyle)
        lineHeight     = try container.decodeIfPresent(TextDimension.self,   forKey: .lineHeight)
        letterSpacing  = try container.decodeIfPresent(CGFloat.self,         forKey: .letterSpacing)
        textDecoration = try container.decodeIfPresent(TextDecoration.self,  forKey: .textDecoration)
        textAlign      = try container.decodeIfPresent(String.self,          forKey: .textAlign)
        maxLines       = try container.decodeIfPresent(Int.self,             forKey: .maxLines)
        overflow       = try container.decodeIfPresent(TextOverflow.self,    forKey: .overflow)
        textShadow     = try container.decodeIfPresent(TextShadow.self,      forKey: .textShadow)
        textGradient   = try container.decodeIfPresent(TextGradient.self,    forKey: .textGradient)
        background     = try container.decodeIfPresent(Background.self,      forKey: .background)
        backgroundColor = try container.decodeIfPresent(String.self,         forKey: .backgroundColor)

        // Backward-compatible borderRadius: raw number → Dimension(.dp), object → Dimension
        if let raw = try? container.decode(CGFloat.self, forKey: .borderRadius) {
            borderRadius = Dimension(value: raw, unit: .dp)
        } else {
            borderRadius = try? container.decode(Dimension.self, forKey: .borderRadius)
        }

        borderWidth    = try container.decodeIfPresent(CGFloat.self,         forKey: .borderWidth)
        borderColor    = try container.decodeIfPresent(String.self,          forKey: .borderColor)
        shadowColor    = try container.decodeIfPresent(String.self,          forKey: .shadowColor)
        shadowRadius   = try container.decodeIfPresent(CGFloat.self,         forKey: .shadowRadius)
        shadowOffsetX  = try container.decodeIfPresent(CGFloat.self,         forKey: .shadowOffsetX)
        shadowOffsetY  = try container.decodeIfPresent(CGFloat.self,         forKey: .shadowOffsetY)
        opacity        = try container.decodeIfPresent(CGFloat.self,         forKey: .opacity)
    }

    private enum CodingKeys: String, CodingKey {
        case textColor, fontSize, fontFamily, fontWeight, fontStyle
        case lineHeight, letterSpacing, textDecoration, textAlign
        case maxLines, overflow, textShadow, textGradient
        case background, backgroundColor
        case borderRadius, borderWidth, borderColor
        case shadowColor, shadowRadius, shadowOffsetX, shadowOffsetY
        case opacity
    }

    public static let empty = Style()
}

// MARK: - Property Extraction Types

/// Text styling properties extracted from Style.
/// Used internally by renderer for text elements (TEXT, BUTTON).
///
/// Contains all text-related properties that cascade through the style hierarchy:
/// - color: Text color in hex format
/// - size: Font size in points
/// - family: Font family name
/// - weight: Font weight (NORMAL, BOLD, etc.)
/// - style: Font style (NORMAL, ITALIC)
/// - lineHeight: Line height in points
/// - letterSpacing: Letter spacing in points
/// - decoration: Text decoration (UNDERLINE, LINE_THROUGH, etc.)
/// - align: Text alignment (LEFT, CENTER, RIGHT, JUSTIFY)
/// - maxLines: Maximum number of lines before truncation
/// - overflow: Text overflow behavior (CLIP, ELLIPSIS, VISIBLE)
/// - textShadow: Drop shadow effect on text
/// - textGradient: Gradient effect on text
/// - opacity: Text opacity (0.0 to 1.0)
public struct TextProperties {
    public let color: String?
    public let size: TextDimension?
    public let family: String?
    public let weight: FontWeight?
    public let style: FontStyle?
    public let lineHeight: TextDimension?
    public let letterSpacing: CGFloat?
    public let decoration: TextDecoration?
    public let align: String?
    public let maxLines: Int?
    public let overflow: TextOverflow?
    public let textShadow: TextShadow?
    public let textGradient: TextGradient?
    public let opacity: CGFloat?

    public init(
        color: String?,
        size: TextDimension?,
        family: String?,
        weight: FontWeight?,
        style: FontStyle?,
        lineHeight: TextDimension?,
        letterSpacing: CGFloat?,
        decoration: TextDecoration?,
        align: String?,
        maxLines: Int?,
        overflow: TextOverflow?,
        textShadow: TextShadow?,
        textGradient: TextGradient?,
        opacity: CGFloat?
    ) {
        self.color = color
        self.size = size
        self.family = family
        self.weight = weight
        self.style = style
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.decoration = decoration
        self.align = align
        self.maxLines = maxLines
        self.overflow = overflow
        self.textShadow = textShadow
        self.textGradient = textGradient
        self.opacity = opacity
    }

    /// Default text properties with sensible defaults.
    /// Used as fallback when properties are not specified.
    public static let `default` = TextProperties(
        color: nil,
        size: TextDimension(value: 14),
        family: nil,
        weight: nil,
        style: nil,
        lineHeight: nil,
        letterSpacing: nil,
        decoration: nil,
        align: nil,
        maxLines: nil,
        overflow: nil,
        textShadow: nil,
        textGradient: nil,
        opacity: nil
    )
}

/// Visual styling properties for containers and visual elements.
/// Used internally by renderer for background and opacity.
///
/// Contains non-cascading visual properties:
/// - background: Complex background (gradients, images, animations)
/// - backgroundColor: Simple solid background color
/// - opacity: Element opacity (0.0 to 1.0)
public struct VisualProperties {
    public let background: Background?
    public let backgroundColor: String?
    public let opacity: CGFloat?

    public init(
        background: Background?,
        backgroundColor: String?,
        opacity: CGFloat?
    ) {
        self.background = background
        self.backgroundColor = backgroundColor
        self.opacity = opacity
    }

    /// Empty visual properties (no background, no opacity).
    public static let empty = VisualProperties(
        background: nil,
        backgroundColor: nil,
        opacity: nil
    )
}

/// Border styling properties.
/// Used internally by decoration application for rendering borders.
///
/// Contains border-related properties:
/// - radius: Border radius as a Dimension (supports dp or percent units)
/// - width: Border width in points (stroke thickness)
/// - color: Border color in hex format
public struct BorderProperties {
    public let radius: Dimension?
    public let width: CGFloat?
    public let color: String?

    public init(
        radius: Dimension?,
        width: CGFloat?,
        color: String?
    ) {
        self.radius = radius
        self.width = width
        self.color = color
    }

    /// Empty border properties (no border).
    public static let empty = BorderProperties(
        radius: nil,
        width: nil,
        color: nil
    )
}

/// Shadow styling properties.
/// Used internally by decoration application for rendering shadows.
///
/// Contains shadow-related properties:
/// - color: Shadow color in hex format
/// - radius: Shadow blur radius in points
/// - offsetX: Horizontal shadow offset in points
/// - offsetY: Vertical shadow offset in points
public struct ShadowProperties {
    public let color: String?
    public let radius: CGFloat?
    public let offsetX: CGFloat?
    public let offsetY: CGFloat?

    public init(
        color: String?,
        radius: CGFloat?,
        offsetX: CGFloat?,
        offsetY: CGFloat?
    ) {
        self.color = color
        self.radius = radius
        self.offsetX = offsetX
        self.offsetY = offsetY
    }

    /// Empty shadow properties (no shadow).
    public static let empty = ShadowProperties(
        color: nil,
        radius: nil,
        offsetX: nil,
        offsetY: nil
    )
}

/// Text shadow configuration for text elements.
/// Provides drop shadow effect on text.
public struct TextShadow: Codable, Equatable {
    public let color: String              // Hex color (e.g., "#00000040" for semi-transparent black)
    public let offsetX: CGFloat           // Horizontal offset in points
    public let offsetY: CGFloat           // Vertical offset in points
    public let blur: CGFloat              // Blur radius in points

    public init(
        color: String,
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0,
        blur: CGFloat = 0
    ) {
        self.color = color
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.blur = blur
    }
}

/// Text gradient configuration for gradient text effects.
/// Supports linear gradients on text.
public struct TextGradient: Codable, Equatable {
    public let type: String               // "linear" (radial and sweep not supported on text)
    public let colors: [String]           // Hex colors for gradient stops
    public let angle: CGFloat             // Angle in degrees (0 = left to right)
    public let stops: [CGFloat]?          // Optional gradient stops (0.0 to 1.0)

    public init(
        type: String = "linear",
        colors: [String],
        angle: CGFloat = 0,
        stops: [CGFloat]? = nil
    ) {
        self.type = type
        self.colors = colors
        self.angle = angle
        self.stops = stops
    }
}

/// Named style class that can be referenced by elements.
public struct StyleClass: Codable, Equatable {
    public let id: String
    public let style: Style

    public init(id: String, style: Style) {
        self.id = id
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
            fontSize: TextDimension(value: 14),
            fontWeight: .normal
        )
    )
}
