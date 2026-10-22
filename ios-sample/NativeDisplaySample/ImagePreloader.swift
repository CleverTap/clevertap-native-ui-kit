import Foundation

/// Incremental, cross-run asset-URL manifest for screenshot automation.
///
/// The screenshot automation ("nd-screenshot-compare" skill) currently has to
/// run each capture TWICE — the first pass warms the image cache, the second is
/// kept. This manifest closes that gap on iOS, mirroring the Flutter sample's
/// `AssetManifestAutomation`:
///
///   * COLLECT — as live CleverTap display units arrive
///     (`CleverTapIntegrationViewModel.onNativeDisplaysLoaded`), we extract every
///     http(s) asset URL from each unit's `rawJson` and APPEND the new ones
///     (deduped, union across runs) to a manifest file in the app documents dir.
///   * WARM — `ImagePreloader` reads that manifest (plus the bundled TestConfigs)
///     and pre-fills `URLCache.shared` so the first screenshot pass paints warm.
///
/// "Incremental" = the manifest is a union across runs: we read what's already
/// there, add newly-seen URLs, and never drop previously-seen ones.
///
/// Location: `<AppDocuments>/nd-asset-urls.txt`, one URL per line. The host
/// collects it by pulling the file off the simulator; the absolute path is
/// printed to the log on every append. Gated behind the `PRELOAD_IMAGES=1`
/// launch environment flag — a no-op in normal runs.
enum AssetManifest {
    static let fileName = "nd-asset-urls.txt"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["PRELOAD_IMAGES"] == "1"
    }

    static var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    /// Reads the manifest file into an ordered, de-duplicated list of URL strings.
    static func read() -> [String] {
        guard let url = fileURL,
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        var seen = Set<String>()
        var result: [String] = []
        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty, seen.insert(trimmed).inserted {
                result.append(trimmed)
            }
        }
        return result
    }

    /// Extracts asset URLs from each unit's rawJson and appends the new ones to
    /// the manifest (union across runs). No-op unless `PRELOAD_IMAGES=1`.
    /// Call from `onNativeDisplaysLoaded`.
    static func record(rawJsons: [String]) {
        guard isEnabled, let url = fileURL else { return }

        var known = Set(read())
        let before = known.count
        var appended: [String] = []
        for json in rawJsons {
            for found in extractURLs(from: json) where known.insert(found).inserted {
                appended.append(found)
            }
        }
        guard !appended.isEmpty else { return }

        let block = appended.joined(separator: "\n") + "\n"
        if FileManager.default.fileExists(atPath: url.path),
           let handle = try? FileHandle(forWritingTo: url) {
            // Append-only: preserves previously-seen URLs across runs.
            handle.seekToEndOfFile()
            handle.write(Data(block.utf8))
            try? handle.close()
        } else {
            try? block.write(to: url, atomically: true, encoding: .utf8)
        }
        print("[AssetManifest] +\(appended.count) new asset URL(s) "
            + "(total \(before + appended.count)) -> \(url.path)")
    }

    /// Matches `"url": "https://..."` JSON string values and filters out template
    /// variables. Shared by the live-unit collector and the bundled-config scan.
    static func extractURLs(from json: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: #""url"\s*:\s*"(https?://[^"]+)""#
        ) else { return [] }

        let range = NSRange(json.startIndex..., in: json)
        var result: [String] = []
        for match in regex.matches(in: json, range: range) {
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: json) else { continue }
            let raw = String(json[r])
            if !raw.contains("{{") {
                result.append(raw)
            }
        }
        return result
    }
}

/// Pre-populates URLCache.shared with image URLs so that AsyncImage and GIFImage
/// render immediately during XCUITest screenshot runs.
///
/// URLs come from two sources, unioned:
///   1. the incremental `AssetManifest` (asset URLs seen in live display units on
///      previous/this run), and
///   2. the bundled TestConfigs/*.json files (static test fixtures).
///
/// Activated by the `PRELOAD_IMAGES=1` launch environment variable. Sets
/// `isComplete = true` (exposed via "images-preloaded" accessibility identifier)
/// when all parallel downloads finish.
@MainActor
final class ImagePreloader: ObservableObject {
    @Published var isComplete = false

    func preloadAll() async {
        let urls = collectImageURLs()
        guard !urls.isEmpty else {
            isComplete = true
            return
        }

        // Configure a generous URLCache (100 MB memory / 200 MB disk).
        let cache = URLCache(memoryCapacity: 100 * 1024 * 1024,
                            diskCapacity:   200 * 1024 * 1024)
        URLCache.shared = cache

        let session = URLSession.shared

        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    let request = URLRequest(url: url)
                    // Skip if already cached.
                    if session.configuration.urlCache?.cachedResponse(for: request) != nil {
                        return
                    }
                    guard let (data, response) = try? await session.data(from: url),
                          let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else { return }

                    let cached = CachedURLResponse(response: response,
                                                  data: data,
                                                  storagePolicy: .allowedInMemoryOnly)
                    session.configuration.urlCache?.storeCachedResponse(cached, for: request)
                }
            }
        }

        isComplete = true
    }

    // MARK: - Private

    /// Unions the incremental manifest URLs with the bundled TestConfigs/*.json
    /// URLs, de-duplicated. Skips video/GIF extensions (handled elsewhere) and
    /// template vars.
    private func collectImageURLs() -> [URL] {
        let videoExtensions: Set<String> = ["mp4", "m3u8", "webm", "mov"]
        let gifExtension = "gif"

        var seen = Set<String>()
        var result: [URL] = []

        func consider(_ raw: String) {
            guard !raw.contains("{{"), !seen.contains(raw) else { return }
            let ext = (raw as NSString).pathExtension.lowercased()
            guard !videoExtensions.contains(ext), ext != gifExtension else { return }
            if let url = URL(string: raw) {
                seen.insert(raw)
                result.append(url)
            }
        }

        // 1. Incremental manifest (asset URLs seen in live display units).
        for raw in AssetManifest.read() {
            consider(raw)
        }

        // 2. Bundled test fixtures.
        for raw in bundledConfigURLs() {
            consider(raw)
        }

        return result
    }

    /// Scans all bundled TestConfigs/*.json files and extracts raw URL strings.
    private func bundledConfigURLs() -> [String] {
        guard let configsURL = Bundle.main.url(forResource: "TestConfigs", withExtension: nil) else {
            return []
        }

        let jsonFiles: [URL]
        do {
            jsonFiles = try FileManager.default.contentsOfDirectory(
                at: configsURL,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
        } catch {
            return []
        }

        var result: [String] = []
        for file in jsonFiles {
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            result.append(contentsOf: AssetManifest.extractURLs(from: content))
        }
        return result
    }
}
