//
//  NativeDisplaySlotTableViewCell.swift
//  CleverTapNativeDisplay
//
//  UITableViewCell that automatically renders content for a named slot.
//

import UIKit
import SwiftUI

/// UITableViewCell that automatically renders the display unit assigned to a named slot.
///
/// Call `configure(slotId:)` after dequeuing to bind the cell to a slot.
/// The cell registers with `NativeDisplaySlotManager` and updates its content
/// automatically when a unit becomes available or changes.
///
/// ## Usage
///
/// ```swift
/// tableView.register(NativeDisplaySlotTableViewCell.self, forCellReuseIdentifier: "SlotCell")
///
/// func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
///     let cell = tableView.dequeueReusableCell(withIdentifier: "SlotCell", for: indexPath)
///         as! NativeDisplaySlotTableViewCell
///     cell.configure(slotId: "hero_banner", actionListener: myListener)
///     return cell
/// }
/// ```
@available(iOS 15.0, *)
public final class NativeDisplaySlotTableViewCell: UITableViewCell, NativeDisplaySlotObserver {

    // MARK: - Properties

    private var slotView: NativeDisplaySlotUIView?
    private var currentSlotId: String?
    private var actionListener: NativeDisplayActionListener?
    private var componentListener: NativeDisplayComponentListener?

    /// Hosting controller for direct SwiftUI rendering.
    private var hostingController: UIHostingController<AnyView>?
    private weak var parentViewController: UIViewController?

    // MARK: - Initialization

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
        selectionStyle = .none
    }

    // MARK: - Configuration

    /// Configure the cell to observe a specific slot.
    ///
    /// If the cell was previously configured for a different slot, the old
    /// registration is cleaned up before the new one is established.
    ///
    /// - Parameters:
    ///   - slotId: The slot identifier to observe.
    ///   - actionListener: Optional listener for action events.
    ///   - componentListener: Optional listener for component interactions.
    public func configure(
        slotId: String,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.actionListener = actionListener
        self.componentListener = componentListener

        // If same slot, no need to re-register
        if currentSlotId == slotId {
            return
        }

        // Unregister from previous slot
        if let previousSlotId = currentSlotId {
            NativeDisplaySlotManager.shared.unregisterSlot(previousSlotId, observer: self)
        }

        // Clean up existing content
        cleanupContent()

        currentSlotId = slotId
        NativeDisplaySlotManager.shared.registerSlot(slotId, observer: self)
    }

    // MARK: - NativeDisplaySlotObserver

    public func onUnitAvailable(_ unit: NativeDisplayUnit) {
        // Reuse the unit's pre-resolved style map (computed off-main by the bridge).
        let swiftUIView = NativeDisplayView(
            unit: unit,
            actionListener: actionListener,
            componentListener: componentListener
        )

        if let hostingController = hostingController {
            hostingController.rootView = AnyView(swiftUIView)
        } else {
            let hc = UIHostingController(rootView: AnyView(swiftUIView))
            hc.view.backgroundColor = .clear

            contentView.addSubview(hc.view)
            hc.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hc.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                hc.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hc.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            self.hostingController = hc

            if let parentVC = findViewController() {
                self.parentViewController = parentVC
                parentVC.addChild(hc)
                hc.didMove(toParent: parentVC)
            }
        }
    }

    public func onUnitCleared(slotId: String) {
        cleanupContent()
    }

    // MARK: - Lifecycle

    public override func prepareForReuse() {
        super.prepareForReuse()

        // Unregister from current slot on reuse
        if let slotId = currentSlotId {
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
            currentSlotId = nil
        }
        cleanupContent()
    }

    deinit {
        if let slotId = currentSlotId {
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
        }
        hostingController?.willMove(toParent: nil)
        hostingController?.removeFromParent()
    }

    // MARK: - Private

    private func cleanupContent() {
        hostingController?.view.removeFromSuperview()
        hostingController?.willMove(toParent: nil)
        hostingController?.removeFromParent()
        hostingController = nil
    }

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
