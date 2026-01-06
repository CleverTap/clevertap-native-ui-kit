//
//  InteractionType.swift
//  CleverTapNativeDisplay
//
//  Created by Lalitkumar Patil on 05/01/26.
//


// MARK: - Component Interaction Listener Protocol
// Client interface for observing/intercepting component interactions

import Foundation

/// Types of interactions that can occur on components.
public enum InteractionType {
    /// Single tap
    case click
    /// Long press and hold
    case longPress
    /// Double tap
    case doubleTap
}

/// Protocol for receiving component interaction callbacks.
/// This allows clients to observe or intercept user interactions with components,
/// regardless of whether the server has defined actions for them.
public protocol NativeDisplayComponentListener: AnyObject {
    
    /// Return the set of node IDs you want to receive callbacks for.
    /// - Returns:
    ///   - nil: Listen to ALL components (may have performance impact)
    ///   - empty set: Don't listen to any components
    ///   - specific IDs: Only listen to those components (recommended)
    func getInterestedNodeIds() -> Set<String>?
    
    /// Called when a user interacts with a component you're interested in.
    /// This is called BEFORE any server-defined action is executed.
    /// - Parameters:
    ///   - nodeId: The ID of the component that was interacted with
    ///   - interactionType: The type of interaction (click, longPress, doubleTap)
    ///   - hasServerAction: Whether the server defined an action for this interaction
    /// - Returns: true to consume the interaction (prevent server action from executing),
    ///            false to allow server action to proceed
    func onComponentInteraction(
        nodeId: String,
        interactionType: InteractionType,
        hasServerAction: Bool
    ) -> Bool
}

/// Default implementation for optional method
public extension NativeDisplayComponentListener {
    func getInterestedNodeIds() -> Set<String>? {
        return nil // Listen to all by default
    }
}
