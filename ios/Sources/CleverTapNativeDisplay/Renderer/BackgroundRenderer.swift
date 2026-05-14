// MARK: - Background Renderer
// Background rendering implementation for SwiftUI

import SwiftUI

/// View that renders a background based on the Background configuration.
struct BackgroundView: View {
    let background: Background

    init(background: Background) {
        self.background = background
    }

    var body: some View {
        switch background {
        case .solid(let bg):
            SolidBackgroundView(background: bg)
            
        case .linearGradient(let bg):
            LinearGradientBackgroundView(background: bg)
            
        case .radialGradient(let bg):
            RadialGradientBackgroundView(background: bg)
            
        case .sweepGradient(let bg):
            SweepGradientBackgroundView(background: bg)
            
        case .image(let bg):
            ImageBackgroundView(background: bg)
            
        case .shimmer(let bg):
            ShimmerBackgroundView(background: bg)
            
        case .animatedGradient(let bg):
            AnimatedGradientBackgroundView(background: bg)
            
        case .pulse(let bg):
            PulseBackgroundView(background: bg)
            
        case .pattern(let bg):
            PatternBackgroundView(background: bg)
            
        case .particles(let bg):
            ParticlesBackgroundView(background: bg)
            
        case .layered(let bg):
            LayeredBackgroundView(background: bg)
        }
    }
}

// MARK: - Static Backgrounds

/// Solid color background.
struct SolidBackgroundView: View {
    let background: SolidBackground
    
    var body: some View {
        ColorParser.parse(background.color) ?? Color.clear
    }
}

/// Linear gradient background.
struct LinearGradientBackgroundView: View {
    let background: LinearGradientBackground
    
    var body: some View {
        let colors = background.colors.compactMap { ColorParser.parse($0) }
        guard !colors.isEmpty else {
            return AnyView(Color.clear)
        }
        
        let stops: [Gradient.Stop]
        if let bgStops = background.stops, !bgStops.isEmpty {
            stops = zip(colors, bgStops).map { Gradient.Stop(color: $0.0, location: $0.1) }
        } else {
            stops = colors.enumerated().map { index, color in
                Gradient.Stop(color: color, location: CGFloat(index) / CGFloat(colors.count - 1))
            }
        }
        
        let (start, end) = calculateGradientPoints(angle: background.angle)
        
        return AnyView(
            LinearGradient(
                stops: stops,
                startPoint: start,
                endPoint: end
            )
        )
    }
    
    private func calculateGradientPoints(angle: CGFloat) -> (UnitPoint, UnitPoint) {
        let radians = (angle - 90) * .pi / 180
        let x = cos(radians)
        let y = sin(radians)
        
        let startX = 0.5 - x * 0.5
        let startY = 0.5 - y * 0.5
        let endX = 0.5 + x * 0.5
        let endY = 0.5 + y * 0.5
        
        return (
            UnitPoint(x: startX, y: startY),
            UnitPoint(x: endX, y: endY)
        )
    }
}

/// Radial gradient background.
struct RadialGradientBackgroundView: View {
    let background: RadialGradientBackground
    
    var body: some View {
        let colors = background.colors.compactMap { ColorParser.parse($0) }
        guard !colors.isEmpty else {
            return AnyView(Color.clear)
        }
        
        return AnyView(
            GeometryReader { geometry in
                let center = UnitPoint(x: background.centerX, y: background.centerY)
                let radius = min(geometry.size.width, geometry.size.height) * background.radius
                
                RadialGradient(
                    colors: colors,
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
            }
        )
    }
}

/// Sweep/Angular gradient background.
struct SweepGradientBackgroundView: View {
    let background: SweepGradientBackground
    
    var body: some View {
        let colors = background.colors.compactMap { ColorParser.parse($0) }
        guard !colors.isEmpty else {
            return AnyView(Color.clear)
        }
        
        let center = UnitPoint(x: background.centerX, y: background.centerY)
        let startAngle = Angle(degrees: Double(background.startAngle))
        
        return AnyView(
            AngularGradient(
                colors: colors,
                center: center,
                startAngle: startAngle,
                endAngle: startAngle + .degrees(360)
            )
        )
    }
}

/// Image background.
struct ImageBackgroundView: View {
    let background: ImageBackground
    
    var body: some View {
        AsyncImage(url: URL(string: background.url)) { phase in
            switch phase {
            case .empty:
                Color.gray.opacity(0.2)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .opacity(background.opacity)
                    .blur(radius: background.blur)
                    .overlay(tintOverlay)
            case .failure:
                Color.gray.opacity(0.3)
            @unknown default:
                Color.clear
            }
        }
    }
    
    private var contentMode: ContentMode {
        switch background.fit {
        case .crop: return .fill
        case .contain: return .fit
        case .fill: return .fill
        case .tile: return .fill // SwiftUI doesn't have native tiling
        }
    }
    
