import XCTest
@testable import CleverTapNativeDisplay

/// Performance measurement tests for the Native Display SDK.
///
/// Measures wall-clock time, memory, and CPU for critical SDK operations
/// at controlled complexity levels. No baselines or thresholds — measurement only.
///
/// NOTE: JSON parsing is measured here for regression tracking, but in production
/// this SDK receives pre-parsed ResolvedConfig objects. The calling SDK is
/// responsible for parsing JSON on a background thread before passing the
/// resolved config to NativeDisplayView.
///
/// Run with: `swift test --filter PerformanceTests`
/// View detailed metrics in Xcode Test Report.
final class PerformanceTests: XCTestCase {

    // MARK: - Helpers

    /// Load benchmark JSON data from the BenchmarkConfigs bundle resource.
    /// Supports both SPM (Bundle.module) and xcodeproj (Bundle(for:)) resource loading.
    private func loadBenchmarkData(_ filename: String) throws -> Data {
        // Try SPM's Bundle.module first (available when built via swift build/test)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(
            forResource: filename,
            withExtension: "json",
            subdirectory: "BenchmarkConfigs"
        ) {
            return try Data(contentsOf: url)
        }
        #endif

        // Fallback for xcodeproj builds: look in the test bundle
        let testBundle = Bundle(for: type(of: self))
        if let url = testBundle.url(
            forResource: filename,
            withExtension: "json",
            subdirectory: "BenchmarkConfigs"
        ) {
            return try Data(contentsOf: url)
        }

        // Also try without subdirectory (flat resource copy)
        if let url = testBundle.url(forResource: filename, withExtension: "json") {
            return try Data(contentsOf: url)
        }

        throw NSError(
            domain: "PerformanceTests",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Missing benchmark config: \(filename).json in bundle: \(testBundle.bundlePath)"]
        )
    }

    /// Standard metrics for all performance measurements.
    private var standardMetrics: [XCTMetric] {
        [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()]
    }

    // MARK: - JSON Parsing Performance

    func testJSONParsing_Minimal() throws {
        let data = try loadBenchmarkData("benchmark_minimal")
        measure(metrics: standardMetrics) {
            _ = try? ResolvedConfig.from(jsonData: data)
        }
    }

    func testJSONParsing_Simple() throws {
        let data = try loadBenchmarkData("benchmark_simple")
        measure(metrics: standardMetrics) {
            _ = try? ResolvedConfig.from(jsonData: data)
        }
    }

    func testJSONParsing_Medium() throws {
        let data = try loadBenchmarkData("benchmark_medium")
        measure(metrics: standardMetrics) {
            _ = try? ResolvedConfig.from(jsonData: data)
        }
    }

    func testJSONParsing_Gallery() throws {
        let data = try loadBenchmarkData("benchmark_gallery")
        measure(metrics: standardMetrics) {
            _ = try? ResolvedConfig.from(jsonData: data)
        }
    }

    func testJSONParsing_Stress() throws {
        let data = try loadBenchmarkData("benchmark_stress")
        measure(metrics: standardMetrics) {
            _ = try? ResolvedConfig.from(jsonData: data)
        }
    }

    func testJSONParsing_Extreme() throws {
        let data = try loadBenchmarkData("benchmark_extreme")
        measure(metrics: standardMetrics) {
            _ = try? ResolvedConfig.from(jsonData: data)
        }
    }

    // MARK: - Style Resolution Performance

    func testStyleResolution_Minimal() throws {
        let data = try loadBenchmarkData("benchmark_minimal")
        let config = try ResolvedConfig.from(jsonData: data)
        let resolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)

        measure(metrics: standardMetrics) {
            _ = resolver.resolveAll(node: config.root)
        }
    }

    func testStyleResolution_Stress() throws {
        let data = try loadBenchmarkData("benchmark_stress")
        let config = try ResolvedConfig.from(jsonData: data)
        let resolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)

        measure(metrics: standardMetrics) {
            _ = resolver.resolveAll(node: config.root)
        }
    }

    func testStyleResolution_Extreme() throws {
        let data = try loadBenchmarkData("benchmark_extreme")
        let config = try ResolvedConfig.from(jsonData: data)
        let resolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)

        measure(metrics: standardMetrics) {
            _ = resolver.resolveAll(node: config.root)
        }
    }

    // MARK: - Variable Evaluation Performance

    func testVariableEvaluation_Stress() throws {
        let data = try loadBenchmarkData("benchmark_stress")
        let config = try ResolvedConfig.from(jsonData: data)
        let evaluator = VariableEvaluator(variables: config.variables)

        // Collect all template strings from the config tree
        let templates = collectTemplateStrings(from: config.root)
        XCTAssertFalse(templates.isEmpty, "Stress config should contain template strings")

        measure(metrics: standardMetrics) {
            for template in templates {
                _ = evaluator.evaluateString(template)
            }
        }
    }

    // MARK: - Full Pipeline Performance

    func testFullPipeline_Minimal() throws {
        let data = try loadBenchmarkData("benchmark_minimal")

        measure(metrics: standardMetrics) {
            guard let config = try? ResolvedConfig.from(jsonData: data) else { return }
            _ = NativeDisplayView(config: config)
        }
    }

    func testFullPipeline_Stress() throws {
        let data = try loadBenchmarkData("benchmark_stress")

        measure(metrics: standardMetrics) {
            guard let config = try? ResolvedConfig.from(jsonData: data) else { return }
            _ = NativeDisplayView(config: config)
        }
    }

    func testFullPipeline_Extreme() throws {
        let data = try loadBenchmarkData("benchmark_extreme")

        measure(metrics: standardMetrics) {
            guard let config = try? ResolvedConfig.from(jsonData: data) else { return }
            _ = NativeDisplayView(config: config)
        }
    }

    // MARK: - Template String Collection

    /// Recursively collect all binding values that contain {{template}} expressions.
    private func collectTemplateStrings(from node: NativeDisplayNode) -> [String] {
        var templates = [String]()

        switch node {
        case .element(let element):
            for (_, value) in element.bindings {
                if value.contains("{{") {
                    templates.append(value)
                }
            }
        case .container(let container):
            for child in container.children {
                templates.append(contentsOf: collectTemplateStrings(from: child))
            }
        }

        return templates
    }
}
