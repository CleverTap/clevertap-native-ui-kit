// MARK: - CleverTapNativeDisplay
// Main public API for the Native Display SDK

import SwiftUI

/// CleverTapNativeDisplay - Server-driven UI framework for native mobile interfaces.
///
/// This SDK renders native SwiftUI interfaces from JSON configurations,
/// supporting dynamic layouts, styling, galleries, and animations.
///
/// ## Quick Start
///
/// ```swift
/// // 1. Parse JSON configuration
/// let config = try ResolvedConfig.from(jsonString: jsonString)
///
/// // 2. Create and display the view
/// NativeDisplayView(config: config)
/// ```
///
/// ## Features
///
/// - **Container Types**: Vertical, Horizontal, Box, Stack, Gallery
/// - **Element Types**: Text, Image, Button, Video, Spacer, Divider
/// - **Gallery Modes**: Snapping (carousel), Free Flow, Free Flow Grid
/// - **Backgrounds**: Solid, Gradient, Pattern, Shimmer, Particles
/// - **Variable Evaluation**: Template expressions with {{variable}} syntax
/// - **Style Resolution**: Theme > Style Class > Inline Style inheritance
///
/// ## Integration Options
///
/// ### Swift Package Manager
/// ```swift
/// dependencies: [
///     .package(url: "https://github.com/example/clevertap-native-display-ios.git", from: "1.0.0")
/// ]
/// ```
///
/// ### CocoaPods
/// ```ruby
/// pod 'CleverTapNativeDisplay'
/// ```
///
public struct CleverTapNativeDisplay {
    
    /// Current SDK version.
    public static let version = "1.0.0"
    
    /// Create a native display view from a resolved configuration.
    /// - Parameter config: The resolved configuration to render.
    /// - Returns: A SwiftUI view that renders the native display.
    public static func createView(config: ResolvedConfig) -> some View {
        NativeDisplayView(config: config)
    }
    
    /// Parse and create a view from JSON data.
    /// - Parameter jsonData: JSON data containing the configuration.
    /// - Returns: A SwiftUI view that renders the native display.
    /// - Throws: If the JSON cannot be parsed.
    public static func createView(from jsonData: Data) throws -> some View {
        let config = try ResolvedConfig.from(jsonData: jsonData)
        return NativeDisplayView(config: config)
    }
    
    /// Parse and create a view from a JSON string.
    /// - Parameter jsonString: JSON string containing the configuration.
    /// - Returns: A SwiftUI view that renders the native display.
    /// - Throws: If the JSON cannot be parsed.
    public static func createView(from jsonString: String) throws -> some View {
        let config = try ResolvedConfig.from(jsonString: jsonString)
        return NativeDisplayView(config: config)
    }
}

// MARK: - Public Type Aliases

// Re-export all public types for convenience

// Container & Element Types
public typealias NDContainerType = ContainerType
public typealias NDElementType = ElementType
public typealias NDGalleryMode = GalleryMode
public typealias NDOrientation = Orientation
public typealias NDSnapBehavior = SnapBehavior
public typealias NDFontWeight = FontWeight
public typealias NDTextDecoration = TextDecoration

// Configuration
public typealias NDConfig = NativeDisplayConfig
public typealias NDResolvedConfig = ResolvedConfig
public typealias NDNode = NativeDisplayNode
public typealias NDContainer = NativeDisplayContainer
public typealias NDElement = NativeDisplayElement

// Styling
public typealias NDStyle = Style
public typealias NDStyleClass = StyleClass
public typealias NDTheme = Theme
public typealias NDLayout = Layout
public typealias NDDimension = Dimension
public typealias NDSpacing = Spacing
public typealias NDBackground = Background

// Gallery
public typealias NDGalleryConfig = GalleryConfig
public typealias NDIndicatorStyle = IndicatorStyle
public typealias NDArrowStyle = ArrowStyle

// MARK: - Convenience Extensions

public extension ResolvedConfig {
    /// Create a view directly from the configuration.
    func createView() -> some View {
        NativeDisplayView(config: self)
    }
}

// MARK: - Preview Support

#if DEBUG
/// Preview helper for sample configurations.
public struct NativeDisplayPreview<Content: View>: View {
    public let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content()
    }
}
#endif
