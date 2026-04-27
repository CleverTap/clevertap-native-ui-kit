//
//  NativeDisplayBridgeListener.swift
//  CleverTapNativeDisplay
//

// MARK: - Bridge Listener Protocol
// Client interface for receiving native display unit updates from the bridge

import Foundation

/// Protocol for receiving native display units from the bridge.
/// Clients implement this to be notified when new display units are available,
/// whether from CleverTap Core SDK auto-wire or manual JSON input.
public protocol NativeDisplayBridgeListener: AnyObject {
    /// Called when native display units are loaded or updated.
    /// - Parameter units: The array of parsed native display units.
    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit])
}
