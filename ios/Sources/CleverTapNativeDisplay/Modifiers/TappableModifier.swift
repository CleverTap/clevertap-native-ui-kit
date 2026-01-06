// MARK: - Tappable Modifier (WITH DEBUG LOGS)
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
        // 🔍 DEBUG: Log when modifier is created
        print("🔧 TappableModifier.body for nodeId: \(nodeId)")
        print("   - actions: \(actions != nil ? "exists (\(actions!.count) actions)" : "nil")")
        print("   - actionHandler: \(actionHandler != nil ? "exists" : "nil")")
        print("   - componentListener: \(componentListener != nil ? "exists" : "nil")")
        
        // Early exit if nothing to do
        guard actions != nil || componentListener != nil else {
            print("⚠️ SKIPPING tappable for \(nodeId) - no actions or listener")
            return AnyView(content)
        }
        
        let onClick = actions?[ActionTriggers.onClick]
        let onLongPress = actions?[ActionTriggers.onLongPress]
        let onDoubleTap = actions?[ActionTriggers.onDoubleTap]
        
        let hasClickActions = onClick != nil || onLongPress != nil || onDoubleTap != nil
        
        print("   - hasClickActions: \(hasClickActions)")
        print("   - onClick: \(onClick != nil ? "exists" : "nil")")
        print("   - onLongPress: \(onLongPress != nil ? "exists" : "nil")")
        print("   - onDoubleTap: \(onDoubleTap != nil ? "exists" : "nil")")
        
        // If no actions but component listener exists, still apply gestures
        guard hasClickActions || componentListener != nil else {
            print("⚠️ SKIPPING \(nodeId) - no click actions and no listener")
            return AnyView(content)
        }
        
        print("✅ APPLYING gesture to \(nodeId)")
        
        // Apply gestures based on what's defined
        if onClick != nil && onLongPress == nil && onDoubleTap == nil {
            // Simple tap only - use exclusive gesture to block propagation
            print("   - Using SIMPLE TAP gesture")
            return AnyView(
                content
                    .contentShape(Rectangle()) // Make entire area tappable
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                print("🎯 TAP DETECTED on \(nodeId)!")
                                handleTap(action: onClick, interactionType: .click)
                            }
                    )
            )
        } else if onDoubleTap != nil && onClick == nil && onLongPress == nil {
            // Only double tap
            print("   - Using DOUBLE TAP gesture only")
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                print("🎯 DOUBLE TAP DETECTED on \(nodeId)!")
                                handleTap(action: onDoubleTap, interactionType: .doubleTap)
                            }
                    )
            )
        } else if onLongPress != nil && onClick == nil && onDoubleTap == nil {
            // Only long press
            print("   - Using LONG PRESS gesture only")
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                print("🎯 LONG PRESS DETECTED on \(nodeId)!")
                                handleTap(action: onLongPress, interactionType: .longPress)
                            }
                    )
            )
        } else if onClick != nil && onDoubleTap != nil && onLongPress == nil {
            // Single + Double tap
            print("   - Using SINGLE + DOUBLE TAP gestures")
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                print("🎯 DOUBLE TAP DETECTED on \(nodeId)!")
                                handleTap(action: onDoubleTap, interactionType: .doubleTap)
                            }
                    )
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                print("🎯 TAP DETECTED on \(nodeId)!")
                                handleTap(action: onClick, interactionType: .click)
                            }
                    )
            )
        } else if onClick != nil && onLongPress != nil && onDoubleTap == nil {
            // Single + Long press
            print("   - Using SINGLE + LONG PRESS gestures")
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                print("🎯 LONG PRESS DETECTED on \(nodeId)!")
                                handleTap(action: onLongPress, interactionType: .longPress)
                            }
                    )
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                print("🎯 TAP DETECTED on \(nodeId)!")
                                handleTap(action: onClick, interactionType: .click)
                            }
                    )
            )
        } else if componentListener != nil && onClick == nil && onLongPress == nil && onDoubleTap == nil {
            // Only component listener (no server actions)
            print("   - Using TAP gesture for listener only")
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                print("🎯 TAP DETECTED on \(nodeId) (listener only)!")
                                handleTap(action: nil, interactionType: .click)
                            }
                    )
            )
        } else {
            // Multiple gestures - need to handle priority
            // Priority: Double Tap > Long Press > Single Tap
            print("   - Using ALL THREE gestures")
            return AnyView(
                content
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                print("🎯 DOUBLE TAP DETECTED on \(nodeId)!")
                                if let action = onDoubleTap {
                                    handleTap(action: action, interactionType: .doubleTap)
                                }
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                print("🎯 LONG PRESS DETECTED on \(nodeId)!")
                                if let action = onLongPress {
                                    handleTap(action: action, interactionType: .longPress)
                                }
                            }
                    )
                    .gesture(
                        TapGesture()
                            .onEnded { _ in
                                print("🎯 TAP DETECTED on \(nodeId)!")
                                if let action = onClick {
                                    handleTap(action: action, interactionType: .click)
                                } else if componentListener != nil {
                                    // No action but listener wants to know
                                    handleTap(action: nil, interactionType: .click)
                                }
                            }
                    )
            )
        }
    }
    
    /// Handle tap gesture with component listener and action execution
    private func handleTap(action: Action?, interactionType: InteractionType) {
        print("🔥 handleTap called for nodeId: \(nodeId)")
        print("   - interactionType: \(interactionType)")
        print("   - hasAction: \(action != nil)")
        
        // 1. Notify component listener first (if interested in this node)
        let shouldProceed = notifyComponentListener(
            interactionType: interactionType,
            hasServerAction: action != nil
        )
        
        print("   - shouldProceed: \(shouldProceed)")
        
        // 2. If component listener consumed it, stop here
        guard shouldProceed else {
            print("   - ❌ CONSUMED by listener, stopping")
            return
        }
        
        // 3. Execute server action if exists
        if let action = action {
            print("   - ✅ Executing server action")
            actionHandler?.handleAction(action, nodeId: nodeId, interactionType: interactionType)
        } else {
            print("   - ⚪ No server action to execute")
        }
    }
    
    /// Notify component listener about an interaction
    /// - Returns: true if should proceed with server action, false if consumed by listener
    private func notifyComponentListener(
        interactionType: InteractionType,
        hasServerAction: Bool
    ) -> Bool {
        print("📞 notifyComponentListener for nodeId: \(nodeId)")
        print("   - interactionType: \(interactionType)")
        print("   - hasServerAction: \(hasServerAction)")
        
        guard let listener = componentListener else {
            print("   - ⚪ No listener, proceeding with action")
            return true // No listener, proceed with server action
        }
        
        print("   - ✅ Listener exists, checking interest")
        
        // Check if listener is interested in this node
        let interestedNodeIds = listener.getInterestedNodeIds()
        print("   - interestedNodeIds: \(interestedNodeIds == nil ? "nil (all)" : String(describing: interestedNodeIds))")
        
        let isInterested = interestedNodeIds == nil || interestedNodeIds?.contains(nodeId) == true
        print("   - isInterested: \(isInterested)")
        
        guard isInterested else {
            print("   - ⚪ Not interested in this node, proceeding")
            return true // Not interested, proceed with server action
        }
        
        print("   - 📲 Calling listener.onComponentInteraction...")
        
        // Call listener and check if it consumed the interaction
        let consumed = listener.onComponentInteraction(
            nodeId: nodeId,
            interactionType: interactionType,
            hasServerAction: hasServerAction
        )
        
        print("   - consumed: \(consumed)")
        
        if consumed {
            print("   - ❌ Listener consumed the event")
        } else {
            print("   - ✅ Listener did not consume, proceeding")
        }
        
        return !consumed // Return true if NOT consumed (should proceed)
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
        print("🔌 applyTappable extension called for nodeId: \(nodeId)")
        return self.modifier(TappableModifier(
            nodeId: nodeId,
            actions: actions,
            actionHandler: actionHandler,
            componentListener: componentListener
        ))
    }
}
