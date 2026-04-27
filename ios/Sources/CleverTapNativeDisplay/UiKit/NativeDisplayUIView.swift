//
//  NativeDisplayUIView.swift
//  CleverTapNativeDisplay
//
//  UIKit UIView wrapper for SwiftUI NativeDisplayView
//

import UIKit
import SwiftUI

/// Internal SwiftUI root wrapper. Avoids AnyView type erasure for better SwiftUI diffing.
@available(iOS 13.0, *)
struct _NativeDisplayRoot: View {
    let config: ResolvedConfig
    let parentSize: CGSize?
    let actionListener: NativeDisplayActionListener?
    let componentListener: NativeDisplayComponentListener?

    var body: some View {
        let view = NativeDisplayView(
            config: config,
            actionListener: actionListener,
            componentListener: componentListener
        )
        if let size = parentSize {
            view.environment(\.nativeDisplayParentSize, size)
        } else {
            view
        }
    }
}

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
    private var hostingController: UIHostingController<_NativeDisplayRoot>?
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
        let rootView = _NativeDisplayRoot(
            config: config,
            parentSize: parentSize,
            actionListener: actionListener,
            componentListener: componentListener
        )
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        addSubview(hostingController.view)
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
    public func updateConfig(_ newConfig: ResolvedConfig) {
        hostingController?.rootView = _NativeDisplayRoot(
            config: newConfig,
            parentSize: parentSize,
            actionListener: actionListener,
            componentListener: componentListener
        )
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
