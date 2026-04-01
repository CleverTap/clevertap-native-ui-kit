// MARK: - Tappable Modifier
// ViewModifier for handling tap gestures with actions

import SwiftUI

/// ViewModifier that applies tap, long press, and double tap gestures to views.
/// Uses exclusive gestures to prevent event propagation to parent views (matches Android behavior).
struct TappableModifier: ViewModifier {
    let nodeId: String
    let actions: [String: Action]?
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?
    
    func body(content: Content) -> some View {
        // Early exit if nothing to do
        guard actions != nil || componentListener != nil else {
            return AnyView(content)
        }
        
        let onClick = actions?[ActionTriggers.onClick]
        let onLongPress = actions?[ActionTriggers.onLongPress]
        let onDoubleTap = actions?[ActionTriggers.onDoubleTap]
        
        let hasClickActions = onClick != nil || onLongPress != nil || onDoubleTap != nil
        
        // If no actions but component listener exists, still apply gestures
        guard hasClickActions || componentListener != nil else {
            return AnyView(content)
        }
        
        let base = content.contentShape(Rectangle())
        
        if let longPress = onLongPress {
            if onClick != nil || componentListener != nil {
                return AnyView(
                    base
                        .onLongPressGesture(minimumDuration: 0.5) {
                            handleTap(action: longPress, interactionType: .longPress)
                        }
                        .ifLet(onDoubleTap) { v, action in
                            v.onTapGesture(count: 2) {
                                handleTap(action: action, interactionType: .doubleTap)
                            }
                        }
                        .onTapGesture {
                            handleTap(action: onClick, interactionType: .click)
                        }
                )
            } else {
                return AnyView(
                    base
                        .onLongPressGesture(minimumDuration: 0.5) {
                            handleTap(action: longPress, interactionType: .longPress)
                        }
                        .ifLet(onDoubleTap) { v, action in
                            v.onTapGesture(count: 2) {
                                handleTap(action: action, interactionType: .doubleTap)
                            }
                        }
                )
            }
        }
        
        // No long press — tap and/or double tap
        return AnyView(
            base
                .ifLet(onDoubleTap) { v, action in
                    v.onTapGesture(count: 2) {
                        handleTap(action: action, interactionType: .doubleTap)
                    }
                }
                .gesture(
                    TapGesture().onEnded { _ in
                        handleTap(action: onClick, interactionType: .click)
                    }
                )
        )
    }
    
    /// Handle tap gesture with component listener and action execution
    private func handleTap(action: Action?, interactionType: InteractionType) {
        let shouldProceed = notifyComponentListener(
            interactionType: interactionType,
            hasServerAction: action != nil
        )

        guard shouldProceed else {
            return
        }

        if let action = action {
            actionHandler?.handleAction(action, nodeId: nodeId, interactionType: interactionType)
        }
    }

    /// Notify component listener about an interaction
    /// - Returns: true if should proceed with server action, false if consumed by listener
    private func notifyComponentListener(
        interactionType: InteractionType,
        hasServerAction: Bool
    ) -> Bool {
        guard let listener = componentListener else {
            return true
        }

        let interestedNodeIds = listener.getInterestedNodeIds()
        let isInterested = interestedNodeIds == nil || interestedNodeIds?.contains(nodeId) == true

        guard isInterested else {
            return true
        }

        let consumed = listener.onComponentInteraction(
            nodeId: nodeId,
            interactionType: interactionType,
            hasServerAction: hasServerAction
        )

        return !consumed
    }
}
/// Conditionally applies a modifier only when an optional value is present.
extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, @ViewBuilder transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

/// View extension to easily apply tappable modifier
extension View {
    func applyTappable(
        nodeId: String,
        actions: [String: Action]?,
        actionHandler: ActionHandler?,
        componentListener: NativeDisplayComponentListener?
    ) -> some View {
        self.modifier(TappableModifier(
            nodeId: nodeId,
            actions: actions,
            actionHandler: actionHandler,
            componentListener: componentListener
        ))
    }
}
