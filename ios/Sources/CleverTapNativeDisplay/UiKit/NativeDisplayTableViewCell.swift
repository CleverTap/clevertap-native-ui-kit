//
//  NativeDisplayTableViewCell.swift
//  CleverTapNativeDisplay
//
//  UITableViewCell wrapper for direct (non-slot) rendering of a
//  ResolvedConfig / NativeDisplayUnit via the SwiftUI NativeDisplayView.
//

import UIKit

/// UITableViewCell that hosts the SDK's SwiftUI renderer via
/// `NativeDisplayUIView`. Use this when you want to drive a `UITableView`
/// directly off the bridge listener (Approach 2) — feed each row a
/// `ResolvedConfig` or `NativeDisplayUnit` and the cell handles the
/// SwiftUI → UIKit hosting, lifecycle, sizing, and re-measurement.
///
/// For the slot-based (Approach 1) flow, see
/// `NativeDisplaySlotTableViewCell`.
///
/// Example usage:
/// ```swift
/// tableView.register(NativeDisplayTableViewCell.self, forCellReuseIdentifier: "ND")
///
/// func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
///     let cell = tableView.dequeueReusableCell(withIdentifier: "ND", for: indexPath)
///         as! NativeDisplayTableViewCell
///     cell.configure(with: units[indexPath.row], actionListener: listener)
///     return cell
/// }
/// ```
@available(iOS 13.0, *)
public final class NativeDisplayTableViewCell: UITableViewCell {

    // MARK: - Properties

    /// The SDK's UIKit-friendly SwiftUI host. Owns the `UIHostingController`,
    /// parent-VC chaining, and SwiftUI → UIKit size bridging via
    /// `sizingOptions = .intrinsicContentSize` (iOS 16+).
    private var displayView: NativeDisplayUIView?

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

    /// Configure the cell with a `ResolvedConfig`. Use this overload for
    /// previews, test browsers, and any flow where you don't have a parsed
    /// `NativeDisplayUnit` — attribution events do NOT fire on this path.
    ///
    /// For bridge-delivered content, prefer `configure(with: unit, ...)`
    /// so `Notification Viewed` / `Notification Clicked` fire correctly.
    public func configure(
        with config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        if let displayView = displayView {
            displayView.updateConfig(
                config,
                actionListener: actionListener,
                componentListener: componentListener
            )
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
        notifyEnclosingTableViewOfHeightChange()
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
            displayView.updateUnit(
                unit,
                actionListener: actionListener,
                componentListener: componentListener
            )
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
        notifyEnclosingTableViewOfHeightChange()
    }

    // MARK: - Lifecycle

    public override func prepareForReuse() {
        super.prepareForReuse()
        // Keep `displayView` across reuse — the next `configure(...)` call
        // will swap its content via `updateConfig`/`updateUnit`, preserving
        // the SwiftUI hosting controller and its parent-VC relationship.
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
    /// Walks up to the enclosing `UIScrollView` (which `UITableView`
    /// subclasses) so the renderer's `nativeDisplayParentSize` environment
    /// is seeded with the real container width — without this, percent-
    /// width / aspect-ratio content locks in against the empty cell's
    /// near-zero bounds and renders permanently tiny.
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

    /// Force the enclosing `UITableView` to re-measure this cell's row.
    /// See `NativeDisplaySlotTableViewCell` for the full rationale — same
    /// two-stage recipe: synchronous `layoutIfNeeded` to drive SwiftUI's
    /// first layout pass, then async `beginUpdates`/`endUpdates` to re-
    /// query row heights once `intrinsicContentSize` is correct.
    private func notifyEnclosingTableViewOfHeightChange() {
        setNeedsLayout()
        layoutIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.invalidateIntrinsicContentSize()
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
}
