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
/// ### SwiftUI
/// ```swift
/// // 1. Parse JSON configuration
/// let config = try ResolvedConfig.from(jsonString: jsonString)
///
/// // 2. Create and display the view
/// NativeDisplayView(config: config)
/// ```
///
/// ### UIKit
/// ```swift
/// // Option 1: Use as ViewController
/// let config = try ResolvedConfig.from(jsonString: jsonString)
/// let viewController = NativeDisplayViewController(config: config)
/// navigationController?.pushViewController(viewController, animated: true)
///
/// // Option 2: Embed in existing view
/// let displayView = NativeDisplayUIView(config: config)
/// containerView.addSubview(displayView)
///
/// // Option 3: Use in UITableView
/// tableView.register(NativeDisplayTableViewCell.self, forCellReuseIdentifier: "SDUICell")
/// cell.configure(with: config)
///
/// // Option 4: Use in UICollectionView
/// collectionView.register(NativeDisplayCollectionViewCell.self, forCellWithReuseIdentifier: "SDUICell")
/// cell.configure(with: config)
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
/// - **UIKit Integration**: Full support for UIKit apps via wrapper classes
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
    
    // MARK: - SwiftUI Factory Methods
    
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
    
    // MARK: - UIKit Factory Methods
    
    /// Create a UIKit view controller from a resolved configuration.
    /// - Parameters:
    ///   - config: The resolved configuration to render.
    ///   - actionListener: Optional listener for action events.
    ///   - componentListener: Optional listener for component interactions.
    /// - Returns: A UIViewController that hosts the native display.
    @available(iOS 13.0, *)
    public static func createViewController(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) -> NativeDisplayViewController {
        return NativeDisplayViewController(
            config: config,
            actionListener: actionListener,
            componentListener: componentListener
        )
    }
    
    /// Create a UIKit view from a resolved configuration.
    /// - Parameters:
    ///   - config: The resolved configuration to render.
    ///   - actionListener: Optional listener for action events.
    ///   - componentListener: Optional listener for component interactions.
    /// - Returns: A UIView that hosts the native display.
    @available(iOS 13.0, *)
    public static func createUIView(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) -> NativeDisplayUIView {
        return NativeDisplayUIView(
            config: config,
            actionListener: actionListener,
            componentListener: componentListener
        )
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

// UIKit Wrappers (iOS 13+)
@available(iOS 13.0, *)
public typealias NDViewController = NativeDisplayViewController

@available(iOS 13.0, *)
public typealias NDUIView = NativeDisplayUIView

@available(iOS 13.0, *)
public typealias NDTableViewCell = NativeDisplayTableViewCell

@available(iOS 13.0, *)
public typealias NDCollectionViewCell = NativeDisplayCollectionViewCell

// MARK: - Convenience Extensions

public extension ResolvedConfig {
    /// Create a SwiftUI view directly from the configuration.
    func createView() -> some View {
        NativeDisplayView(config: self)
    }
    
    /// Create a UIKit view controller directly from the configuration.
    /// - Parameters:
    ///   - actionListener: Optional listener for action events.
    ///   - componentListener: Optional listener for component interactions.
    /// - Returns: A UIViewController that hosts the native display.
    @available(iOS 13.0, *)
    func createViewController(
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) -> NativeDisplayViewController {
        NativeDisplayViewController(
            config: self,
            actionListener: actionListener,
            componentListener: componentListener
        )
    }
    
    /// Create a UIKit view directly from the configuration.
    /// - Parameters:
    ///   - actionListener: Optional listener for action events.
    ///   - componentListener: Optional listener for component interactions.
    /// - Returns: A UIView that hosts the native display.
    @available(iOS 13.0, *)
    func createUIView(
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) -> NativeDisplayUIView {
        NativeDisplayUIView(
            config: self,
            actionListener: actionListener,
            componentListener: componentListener
        )
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