    @ViewBuilder
    private var tintOverlay: some View {
        if let tint = background.tint, background.tintOpacity > 0 {
            ColorParser.parse(tint)?
                .opacity(background.tintOpacity)
        }
    }
}

/// Pattern background.
struct PatternBackgroundView: View {
    let background: PatternBackground
    
    var body: some View {
        GeometryReader { geometry in
            let primaryColor = ColorParser.parse(background.primaryColor) ?? .gray
            let secondaryColor = ColorParser.parse(background.secondaryColor) ?? .white
            
            Canvas { context, size in
                // Draw base color
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(primaryColor))
                
                // Draw pattern
                switch background.patternType {
                case .dots, .polkaDots:
                    drawDots(context: context, size: size, color: secondaryColor)
                case .stripesHorizontal:
                    drawHorizontalStripes(context: context, size: size, color: secondaryColor)
                case .stripesVertical:
                    drawVerticalStripes(context: context, size: size, color: secondaryColor)
                case .stripesDiagonal:
                    drawDiagonalStripes(context: context, size: size, color: secondaryColor)
                case .grid:
                    drawGrid(context: context, size: size, color: secondaryColor)
                case .checkerboard:
                    drawCheckerboard(context: context, size: size, color: secondaryColor)
                }
            }
            .opacity(background.opacity)
        }
    }
    
    private func drawDots(context: GraphicsContext, size: CGSize, color: Color) {
        let spacing = background.spacing
        let dotSize = background.size
        
        var y: CGFloat = 0
        while y < size.height + spacing {
            var x: CGFloat = 0
            while x < size.width + spacing {
                let path = Path(ellipseIn: CGRect(
                    x: x - dotSize / 2,
                    y: y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                ))
                context.fill(path, with: .color(color))
                x += spacing
            }
            y += spacing
        }
    }
    
    private func drawHorizontalStripes(context: GraphicsContext, size: CGSize, color: Color) {
        let stripeHeight = background.size
        let spacing = background.spacing
        
        var y: CGFloat = 0
        while y < size.height + spacing {
            let path = Path(CGRect(x: 0, y: y, width: size.width, height: stripeHeight))
            context.fill(path, with: .color(color))
            y += stripeHeight + spacing
        }
    }
    
    private func drawVerticalStripes(context: GraphicsContext, size: CGSize, color: Color) {
        let stripeWidth = background.size
        let spacing = background.spacing
        
        var x: CGFloat = 0
        while x < size.width + spacing {
            let path = Path(CGRect(x: x, y: 0, width: stripeWidth, height: size.height))
            context.fill(path, with: .color(color))
            x += stripeWidth + spacing
        }
    }
    
    private func drawDiagonalStripes(context: GraphicsContext, size: CGSize, color: Color) {
        let stripeWidth = background.size
        let spacing = background.spacing
        let diagonal = sqrt(size.width * size.width + size.height * size.height)
        
        var offset: CGFloat = -diagonal
        while offset < diagonal {
            var path = Path()
            path.move(to: CGPoint(x: offset, y: 0))
            path.addLine(to: CGPoint(x: offset + diagonal, y: diagonal))
            context.stroke(path, with: .color(color), lineWidth: stripeWidth)
            offset += stripeWidth + spacing
        }
    }
    
    private func drawGrid(context: GraphicsContext, size: CGSize, color: Color) {
        drawHorizontalStripes(context: context, size: size, color: color)
        drawVerticalStripes(context: context, size: size, color: color)
    }
    
    private func drawCheckerboard(context: GraphicsContext, size: CGSize, color: Color) {
        let squareSize = background.size
        
        var row = 0
        var y: CGFloat = 0
        while y < size.height + squareSize {
            var col = 0
            var x: CGFloat = 0
            while x < size.width + squareSize {
                if (row + col) % 2 == 0 {
                    let path = Path(CGRect(x: x, y: y, width: squareSize, height: squareSize))
                    context.fill(path, with: .color(color))
                }
                x += squareSize
                col += 1
            }
            y += squareSize
            row += 1
        }
    }
}

// MARK: - Animated Backgrounds

/// Shimmer effect background.
struct ShimmerBackgroundView: View {
    let background: ShimmerBackground
    @State private var offset: CGFloat = -1
    
    var body: some View {
        let baseColor = ColorParser.parse(background.baseColor) ?? .gray
        let highlightColor = ColorParser.parse(background.highlightColor) ?? .white
        
        GeometryReader { geometry in
            let (start, end) = calculateGradientPoints(angle: background.angle, offset: offset)
            
            LinearGradient(
                colors: [baseColor, highlightColor, baseColor],
                startPoint: start,
                endPoint: end
            )
        }
        .onAppear {
            if background.loop {
                withAnimation(.linear(duration: Double(background.duration) / 1000).repeatForever(autoreverses: false)) {
                    offset = 1
                }
            } else {
                withAnimation(.linear(duration: Double(background.duration) / 1000)) {
                    offset = 1
                }
            }
        }
    }
    
