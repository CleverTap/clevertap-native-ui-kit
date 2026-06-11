//
//  NDLogger.swift
//  CleverTapNativeDisplay
//

// MARK: - Native Display Logger
// Structured logger for the Native Display SDK.
// Defaults to .info. Clients configure via NativeDisplayBridge.setLogLevel(_:).

import Foundation
import os.log

/// Log level for the Native Display SDK, matching CleverTap Core SDK conventions.
///
/// Mirrors `CleverTap.setDebugLevel(Int32)` raw values:
/// - `-1` OFF, `0` INFO, `2` DEBUG, `3` VERBOSE
///
/// Aliased publicly as `CTNDLogLevel` — use `NativeDisplayBridge.setLogLevel(_:)` to configure.
@objc public enum NDLogLevel: Int {
    case off = -1
    case info = 0
    case debug = 1
    case verbose = 2
}

extension NDLogLevel: Comparable {
    public static func < (lhs: NDLogLevel, rhs: NDLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

internal enum NDLogger {

    // MARK: - State

    private static let tag = "[CleverTap]: [NativeDisplay]"
    private static let osLog = OSLog(subsystem: "com.clevertap.NativeDisplay", category: "SDK")
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
    static func v(_ caller: Any, _ message: String) {
        guard _level >= .verbose else { return }
        os_log("%{public}@: %{public}@: %{public}@", log: osLog, type: .debug, tag, className(caller), message)
    }

    /// Debug — standard development output. Shown at `.debug` and above.
    static func d(_ caller: Any, _ message: String) {
        guard _level >= .debug else { return }
        os_log("%{public}@: %{public}@: %{public}@", log: osLog, type: .debug, tag, className(caller), message)
    }

    /// Info — notable lifecycle milestones. Shown at `.info` and above.
    static func i(_ caller: Any, _ message: String) {
        guard _level >= .info else { return }
        os_log("%{public}@: %{public}@: %{public}@", log: osLog, type: .info, tag, className(caller), message)
    }

    /// Warning — recoverable issues. Always shown at `.info` and above.
    static func w(_ caller: Any, _ message: String) {
        guard _level >= .info else { return }
        os_log("%{public}@: %{public}@: [WARN] %{public}@", log: osLog, type: .default, tag, className(caller), message)
    }

    /// Error — non-recoverable failures. Always shown at `.info` and above.
    static func e(_ caller: Any, _ message: String) {
        guard _level >= .info else { return }
        os_log("%{public}@: %{public}@: [ERROR] %{public}@", log: osLog, type: .error, tag, className(caller), message)
    }

    // MARK: - Helpers

    /// Extracts a bare type name from an instance (`self`), a metatype (`Self.self`), or a plain String.
    private static func className(_ caller: Any) -> String {
        if let name = caller as? String { return name }
        if let type_ = caller as? Any.Type { return String(describing: type_) }
        return String(describing: type(of: caller))
    }
}
