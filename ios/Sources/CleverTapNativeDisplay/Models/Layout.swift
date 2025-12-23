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

/// Offset for absolute positioning within a container (x, y coordinates).
/// Used for positioning elements at specific locations within ZStack containers.
/// Supports negative values for positioning outside the normal flow.
public struct Offset: Codable, Equatable {
    public let x: CGFloat
    public let y: CGFloat
    public let unit: DimensionUnit
    
    public init(
        x: CGFloat = 0,
        y: CGFloat = 0,
        unit: DimensionUnit = .dp
    ) {
        self.x = x
        self.y = y
        self.unit = unit
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        self.y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        self.unit = try container.decodeIfPresent(DimensionUnit.self, forKey: .unit) ?? .dp
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y, unit
    }
    
    // MARK: - Factory Methods
    
    public static func dp(x: CGFloat, y: CGFloat) -> Offset {
        Offset(x: x, y: y, unit: .dp)
    }
    
    public static func percent(x: CGFloat, y: CGFloat) -> Offset {
        Offset(x: x, y: y, unit: .percent)
    }
    
    public static let zero = Offset(x: 0, y: 0)
}

/// Spacing values for padding.
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

/// Child arrangement strategy for container layouts.
/// Defines how children are positioned and spaced within VStack/HStack containers.
public struct ChildArrangement: Codable, Equatable {
    /// Spacing value between children (used when strategy is .spaced).
    public let spacing: CGFloat?
    
    /// Unit for spacing value.
    public let spacingUnit: DimensionUnit
    
    /// Arrangement strategy for positioning children.
    public let strategy: ArrangementStrategy
    
    public init(
        spacing: CGFloat? = nil,
        spacingUnit: DimensionUnit = .dp,
        strategy: ArrangementStrategy = .spaced
    ) {
        self.spacing = spacing
        self.spacingUnit = spacingUnit
        self.strategy = strategy
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        self.spacingUnit = try container.decodeIfPresent(DimensionUnit.self, forKey: .spacingUnit) ?? .dp
        self.strategy = try container.decodeIfPresent(ArrangementStrategy.self, forKey: .strategy) ?? .spaced
    }
    
    private enum CodingKeys: String, CodingKey {
        case spacing, spacingUnit, strategy
    }
    
    // MARK: - Factory Methods
    
    /// Default arrangement: no spacing between children.
    public static let `default` = ChildArrangement(spacing: 0, strategy: .spaced)
    
    /// Fixed spacing between children.
    public static func spaced(_ spacing: CGFloat, unit: DimensionUnit = .dp) -> ChildArrangement {
        ChildArrangement(spacing: spacing, spacingUnit: unit, strategy: .spaced)
    }
    
    /// Equal space between children, no space at edges.
    public static func spaceBetween() -> ChildArrangement {
        ChildArrangement(strategy: .spaceBetween)
    }
    
    /// Equal space between children AND at edges.
    public static func spaceEvenly() -> ChildArrangement {
        ChildArrangement(strategy: .spaceEvenly)
    }
    
    /// Equal space around each child (half space at edges).
    public static func spaceAround() -> ChildArrangement {
        ChildArrangement(strategy: .spaceAround)
    }
    
    /// Children aligned to start, no spacing.
    public static func start() -> ChildArrangement {
        ChildArrangement(strategy: .start)
    }
    
    /// Children centered, no spacing.
    public static func center() -> ChildArrangement {
        ChildArrangement(strategy: .center)
    }
    
    /// Children aligned to end, no spacing.
    public static func end() -> ChildArrangement {
        ChildArrangement(strategy: .end)
    }
}

/// Layout properties for positioning and sizing elements.
public struct Layout: Codable, Equatable {
    public let width: Dimension?
    public let height: Dimension?
    public let offset: Offset?  // Changed from margin
    public let padding: Spacing?
    public let arrangement: ChildArrangement?  // Changed from spacing/spacingUnit
    
    public init(
        width: Dimension? = nil,
        height: Dimension? = nil,
        offset: Offset? = nil,
        padding: Spacing? = nil,
        arrangement: ChildArrangement? = nil
    ) {
        self.width = width
        self.height = height
        self.offset = offset
        self.padding = padding
        self.arrangement = arrangement
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.width = try container.decodeIfPresent(Dimension.self, forKey: .width)
        self.height = try container.decodeIfPresent(Dimension.self, forKey: .height)
        self.offset = try container.decodeIfPresent(Offset.self, forKey: .offset)
        self.padding = try container.decodeIfPresent(Spacing.self, forKey: .padding)
        self.arrangement = try container.decodeIfPresent(ChildArrangement.self, forKey: .arrangement)
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height, offset, padding, arrangement
    }
    
    public static let `default` = Layout(
        width: .wrapContent,
        height: .wrapContent
    )
}
