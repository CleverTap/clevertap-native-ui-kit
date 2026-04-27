// MARK: - Native Display Enums
// Enumeration types for the Native Display System

import Foundation

/// Types of containers that can be rendered.
/// Containers hold and organize child nodes (both containers and elements).
public enum ContainerType: String, Codable, CaseIterable {
    case vertical
    case horizontal
    case box
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

/// Font style values.
public enum FontStyle: String, Codable, CaseIterable {
    case normal
    case italic
}

/// Text decoration values.
public enum TextDecoration: String, Codable, CaseIterable {
    case none
    case underline
    case strikethrough
}

/// Text overflow behavior when text exceeds available space.
public enum TextOverflow: String, Codable, CaseIterable {
    case clip       // Cut off at container edge
    case ellipsis   // Show ellipsis (...)
    case visible    // Allow text to overflow container
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
    case crop       // Fill entire area, may crop edges
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

/// Arrangement strategies for positioning children in VStack/HStack containers.
/// Maps to SwiftUI spacing and alignment options.
public enum ArrangementStrategy: String, Codable, CaseIterable {
    /// Fixed spacing between children.
    /// Uses the spacing value from ChildArrangement.
    /// Maps to: VStack/HStack spacing parameter
    case spaced
    
    /// Space between children, no space at edges.
    /// Example: [child1]---[child2]---[child3]
    /// Maps to: Spacer() between children
    case spaceBetween = "space_between"
    
    /// Equal space between children AND at edges.
    /// Example: ---[child1]---[child2]---[child3]---
    /// Maps to: Spacer() between and around children
    case spaceEvenly = "space_evenly"
    
    /// Equal space around each child (half space at edges).
    /// Example: -[child1]--[child2]--[child3]-
    /// Maps to: Spacer() with flexible spacing
    case spaceAround = "space_around"
    
    /// Align children to start, no extra spacing.
    /// Example: [child1][child2][child3]          
    /// Maps to: .leading/.top alignment
    case start
    
    /// Center children, no extra spacing.
    /// Example:     [child1][child2][child3]     
    /// Maps to: .center alignment
    case center
    
    /// Align children to end, no extra spacing.
    /// Example:          [child1][child2][child3]
    /// Maps to: .trailing/.bottom alignment
    case end
}

/// Animation types for component entrance effects.
/// Each component animates independently when it first appears.
public enum AnimationType: String, Codable, CaseIterable {
    case none
    case fadeIn = "fade_in"
    case slideInLeft = "slide_in_left"
    case slideInRight = "slide_in_right"
    case slideInTop = "slide_in_top"
    case slideInBottom = "slide_in_bottom"
    case scaleIn = "scale_in"
    case fadeScaleIn = "fade_scale_in"
    case fadeSlideIn = "fade_slide_in"
}

/// Easing functions for animations.
/// Maps to SwiftUI's built-in Animation curves.
public enum Easing: String, Codable, CaseIterable {
    case linear
    case easeIn = "ease_in"
    case easeOut = "ease_out"
    case easeInOut = "ease_in_out"
    case easeInBack = "ease_in_back"
    case easeOutBack = "ease_out_back"
    case spring
}
