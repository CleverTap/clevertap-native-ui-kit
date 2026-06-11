//
//  NDDisplayHelper.swift
//  NativeDisplaySampleObjc
//
//  Swift bridge providing @objc-compatible factory methods for creating
//  NativeDisplayUIView instances from JSON data. ObjC files import this
//  via #import "NativeDisplaySampleObjc-Swift.h".
//

import Foundation
import UIKit
import SwiftUI
import CleverTapNativeDisplay

/// ObjC-accessible factory for creating NativeDisplayUIView instances from JSON data.
@objc public class NDDisplayHelper: NSObject {

    /// Create a NativeDisplayUIView from JSON data with optional listeners.
    @objc public static func createView(
        from jsonData: Data,
        parentWidth: CGFloat,
        componentListener: NativeDisplayComponentListener?,
        actionListener: NativeDisplayActionListener?,
        error: NSErrorPointer
    ) -> NativeDisplayUIView? {
        do {
            let config = try ResolvedConfig.from(jsonData: jsonData)
            let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth - 32, height: 0) : nil
            return NativeDisplayUIView(
                config: config,
                parentSize: parentSize,
                actionListener: actionListener,
                componentListener: componentListener
            )
        } catch let err as NSError {
            error?.pointee = err
            return nil
        }
    }

    /// Create a NativeDisplayUIView from JSON data with an arrangement strategy override.
    @objc public static func createView(
        from jsonData: Data,
        parentWidth: CGFloat,
        arrangementStrategy: String,
        componentListener: NativeDisplayComponentListener?,
        actionListener: NativeDisplayActionListener?,
        error: NSErrorPointer
    ) -> NativeDisplayUIView? {
        do {
            var config = try ResolvedConfig.from(jsonData: jsonData)

            // Map strategy string to ArrangementStrategy enum
            let strategy: ArrangementStrategy
            switch arrangementStrategy {
            case "space_between": strategy = .spaceBetween
            case "space_evenly":  strategy = .spaceEvenly
            case "space_around":  strategy = .spaceAround
            case "start":         strategy = .start
            case "center":        strategy = .center
            case "end":           strategy = .end
            default:              strategy = .spaced
            }

            // Update root container arrangement
            if case .container(let container) = config.root {
                let spacing: CGFloat? = strategy == .spaced ? 16 : nil
                let newArrangement = ChildArrangement(spacing: spacing, spacingUnit: .dp, strategy: strategy)
                let updatedLayout = Layout(
                    width: container.layout?.width,
                    height: container.layout?.height,
                    offset: container.layout?.offset,
                    padding: container.layout?.padding,
                    arrangement: newArrangement
                )
                let updatedContainer = NativeDisplayContainer(
                    id: container.id,
                    containerType: container.containerType,
                    children: container.children,
                    layout: updatedLayout,
                    style: container.style,
                    styleClass: container.styleClass,
                    visible: container.visible,
                    actions: container.actions,
                    animation: container.animation,
                    galleryConfig: container.galleryConfig,
                    dividerConfig: container.dividerConfig
                )
                config = ResolvedConfig(
                    theme: config.theme,
                    styleClasses: config.styleClasses,
                    variables: config.variables,
                    root: .container(updatedContainer)
                )
            }

            let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth - 32, height: 0) : nil
            return NativeDisplayUIView(
                config: config,
                parentSize: parentSize,
                actionListener: actionListener,
                componentListener: componentListener
            )
        } catch let err as NSError {
            error?.pointee = err
            return nil
        }
    }

    /// Load JSON data from the bundle, searching multiple directory paths.
    @objc public static func loadJSONData(filename: String, directory: String?) -> Data? {
        let bundle = Bundle.main
        var paths: [String?] = []
        if let dir = directory {
            paths.append(bundle.path(forResource: filename, ofType: "json", inDirectory: dir))
            paths.append(bundle.path(forResource: filename, ofType: "json", inDirectory: "Resources/\(dir)"))
        }
        paths.append(bundle.path(forResource: filename, ofType: "json"))

        for path in paths {
            if let p = path, let data = try? Data(contentsOf: URL(fileURLWithPath: p)) {
                return data
            }
        }
        return nil
    }

    // MARK: - Font Demo helpers

    /// Create a UIView that renders the given JSON config using the system default font.
    /// The view is hosted inside a UIHostingController-based container so that SwiftUI
    /// environment values can be injected. Callers should size the returned view and add
    /// it to the hierarchy; it will self-size vertically using Auto Layout.
    @objc public static func createFontDemoView(
        from jsonData: Data,
        fontFamily: String?,
        parentWidth: CGFloat,
        error: NSErrorPointer
    ) -> UIView? {
        do {
            let config = try ResolvedConfig.from(jsonData: jsonData)
            let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth - 32, height: 0) : nil
            let hostView = NDFontDemoHostView(
                config: config,
                parentSize: parentSize,
                fontFamily: fontFamily
            )
            let host = UIHostingController(rootView: hostView)
            host.view.backgroundColor = .clear
            return host.view
        } catch let err as NSError {
            error?.pointee = err
            return nil
        }
    }

    // MARK: - Bridge helpers (used by demo view controllers)

    /// Returns unit IDs of all cached units in NativeDisplayBridge.shared.
    @objc public static func bridgeGetAllUnitIds() -> [String] {
        NativeDisplayBridge.shared.getAllNativeDisplays().map { $0.unitId }
    }

    /// Register an ObjC-compatible bridge listener. Returns an opaque token that must
    /// be passed to `bridgeRemoveListener(_:)` to unregister.
    @objc public static func bridgeAddListener(_ listener: NDBridgeListenerObjc) -> NDBridgeListenerToken {
        let token = NDBridgeListenerToken(listener: listener)
        NativeDisplayBridge.shared.addListener(token)
        return token
    }

    /// Unregister a listener token obtained from `bridgeAddListener(_:)`.
    @objc public static func bridgeRemoveListener(_ token: NDBridgeListenerToken) {
        NativeDisplayBridge.shared.removeListener(token)
    }

    // MARK: - Slot helpers

    /// Create a NativeDisplaySlotUIView for the given slot ID.
    /// Available on iOS 15+; returns nil on earlier versions.
    @objc public static func createSlotView(slotId: String) -> UIView? {
        if #available(iOS 15.0, *) {
            return NativeDisplaySlotUIView(slotId: slotId)
        }
        return nil
    }

    /// Create a slot view with a placeholder shown until content arrives.
    /// Available on iOS 15+; returns nil on earlier versions.
    @objc public static func createSlotView(slotId: String, placeholder: UIView) -> UIView? {
        if #available(iOS 15.0, *) {
            return NDSlotPlaceholderView(slotId: slotId, placeholder: placeholder)
        }
        return nil
    }

    /// Render a cached NativeDisplayUnit by ID into a UIView.
    @objc public static func createView(
        forUnitId unitId: String,
        parentWidth: CGFloat,
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?
    ) -> NativeDisplayUIView? {
        guard let unit = NativeDisplayBridge.shared.getNativeDisplayForId(unitId) else { return nil }
        let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth - 32, height: 0) : nil
        return NativeDisplayUIView(
            config: unit.config,
            parentSize: parentSize,
            actionListener: actionListener,
            componentListener: componentListener
        )
    }

}

