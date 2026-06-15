//
//  NativeDisplaySlot.swift
//  CleverTapNativeDisplay
//
//  SwiftUI view that automatically renders content for a named slot.
//

import SwiftUI

// MARK: - Slot View Model

/// Internal view model that observes a slot and publishes unit changes.
@available(iOS 15.0, *)
internal class SlotViewModel: ObservableObject, NativeDisplaySlotObserver {
    @Published var unit: NativeDisplayUnit?

    let slotId: String

    init(slotId: String) {
        self.slotId = slotId
        NativeDisplaySlotManager.shared.registerSlot(slotId, observer: self)
    }

    deinit {
        NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer: self)
    }

    // MARK: - NativeDisplaySlotObserver

    func onUnitAvailable(_ unit: NativeDisplayUnit) {
        NDLogger.d(Self.self, "Slot '\(slotId)': unit '\(unit.unitId)' available — updating view")
        DispatchQueue.main.async { [weak self] in
            self?.unit = unit
        }
    }

    func onUnitCleared(slotId: String) {
        NDLogger.d(Self.self, "Slot '\(slotId)' cleared — removing rendered view")
        DispatchQueue.main.async { [weak self] in
            self?.unit = nil
        }
    }
}

// MARK: - Slot View

/// A SwiftUI view that automatically renders the display unit assigned to a named slot.
///
/// `NativeDisplaySlot` registers with `NativeDisplaySlotManager` for the given `slotId`
/// and renders the unit's configuration when available. While no unit is assigned, it
/// displays the `loading` view (defaults to `EmptyView`).
///
/// ## Usage
///
/// ```swift
/// // Basic — renders content or nothing
/// NativeDisplaySlot(slotId: "hero_banner")
///
/// // With loading placeholder
/// NativeDisplaySlot(slotId: "hero_banner") {
///     ProgressView()
/// }
///
/// // With listeners
/// NativeDisplaySlot(
///     slotId: "hero_banner",
///     actionListener: myActionListener,
///     componentListener: myComponentListener
/// ) {
///     Text("Loading...")
/// }
/// ```
@available(iOS 15.0, *)
public struct NativeDisplaySlot<Loading: View>: View {

    let slotId: String
    let actionListener: NativeDisplayActionListener?
    let componentListener: NativeDisplayComponentListener?
    let loading: () -> Loading

    @StateObject private var viewModel: SlotViewModel

    /// Create a slot view for the given slot identifier.
    ///
    /// - Parameters:
    ///   - slotId: The slot identifier to observe.
    ///   - actionListener: Optional listener for action events (e.g., URL opens).
    ///   - componentListener: Optional listener for component interaction events.
    ///   - loading: A view builder for the placeholder shown while no unit is available.
    public init(
        slotId: String,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil,
        @ViewBuilder loading: @escaping () -> Loading = { EmptyView() }
    ) {
        self.slotId = slotId
        self.actionListener = actionListener
        self.componentListener = componentListener
        self.loading = loading
        self._viewModel = StateObject(wrappedValue: SlotViewModel(slotId: slotId))
    }

    public var body: some View {
        if let unit = viewModel.unit {
            // Routes through the unit-aware initializer so the bridge's
            // pre-resolved style map (computed off-main) is reused — avoids
            // a redundant `StyleResolver.resolveAll` walk on the main thread.
            NativeDisplayView(
                unit: unit,
                actionListener: actionListener,
                componentListener: componentListener
            )
        } else {
            loading()
        }
    }
}
