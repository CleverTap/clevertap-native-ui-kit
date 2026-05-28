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

        public init(url: String, openInBrowser: Bool = false, customTabsEnabled: Bool = true) {
            self.url = url
            self.openInBrowser = openInBrowser
            self.customTabsEnabled = customTabsEnabled
        }

        private enum CodingKeys: String, CodingKey {
            case url
            case openInBrowser
            case customTabsEnabled
        }

        /// Platform-specific URL object keys
        private enum PlatformUrlKeys: String, CodingKey {
            case ios
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // url can be a plain string or an object with platform keys
            if let urlString = try? container.decode(String.self, forKey: .url) {
                // Old format: "url": "www.google.com"
                self.url = urlString
            } else if let platformContainer = try? container.nestedContainer(
                keyedBy: PlatformUrlKeys.self, forKey: .url
            ) {
                // New format: "url": {"android": "...", "ios": "..."}
                self.url = try platformContainer.decode(String.self, forKey: .ios)
            } else {
                throw DecodingError.typeMismatch(
                    String.self,
                    DecodingError.Context(
                        codingPath: container.codingPath + [CodingKeys.url],
                        debugDescription: "Expected url to be a String or an object with an 'ios' key"
                    )
                )
            }

            self.openInBrowser = try container.decodeIfPresent(Bool.self, forKey: .openInBrowser) ?? false
            self.customTabsEnabled = try container.decodeIfPresent(Bool.self, forKey: .customTabsEnabled) ?? true
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
