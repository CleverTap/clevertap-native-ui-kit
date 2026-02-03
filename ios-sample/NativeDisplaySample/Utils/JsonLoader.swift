import Foundation
import CleverTapNativeDisplay

/// Utility for loading JSON configuration files from the app bundle
struct JsonLoader {

    /// Load a test configuration from the TestConfigs subfolder
    /// - Parameter filename: The name of the JSON file (without .json extension)
    /// - Returns: A resolved configuration if successful, nil otherwise
    static func loadTestConfig(filename: String) -> ResolvedConfig? {
        guard let path = Bundle.main.path(
            forResource: filename,
            ofType: "json",
            inDirectory: "TestConfigs"
        ) else {
            print("❌ JsonLoader: Could not find \(filename).json in TestConfigs folder")
            return nil
        }

        do {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(ResolvedConfig.self, from: data)
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

    /// Load a configuration from any subfolder
    /// - Parameters:
    ///   - filename: The name of the JSON file (without .json extension)
    ///   - directory: The subdirectory within the bundle
    /// - Returns: A resolved configuration if successful, nil otherwise
    static func loadConfig(filename: String, fromDirectory directory: String? = nil) -> ResolvedConfig? {
        guard let path = Bundle.main.path(
            forResource: filename,
            ofType: "json",
            inDirectory: directory
        ) else {
            let dirName = directory ?? "root"
            print("❌ JsonLoader: Could not find \(filename).json in \(dirName)")
            return nil
        }

        do {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(ResolvedConfig.self, from: data)
            print("✅ JsonLoader: Successfully loaded \(filename).json")
            return config
        } catch {
            print("❌ JsonLoader: Failed to load \(filename).json - \(error)")
            return nil
        }
    }
}
