import Foundation
import CleverTapNativeDisplay

/// Utility for loading JSON configuration files from the app bundle
///
/// Note: This is primarily used for loading test configurations.
/// For banner loading, see BannerDetailView.loadFromBundle() which handles
/// the multiple possible bundle paths more directly.
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
        // Try multiple path options to handle different bundle structures
        let pathsToTry: [(path: String?, description: String)] = [
            (Bundle.main.path(forResource: filename, ofType: "json", inDirectory: directory), directory ?? "root"),
            (Bundle.main.path(forResource: filename, ofType: "json", inDirectory: "Resources/\(directory ?? "")"), "Resources/\(directory ?? "")"),
            (Bundle.main.path(forResource: filename, ofType: "json"), "bundle root")
        ]

        for (path, pathDescription) in pathsToTry {
            if let validPath = path {
                print("✅ JsonLoader: Found \(filename).json in \(pathDescription)")
                do {
                    let url = URL(fileURLWithPath: validPath)
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let config = try decoder.decode(ResolvedConfig.self, from: data)
                    print("✅ JsonLoader: Successfully loaded \(filename).json")
                    return config
                } catch {
                    print("❌ JsonLoader: Failed to decode \(filename).json - \(error)")
                    return nil
                }
            }
        }

        // If none of the paths worked
        let dirName = directory ?? "root"
        print("❌ JsonLoader: Could not find \(filename).json - tried: \(dirName), Resources/\(dirName), bundle root")
        return nil
    }
}
