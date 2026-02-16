import Foundation

/// Text styling properties extracted from Style.
/// Used internally by renderer for text elements (TEXT, BUTTON).
///
/// Contains all text-related properties that cascade through the style hierarchy:
/// - color: Text color in hex format
/// - size: Font size in points
/// - family: Font family name
/// - weight: Font weight (NORMAL, BOLD, etc.)
/// - lineHeight: Line height in points
/// - decoration: Text decoration (UNDERLINE, LINE_THROUGH, etc.)
/// - align: Text alignment (LEFT, CENTER, RIGHT, JUSTIFY)
/// - opacity: Text opacity (0.0 to 1.0)
public struct TextProperties {
    public let color: String?
    public let size: CGFloat?
    public let family: String?
    public let weight: FontWeight?
    public let lineHeight: CGFloat?
    public let decoration: TextDecoration?
    public let align: String?
    public let opacity: CGFloat?

    public init(
        color: String?,
        size: CGFloat?,
        family: String?,
        weight: FontWeight?,
        lineHeight: CGFloat?,
        decoration: TextDecoration?,
        align: String?,
        opacity: CGFloat?
    ) {
        self.color = color
        self.size = size
        self.family = family
        self.weight = weight
        self.lineHeight = lineHeight
        self.decoration = decoration
        self.align = align
        self.opacity = opacity
    }

    /// Default text properties with sensible defaults.
    /// Used as fallback when properties are not specified.
    public static let `default` = TextProperties(
        color: nil,
        size: 14,
        family: nil,
        weight: nil,
        lineHeight: nil,
        decoration: nil,
        align: nil,
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
/// - radius: Border radius in points (rounded corners)
/// - width: Border width in points (stroke thickness)
/// - color: Border color in hex format
public struct BorderProperties {
    public let radius: CGFloat?
    public let width: CGFloat?
    public let color: String?

    public init(
        radius: CGFloat?,
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
