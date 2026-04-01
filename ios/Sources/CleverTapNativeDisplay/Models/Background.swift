// MARK: - Background Models
// Background configuration for the Native Display System

import Foundation

/// Background configuration for elements and containers.
/// Supports various background types from simple colors to complex animations.
public enum Background: Codable, Equatable {
    /// Solid color background.
    case solid(SolidBackground)
    
    /// Linear gradient background.
    case linearGradient(LinearGradientBackground)
    
    /// Radial gradient background.
    case radialGradient(RadialGradientBackground)
    
    /// Sweep/Conic gradient background.
    case sweepGradient(SweepGradientBackground)
    
    /// Image background.
    case image(ImageBackground)
    
    /// Shimmer/shine effect background.
    case shimmer(ShimmerBackground)
    
    /// Animated gradient background.
    case animatedGradient(AnimatedGradientBackground)
    
    /// Pulse/breathing effect background.
    case pulse(PulseBackground)
    
    /// Pattern background.
    case pattern(PatternBackground)
    
    /// Particle effect background.
    case particles(ParticlesBackground)
    
    /// Layered background.
    case layered(LayeredBackground)
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "solid":
            self = .solid(try SolidBackground(from: decoder))
        case "linear_gradient":
            self = .linearGradient(try LinearGradientBackground(from: decoder))
        case "radial_gradient":
            self = .radialGradient(try RadialGradientBackground(from: decoder))
        case "sweep_gradient":
            self = .sweepGradient(try SweepGradientBackground(from: decoder))
        case "image":
            self = .image(try ImageBackground(from: decoder))
        case "shimmer":
            self = .shimmer(try ShimmerBackground(from: decoder))
        case "animated_gradient":
            self = .animatedGradient(try AnimatedGradientBackground(from: decoder))
        case "pulse":
            self = .pulse(try PulseBackground(from: decoder))
        case "pattern":
            self = .pattern(try PatternBackground(from: decoder))
        case "particles":
            self = .particles(try ParticlesBackground(from: decoder))
        case "layered":
            self = .layered(try LayeredBackground(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown background type: \(type)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .solid(let bg):
            try bg.encode(to: encoder)
        case .linearGradient(let bg):
            try bg.encode(to: encoder)
        case .radialGradient(let bg):
            try bg.encode(to: encoder)
        case .sweepGradient(let bg):
            try bg.encode(to: encoder)
        case .image(let bg):
            try bg.encode(to: encoder)
        case .shimmer(let bg):
            try bg.encode(to: encoder)
        case .animatedGradient(let bg):
            try bg.encode(to: encoder)
        case .pulse(let bg):
            try bg.encode(to: encoder)
        case .pattern(let bg):
            try bg.encode(to: encoder)
        case .particles(let bg):
            try bg.encode(to: encoder)
        case .layered(let bg):
            try bg.encode(to: encoder)
        }
    }
}

// MARK: - Background Type Structs

public struct SolidBackground: Codable, Equatable {
    public let color: String
    
    public init(color: String) {
        self.color = color
    }
}

public struct LinearGradientBackground: Codable, Equatable {
    public let angle: CGFloat
    public let colors: [String]
    public let stops: [CGFloat]?
    
    public init(angle: CGFloat, colors: [String], stops: [CGFloat]? = nil) {
        self.angle = angle
        self.colors = colors
        self.stops = stops
    }
}

public struct RadialGradientBackground: Codable, Equatable {
    public let centerX: CGFloat
    public let centerY: CGFloat
    public let radius: CGFloat
    public let colors: [String]
    public let stops: [CGFloat]?
    
    private enum CodingKeys: String, CodingKey {
        case centerX = "center_x"
        case centerY = "center_y"
        case radius
        case colors
        case stops
    }
    
    public init(
        centerX: CGFloat = 0.5,
        centerY: CGFloat = 0.5,
        radius: CGFloat = 1.0,
        colors: [String],
        stops: [CGFloat]? = nil
    ) {
        self.centerX = centerX
        self.centerY = centerY
        self.radius = radius
        self.colors = colors
        self.stops = stops
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        centerX = try c.decodeIfPresent(CGFloat.self, forKey: .centerX) ?? 0.5
        centerY = try c.decodeIfPresent(CGFloat.self, forKey: .centerY) ?? 0.5
        radius = try c.decodeIfPresent(CGFloat.self, forKey: .radius) ?? 1.0
        colors = try c.decode([String].self, forKey: .colors)
        stops = try c.decodeIfPresent([CGFloat].self, forKey: .stops)
    }
}

