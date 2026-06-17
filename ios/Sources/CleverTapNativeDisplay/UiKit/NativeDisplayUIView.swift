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

    private var config: ResolvedConfig
    private var unit: NativeDisplayUnit?
    // Mutable so cell-reuse callers can swap listeners via the
    // `updateConfig(_:actionListener:componentListener:)` /
    // `updateUnit(_:actionListener:componentListener:)` overloads. Without that,
    // a recycled cell keeps routing taps to whichever listeners the initial
    // `init` saw.
    private var actionListener: NativeDisplayActionListener?
    private var componentListener: NativeDisplayComponentListener?
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
        // Tell UIHostingController to expose the SwiftUI root's preferred
        // size via `view.intrinsicContentSize` independent of its current
        // bounds. Without this, the intrinsic size reflects whatever size
        // the hosting view has already been laid out at — which breaks
        // self-sizing UITableView/UICollectionView cells whose initial
        // (empty) measurement caches a near-zero height. iOS 16+ only.
        if #available(iOS 16.0, *) {
            hostingController.sizingOptions = [.intrinsicContentSize]
        }
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
    /// Keeps the listeners supplied at `init` — use the
    /// `updateConfig(_:actionListener:componentListener:)` overload to also
    /// rebind listeners (needed when reusing this view across hosts with
    /// different listener instances, e.g. recycled `UITableViewCell`s).
    /// - Parameter config: New configuration to display
    public func updateConfig(_ newConfig: ResolvedConfig) {
        self.config = newConfig
        self.unit = nil
        rebuildRootView()
    }

    /// Update configuration *and* swap the action/component listeners. Required
    /// when the host reconfigures a recycled cell with different listeners on
    /// the same `NativeDisplayUIView` — the single-arg `updateConfig(_:)` keeps
    /// the original listeners, so taps would route to the previous host.
    public func updateConfig(
        _ newConfig: ResolvedConfig,
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?
    ) {
        self.config = newConfig
        self.unit = nil
        self.actionListener = actionListener
        self.componentListener = componentListener
        rebuildRootView()
    }

    /// Update the displayed unit dynamically. Preserves attribution wiring —
    /// `Notification Viewed` / `Notification Clicked` events fire for the new
    /// unit's id. Keeps the listeners supplied at `init` — use the
    /// `updateUnit(_:actionListener:componentListener:)` overload to also
    /// rebind listeners.
    /// - Parameter newUnit: New display unit to render
    public func updateUnit(_ newUnit: NativeDisplayUnit) {
        self.config = newUnit.config
        self.unit = newUnit
        rebuildRootView()
    }

    /// Update unit *and* swap the action/component listeners. Mirrors
    /// `updateConfig(_:actionListener:componentListener:)` for the attribution-
    /// aware path.
    public func updateUnit(
        _ newUnit: NativeDisplayUnit,
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?
    ) {
        self.config = newUnit.config
        self.unit = newUnit
        self.actionListener = actionListener
        self.componentListener = componentListener
        rebuildRootView()
    }

    private func rebuildRootView() {
        hostingController?.rootView = _NativeDisplayRoot(
            unit: unit,
            config: config,
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

// MARK: - ObjC Compatibility

public extension NativeDisplayUIView {

    /// Convenience initializer that creates a view from a `NativeDisplayUnit`.
    ///
    /// Use this from Objective-C to render a unit received in `onNativeDisplaysLoaded:`.
    ///
    /// ```objc
    /// NativeDisplayUIView *view = [[NativeDisplayUIView alloc]
    ///     initWithUnit:unit
    ///     parentWidth:self.view.bounds.size.width
    ///     actionListener:self
    ///     componentListener:nil];
    /// ```
    @objc convenience init(
        unit: NativeDisplayUnit,
        parentWidth: CGFloat,
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?
    ) {
        let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth, height: 0) : nil
        self.init(
            unit: unit,
            parentSize: parentSize,
            actionListener: actionListener,
            componentListener: componentListener
        )
    }

    /// Convenience initializer that parses raw JSON data and renders the result.
    ///
    /// Returns `nil` if the JSON cannot be parsed. Use this from Objective-C where
    /// `ResolvedConfig` (a Swift type) is not directly accessible.
    ///
    /// ```objc
    /// NativeDisplayUIView *view = [[NativeDisplayUIView alloc]
    ///     initWithJsonData:jsonData
    ///     parentWidth:self.view.bounds.size.width
    ///     actionListener:self
    ///     componentListener:nil];
    /// ```
    @objc convenience init?(
        jsonData: Data,
        parentWidth: CGFloat,
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?
    ) {
        guard let config = try? ResolvedConfig.from(jsonData: jsonData) else { return nil }
        let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth, height: 0) : nil
        self.init(
            config: config,
            parentSize: parentSize,
            actionListener: actionListener,
            componentListener: componentListener
        )
    }
}
