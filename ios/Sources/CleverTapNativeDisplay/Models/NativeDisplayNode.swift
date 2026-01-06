// MARK: - Native Display Node Models
// Node models for the Native Display System

import Foundation

/// Base protocol for all display nodes (containers and elements).
/// Supports unlimited nesting for maximum flexibility.
public protocol NativeDisplayNodeProtocol: Codable {
    var id: String { get }
    var layout: Layout? { get }
    var style: Style? { get }
    var styleClass: String? { get }
    var visible: String? { get }
    var actions: [String: Action]? { get }
    var animation: Animation? { get }
}

/// Union type for native display nodes (container or element).
public enum NativeDisplayNode: Codable, Equatable {
    case container(NativeDisplayContainer)
    case element(NativeDisplayElement)
    
    // MARK: - Protocol Forwarding
    
    public var id: String {
        switch self {
        case .container(let c): return c.id
        case .element(let e): return e.id
        }
    }
    
    public var layout: Layout? {
        switch self {
        case .container(let c): return c.layout
        case .element(let e): return e.layout
        }
    }
    
    public var style: Style? {
        switch self {
        case .container(let c): return c.style
        case .element(let e): return e.style
        }
    }
    
    public var styleClass: String? {
        switch self {
        case .container(let c): return c.styleClass
        case .element(let e): return e.styleClass
        }
    }
    
    public var visible: String? {
        switch self {
        case .container(let c): return c.visible
        case .element(let e): return e.visible
        }
    }
    
    public var actions: [String: Action]? {
        switch self {
        case .container(let c): return c.actions
        case .element(let e): return e.actions
        }
    }
    