// MARK: - Slot placeholder wrapper

/// Wraps NativeDisplaySlotManager observation directly so a placeholder UIView can be
/// shown until a unit arrives, without requiring SDK changes.
@available(iOS 15.0, *)
final class NDSlotPlaceholderView: UIView, NativeDisplaySlotObserver {

    private let slotId: String
    private let placeholderView: UIView
    private var displayView: NativeDisplayUIView?
    private var pendingUnit: NativeDisplayUnit?
    private var isRegistered = false
    private var placeholderBottomConstraint: NSLayoutConstraint?

    init(slotId: String, placeholder: UIView) {
        self.slotId = slotId
        self.placeholderView = placeholder
        super.init(frame: .zero)
        backgroundColor = .clear

        placeholder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholder)
        let bottom = placeholder.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([
            placeholder.topAnchor.constraint(equalTo: topAnchor),
            placeholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholder.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottom,
        ])
        placeholderBottomConstraint = bottom
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if isRegistered {
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && !isRegistered {
            isRegistered = true
            NativeDisplaySlotManager.shared.registerSlot(slotId, observer: self)
        } else if window == nil && isRegistered {
            isRegistered = false
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Create or update the display view now that we have a valid width.
        if let unit = pendingUnit, bounds.width > 0 {
            pendingUnit = nil
            installDisplayView(for: unit)
        }
    }

    func onUnitAvailable(_ unit: NativeDisplayUnit) {
        if bounds.width > 0 {
            installDisplayView(for: unit)
        } else {
            // Bounds not yet resolved — defer to layoutSubviews.
            pendingUnit = unit
            placeholderView.isHidden = true
            setNeedsLayout()
        }
    }

    private func installDisplayView(for unit: NativeDisplayUnit) {
        // Deactivate the placeholder's bottom constraint so the display view
        // can drive the wrapper height freely (placeholder was locking it to 80pt).
        placeholderBottomConstraint?.isActive = false
        placeholderView.isHidden = true

        let parentSize = CGSize(width: bounds.width, height: 0)
        if let existing = displayView {
            existing.updateConfig(unit.config)
        } else {
            let view = NativeDisplayUIView(config: unit.config, parentSize: parentSize)
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            displayView = view
        }
    }

    func onUnitCleared(slotId: String) {
        pendingUnit = nil
        displayView?.removeFromSuperview()
        displayView = nil
        placeholderBottomConstraint?.isActive = true
        placeholderView.isHidden = false
    }

    override var intrinsicContentSize: CGSize {
        displayView?.intrinsicContentSize ?? placeholderView.intrinsicContentSize
    }
}

// MARK: - ObjC-compatible bridge listener protocol

/// ObjC classes implement this protocol to receive bridge callbacks.
/// Unit IDs are passed instead of NativeDisplayUnit (which is not ObjC-representable).
/// Use `NDDisplayHelper.createView(forUnitId:...)` to render a unit by its ID.
@objc public protocol NDBridgeListenerObjc: AnyObject {
    func onNativeDisplaysLoaded(_ unitIds: [String])
}

// MARK: - Bridge listener token (Swift adapter)

/// Adapts NDBridgeListenerObjc to the Swift NativeDisplayBridgeListener protocol.
/// Returned as an opaque token from NDDisplayHelper.bridgeAddListener(_:).
@objc public class NDBridgeListenerToken: NSObject, NativeDisplayBridgeListener {
    private weak var objcListener: NDBridgeListenerObjc?

    init(listener: NDBridgeListenerObjc) {
        self.objcListener = listener
    }

    public func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        objcListener?.onNativeDisplaysLoaded(units.map { $0.unitId })
    }
}

// MARK: - SwiftUI host view for font demos

/// Internal SwiftUI view that wraps NativeDisplayView with optional font env values.
private struct NDFontDemoHostView: View {
    let config: ResolvedConfig
    let parentSize: CGSize?
    let fontFamily: String?

    var body: some View {
        Group {
            if let family = fontFamily {
                NativeDisplayView(config: config)
                    .environment(\.nativeDisplayFontFamily, family)
                    .applyParentSizeIfNeeded(parentSize)
            } else {
                NativeDisplayView(config: config)
                    .applyParentSizeIfNeeded(parentSize)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func applyParentSizeIfNeeded(_ size: CGSize?) -> some View {
        if let size = size {
            self.environment(\.nativeDisplayParentSize, size)
        } else {
            self
        }
    }
}
