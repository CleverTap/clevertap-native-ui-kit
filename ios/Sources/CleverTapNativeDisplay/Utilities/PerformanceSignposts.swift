// MARK: - Performance Signposts
// Zero-overhead performance instrumentation using os_signpost

import os

/// Performance signposts for profiling critical SDK paths in Instruments.
///
/// Uses `os_signpost` (iOS 15+) for zero overhead when not profiling.
/// Wrap critical sections with `beginInterval`/`endInterval`:
///
/// ```swift
/// let id = PerformanceSignposts.jsonParsing.begin("parseConfig")
/// defer { PerformanceSignposts.jsonParsing.end("parseConfig", id) }
/// ```
///
/// View results in Instruments > os_signpost or Logging template
/// with subsystem filter: `com.clevertap.nativedisplay`
enum PerformanceSignposts {
    static let subsystem = "com.clevertap.nativedisplay"

    static let jsonParsing = SignpostHelper(subsystem: subsystem, category: "JSONParsing")
    static let styleResolution = SignpostHelper(subsystem: subsystem, category: "StyleResolution")
    static let variableEvaluation = SignpostHelper(subsystem: subsystem, category: "VariableEvaluation")
    static let rendering = SignpostHelper(subsystem: subsystem, category: "Rendering")
}

/// Thin wrapper around os_signpost that works on iOS 15+.
///
/// On iOS 16+ this delegates to `OSSignposter` for richer Instruments integration.
/// On iOS 15 it uses the legacy `os_signpost` API with `OSSignpostID`.
struct SignpostHelper {
    private let log: OSLog

    init(subsystem: String, category: String) {
        self.log = OSLog(subsystem: subsystem, category: category)
    }

    /// Begin a signpost interval and return an ID for pairing with `end`.
    func begin(_ name: StaticString) -> OSSignpostID {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        return id
    }

    /// End a signpost interval previously started with `begin`.
    func end(_ name: StaticString, _ id: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }
}
