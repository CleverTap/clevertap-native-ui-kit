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

    private static let lock = NSLock()
    private static var _level: NDLogLevel = .info
    private static var explicitlySet = false

    // MARK: - Configuration

    /// Set the log level explicitly. Marks as explicitly set so Core SDK auto-sync
    /// will no longer override it.
    static func setLevel(_ level: NDLogLevel) {
        lock.lock()
        defer { lock.unlock() }
        _level = level
        explicitlySet = true
    }

    /// Sync from Core SDK debug level without marking as explicitly set.
    /// Allows future Core SDK syncs unless the client calls setLevel explicitly.
    static func syncFromCoreSdk(_ level: NDLogLevel) {
        lock.lock()
        defer { lock.unlock() }
        guard !explicitlySet else { return }
        _level = level
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
