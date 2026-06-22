//
//  NativeDisplaySlotTableViewCell.swift
//  CleverTapNativeDisplay
//
//  UITableViewCell that automatically renders content for a named slot.
//

import UIKit

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

    private var currentSlotId: String?
    private var actionListener: NativeDisplayActionListener?
    private var componentListener: NativeDisplayComponentListener?

    /// The SDK's UIKit-friendly SwiftUI host. Owns the `UIHostingController`
    /// lifecycle, parent-VC chaining, and SwiftUI → UIKit size bridging via
    /// `sizingOptions = .intrinsicContentSize` (iOS 16+).
    private var displayView: NativeDisplayUIView?

    /// Temporary height constraint installed when the manager has a cached
    /// measurement for the current slot. Pins the cell to the last-known
    /// height before any unit arrives, eliminating the visible jump from
    /// `estimatedRowHeight` to the real size on cell reuse. Deactivated as
    /// soon as the displayView's own intrinsic size has settled.
    private var placeholderHeightConstraint: NSLayoutConstraint?

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
    @objc public func configure(
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

        // If we've previously measured this slot, pin the cell to that
        // height before content arrives so a recycled cell starts at the
        // right size instead of `estimatedRowHeight`. The constraint is
        // torn down once the displayView's own intrinsic size has settled.
        installPlaceholderHeightIfCached(for: slotId)

        NativeDisplaySlotManager.shared.registerSlot(slotId, observer: self)
    }

    private func installPlaceholderHeightIfCached(for slotId: String) {
        removePlaceholderHeight()
        guard let cached = NativeDisplaySlotManager.shared.measuredHeight(forSlotId: slotId), cached > 0 else { return }
        let c = contentView.heightAnchor.constraint(equalToConstant: cached)
        // Just below `.required` so AutoLayout never has to break the
        // table-view's own `UIView-Encapsulated-Layout-Height`, but well
        // above the displayView's intrinsic-content priority (750) — wins
        // until we explicitly deactivate it.
        c.priority = UILayoutPriority(999)
        c.isActive = true
        placeholderHeightConstraint = c
    }

    private func removePlaceholderHeight() {
        placeholderHeightConstraint?.isActive = false
        placeholderHeightConstraint = nil
    }

    // MARK: - NativeDisplaySlotObserver

    public func onUnitAvailable(_ unit: NativeDisplayUnit) {
        if let displayView = displayView {
            // Re-use the existing wrapper. Preserves the hosting controller
            // and its parent-VC relationship; only the SwiftUI rootView is
            // swapped to point at the new unit. Pass through the cell's
            // current listeners so a re-`configure(slotId:)` with new listeners
            // (same slot id) is honored — `NativeDisplayUIView`'s plain
            // `updateUnit(_:)` would keep the listeners from the initial bind.
            displayView.updateUnit(
                unit,
                actionListener: actionListener,
                componentListener: componentListener
            )
        } else {
            // Seed the renderer's `nativeDisplayParentSize` environment via
            // the explicit parentSize init. Without it, the renderer's
            // `GeometryReader` fallback measures the freshly-attached
            // wrapper while its bounds are still ~0 (the empty-cell size),
            // so any percent-width / aspect-ratio child in the campaign
            // locks in against zero and the content renders permanently
            // tiny. The enclosing scroll view's bounds are the real
            // container width at this moment — pass them through.
            let parentSize = resolveContainerSize()
            let view = NativeDisplayUIView(
                unit: unit,
                parentSize: parentSize,
                actionListener: actionListener,
                componentListener: componentListener
            )
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: contentView.topAnchor),
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
            self.displayView = view
        }

        notifyEnclosingTableViewOfHeightChange()
    }

    /// Resolve the layout-context size that SwiftUI should treat as its
    /// parent. Walks up to the nearest `UIScrollView` (both `UITableView`
    /// and `UICollectionView` subclass it) and uses its bounds. Falls back
    /// to the cell's own bounds, then to the screen — in that order — so a
    /// cell used outside a recycler still gets sensible defaults.
    private func resolveContainerSize() -> CGSize {
        var view: UIView? = self.superview
        while view != nil {
            if let scrollView = view as? UIScrollView, scrollView.bounds.width > 0 {
                return scrollView.bounds.size
            }
            view = view?.superview
        }
        if bounds.width > 0 {
            return bounds.size
        }
        return UIScreen.main.bounds.size
    }

    public func onUnitCleared(slotId: String) {
        cleanupContent()
        notifyEnclosingTableViewOfHeightChange()
    }

    /// Force the enclosing `UITableView` to re-measure this cell's row.
    ///
    /// The cell's content is `NativeDisplayUIView`, which hosts SwiftUI. Its
    /// preferred height isn't known until SwiftUI has laid out at the cell's
    /// real width; by the time `onUnitAvailable` fires, the table view has
    /// already cached this row at its empty height, so the cell renders
    /// undersized until something forces a re-measure.
    ///
    /// Two-stage recipe:
    ///
    ///  1. **Synchronously** `layoutIfNeeded()` on the cell. Adding the
    ///     `NativeDisplayUIView` above marked the cell's layout dirty;
    ///     `layoutIfNeeded` runs the pending pass right now — resolving the
    ///     4-edge constraints so the embedded view's bounds match the
    ///     cell's full width, then driving SwiftUI to lay out at that
    ///     width. With `sizingOptions = .intrinsicContentSize` set on the
    ///     hosting controller inside `NativeDisplayUIView`, SwiftUI's
    ///     preferred size flows up through `intrinsicContentSize`.
    ///
    ///     A measurement-only call like `systemLayoutSizeFitting` doesn't
    ///     work here — it can return based on incomplete state without
    ///     actually triggering the layout pipeline. Only a real
    ///     `layoutIfNeeded` drives SwiftUI.
    ///
    ///  2. **Asynchronously** invalidate this cell's intrinsic size and
    ///     call `beginUpdates()` / `endUpdates()` on the enclosing table
    ///     view — the canonical "re-query row heights without animating
    ///     any other change" idiom. By this runloop tick the intrinsic
    ///     size reflects SwiftUI's real preferred size, so the solver
    ///     picks the correct row height.
    private func notifyEnclosingTableViewOfHeightChange() {
        // Stage 1 — drive SwiftUI's layout pass now.
        setNeedsLayout()
        layoutIfNeeded()

        // Stage 2 — re-query row heights on the next runloop tick.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.invalidateIntrinsicContentSize()

            // Record the measured height so the next time this slot is
            // displayed in a recycled cell, we can pre-size via the
            // placeholder constraint and skip the visible jump.
            if let slotId = self.currentSlotId,
               let measured = self.displayView?.intrinsicContentSize.height,
               measured > 0 {
                NativeDisplaySlotManager.shared.setMeasuredHeight(measured, forSlotId: slotId)
            }
            // The displayView now owns the height via its intrinsic size —
            // the placeholder has served its purpose and would only fight
            // future size changes if left active.
            self.removePlaceholderHeight()

            var view: UIView? = self.superview
            while view != nil {
                if let tableView = view as? UITableView {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                    return
                }
                view = view?.superview
            }
        }
    }

    // MARK: - Lifecycle

    public override func prepareForReuse() {
        super.prepareForReuse()

        // Unregister from current slot on reuse
        if let slotId = currentSlotId {
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
            currentSlotId = nil
        }
        removePlaceholderHeight()
        cleanupContent()
    }

    deinit {
        if let slotId = currentSlotId {
            NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
        }
    }

    // MARK: - Private

    private func cleanupContent() {
        displayView?.removeFromSuperview()
        displayView = nil
    }
}
