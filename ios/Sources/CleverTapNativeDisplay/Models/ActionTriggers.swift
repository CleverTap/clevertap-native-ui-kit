//
//  ActionTriggers.swift
//  CleverTapNativeDisplay
//
//  Created by Lalitkumar Patil on 05/01/26.
//


// MARK: - Action Models
// Defines all action types that can be triggered by user interactions

import Foundation

/// Action triggers - constants for when actions execute
public struct ActionTriggers {
    public static let onClick = "onClick"
    public static let onLongPress = "onLongPress"
    public static let onDoubleTap = "onDoubleTap"
    public static let onAppear = "onAppear"
    public static let onDisappear = "onDisappear"
}

/// Action types that can be executed (matches Android sealed class)
public enum Action: Codable, Equatable {
    case openUrl(OpenUrlAction)
    case custom(CustomAction)
    case navigate(NavigateAction)
    case trackEvent(TrackEventAction)
    case composite(CompositeAction)
    
    // MARK: - Action Type Definitions
    
    public struct OpenUrlAction: Codable, Equatable {
        public let url: String
        public let openInBrowser: Bool
        public let customTabsEnabled: Bool
        public let metadata: [String: String]?

        public init(url: String, openInBrowser: Bool = false, customTabsEnabled: Bool = true, metadata: [String: String]? = nil) {
            self.url = url
            self.openInBrowser = openInBrowser
            self.customTabsEnabled = customTabsEnabled
            self.metadata = metadata
        }

        private enum CodingKeys: String, CodingKey {
            case url
            case openInBrowser
            case customTabsEnabled
            case metadata
        }

        /// Platform-specific URL object keys (prefer ios; also handle legacy {text, replacements} object)
        private enum PlatformUrlKeys: String, CodingKey {
            case android, ios
        }

        private enum LegacyUrlObjectKeys: String, CodingKey {
            case text
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // url can be: plain string, {"android":…,"ios":…} with string values,
            // or {"android":{text,replacements}} legacy Ultron object format — use `text`.
            if let urlString = try? container.decode(String.self, forKey: .url) {
                self.url = urlString
            } else if let platformContainer = try? container.nestedContainer(
                keyedBy: PlatformUrlKeys.self, forKey: .url
            ) {
                // Prefer ios; if the value is an object, dig into `text`
                if let direct = try? platformContainer.decode(String.self, forKey: .ios) {
                    self.url = direct
                } else if let legacyContainer = try? platformContainer.nestedContainer(
                    keyedBy: LegacyUrlObjectKeys.self, forKey: .ios
                ), let text = try? legacyContainer.decode(String.self, forKey: .text) {
                    self.url = text
                } else {
                    self.url = ""
                }
            } else {
                self.url = ""
            }

            self.openInBrowser = try container.decodeIfPresent(Bool.self, forKey: .openInBrowser) ?? false
            self.customTabsEnabled = try container.decodeIfPresent(Bool.self, forKey: .customTabsEnabled) ?? true

            // Metadata: coerce any JSON value type to String — never crash on nested objects
            let rawMeta = (try? container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)) ?? nil
            self.metadata = ndMetadataToStringMap(rawMeta)
        }
    }
    
    public struct CustomAction: Codable, Equatable {
        public let key: String
        public let value: AnyCodable
        public let metadata: [String: String]?

        public init(key: String, value: AnyCodable, metadata: [String: String]? = nil) {
            self.key = key
            self.value = value
            self.metadata = metadata
        }

        private enum CodingKeys: String, CodingKey {
            case key, value, metadata
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.key = try container.decode(String.self, forKey: .key)
            self.value = try container.decode(AnyCodable.self, forKey: .value)
            // Metadata: coerce any JSON value type to String — never crash on nested objects
            let rawMeta = (try? container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)) ?? nil
            self.metadata = ndMetadataToStringMap(rawMeta)
        }
    }
    
    public struct NavigateAction: Codable, Equatable {
        public let destination: String
        public let params: [String: String]?
        
        public init(destination: String, params: [String: String]? = nil) {
            self.destination = destination
            self.params = params
        }
    }
    
    public struct TrackEventAction: Codable, Equatable {
        public let eventName: String
        public let properties: [String: AnyCodable]?
        
        public init(eventName: String, properties: [String: AnyCodable]? = nil) {
            self.eventName = eventName
            self.properties = properties
        }
    }
    
    public struct CompositeAction: Codable, Equatable {
        public let actions: [Action]
        public let executionMode: ExecutionMode
        
        public init(actions: [Action], executionMode: ExecutionMode = .sequential) {
            self.actions = actions
            self.executionMode = executionMode
        }
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "open_url":
            self = .openUrl(try OpenUrlAction(from: decoder))
        case "custom":
            self = .custom(try CustomAction(from: decoder))
        case "navigate":
            self = .navigate(try NavigateAction(from: decoder))
        case "event":
            self = .trackEvent(try TrackEventAction(from: decoder))
        case "composite":
            self = .composite(try CompositeAction(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown action type: \(type)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .openUrl(let action):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("open_url", forKey: .type)
            try action.encode(to: encoder)
        case .custom(let action):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("custom", forKey: .type)
            try action.encode(to: encoder)
        case .navigate(let action):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("navigate", forKey: .type)
            try action.encode(to: encoder)
        case .trackEvent(let action):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("event", forKey: .type)
            try action.encode(to: encoder)
        case .composite(let action):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("composite", forKey: .type)
            try action.encode(to: encoder)
        }
    }
}

/// Execution mode for composite actions
public enum ExecutionMode: String, Codable {
    case sequential
    case parallel
}

// MARK: - Metadata parsing helpers (file-private)

/// Converts an `[String: AnyCodable]` metadata map to `[String: String]`, coercing any
/// JSON value type to its string representation. Objects and arrays become compact JSON strings.
/// Null/void values are dropped. Never throws or crashes.
private func ndMetadataToStringMap(_ raw: [String: AnyCodable]?) -> [String: String]? {
    guard let raw = raw, !raw.isEmpty else { return nil }
    var result: [String: String] = [:]
    for (k, v) in raw {
        if let s = ndAnyCodableToString(v.value) {
            result[k] = s
        }
    }
    return result.isEmpty ? nil : result
}

private func ndAnyCodableToString(_ v: Any) -> String? {
    if v is Void || v is NSNull { return nil }
    if let s = v as? String { return s }
    // Bool must be checked before NSNumber — on Darwin, Bool bridges to NSNumber
    if let b = v as? Bool { return b ? "true" : "false" }
    if let n = v as? NSNumber { return n.stringValue }
    // Objects and arrays: serialize to compact JSON string
    if let data = try? JSONSerialization.data(withJSONObject: ndUnwrapAnyCodable(v)),
       let s = String(data: data, encoding: .utf8) { return s }
    return String(describing: v)
}

/// Recursively unwraps `AnyCodable` wrappers inside arrays/dicts so `JSONSerialization` can
/// handle them without encountering opaque wrapper types.
private func ndUnwrapAnyCodable(_ value: Any) -> Any {
    if let arr = value as? [Any] {
        return arr.map { ndUnwrapAnyCodable(($0 as? AnyCodable)?.value ?? $0) }
    }
    if let dict = value as? [String: Any] {
        return dict.mapValues { ndUnwrapAnyCodable(($0 as? AnyCodable)?.value ?? $0) }
    }
    return value
}
