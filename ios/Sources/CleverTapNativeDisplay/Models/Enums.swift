// MARK: - Native Display Enums
// Enumeration types for the Native Display System

import Foundation

/// Types of containers that can be rendered.
/// Containers hold and organize child nodes (both containers and elements).
public enum ContainerType: String, Codable, CaseIterable {
    case vertical
    case horizontal
    case box
    case stack
    case gallery
}

/// Types of UI elements that can be rendered.
/// Elements are leaf nodes that display actual content.
public enum ElementType: String, Codable, CaseIterable {
    case text
    case image
    case button
    case video
    case spacer
    case divider
}

/// Units for dimension values.
public enum DimensionUnit: String, Codable, CaseIterable {
    case dp
    case sp
    case percent
    case px
}

/// Special dimension values.
public enum SpecialDimension: String, Codable, CaseIterable {
    case wrapContent = "wrap_content"
    case matchParent = "match_parent"
}

/// Font weight values.
public enum FontWeight: String, Codable, CaseIterable {
    case normal
    case medium
    case bold
    case light
}

/// Text decoration values.
public enum TextDecoration: String, Codable, CaseIterable {
    case none
    case underline
    case strikethrough
}

/// Orientation for divider and gallery.
public enum Orientation: String, Codable, CaseIterable {
    case horizontal
    case vertical
}

/// Snap behavior for gallery/carousel.
public enum SnapBehavior: String, Codable, CaseIterable {
    case none       // Free scrolling
    case start      // Snap to start
    case center     // Snap to center (one item centered)
    case end        // Snap to end
}

/// Gallery mode determines the behavior and layout strategy.
public enum GalleryMode: String, Codable, CaseIterable {
    case snapping           // Pager with full-size items and peek support
    case freeFlow = "free_flow"          // Items size themselves independently (no peek)
    case freeFlowGrid = "free_flow_grid" // Fixed items per view with peek via itemsPerView
}

/// Image fit modes for image backgrounds.
public enum ImageFit: String, Codable, CaseIterable {
    case cover      // Fill entire area, may crop
    case contain    // Fit within area, may letterbox
    case fill       // Stretch to fill
    case tile       // Repeat image
}

/// Gradient type for animated gradients.
public enum GradientType: String, Codable, CaseIterable {
    case linear
    case radial
    case sweep
}

/// Animation style for animated backgrounds.
public enum AnimationStyle: String, Codable, CaseIterable {
    case smooth     // Colors blend smoothly
    case shift      // Colors shift positions
    case pulse      // Colors pulse intensity
}

/// Pattern types for pattern backgrounds.
public enum PatternType: String, Codable, CaseIterable {
    case dots
    case stripesHorizontal = "stripes_horizontal"
    case stripesVertical = "stripes_vertical"
    case stripesDiagonal = "stripes_diagonal"
    case grid
    case checkerboard
    case polkaDots = "polka_dots"
}

/// Particle movement direction.
public enum ParticleDirection: String, Codable, CaseIterable {
    case up
    case down
    case left
    case right
    case random
}
