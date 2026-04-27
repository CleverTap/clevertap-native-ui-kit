import Foundation
import CleverTapNativeDisplay

/// Utility for loading JSON configuration files from the app bundle
struct JsonLoader {

    /// Load a test configuration from the TestConfigs subfolder.
    ///
    /// Tries the following locations in order:
    ///   1. `TestConfigs/<filename>.json` — the standard bundle folder group
    ///   2. Bundle root `<filename>.json` — fallback for files added at the top level
    ///
    /// - Parameter filename: The name of the JSON file (without .json extension)
    /// - Returns: A resolved configuration if successful, nil otherwise
    static func loadTestConfig(filename: String) -> ResolvedConfig? {
        let pathsToTry: [(path: String?, label: String)] = [
            (Bundle.main.path(forResource: filename, ofType: "json", inDirectory: "TestConfigs"), "TestConfigs/"),
            (Bundle.main.path(forResource: filename, ofType: "json"), "bundle root")
        ]

        for (path, label) in pathsToTry {
            guard let validPath = path else { continue }
            print("✅ JsonLoader: Found \(filename).json in \(label)")
            do {
                let url = URL(fileURLWithPath: validPath)
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(ResolvedConfig.self, from: data)
                print("✅ JsonLoader: Successfully loaded \(filename).json")
                return config
            } catch let decodingError as DecodingError {
                print("❌ JsonLoader: Failed to decode \(filename).json")
                print("   Error: \(decodingError)")
                return nil
            } catch {
                print("❌ JsonLoader: Failed to load \(filename).json - \(error)")
                return nil
            }
        }

        print("❌ JsonLoader: Could not find \(filename).json — tried TestConfigs/ and bundle root")
        return nil
    }

    /// Load a configuration from any subfolder.
    ///
    /// Tries the specified directory first, then falls back to the bundle root.
    ///
    /// - Parameters:
    ///   - filename: The name of the JSON file (without .json extension)
    ///   - directory: The subdirectory within the bundle (nil = bundle root only)
    /// - Returns: A resolved configuration if successful, nil otherwise
    static func loadConfig(filename: String, fromDirectory directory: String? = nil) -> ResolvedConfig? {
        var pathsToTry: [(path: String?, label: String)] = []

        if let dir = directory {
            pathsToTry.append((Bundle.main.path(forResource: filename, ofType: "json", inDirectory: dir), dir))
            pathsToTry.append((Bundle.main.path(forResource: filename, ofType: "json", inDirectory: "Resources/\(dir)"), "Resources/\(dir)"))
        }
        pathsToTry.append((Bundle.main.path(forResource: filename, ofType: "json"), "bundle root"))

        for (path, label) in pathsToTry {
            guard let validPath = path else { continue }
            print("✅ JsonLoader: Found \(filename).json in \(label)")
            do {
                let url = URL(fileURLWithPath: validPath)
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(ResolvedConfig.self, from: data)
                print("✅ JsonLoader: Successfully loaded \(filename).json")
                return config
            } catch {
                print("❌ JsonLoader: Failed to decode \(filename).json - \(error)")
                return nil
            }
        }

        let dirName = directory ?? "root"
        print("❌ JsonLoader: Could not find \(filename).json — tried \(dirName), Resources/\(dirName), bundle root")
        return nil
    }
}