    private func calculateGradientPoints(angle: CGFloat, offset: CGFloat) -> (UnitPoint, UnitPoint) {
        let radians = (angle - 90) * .pi / 180
        let x = cos(radians)
        let y = sin(radians)
        
        let startX = 0.5 - x * 0.5 + offset * x
        let startY = 0.5 - y * 0.5 + offset * y
        let endX = 0.5 + x * 0.5 + offset * x
        let endY = 0.5 + y * 0.5 + offset * y
        
        return (
            UnitPoint(x: startX, y: startY),
            UnitPoint(x: endX, y: endY)
        )
    }
}

/// Animated gradient background.
struct AnimatedGradientBackgroundView: View {
    let background: AnimatedGradientBackground
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        let colors = background.colors.compactMap { ColorParser.parse($0) }
        guard !colors.isEmpty else {
            return AnyView(Color.clear)
        }
        
        return AnyView(
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSince1970.truncatingRemainder(dividingBy: Double(background.duration) / 1000)
                let progress = phase / (Double(background.duration) / 1000)
                
                gradientView(colors: colors, progress: CGFloat(progress))
            }
        )
    }
    
    @ViewBuilder
    private func gradientView(colors: [Color], progress: CGFloat) -> some View {
        switch background.gradientType {
        case .linear:
            let (start, end) = animatedLinearPoints(progress: progress)
            LinearGradient(colors: colors, startPoint: start, endPoint: end)
            
        case .radial:
            let radius = 0.5 + progress * 0.5
            GeometryReader { geometry in
                RadialGradient(colors: colors, center: .center, startRadius: 0, endRadius: geometry.size.width * radius)
            }
            
        case .sweep:
            let startAngle = Angle(degrees: Double(progress * 360))
            AngularGradient(colors: colors, center: .center, startAngle: startAngle, endAngle: startAngle + .degrees(360))
        }
    }
    
    private func animatedLinearPoints(progress: CGFloat) -> (UnitPoint, UnitPoint) {
        let angle = background.angle + progress * 360
        let radians = angle * .pi / 180
        let x = cos(radians)
        let y = sin(radians)
        
        return (
            UnitPoint(x: 0.5 - x * 0.5, y: 0.5 - y * 0.5),
            UnitPoint(x: 0.5 + x * 0.5, y: 0.5 + y * 0.5)
        )
    }
}

/// Pulse/breathing effect background.
struct PulseBackgroundView: View {
    let background: PulseBackground
    @State private var opacity: Double = 0.3
    
    var body: some View {
        let color = ColorParser.parse(background.color) ?? .blue
        
        color
            .opacity(opacity)
            .onAppear {
                let duration = Double(background.duration) / 1000
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = background.maxOpacity
                }
            }
    }
}

/// Particles effect background.
struct ParticlesBackgroundView: View {
    let background: ParticlesBackground
    @State private var particles: [Particle] = []
    @State private var time: Date = Date()
    
    private struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
    }
    
    var body: some View {
        let particleColor = ColorParser.parse(background.particleColor)?.opacity(background.opacity) ?? .white.opacity(0.7)
        
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let elapsed = context.date.timeIntervalSince(time)
                
                for particle in particles {
                    let x = ((particle.x + particle.vx * CGFloat(elapsed) * 0.01).truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1) * size.width
                    let y = ((particle.y + particle.vy * CGFloat(elapsed) * 0.01).truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1) * size.height
                    
                    let path = Path(ellipseIn: CGRect(
                        x: x - background.particleSize / 2,
                        y: y - background.particleSize / 2,
                        width: background.particleSize,
                        height: background.particleSize
                    ))
                    ctx.fill(path, with: .color(particleColor))
                }
            }
        }
        .onAppear {
            time = Date()
            particles = (0..<background.particleCount).map { _ in
                let vy: CGFloat
                switch background.direction {
                case .up: vy = -CGFloat.random(in: 0..<background.speed)
                case .down: vy = CGFloat.random(in: 0..<background.speed)
                case .left: vy = 0
                case .right: vy = 0
                case .random: vy = CGFloat.random(in: -background.speed..<background.speed)
                }
                
                let vx: CGFloat
                switch background.direction {
                case .up, .down: vx = CGFloat.random(in: -0.5..<0.5) * background.speed
                case .left: vx = -CGFloat.random(in: 0..<background.speed)
                case .right: vx = CGFloat.random(in: 0..<background.speed)
                case .random: vx = CGFloat.random(in: -background.speed..<background.speed)
                }
                
                return Particle(
                    x: CGFloat.random(in: 0..<1),
                    y: CGFloat.random(in: 0..<1),
                    vx: vx,
                    vy: vy
                )
            }
        }
    }
}

/// Layered background.
struct LayeredBackgroundView: View {
    let background: LayeredBackground
    
    var body: some View {
        ZStack {
            ForEach(background.layers.indices, id: \.self) { index in
                BackgroundView(background: background.layers[index])
            }
        }
    }
}
