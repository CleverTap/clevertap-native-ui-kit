import Foundation

/// Pre-populates URLCache.shared with all image URLs found in TestConfigs/*.json
/// so that AsyncImage and GIFImage render immediately during XCUITest screenshot runs.
///
/// Activated by the `PRELOAD_IMAGES=1` launch environment variable.
/// Sets `isComplete = true` (exposed via "images-preloaded" accessibility identifier)
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

    /// Scans all bundled TestConfigs/*.json files and extracts image URLs.
    /// Skips video extensions, GIF files (handled separately by GIFImage), and template vars.
    private func collectImageURLs() -> [URL] {
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

        // Match "url": "https://..." values (double-quoted JSON strings).
        let urlPattern = try? NSRegularExpression(
            pattern: #""url"\s*:\s*"(https?://[^"]+)""#,
            options: []
        )

        let videoExtensions: Set<String> = ["mp4", "m3u8", "webm", "mov"]
        let gifExtension = "gif"

        var seen = Set<String>()
        var result: [URL] = []

        for file in jsonFiles {
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let range = NSRange(content.startIndex..., in: content)
            let matches = urlPattern?.matches(in: content, options: [], range: range) ?? []

            for match in matches {
                guard match.numberOfRanges > 1,
                      let captureRange = Range(match.range(at: 1), in: content) else { continue }
                let raw = String(content[captureRange])

                // Skip template variables and already-seen URLs.
                guard !raw.contains("{{"), !seen.contains(raw) else { continue }

                let ext = (raw as NSString).pathExtension.lowercased()
                guard !videoExtensions.contains(ext), ext != gifExtension else { continue }

                if let url = URL(string: raw) {
                    seen.insert(raw)
                    result.append(url)
                }
            }
        }

        return result
    }
}
