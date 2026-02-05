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
        
        // Apply gestures based on what's defined
        if onClick != nil && onLongPress == nil && onDoubleTap == nil {
            // Simple tap only - use exclusive gesture to block propagation
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                handleTap(action: onClick, interactionType: .click)
                            }
                    )
            )
        } else if onDoubleTap != nil && onClick == nil && onLongPress == nil {
            // Only double tap
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                handleTap(action: onDoubleTap, interactionType: .doubleTap)
                            }
                    )
            )
        } else if onLongPress != nil && onClick == nil && onDoubleTap == nil {
            // Only long press
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                handleTap(action: onLongPress, interactionType: .longPress)
                            }
                    )
            )
        } else if onClick != nil && onDoubleTap != nil && onLongPress == nil {
            // Single + Double tap
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                handleTap(action: onDoubleTap, interactionType: .doubleTap)
                            }
                    )
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                handleTap(action: onClick, interactionType: .click)
                            }
                    )
            )
        } else if onClick != nil && onLongPress != nil && onDoubleTap == nil {
            // Single + Long press
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                handleTap(action: onLongPress, interactionType: .longPress)
                            }
                    )
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                handleTap(action: onClick, interactionType: .click)
                            }
                    )
            )
        } else if componentListener != nil && onClick == nil && onLongPress == nil && onDoubleTap == nil {
            // Only component listener (no server actions)
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                handleTap(action: nil, interactionType: .click)
                            }
                    )
            )
        } else {
            // Multiple gestures
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                if let action = onDoubleTap {
                                    handleTap(action: action, interactionType: .doubleTap)
                                }
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                if let action = onLongPress {
                                    handleTap(action: action, interactionType: .longPress)
                                }
                            }
                    )
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                if let action = onClick {
                                    handleTap(action: action, interactionType: .click)
                                } else if componentListener != nil {
                                    handleTap(action: nil, interactionType: .click)
                                }
                            }
                    )
            )
        }
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
