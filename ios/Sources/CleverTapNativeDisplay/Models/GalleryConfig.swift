// MARK: - Gallery Configuration
// Gallery configuration for carousel/scrolling containers

import Foundation

/// Peek configuration for gallery items (dp-based leading/trailing reveal).
public struct PeekConfig: Codable, Equatable {
    public let before: CGFloat  // dp: leading side reveal
    public let after: CGFloat   // dp: trailing side reveal

    public init(before: CGFloat = 0, after: CGFloat = 0) {
        self.before = before
        self.after = after
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        before = try c.decodeIfPresent(CGFloat.self, forKey: .before) ?? 0
        after  = try c.decodeIfPresent(CGFloat.self, forKey: .after)  ?? 0
    }

    private enum CodingKeys: String, CodingKey { case before, after }
}

/// Gallery configuration for carousel/scrolling containers.
///
/// Three distinct modes:
/// 1. SNAPPING: Full-size items with snap, peek shows adjacent items (image carousels)
/// 2. FREE_FLOW: Items define their own size, natural scrolling (tag lists, varying widths)
/// 3. FREE_FLOW_GRID: Fixed items per view, peek via itemsPerView (product grids)
public struct GalleryConfig: Codable, Equatable {
    // Core mode selection
    public let mode: GalleryMode
    public let orientation: Orientation
    
    // SNAPPING mode parameters
    public let snapBehavior: SnapBehavior
    public let peek: PeekConfig         // dp-based leading/trailing peek

    // FREE_FLOW_GRID mode parameters
    public let itemsPerView: CGFloat    // Number of items visible (2.5 = 2 full + 0.5 peek)
    public let columns: Int?            // Optional column count override for effectiveItemsPerView
    
    // Common parameters
    public let spacing: CGFloat          // Gap between items in dp
    public let showIndicators: Bool
    public let indicatorStyle: IndicatorStyle?
    public let autoScrollInterval: Int   // Auto-scroll interval in ms (0 = disabled)
    public let infiniteScroll: Bool
    public let showArrows: Bool
    public let arrowStyle: ArrowStyle?
    public let initialPage: Int
    
    public init(
        mode: GalleryMode = .snapping,
        orientation: Orientation = .horizontal,
        snapBehavior: SnapBehavior = .center,
        peek: PeekConfig = PeekConfig(),
        itemsPerView: CGFloat = 1,
        columns: Int? = nil,
        spacing: CGFloat = 8,
        showIndicators: Bool = false,
        indicatorStyle: IndicatorStyle? = nil,
        autoScrollInterval: Int = 0,
        infiniteScroll: Bool = false,
        showArrows: Bool = false,
        arrowStyle: ArrowStyle? = nil,
        initialPage: Int = 0
    ) {
        self.mode = mode
        self.orientation = orientation
        self.snapBehavior = snapBehavior
        self.peek = peek
        self.itemsPerView = itemsPerView
        self.columns = columns
        self.spacing = spacing
        self.showIndicators = showIndicators
        self.indicatorStyle = indicatorStyle
        self.autoScrollInterval = autoScrollInterval
        self.infiniteScroll = infiniteScroll
        self.showArrows = showArrows
        self.arrowStyle = arrowStyle
        self.initialPage = initialPage
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.mode = try container.decodeIfPresent(GalleryMode.self, forKey: .mode) ?? .snapping
        self.orientation = try container.decodeIfPresent(Orientation.self, forKey: .orientation) ?? .horizontal
        self.snapBehavior = try container.decodeIfPresent(SnapBehavior.self, forKey: .snapBehavior) ?? .center
        self.peek = try container.decodeIfPresent(PeekConfig.self, forKey: .peek) ?? PeekConfig()
        self.itemsPerView = try container.decodeIfPresent(CGFloat.self, forKey: .itemsPerView) ?? 1
        self.columns = try container.decodeIfPresent(Int.self, forKey: .columns)
        self.spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing) ?? 8
        self.showIndicators = try container.decodeIfPresent(Bool.self, forKey: .showIndicators) ?? false
        self.indicatorStyle = try container.decodeIfPresent(IndicatorStyle.self, forKey: .indicatorStyle)
        self.autoScrollInterval = try container.decodeIfPresent(Int.self, forKey: .autoScrollInterval) ?? 0
        self.infiniteScroll = try container.decodeIfPresent(Bool.self, forKey: .infiniteScroll) ?? false
        self.showArrows = try container.decodeIfPresent(Bool.self, forKey: .showArrows) ?? false
        self.arrowStyle = try container.decodeIfPresent(ArrowStyle.self, forKey: .arrowStyle)
        self.initialPage = try container.decodeIfPresent(Int.self, forKey: .initialPage) ?? 0
    }
    
    private enum CodingKeys: String, CodingKey {
        case mode, orientation, snapBehavior, peek, itemsPerView, columns
        case spacing, showIndicators, indicatorStyle, autoScrollInterval
        case infiniteScroll, showArrows, arrowStyle, initialPage
    }

    /// Returns `columns` (if set) as CGFloat, otherwise falls back to `itemsPerView`.
    public var effectiveItemsPerView: CGFloat {
        if let c = columns { return CGFloat(c) }
        return itemsPerView
    }
}

/// Style configuration for gallery page indicators.
public struct IndicatorStyle: Codable, Equatable {
    public let size: CGFloat
    public let spacing: CGFloat
    public let activeColor: String
    public let inactiveColor: String
    public let shape: String        // "circle" or "rectangle"
    public let position: String     // "top", "bottom", "left", "right"
    
    public init(
        size: CGFloat = 8,
        spacing: CGFloat = 8,
        activeColor: String = "#2196F3",
        inactiveColor: String = "#BDBDBD",
        shape: String = "circle",
        position: String = "bottom"
    ) {
        self.size = size
        self.spacing = spacing
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.shape = shape
        self.position = position
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.size = try container.decodeIfPresent(CGFloat.self, forKey: .size) ?? 8
        self.spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing) ?? 8
        self.activeColor = try container.decodeIfPresent(String.self, forKey: .activeColor) ?? "#2196F3"
        self.inactiveColor = try container.decodeIfPresent(String.self, forKey: .inactiveColor) ?? "#BDBDBD"
        self.shape = try container.decodeIfPresent(String.self, forKey: .shape) ?? "circle"
        self.position = try container.decodeIfPresent(String.self, forKey: .position) ?? "bottom"
    }
    
    private enum CodingKeys: String, CodingKey {
        case size, spacing, activeColor, inactiveColor, shape, position
    }
}

/// Style configuration for gallery navigation arrows.
public struct ArrowStyle: Codable, Equatable {
    public let size: CGFloat
    public let color: String
    public let backgroundColor: String?
    public let padding: CGFloat
    
    public init(
        size: CGFloat = 24,
        color: String = "#FFFFFF",
        backgroundColor: String? = nil,
        padding: CGFloat = 8
    ) {
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.padding = padding
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.size = try container.decodeIfPresent(CGFloat.self, forKey: .size) ?? 24
        self.color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#FFFFFF"
        self.backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
        self.padding = try container.decodeIfPresent(CGFloat.self, forKey: .padding) ?? 8
    }
    
    private enum CodingKeys: String, CodingKey {
        case size, color, backgroundColor, padding
    }
}