public struct SweepGradientBackground: Codable, Equatable {
    public let centerX: CGFloat
    public let centerY: CGFloat
    public let startAngle: CGFloat
    public let colors: [String]
    public let stops: [CGFloat]?
    
    private enum CodingKeys: String, CodingKey {
        case centerX = "center_x"
        case centerY = "center_y"
        case startAngle = "start_angle"
        case colors
        case stops
    }
    
    public init(
        centerX: CGFloat = 0.5,
        centerY: CGFloat = 0.5,
        startAngle: CGFloat = 0,
        colors: [String],
        stops: [CGFloat]? = nil
    ) {
        self.centerX = centerX
        self.centerY = centerY
        self.startAngle = startAngle
        self.colors = colors
        self.stops = stops
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        centerX = try c.decodeIfPresent(CGFloat.self, forKey: .centerX) ?? 0.5
        centerY = try c.decodeIfPresent(CGFloat.self, forKey: .centerY) ?? 0.5
        startAngle = try c.decodeIfPresent(CGFloat.self, forKey: .startAngle) ?? 0
        colors = try c.decode([String].self, forKey: .colors)
        stops = try c.decodeIfPresent([CGFloat].self, forKey: .stops)
    }
}

public struct ImageBackground: Codable, Equatable {
    public let url: String
    public let fit: ImageFit
    public let opacity: CGFloat
    public let blur: CGFloat
    public let tint: String?
    public let tintOpacity: CGFloat
    
    private enum CodingKeys: String, CodingKey {
        case url
        case fit
        case opacity
        case blur
        case tint
        case tintOpacity = "tint_opacity"
    }
    
    public init(
        url: String,
        fit: ImageFit = .crop,
        opacity: CGFloat = 1.0,
        blur: CGFloat = 0,
        tint: String? = nil,
        tintOpacity: CGFloat = 0
    ) {
        self.url = url
        self.fit = fit
        self.opacity = opacity
        self.blur = blur
        self.tint = tint
        self.tintOpacity = tintOpacity
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        url = try c.decode(String.self, forKey: .url)
        fit = try c.decodeIfPresent(ImageFit.self, forKey: .fit) ?? .crop
        opacity = try c.decodeIfPresent(CGFloat.self, forKey: .opacity) ?? 1.0
        blur = try c.decodeIfPresent(CGFloat.self, forKey: .blur) ?? 0
        tint = try c.decodeIfPresent(String.self, forKey: .tint)
        tintOpacity = try c.decodeIfPresent(CGFloat.self, forKey: .tintOpacity) ?? 0
    }
}

public struct ShimmerBackground: Codable, Equatable {
    public let baseColor: String
    public let highlightColor: String
    public let angle: CGFloat
    public let duration: Int
    public let loop: Bool
    
    private enum CodingKeys: String, CodingKey {
        case baseColor = "base_color"
        case highlightColor = "highlight_color"
        case angle
        case duration
        case loop
    }
    
    public init(
        baseColor: String,
        highlightColor: String,
        angle: CGFloat = 45,
        duration: Int = 1500,
        loop: Bool = true
    ) {
        self.baseColor = baseColor
        self.highlightColor = highlightColor
        self.angle = angle
        self.duration = duration
        self.loop = loop
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        baseColor = try c.decode(String.self, forKey: .baseColor)
        highlightColor = try c.decode(String.self, forKey: .highlightColor)
        angle = try c.decodeIfPresent(CGFloat.self, forKey: .angle) ?? 45
        duration = try c.decodeIfPresent(Int.self, forKey: .duration) ?? 1500
        loop = try c.decodeIfPresent(Bool.self, forKey: .loop) ?? true
    }
}

public struct AnimatedGradientBackground: Codable, Equatable {
    public let gradientType: GradientType
    public let angle: CGFloat
    public let colors: [String]
    public let duration: Int
    public let loop: Bool
    public let animationStyle: AnimationStyle
    
    private enum CodingKeys: String, CodingKey {
        case gradientType = "gradient_type"
        case angle
        case colors
        case duration
        case loop
        case animationStyle = "animation_style"
    }
    
