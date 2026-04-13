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
@objc public protocol NativeDisplayActionListener: AnyObject {

    /// Called when an OPEN_URL action is triggered.
    /// - Parameters:
    ///   - url: The URL to open
    ///   - openInBrowser: Whether to open in external browser
    /// - Returns: true if the client handled the action, false to use default behavior
    @objc @discardableResult func onOpenUrl(url: String, openInBrowser: Bool) -> Bool

    /// Called when a CUSTOM action is triggered.
    /// This is the most flexible action type - the client defines what happens.
    /// - Parameters:
    ///   - key: The action identifier (e.g., "add_to_cart", "share", "like")
    ///   - value: The action data (can be any type)
    ///   - metadata: Optional additional metadata about the action
    @objc func onCustomAction(key: String, value: Any?, metadata: [String: String]?)

    /// Called when a NAVIGATE action is triggered.
    /// - Parameters:
    ///   - destination: The navigation destination identifier
    ///   - params: Optional navigation parameters
    @objc func onNavigate(destination: String, params: [String: String]?)

    /// Called when an EVENT action is triggered.
    /// Used for analytics tracking.
    /// - Parameters:
    ///   - eventName: The name of the event to track
    ///   - properties: Optional event properties
    @objc func onTrackEvent(eventName: String, properties: [String: Any]?)

    /// Called when a display unit is viewed (Notification Viewed system event).
    /// Use this to call `pushDisplayUnitViewedEventForID` on the CleverTap Core SDK.
    /// - Parameter unitId: The `wzrk_id` of the display unit that was viewed.
    @objc optional func onDisplayUnitViewed(unitId: String)

    /// Called when a display unit is clicked (Notification Clicked system event).
    /// Use this to call `pushDisplayUnitClickedEventForID` on the CleverTap Core SDK.
    /// - Parameter unitId: The `wzrk_id` of the display unit that was clicked.
    @objc optional func onDisplayUnitClicked(unitId: String)
}

/// Default implementations for optional methods.
/// `onActionError` is defined here (not in the protocol) because `Action` is a Swift enum
/// that cannot be represented in Objective-C. Override in your conforming type to handle errors.
public extension NativeDisplayActionListener {
    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        return false // Use default behavior
    }

    func onActionError(action: Action, error: Error) {
        // Default: do nothing — override to log errors
    }
}
