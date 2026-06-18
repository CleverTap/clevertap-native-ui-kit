//
//  NativeDisplaySlotCollectionViewCell.swift
//  CleverTapNativeDisplay
//
//  UICollectionViewCell that automatically renders content for a named slot.
//

import UIKit

/// UICollectionViewCell that automatically renders the display unit assigned to a named slot.
///
/// Call `configure(slotId:)` after dequeuing to bind the cell to a slot.
/// The cell registers with `NativeDisplaySlotManager` and updates its content
/// automatically when a unit becomes available or changes.
///
/// ## Usage
///
/// ```swift
/// collectionView.register(NativeDisplaySlotCollectionViewCell.self, forCellWithReuseIdentifier: "SlotCell")
///
/// func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
///     let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SlotCell", for: indexPath)
///         as! NativeDisplaySlotCollectionViewCell
///     cell.configure(slotId: "hero_banner", actionListener: myListener)
///     return cell
/// }
/// ```
@available(iOS 15.0, *)
public final class NativeDisplaySlotCollectionViewCell: UICollectionViewCell, NativeDisplaySlotObserver {

    // MARK: - Properties

    private var currentSlotId: String?
    private var actionListener: NativeDisplayActionListener?
    private var componentListener: NativeDisplayComponentListener?

    /// The SDK's UIKit-friendly SwiftUI host. Owns the `UIHostingController`
    /// lifecycle, parent-VC chaining, and SwiftUI → UIKit size bridging via
    /// `sizingOptions = .intrinsicContentSize` (iOS 16+).
    private var displayView: NativeDisplayUIView?

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
        NativeDisplaySlotManager.shared.registerSlot(slotId, observer: self)
    }

    // MARK: - NativeDisplaySlotObserver

    public func onUnitAvailable(_ unit: NativeDisplayUnit) {
        if let displayView = displayView {
            // Re-use the existing wrapper. Preserves the hosting controller
            // and its parent-VC relationship; only the SwiftUI rootView is
            // swapped to point at the new unit.
            displayView.updateUnit(unit)
        } else {
            // Seed the renderer's `nativeDisplayParentSize` environment via
            // the explicit parentSize init — see the companion docs in
            // `NativeDisplaySlotTableViewCell.onUnitAvailable` for why.
            // Without this, any percent-width / aspect-ratio child renders
            // against the empty cell's near-zero bounds and stays tiny.
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

        notifyEnclosingCollectionViewOfSizeChange()
    }

    /// Resolve the layout-context size SwiftUI should treat as its parent.
    /// Walks up to the nearest `UIScrollView` (which both `UITableView`
    /// and `UICollectionView` subclass) and uses its bounds. Falls back to
    /// the cell's own bounds, then to the screen.
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
        notifyEnclosingCollectionViewOfSizeChange()
    }

    /// Force the enclosing `UICollectionView` to re-measure this cell.
    ///
    /// Mirror of the table-view variant — see its docs for the why.
    ///
    ///  1. **Synchronously** `layoutIfNeeded()` on the cell so the freshly-
    ///     added `NativeDisplayUIView` runs its first layout pass — Auto
    ///     Layout resolves the 4-edge constraints, the hosting view lays
    ///     out at the correct width, SwiftUI lays out, and SwiftUI's
    ///     preferred size populates the hosting view's
    ///     `intrinsicContentSize` via `sizingOptions =
    ///     .intrinsicContentSize` (set inside `NativeDisplayUIView`).
    ///  2. **Asynchronously** invalidate this cell's intrinsic size and
    ///     call `collectionViewLayout.invalidateLayout()` so the flow
    ///     layout recomputes using the now-correct preferred size.
    private func notifyEnclosingCollectionViewOfSizeChange() {
        // Stage 1 — drive SwiftUI's layout pass now.
        setNeedsLayout()
        layoutIfNeeded()

        // Stage 2 — invalidate the flow layout on the next runloop tick.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.invalidateIntrinsicContentSize()
            var view: UIView? = self.superview
            while view != nil {
                if let collectionView = view as? UICollectionView {
                    collectionView.collectionViewLayout.invalidateLayout()
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
