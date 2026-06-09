//
//  NDLogger.swift
//  CleverTapNativeDisplay
//

// MARK: - Native Display Logger
// Structured logger for the Native Display SDK.
// Defaults to .info. Clients configure via NativeDisplayBridge.setLogLevel(_:).

import Foundation

/// Log level for the Native Display SDK, matching CleverTap Core SDK conventions.
///
/// Mirrors `CleverTap.setDebugLevel(Int32)` raw values:
/// - `-1` OFF, `0` INFO, `2` DEBUG, `3` VERBOSE
///
/// Aliased publicly as `CTNDLogLevel` — use `NativeDisplayBridge.setLogLevel(_:)` to configure.
public enum NDLogLevel: Int, Comparable {
    case off = -1
    case info = 0
    case debug = 2
    case verbose = 3

    public static func < (lhs: NDLogLevel, rhs: NDLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

internal enum NDLogger {

    // MARK: - State

    private static var _level: NDLogLevel = .info

    /// Whether the level has been explicitly set by the client or by Core SDK sync.
    /// When `false`, Core SDK sync may update `_level` on first auto-wire.
    private static var explicitlySet = false

    // MARK: - Configuration

    static func setLevel(_ level: NDLogLevel) {
        _level = level
        explicitlySet = true
    }

    static func currentLevel() -> NDLogLevel { _level }

    static func isExplicitlySet() -> Bool { explicitlySet }

    // MARK: - Logging

    /// Verbose — fine-grained diagnostic detail. Shown at `.verbose` only.
    static func v(_ tag: String, _ message: String) {
        guard _level >= .verbose else { return }
        print("[\(tag)] \(message)")
    }

    /// Debug — standard development output. Shown at `.debug` and above.
    static func d(_ tag: String, _ message: String) {
        guard _level >= .debug else { return }
        print("[\(tag)] \(message)")
    }

    /// Info — notable lifecycle milestones. Shown at `.info` and above.
    static func i(_ tag: String, _ message: String) {
        guard _level >= .info else { return }
        print("[\(tag)] \(message)")
    }

    /// Warning — recoverable issues. Always shown at `.info` and above.
    static func w(_ tag: String, _ message: String) {
        guard _level >= .info else { return }
        print("[WARN][\(tag)] \(message)")
    }

    /// Error — non-recoverable failures. Always shown at `.info` and above.
    static func e(_ tag: String, _ message: String) {
        guard _level >= .info else { return }
        print("[ERROR][\(tag)] \(message)")
    }
}
