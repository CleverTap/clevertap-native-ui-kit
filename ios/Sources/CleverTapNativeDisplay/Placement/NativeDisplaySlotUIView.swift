//
//  NativeDisplaySlotUIView.swift
//  CleverTapNativeDisplay
//
//  UIKit UIView that automatically renders content for a named slot.
//

import UIKit
import SwiftUI

/// A UIView that automatically renders the display unit assigned to a named slot.
///
/// Registers with `NativeDisplaySlotManager` when added to a window and unregisters
/// when removed. When a unit becomes available, it creates an internal
/// `NativeDisplayUIView` to render the content.
///
/// ## Usage
///
/// ```swift
/// let slotView = NativeDisplaySlotUIView(slotId: "hero_banner")
/// slotView.actionListener = myActionListener
/// containerView.addSubview(slotView)
/// slotView.translatesAutoresizingMaskIntoConstraints = false
/// NSLayoutConstraint.activate([
///     slotView.topAnchor.constraint(equalTo: containerView.topAnchor),
///     slotView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
///     slotView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
///     slotView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
/// ])
/// ```
@available(iOS 15.0, *)
public final class NativeDisplaySlotUIView: UIView, NativeDisplaySlotObserver {

    // MARK: - Properties

    /// The slot identifier this view observes.
    public let slotId: String

    /// Optional listener for action events.
    public var actionListener: NativeDisplayActionListener?

    /// Optional listener for component interaction events.
    public var componentListener: NativeDisplayComponentListener?

    /// The internal display view currently showing content.
    private var displayView: NativeDisplayUIView?

    /// Whether this view is currently registered as a slot observer.
    private var isRegistered = false

    // MARK: - Initialization

    /// Create a slot UIView for the given slot identifier.
    ///
    /// - Parameter slotId: The slot identifier to observe.
    public init(slotId: String) {
        self.slotId = slotId
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(slotId:) instead.")
    }

    deinit {
        if isRegistered {
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
        }
    }

    // MARK: - Lifecycle

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

    // MARK: - NativeDisplaySlotObserver

    public func onUnitAvailable(_ unit: NativeDisplayUnit) {
        if let existing = displayView {
            existing.updateConfig(unit.config)
        } else {
            let view = NativeDisplayUIView(
                config: unit.config,
                actionListener: actionListener,
                componentListener: componentListener
            )
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            displayView = view
        }
    }

    public func onUnitCleared(slotId: String) {
        displayView?.removeFromSuperview()
        displayView = nil
    }

    // MARK: - Intrinsic Content Size

    public override var intrinsicContentSize: CGSize {
        displayView?.intrinsicContentSize ?? .zero
    }
}