    public init(
        gradientType: GradientType,
        angle: CGFloat = 0,
        colors: [String],
        duration: Int = 3000,
        loop: Bool = true,
        animationStyle: AnimationStyle = .smooth
    ) {
        self.gradientType = gradientType
        self.angle = angle
        self.colors = colors
        self.duration = duration
        self.loop = loop
        self.animationStyle = animationStyle
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gradientType = try c.decode(GradientType.self, forKey: .gradientType)
        angle = try c.decodeIfPresent(CGFloat.self, forKey: .angle) ?? 0
        colors = try c.decode([String].self, forKey: .colors)
        duration = try c.decodeIfPresent(Int.self, forKey: .duration) ?? 3000
        loop = try c.decodeIfPresent(Bool.self, forKey: .loop) ?? true
        animationStyle = try c.decodeIfPresent(AnimationStyle.self, forKey: .animationStyle) ?? .smooth
    }
}

public struct PulseBackground: Codable, Equatable {
    public let color: String
    public let minOpacity: CGFloat
    public let maxOpacity: CGFloat
    public let duration: Int
    public let loop: Bool
    
    private enum CodingKeys: String, CodingKey {
        case color
        case minOpacity = "min_opacity"
        case maxOpacity = "max_opacity"
        case duration
        case loop
    }
    
    public init(
        color: String,
        minOpacity: CGFloat = 0.3,
        maxOpacity: CGFloat = 1.0,
        duration: Int = 1000,
        loop: Bool = true
    ) {
        self.color = color
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.duration = duration
        self.loop = loop
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        color = try c.decode(String.self, forKey: .color)
        minOpacity = try c.decodeIfPresent(CGFloat.self, forKey: .minOpacity) ?? 0.3
        maxOpacity = try c.decodeIfPresent(CGFloat.self, forKey: .maxOpacity) ?? 1.0
        duration = try c.decodeIfPresent(Int.self, forKey: .duration) ?? 1000
        loop = try c.decodeIfPresent(Bool.self, forKey: .loop) ?? true
    }
}

public struct PatternBackground: Codable, Equatable {
    public let patternType: PatternType
    public let primaryColor: String
    public let secondaryColor: String
    public let size: CGFloat
    public let spacing: CGFloat
    public let opacity: CGFloat
    
    private enum CodingKeys: String, CodingKey {
        case patternType = "pattern_type"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case size
        case spacing
        case opacity
    }
    
    public init(
        patternType: PatternType,
        primaryColor: String,
        secondaryColor: String,
        size: CGFloat = 20,
        spacing: CGFloat = 30,
        opacity: CGFloat = 1.0
    ) {
        self.patternType = patternType
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.size = size
        self.spacing = spacing
        self.opacity = opacity
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        patternType = try c.decode(PatternType.self, forKey: .patternType)
        primaryColor = try c.decode(String.self, forKey: .primaryColor)
        secondaryColor = try c.decode(String.self, forKey: .secondaryColor)
        size = try c.decodeIfPresent(CGFloat.self, forKey: .size) ?? 20
        spacing = try c.decodeIfPresent(CGFloat.self, forKey: .spacing) ?? 30
        opacity = try c.decodeIfPresent(CGFloat.self, forKey: .opacity) ?? 1.0
    }
}

public struct ParticlesBackground: Codable, Equatable {
    public let particleColor: String
    public let particleCount: Int
    public let particleSize: CGFloat
    public let speed: CGFloat
    public let direction: ParticleDirection
    public let opacity: CGFloat
    
    private enum CodingKeys: String, CodingKey {
        case particleColor = "particle_color"
        case particleCount = "particle_count"
        case particleSize = "particle_size"
        case speed
        case direction
        case opacity
    }
    
    public init(
        particleColor: String,
        particleCount: Int = 50,
        particleSize: CGFloat = 4,
        speed: CGFloat = 2,
        direction: ParticleDirection = .up,
        opacity: CGFloat = 0.7
    ) {
        self.particleColor = particleColor
        self.particleCount = particleCount
        self.particleSize = particleSize
        self.speed = speed
        self.direction = direction
        self.opacity = opacity
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        particleColor = try c.decode(String.self, forKey: .particleColor)
        particleCount = try c.decodeIfPresent(Int.self, forKey: .particleCount) ?? 50
        particleSize = try c.decodeIfPresent(CGFloat.self, forKey: .particleSize) ?? 4
        speed = try c.decodeIfPresent(CGFloat.self, forKey: .speed) ?? 2
        direction = try c.decodeIfPresent(ParticleDirection.self, forKey: .direction) ?? .up
        opacity = try c.decodeIfPresent(CGFloat.self, forKey: .opacity) ?? 0.7
    }
}

public struct LayeredBackground: Codable, Equatable {
    public let layers: [Background]
    
    public init(layers: [Background]) {
        self.layers = layers
    }
}
