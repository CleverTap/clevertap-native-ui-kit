// MARK: - Native Display Configuration
// Main configuration models for the Native Display System

import Foundation
import os

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
        let signpostID = PerformanceSignposts.jsonParsing.begin("parseResolvedConfig")
        defer { PerformanceSignposts.jsonParsing.end("parseResolvedConfig", signpostID) }
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
        let signpostID = PerformanceSignposts.jsonParsing.begin("parseConfig")
        defer { PerformanceSignposts.jsonParsing.end("parseConfig", signpostID) }
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

// MARK: - Layout Analysis Extensions

public extension ResolvedConfig {
    /// Returns the root container's explicit size if both dimensions are fixed (DP/SP/PX).
    /// Returns nil if root uses percentages, match_parent, or wrap_content.
    ///
    /// This optimization allows skipping GeometryReader when the root has a known fixed size,
    /// even if children use percentage-based dimensions (they calculate from root's fixed size).
    func rootExplicitSize() -> CGSize? {
        guard case .container(let container) = root,
              let layout = container.layout else {
            return nil
        }

        // Check width
        guard let width = layout.width,
              width.special == nil,
              width.unit != .percent else {
            return nil
        }

        // Check height
        guard let height = layout.height,
              height.special == nil,
              height.unit != .percent else {
            return nil
        }

        // Both dimensions are explicit fixed values
        return CGSize(width: width.value, height: height.value)
    }

    /// Scans entire config tree to detect if any percentage-based dimensions are used.
    /// - Returns: true if any width, height, or offset uses .percent unit
    /// - Performance: O(n) where n is total nodes, typically fast for real configs
    func usesPercentageDimensions() -> Bool {
        return scanNodeForPercentages(root)
    }

    /// Recursively scans a node and its children for percentage-based dimensions.
    private func scanNodeForPercentages(_ node: NativeDisplayNode) -> Bool {
        // Check current node's layout for percentage units
        if let layout = node.layout {
            // Check width
            if layout.width?.unit == .percent { return true }
            // Check height
            if layout.height?.unit == .percent { return true }
            // Check offset
            if layout.offset?.unit == .percent { return true }
        }

        // Recursively check children (only containers have children)
        switch node {
        case .container(let container):
            return container.children.contains { child in
                scanNodeForPercentages(child)
            }
        case .element:
            return false // Elements have no children
        }
    }
}