    public var animation: Animation? {
        switch self {
        case .container(let c): return c.animation
        case .element(let e): return e.animation
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
        case "container":
            self = .container(try NativeDisplayContainer(from: decoder))
        case "element":
            self = .element(try NativeDisplayElement(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown node type: \(type)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .container(let c):
            try c.encode(to: encoder)
        case .element(let e):
            try e.encode(to: encoder)
        }
    }
}

/// Container node that can hold multiple children (both containers and elements).
/// Supports unlimited nesting depth.
public struct NativeDisplayContainer: Codable, Equatable {
    public let id: String
    public let containerType: ContainerType
    public let children: [NativeDisplayNode]
    public let layout: Layout?
    public let style: Style?
    public let styleClass: String?
    public let visible: String?
    public let actions: [String: Action]?
    public let animation: Animation?
    
    // Gallery configuration (only used when containerType = GALLERY)
    public let galleryConfig: GalleryConfig?
    
    // Divider configuration
    public let dividerConfig: DividerConfig?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case containerType
        case children
        case layout
        case style
        case styleClass
        case visible
        case actions
        case animation
        case galleryConfig
        case dividerConfig
    }
    
    public init(
        id: String,
        containerType: ContainerType,
        children: [NativeDisplayNode] = [],
        layout: Layout? = nil,
        style: Style? = nil,
        styleClass: String? = nil,
        visible: String? = nil,
        actions: [String: Action]? = nil,
        animation: Animation? = nil,
        galleryConfig: GalleryConfig? = nil,
        dividerConfig: DividerConfig? = nil
    ) {
        self.id = id
        self.containerType = containerType
        self.children = children
        self.layout = layout
        self.style = style
        self.styleClass = styleClass
        self.visible = visible
        self.actions = actions
        self.animation = animation
        self.galleryConfig = galleryConfig
        self.dividerConfig = dividerConfig
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        containerType = try container.decode(ContainerType.self, forKey: .containerType)
        children = try container.decodeIfPresent([NativeDisplayNode].self, forKey: .children) ?? []
        layout = try container.decodeIfPresent(Layout.self, forKey: .layout)
        style = try container.decodeIfPresent(Style.self, forKey: .style)
        styleClass = try container.decodeIfPresent(String.self, forKey: .styleClass)
        visible = try container.decodeIfPresent(String.self, forKey: .visible)
        actions = try container.decodeIfPresent([String: Action].self, forKey: .actions)
        animation = try container.decodeIfPresent(Animation.self, forKey: .animation)
        galleryConfig = try container.decodeIfPresent(GalleryConfig.self, forKey: .galleryConfig)
        dividerConfig = try container.decodeIfPresent(DividerConfig.self, forKey: .dividerConfig)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("container", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(containerType, forKey: .containerType)
        try container.encode(children, forKey: .children)
        try container.encodeIfPresent(layout, forKey: .layout)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encodeIfPresent(styleClass, forKey: .styleClass)
        try container.encodeIfPresent(visible, forKey: .visible)
        try container.encodeIfPresent(actions, forKey: .actions)
        try container.encodeIfPresent(animation, forKey: .animation)
        try container.encodeIfPresent(galleryConfig, forKey: .galleryConfig)
        try container.encodeIfPresent(dividerConfig, forKey: .dividerConfig)
    }
}

/// Element node that displays actual content (leaf node).
public struct NativeDisplayElement: Codable, Equatable {
    public let id: String
    public let elementType: ElementType
    public let bindings: [String: String]
    public let layout: Layout?
    public let style: Style?
    public let styleClass: String?
    public let visible: String?
    public let actions: [String: Action]?
    public let animation: Animation?
    
    // Divider configuration (only used when elementType = DIVIDER)
    public let dividerConfig: DividerConfig?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case elementType
        case bindings
        case layout
        case style
        case styleClass
        case visible
        case actions
        case animation
        case dividerConfig
    }
    
    public init(
        id: String,
        elementType: ElementType,
        bindings: [String: String] = [:],
        layout: Layout? = nil,
        style: Style? = nil,
        styleClass: String? = nil,
        visible: String? = nil,
        actions: [String: Action]? = nil,
        animation: Animation? = nil,
        dividerConfig: DividerConfig? = nil
    ) {
        self.id = id
        self.elementType = elementType
        self.bindings = bindings
        self.layout = layout
        self.style = style
        self.styleClass = styleClass
        self.visible = visible
        self.actions = actions
        self.animation = animation
        self.dividerConfig = dividerConfig
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        elementType = try container.decode(ElementType.self, forKey: .elementType)
        bindings = try container.decodeIfPresent([String: String].self, forKey: .bindings) ?? [:]
        layout = try container.decodeIfPresent(Layout.self, forKey: .layout)
        style = try container.decodeIfPresent(Style.self, forKey: .style)
        styleClass = try container.decodeIfPresent(String.self, forKey: .styleClass)
        visible = try container.decodeIfPresent(String.self, forKey: .visible)
        actions = try container.decodeIfPresent([String: Action].self, forKey: .actions)
        animation = try container.decodeIfPresent(Animation.self, forKey: .animation)
        dividerConfig = try container.decodeIfPresent(DividerConfig.self, forKey: .dividerConfig)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("element", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(elementType, forKey: .elementType)
        try container.encode(bindings, forKey: .bindings)
        try container.encodeIfPresent(layout, forKey: .layout)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encodeIfPresent(styleClass, forKey: .styleClass)
        try container.encodeIfPresent(visible, forKey: .visible)
        try container.encodeIfPresent(actions, forKey: .actions)
        try container.encodeIfPresent(animation, forKey: .animation)
        try container.encodeIfPresent(dividerConfig, forKey: .dividerConfig)
    }
}

/// Divider configuration.
public struct DividerConfig: Codable, Equatable {
    public let orientation: Orientation
    public let thickness: CGFloat
    public let color: String
    
    public init(
        orientation: Orientation = .horizontal,
        thickness: CGFloat = 1,
        color: String = "#E0E0E0"
    ) {
        self.orientation = orientation
        self.thickness = thickness
        self.color = color
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.orientation = try container.decodeIfPresent(Orientation.self, forKey: .orientation) ?? .horizontal
        self.thickness = try container.decodeIfPresent(CGFloat.self, forKey: .thickness) ?? 1
        self.color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#E0E0E0"
    }
    
    private enum CodingKeys: String, CodingKey {
        case orientation, thickness, color
    }
}

/// Animation configuration (Phase 4+).
public struct Animation: Codable, Equatable {
    public let type: String  // "fadeIn", "slideIn", etc.
    public let duration: Int
    public let delay: Int
    
    public init(type: String, duration: Int = 300, delay: Int = 0) {
        self.type = type
        self.duration = duration
        self.delay = delay
    }
    
    // Custom decoder to handle defaults
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 300
        self.delay = try container.decodeIfPresent(Int.self, forKey: .delay) ?? 0
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, duration, delay
    }
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for handling arbitrary JSON values.
public struct AnyCodable: Codable, Equatable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = ()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Cannot encode AnyCodable"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as Bool, let r as Bool): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        case (is Void, is Void): return true
        default: return false
        }
    }
}
