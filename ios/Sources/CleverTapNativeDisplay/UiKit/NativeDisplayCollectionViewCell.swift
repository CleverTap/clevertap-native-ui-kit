//
//  NativeDisplayCollectionViewCell.swift
//  CleverTapNativeDisplay
//
//  UICollectionViewCell wrapper for SwiftUI NativeDisplayView
//

import UIKit
import SwiftUI

/// UICollectionViewCell that hosts the SwiftUI NativeDisplayView.
/// Use this to display native display content in UICollectionView.
///
/// Example usage:
/// ```swift
/// collectionView.register(NativeDisplayCollectionViewCell.self, forCellWithReuseIdentifier: "SDUICell")
///
/// func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
///     let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SDUICell", for: indexPath) as! NativeDisplayCollectionViewCell
///     cell.configure(with: config, actionListener: listener)
///     return cell
/// }
/// ```
@available(iOS 13.0, *)
public final class NativeDisplayCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    private var hostingController: UIHostingController<AnyView>?
    private weak var parentViewController: UIViewController?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    // MARK: - Setup
    
    private func setupCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    // MARK: - Configuration
    
    /// Configure the cell with a display configuration
    /// - Parameters:
    ///   - config: The resolved display configuration
    ///   - actionListener: Optional listener for action events
    ///   - componentListener: Optional listener for component interactions
    public func configure(
        with config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        // Create SwiftUI view
        let swiftUIView = NativeDisplayView(
            config: config,
            actionListener: actionListener,
            componentListener: componentListener
        )
        
        // If hosting controller already exists, update it
        if let hostingController = hostingController {
            hostingController.rootView = AnyView(swiftUIView)
        } else {
            // Create new hosting controller
            let hostingController = UIHostingController(rootView: AnyView(swiftUIView))
            hostingController.view.backgroundColor = .clear
            
            // Add hosting controller's view
            contentView.addSubview(hostingController.view)
            
            // Setup constraints
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
            
            self.hostingController = hostingController
            
            // Find and add to parent view controller
            if let parentVC = findViewController() {
                self.parentViewController = parentVC
                parentVC.addChild(hostingController)
                hostingController.didMove(toParent: parentVC)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        // Note: We keep the hosting controller for reuse
        // The configure method will update its content
    }
    
    deinit {
        hostingController?.willMove(toParent: nil)
        hostingController?.removeFromParent()
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
