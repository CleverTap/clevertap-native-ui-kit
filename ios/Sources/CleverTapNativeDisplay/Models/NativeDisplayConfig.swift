// MARK: - Native Display Configuration
// Main configuration models for the Native Display System

import Foundation

/// Main configuration for native display rendering.
/// Supports both Phase 1 (monolithic) and Phase 2+ (split APIs).
public struct NativeDisplayConfig: Codable, Equatable {
    public let version: String
    
    // Phase 1: Inline data (everything together)
    public let theme: Theme?
    public let styleClasses: [StyleClass]
    public let variables: [String: AnyCodable]
    public let root: NativeDisplayNode?
    
    // Phase 2+: References to external resources (optional)
    public let templateRef: TemplateReference?
    public let styleRef: StyleReference?
    public let dataRef: DataReference?
    
    public init(
        version: String = "1.0",
        theme: Theme? = nil,
        styleClasses: [StyleClass] = [],
        variables: [String: AnyCodable] = [:],
        root: NativeDisplayNode? = nil,
        templateRef: TemplateReference? = nil,
        styleRef: StyleReference? = nil,
        dataRef: DataReference? = nil
    ) {
        self.version = version
        self.theme = theme
        self.styleClasses = styleClasses
        self.variables = variables
        self.root = root
        self.templateRef = templateRef
        self.styleRef = styleRef
        self.dataRef = dataRef
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0"
        self.theme = try container.decodeIfPresent(Theme.self, forKey: .theme)
        self.styleClasses = try container.decodeIfPresent([StyleClass].self, forKey: .styleClasses) ?? []
        self.variables = try container.decodeIfPresent([String: AnyCodable].self, forKey: .variables) ?? [:]
        self.root = try container.decodeIfPresent(NativeDisplayNode.self, forKey: .root)
        self.templateRef = try container.decodeIfPresent(TemplateReference.self, forKey: .templateRef)
        self.styleRef = try container.decodeIfPresent(StyleReference.self, forKey: .styleRef)
        self.dataRef = try container.decodeIfPresent(DataReference.self, forKey: .dataRef)
    }
    
    private enum CodingKeys: String, CodingKey {
        case version, theme, styleClasses, variables, root
        case templateRef, styleRef, dataRef
    }
    
    /// Check if this is a monolithic config (Phase 1).
    public var isMonolithic: Bool {
        theme != nil &&
        root != nil &&
        templateRef == nil &&
        styleRef == nil &&
        dataRef == nil
    }
    
    /// Check if this config has external references (Phase 2+).
    public var hasReferences: Bool {
        templateRef != nil ||
        styleRef != nil ||
        dataRef != nil
    }
}

/// Reference to external template (Phase 2+).
public struct TemplateReference: Codable, Equatable {
    public let templateId: String
    public let version: String
    public let url: String?
    
    public init(templateId: String, version: String, url: String? = nil) {
        self.templateId = templateId
        self.version = version
        self.url = url
    }
}

/// Reference to external style data (Phase 2+).
public struct StyleReference: Codable, Equatable {
    public let styleId: String
    public let version: String
    public let url: String?
    
    public init(styleId: String, version: String, url: String? = nil) {
        self.styleId = styleId
        self.version = version
        self.url = url
    }
}

/// Reference to external data (Phase 2+).
public struct DataReference: Codable, Equatable {
    public let dataId: String
    public let url: String
    
    public init(dataId: String, url: String) {
        self.dataId = dataId
        self.url = url
    }
}

/// Resolved configuration after loading all resources.
/// Used internally after fetching templates, styles, and data.
public struct ResolvedConfig: Codable, Equatable {
    public let theme: Theme
    public let styleClasses: [StyleClass]
    public let variables: [String: AnyCodable]
    public let root: NativeDisplayNode
    
    public init(
        theme: Theme,
        styleClasses: [StyleClass],
        variables: [String: AnyCodable],
        root: NativeDisplayNode
    ) {
        self.theme = theme
        self.styleClasses = styleClasses
        self.variables = variables
        self.root = root
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.theme = try container.decodeIfPresent(Theme.self, forKey: .theme) ?? Theme.default
        self.styleClasses = try container.decodeIfPresent([StyleClass].self, forKey: .styleClasses) ?? []
        self.variables = try container.decodeIfPresent([String: AnyCodable].self, forKey: .variables) ?? [:]
        self.root = try container.decode(NativeDisplayNode.self, forKey: .root)
    }
    
    private enum CodingKeys: String, CodingKey {
        case theme, styleClasses, variables, root
    }
}

// MARK: - JSON Parsing

public extension ResolvedConfig {
    /// Parse a ResolvedConfig from JSON data.
    static func from(jsonData: Data) throws -> ResolvedConfig {
        let decoder = JSONDecoder()
        return try decoder.decode(ResolvedConfig.self, from: jsonData)
    }
    
    /// Parse a ResolvedConfig from a JSON string.
    static func from(jsonString: String) throws -> ResolvedConfig {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(
                domain: "NativeDisplayConfig",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string encoding"]
            )
        }
        return try from(jsonData: data)
    }
}

public extension NativeDisplayConfig {
    /// Parse a NativeDisplayConfig from JSON data.
    static func from(jsonData: Data) throws -> NativeDisplayConfig {
        let decoder = JSONDecoder()
        return try decoder.decode(NativeDisplayConfig.self, from: jsonData)
    }
    
    /// Parse a NativeDisplayConfig from a JSON string.
    static func from(jsonString: String) throws -> NativeDisplayConfig {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(
                domain: "NativeDisplayConfig",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string encoding"]
            )
        }
        return try from(jsonData: data)
    }
    
    /// Convert to ResolvedConfig if this is a monolithic config.
    func toResolvedConfig() -> ResolvedConfig? {
        guard let theme = theme, let root = root else {
            return nil
        }
        return ResolvedConfig(
            theme: theme,
            styleClasses: styleClasses,
            variables: variables,
            root: root
        )
    }
}
