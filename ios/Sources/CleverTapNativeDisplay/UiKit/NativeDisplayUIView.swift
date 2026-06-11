//
//  NativeDisplayUIView.swift
//  CleverTapNativeDisplay
//
//  UIKit UIView wrapper for SwiftUI NativeDisplayView
//

import UIKit
import SwiftUI

/// Internal SwiftUI root wrapper. Avoids AnyView type erasure for better SwiftUI diffing.
/// When `unit` is provided, attribution (`Notification Viewed` / `Notification Clicked`)
/// is wired through the SwiftUI `NativeDisplayView(unit:)` initializer.
@available(iOS 13.0, *)
struct _NativeDisplayRoot: View {
    let unit: NativeDisplayUnit?
    let config: ResolvedConfig
    let parentSize: CGSize?
    let actionListener: NativeDisplayActionListener?
    let componentListener: NativeDisplayComponentListener?

    var body: some View {
        let view: NativeDisplayView = {
            if let unit = unit {
                return NativeDisplayView(
                    unit: unit,
                    actionListener: actionListener,
                    componentListener: componentListener
                )
            } else {
                return NativeDisplayView(
                    config: config,
                    actionListener: actionListener,
                    componentListener: componentListener
                )
            }
        }()
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
public final class NativeDisplayUIView: UIView {
    
    // MARK: - Properties

    private let config: ResolvedConfig
    private var unit: NativeDisplayUnit?
    private let actionListener: NativeDisplayActionListener?
    private let componentListener: NativeDisplayComponentListener?
    private let parentSize: CGSize?
    private var hostingController: UIHostingController<_NativeDisplayRoot>?
    private weak var parentViewController: UIViewController?

    // MARK: - Initialization

    /// Render-only initializer. No `unitId` is wired, so attribution events
    /// (`Notification Viewed` / `Notification Clicked`) do not fire. Use this
    /// for previews, tests, and raw-JSON browsers that do not have a parsed
    /// `NativeDisplayUnit`. For bridge- or placement-delivered content, prefer
    /// `init(unit:parentSize:actionListener:componentListener:)`.
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
        self.unit = nil
        self.parentSize = parentSize
        self.actionListener = actionListener
        self.componentListener = componentListener
        super.init(frame: .zero)
        setupSwiftUIView()
    }

    /// Attribution-aware initializer. Uses the unit's pre-resolved style map
    /// (computed off-main by the bridge parser) and the `unitId` needed to fire
    /// `Notification Viewed` / `Notification Clicked` events.
    /// - Parameters:
    ///   - unit: The display unit delivered by the bridge
    ///   - parentSize: Optional explicit parent size for layout calculations (overrides automatic size detection)
    ///   - actionListener: Optional listener for action events
    ///   - componentListener: Optional listener for component interactions
    public init(
        unit: NativeDisplayUnit,
        parentSize: CGSize? = nil,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.config = unit.config
        self.unit = unit
        self.parentSize = parentSize
        self.actionListener = actionListener
        self.componentListener = componentListener
        super.init(frame: .zero)
        setupSwiftUIView()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(config:) or init(unit:) instead.")
    }

    // MARK: - Setup

    private func setupSwiftUIView() {
        let rootView = _NativeDisplayRoot(
            unit: unit,
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
    
    public override func didMoveToWindow() {
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
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        // Remove from parent if moving to nil window
        if newWindow == nil {
            hostingController?.willMove(toParent: nil)
            hostingController?.removeFromParent()
        }
    }
    
    // MARK: - Public Methods
    
    /// Update the configuration dynamically. Clears any previously set unit, so
    /// attribution events stop firing for this view until `updateUnit(_:)` is called.
    /// - Parameter config: New configuration to display
    public func updateConfig(_ newConfig: ResolvedConfig) {
        self.unit = nil
        hostingController?.rootView = _NativeDisplayRoot(
            unit: nil,
            config: newConfig,
            parentSize: parentSize,
            actionListener: actionListener,
            componentListener: componentListener
        )
    }

    /// Update the displayed unit dynamically. Preserves attribution wiring —
    /// `Notification Viewed` / `Notification Clicked` events fire for the new unit's id.
    /// - Parameter newUnit: New display unit to render
    public func updateUnit(_ newUnit: NativeDisplayUnit) {
        self.unit = newUnit
        hostingController?.rootView = _NativeDisplayRoot(
            unit: newUnit,
            config: newUnit.config,
            parentSize: parentSize,
            actionListener: actionListener,
            componentListener: componentListener
        )
    }
    
    // MARK: - Intrinsic Content Size
    
    public override var intrinsicContentSize: CGSize {
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
