//
//  NativeDisplayViewController.swift
//  CleverTapNativeDisplay
//
//  UIKit ViewController wrapper for SwiftUI NativeDisplayView
//

import UIKit
import SwiftUI

/// UIKit ViewController that hosts the SwiftUI NativeDisplayView.
/// Use this in UIKit-based apps to display native display content.
///
/// Example usage:
/// ```swift
/// let config = ResolvedConfig(...)
/// let viewController = NativeDisplayViewController(config: config)
/// navigationController?.pushViewController(viewController, animated: true)
/// ```
@available(iOS 13.0, *)
open class NativeDisplayViewController: UIViewController {
    
    // MARK: - Properties
    
    private let config: ResolvedConfig
    private let actionListener: NativeDisplayActionListener?
    private let componentListener: NativeDisplayComponentListener?
    private var hostingController: UIHostingController<NativeDisplayView>?
    
    // MARK: - Initialization
    
    /// Initialize with a resolved configuration
    /// - Parameters:
    ///   - config: The resolved display configuration
    ///   - actionListener: Optional listener for action events
    ///   - componentListener: Optional listener for component interactions
    public init(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.config = config
        self.actionListener = actionListener
        self.componentListener = componentListener
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(config:) instead.")
    }
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUIView()
    }
    
    // MARK: - Setup
    
    private func setupSwiftUIView() {
        // Create SwiftUI view
        let swiftUIView = NativeDisplayView(
            config: config,
            actionListener: actionListener,
            componentListener: componentListener
        )
        
        // Create hosting controller
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
        
        // Remove default background to allow custom styling
        hostingController.view.backgroundColor = .clear
    }
    
    // MARK: - Public Methods
    
    /// Update the configuration dynamically
    /// - Parameter config: New configuration to display
    public func updateConfig(_ config: ResolvedConfig) {
        let swiftUIView = NativeDisplayView(
            config: config,
            actionListener: actionListener,
            componentListener: componentListener
        )
        hostingController?.rootView = swiftUIView
    }
}
