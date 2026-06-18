//
//  NativeDisplayCollectionViewCell.swift
//  CleverTapNativeDisplay
//
//  UICollectionViewCell wrapper for direct (non-slot) rendering of a
//  ResolvedConfig / NativeDisplayUnit via the SwiftUI NativeDisplayView.
//

import UIKit

/// UICollectionViewCell that hosts the SDK's SwiftUI renderer via
/// `NativeDisplayUIView`. Use this when you want to drive a
/// `UICollectionView` directly off the bridge listener (Approach 2) — feed
/// each cell a `ResolvedConfig` or `NativeDisplayUnit` and the cell handles
/// the SwiftUI → UIKit hosting, lifecycle, sizing, and re-measurement.
///
/// For the slot-based (Approach 1) flow, see
/// `NativeDisplaySlotCollectionViewCell`.
///
/// Example usage:
/// ```swift
/// collectionView.register(NativeDisplayCollectionViewCell.self, forCellWithReuseIdentifier: "ND")
///
/// func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
///     let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ND", for: indexPath)
///         as! NativeDisplayCollectionViewCell
///     cell.configure(with: units[indexPath.item], actionListener: listener)
///     return cell
/// }
/// ```
@available(iOS 13.0, *)
public final class NativeDisplayCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

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

    /// Configure the cell with a `ResolvedConfig`. No attribution events
    /// fire on this path — use `configure(with: unit, ...)` for bridge-
    /// delivered content.
    public func configure(
        with config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        if let displayView = displayView {
            displayView.updateConfig(config)
        } else {
            installDisplayView(
                NativeDisplayUIView(
                    config: config,
                    parentSize: resolveContainerSize(),
                    actionListener: actionListener,
                    componentListener: componentListener
                )
            )
        }
        notifyEnclosingCollectionViewOfSizeChange()
    }

    /// Configure the cell with a `NativeDisplayUnit`. Preferred overload for
    /// bridge-delivered content — `Notification Viewed` / `Notification
    /// Clicked` attribution events fire for the unit's id.
    public func configure(
        with unit: NativeDisplayUnit,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        if let displayView = displayView {
            displayView.updateUnit(unit)
        } else {
            installDisplayView(
                NativeDisplayUIView(
                    unit: unit,
                    parentSize: resolveContainerSize(),
                    actionListener: actionListener,
                    componentListener: componentListener
                )
            )
        }
        notifyEnclosingCollectionViewOfSizeChange()
    }

    // MARK: - Lifecycle

    public override func prepareForReuse() {
        super.prepareForReuse()
        // Keep `displayView` across reuse — see companion comment in
        // `NativeDisplayTableViewCell.prepareForReuse`.
    }

    // MARK: - Private

    private func installDisplayView(_ view: NativeDisplayUIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        self.displayView = view
    }

    /// Resolve the layout-context size SwiftUI should treat as its parent.
    /// Walks up to the enclosing `UIScrollView` (which `UICollectionView`
    /// subclasses) so the renderer's `nativeDisplayParentSize` environment
    /// is seeded with the real container width.
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

    /// Force the enclosing `UICollectionView` to re-measure this cell. Same
    /// two-stage recipe as the table-view variant — `layoutIfNeeded`
    /// synchronously drives SwiftUI's first layout, then async
    /// `invalidateLayout()` tells the flow layout to recompute.
    private func notifyEnclosingCollectionViewOfSizeChange() {
        setNeedsLayout()
        layoutIfNeeded()

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
}
