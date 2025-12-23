// MARK: - Layout Models
// Layout and dimension configuration for the Native Display System

import Foundation

/// Represents a dimension value that can be either a specific value or a special dimension.
public struct Dimension: Codable, Equatable {
    public let value: CGFloat
    public let unit: DimensionUnit
    public let special: SpecialDimension?
    
    public init(
        value: CGFloat = 0,
        unit: DimensionUnit = .dp,
        special: SpecialDimension? = nil
    ) {
        self.value = value
        self.unit = unit
        self.special = special
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decodeIfPresent(CGFloat.self, forKey: .value) ?? 0
        self.unit = try container.decodeIfPresent(DimensionUnit.self, forKey: .unit) ?? .dp
        self.special = try container.decodeIfPresent(SpecialDimension.self, forKey: .special)
    }
    
    private enum CodingKeys: String, CodingKey {
        case value, unit, special
    }
    
    // MARK: - Factory Methods
    
    public static func dp(_ value: CGFloat) -> Dimension {
        Dimension(value: value, unit: .dp)
    }
    
    public static func sp(_ value: CGFloat) -> Dimension {
        Dimension(value: value, unit: .sp)
    }
    
    public static func percent(_ value: CGFloat) -> Dimension {
        Dimension(value: value, unit: .percent)
    }
    
    public static func px(_ value: CGFloat) -> Dimension {
        Dimension(value: value, unit: .px)
    }
    
    public static let wrapContent = Dimension(value: 0, unit: .dp, special: .wrapContent)
    public static let matchParent = Dimension(value: 0, unit: .dp, special: .matchParent)
}

/// Spacing values for padding or margin.
/// Can specify individual sides or use shortcuts for all/horizontal/vertical.
public struct Spacing: Codable, Equatable {
    public let all: CGFloat?
    public let horizontal: CGFloat?
    public let vertical: CGFloat?
    public let top: CGFloat?
    public let bottom: CGFloat?
    public let left: CGFloat?
    public let right: CGFloat?
    public let unit: DimensionUnit
    
    public init(
        all: CGFloat? = nil,
        horizontal: CGFloat? = nil,
        vertical: CGFloat? = nil,
        top: CGFloat? = nil,
        bottom: CGFloat? = nil,
        left: CGFloat? = nil,
        right: CGFloat? = nil,
        unit: DimensionUnit = .dp
    ) {
        self.all = all
        self.horizontal = horizontal
        self.vertical = vertical
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
        self.unit = unit
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.all = try container.decodeIfPresent(CGFloat.self, forKey: .all)
        self.horizontal = try container.decodeIfPresent(CGFloat.self, forKey: .horizontal)
        self.vertical = try container.decodeIfPresent(CGFloat.self, forKey: .vertical)
        self.top = try container.decodeIfPresent(CGFloat.self, forKey: .top)
        self.bottom = try container.decodeIfPresent(CGFloat.self, forKey: .bottom)
        self.left = try container.decodeIfPresent(CGFloat.self, forKey: .left)
        self.right = try container.decodeIfPresent(CGFloat.self, forKey: .right)
        self.unit = try container.decodeIfPresent(DimensionUnit.self, forKey: .unit) ?? .dp
    }
    
    private enum CodingKeys: String, CodingKey {
        case all, horizontal, vertical, top, bottom, left, right, unit
    }
    
    // MARK: - Resolution Methods
    
    /// Resolve individual spacing values with proper fallbacks.
    public func resolveTop() -> CGFloat {
        top ?? vertical ?? all ?? 0
    }
    
    public func resolveBottom() -> CGFloat {
        bottom ?? vertical ?? all ?? 0
    }
    
    public func resolveLeft() -> CGFloat {
        left ?? horizontal ?? all ?? 0
    }
    
    public func resolveRight() -> CGFloat {
        right ?? horizontal ?? all ?? 0
    }
    
    // MARK: - Factory Methods
    
    public static func all(_ value: CGFloat, unit: DimensionUnit = .dp) -> Spacing {
        Spacing(all: value, unit: unit)
    }
    
    public static func horizontal(_ value: CGFloat, unit: DimensionUnit = .dp) -> Spacing {
        Spacing(horizontal: value, unit: unit)
    }
    
    public static func vertical(_ value: CGFloat, unit: DimensionUnit = .dp) -> Spacing {
        Spacing(vertical: value, unit: unit)
    }
    
    public static let zero = Spacing()
}

/// Layout properties for positioning and sizing elements.
public struct Layout: Codable, Equatable {
    public let width: Dimension?
    public let height: Dimension?
    public let margin: Spacing?
    public let padding: Spacing?
    public let spacing: CGFloat?
    public let spacingUnit: DimensionUnit
    
    public init(
        width: Dimension? = nil,
        height: Dimension? = nil,
        margin: Spacing? = nil,
        padding: Spacing? = nil,
        spacing: CGFloat? = nil,
        spacingUnit: DimensionUnit = .dp
    ) {
        self.width = width
        self.height = height
        self.margin = margin
        self.padding = padding
        self.spacing = spacing
        self.spacingUnit = spacingUnit
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.width = try container.decodeIfPresent(Dimension.self, forKey: .width)
        self.height = try container.decodeIfPresent(Dimension.self, forKey: .height)
        self.margin = try container.decodeIfPresent(Spacing.self, forKey: .margin)
        self.padding = try container.decodeIfPresent(Spacing.self, forKey: .padding)
        self.spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        self.spacingUnit = try container.decodeIfPresent(DimensionUnit.self, forKey: .spacingUnit) ?? .dp
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height, margin, padding, spacing, spacingUnit
    }
    
    public static let `default` = Layout(
        width: .wrapContent,
        height: .wrapContent
    )
}
