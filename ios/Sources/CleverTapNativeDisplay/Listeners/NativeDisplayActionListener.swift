//
//  NativeDisplayActionListener.swift
//  CleverTapNativeDisplay
//
//  Created by Lalitkumar Patil on 05/01/26.
//


// MARK: - Action Listener Protocol
// Client interface for handling server-defined actions

import Foundation

/// Protocol for handling actions triggered by Native Display components.
/// Clients implement this to respond to server-defined actions.
public protocol NativeDisplayActionListener: AnyObject {
    
    /// Called when an OPEN_URL action is triggered.
    /// - Parameters:
    ///   - url: The URL to open
    ///   - openInBrowser: Whether to open in external browser
    /// - Returns: true if the client handled the action, false to use default behavior
    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool
    
    /// Called when a CUSTOM action is triggered.
    /// This is the most flexible action type - the client defines what happens.
    /// - Parameters:
    ///   - key: The action identifier (e.g., "add_to_cart", "share", "like")
    ///   - value: The action data (can be any type)
    ///   - metadata: Optional additional metadata about the action
    func onCustomAction(key: String, value: Any?, metadata: [String: String]?)
    
    /// Called when a NAVIGATE action is triggered.
    /// - Parameters:
    ///   - destination: The navigation destination identifier
    ///   - params: Optional navigation parameters
    func onNavigate(destination: String, params: [String: String]?)
    
    /// Called when an EVENT action is triggered.
    /// Used for analytics tracking.
    /// - Parameters:
    ///   - eventName: The name of the event to track
    ///   - properties: Optional event properties
    func onTrackEvent(eventName: String, properties: [String: Any]?)
    
    /// Called when any action execution fails.
    /// Override this to handle errors gracefully.
    /// - Parameters:
    ///   - action: The action that failed
    ///   - error: The error that occurred
    func onActionError(action: Action, error: Error)
}

/// Default implementations for optional methods
public extension NativeDisplayActionListener {
    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        return false // Use default behavior
    }
    
    func onActionError(action: Action, error: Error) {
        // Default: do nothing (client can override to log or show error)
        print("Action error: \(error.localizedDescription)")
    }
}
