//
//  SampleHelpers.swift
//  NativeDisplaySampleObjc
//
//  Sample-app-specific helpers. NOT part of the SDK.
//  Slot placeholder view and font demo host — both too demo-specific for the SDK.
//

import Foundation
import UIKit
import SwiftUI
import CleverTapNativeDisplay

// MARK: - Sample helpers (ObjC-accessible via class)

/// ObjC-accessible sample-app utilities. NOT part of the SDK.
@objc public final class NDSampleHelpers: NSObject {

    private override init() {}

    /// Load JSON data from the main bundle, searching common directory paths.
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

    /// Create a UIView that renders a Native Display config with an optional font family.
    @objc public static func createFontDemoView(
        from jsonData: Data,
        fontFamily: String?,
        parentWidth: CGFloat,
        error: NSErrorPointer
    ) -> UIView? {
        do {
            let config = try ResolvedConfig.from(jsonData: jsonData)
            let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth - 32, height: 0) : nil
            let hostView = NDFontDemoHostView(config: config, parentSize: parentSize, fontFamily: fontFamily)
            let host = UIHostingController(rootView: hostView)
            host.view.backgroundColor = .clear
            return host.view
        } catch let err as NSError {
            error?.pointee = err
            return nil
        }
    }
}

// MARK: - Slot placeholder

/// Wraps a `NativeDisplaySlotUIView` with a placeholder shown until content arrives.
@available(iOS 15.0, *)
@objc public final class NDSlotPlaceholderView: UIView, NativeDisplaySlotObserver {

    private let slotId: String
    private let placeholderView: UIView
    private var displayView: NativeDisplayUIView?
    private var pendingUnit: NativeDisplayUnit?
    private var isRegistered = false
    private var placeholderBottomConstraint: NSLayoutConstraint?

    @objc public init(slotId: String, placeholder: UIView) {
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

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && !isRegistered {
            isRegistered = true
            NativeDisplaySlotManager.shared.registerSlot(slotId, observer: self)
        } else if window == nil && isRegistered {
            isRegistered = false
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if let unit = pendingUnit, bounds.width > 0 {
            pendingUnit = nil
            installDisplayView(for: unit)
        }
    }

    public func onUnitAvailable(_ unit: NativeDisplayUnit) {
        if bounds.width > 0 {
            installDisplayView(for: unit)
        } else {
            pendingUnit = unit
            placeholderView.isHidden = true
            setNeedsLayout()
        }
    }

    private func installDisplayView(for unit: NativeDisplayUnit) {
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

    public func onUnitCleared(slotId: String) {
        pendingUnit = nil
        displayView?.removeFromSuperview()
        displayView = nil
        placeholderBottomConstraint?.isActive = true
        placeholderView.isHidden = false
    }

    public override var intrinsicContentSize: CGSize {
        displayView?.intrinsicContentSize ?? placeholderView.intrinsicContentSize
    }
}

// MARK: - Font demo SwiftUI host (private)

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
