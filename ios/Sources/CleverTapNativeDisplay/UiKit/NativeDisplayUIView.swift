//
//  NativeDisplayUIView.swift
//  CleverTapNativeDisplay
//
//  UIKit UIView wrapper for SwiftUI NativeDisplayView
//

import UIKit
import SwiftUI

/// UIKit UIView that hosts the SwiftUI NativeDisplayView.
/// Use this to embed native display content in existing UIKit views.
///
/// Example usage:
/// ```swift
/// let config = ResolvedConfig(...)
/// let displayView = NativeDisplayUIView(config: config)
/// containerView.addSubview(displayView)
/// displayView.translatesAutoresizingMaskIntoConstraints = false
/// NSLayoutConstraint.activate([...])
/// ```
@available(iOS 13.0, *)
open class NativeDisplayUIView: UIView {
    
    // MARK: - Properties

    private let config: ResolvedConfig
    private let actionListener: NativeDisplayActionListener?
    private let componentListener: NativeDisplayComponentListener?
    private let parentSize: CGSize?
    private var hostingController: UIHostingController<AnyView>?
    private weak var parentViewController: UIViewController?

    // MARK: - Initialization

    /// Initialize with a resolved configuration
    /// - Parameters:
    ///   - config: The resolved display configuration
    ///   - parentSize: Optional explicit parent size for layout calculations (overrides automatic size detection)
    ///   - actionListener: Optional listener for action events
    ///   - componentListener: Optional listener for component interactions
    public init(
        config: ResolvedConfig,
        parentSize: CGSize? = nil,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.config = config
        self.parentSize = parentSize
        self.actionListener = actionListener
        self.componentListener = componentListener
        super.init(frame: .zero)
        setupSwiftUIView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(config:) instead.")
    }
    
    // MARK: - Setup
    
    private func setupSwiftUIView() {
        // Create hosting controller with SwiftUI view
        let hostingController: UIHostingController<AnyView>

        if let size = parentSize {
            // Apply environment override if parent size is provided
            let view = NativeDisplayView(
                config: config,
                actionListener: actionListener,
                componentListener: componentListener
            )
            .environment(\.nativeDisplayParentSize, size)
            hostingController = UIHostingController(rootView: AnyView(view))
        } else {
            // No environment override needed
            let view = NativeDisplayView(
                config: config,
                actionListener: actionListener,
                componentListener: componentListener
            )
            hostingController = UIHostingController(rootView: AnyView(view))
        }

        hostingController.view.backgroundColor = .clear

        // Add hosting controller's view
        addSubview(hostingController.view)

        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.hostingController = hostingController
    }
    
    // MARK: - Lifecycle
    
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // Find parent view controller and add hosting controller as child
        if let parentVC = findViewController() {
            self.parentViewController = parentVC
            if let hostingController = hostingController,
               hostingController.parent == nil {
                parentVC.addChild(hostingController)
                hostingController.didMove(toParent: parentVC)
            }
        }
    }
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        // Remove from parent if moving to nil window
        if newWindow == nil {
            hostingController?.willMove(toParent: nil)
            hostingController?.removeFromParent()
        }
    }
    
    // MARK: - Public Methods
    
    /// Update the configuration dynamically
    /// - Parameter config: New configuration to display
    public func updateConfig(_ config: ResolvedConfig) {
        if let size = parentSize {
            let view = NativeDisplayView(
                config: config,
                actionListener: actionListener,
                componentListener: componentListener
            )
            .environment(\.nativeDisplayParentSize, size)
            hostingController?.rootView = AnyView(view)
        } else {
            let view = NativeDisplayView(
                config: config,
                actionListener: actionListener,
                componentListener: componentListener
            )
            hostingController?.rootView = AnyView(view)
        }
    }
    
    // MARK: - Intrinsic Content Size
    
    open override var intrinsicContentSize: CGSize {
        hostingController?.view.intrinsicContentSize ?? .zero
    }
    
    // MARK: - Helper Methods
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}
