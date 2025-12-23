// MARK: - Native Display Renderer
// Main entry point for rendering native display UI using SwiftUI

import SwiftUI

/// Main entry point for rendering native display UI.
public struct NativeDisplayView: View {
    private let config: ResolvedConfig
    private let styleResolver: StyleResolver
    private let evaluator: VariableEvaluator
    
    public init(config: ResolvedConfig) {
        self.config = config
        self.styleResolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)
        self.evaluator = VariableEvaluator(variables: config.variables)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            RenderNode(
                node: config.root,
                styleResolver: styleResolver,
                evaluator: evaluator,
                parentStyle: nil,
                parentSize: geometry.size
            )
            .frame(width: geometry.size.width, alignment: .top)
        }
    }
}

/// Recursively render a display node (container or element).
struct RenderNode: View {
    let node: NativeDisplayNode
    let styleResolver: StyleResolver
    let evaluator: VariableEvaluator
    let parentStyle: Style?
    let parentSize: CGSize
    
    var body: some View {
        // Check visibility condition
        if let visibleExpr = node.visible {
            let isVisible = evaluator.evaluateBoolean(visibleExpr)
            if !isVisible {
                EmptyView()
            } else {
                renderContent()
            }
        } else {
            renderContent()
        }
    }
    
    @ViewBuilder
    private func renderContent() -> some View {
        // Resolve style with inheritance
        let resolvedStyle = styleResolver.resolveWithColors(node: node, parentStyle: parentStyle)
        
        switch node {
        case .container(let container):
            RenderContainer(
                container: container,
                styleResolver: styleResolver,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize
            )
            .modifier(LayoutModifier(layout: node.layout, parentSize: parentSize))
            .modifier(DecorationModifier(style: resolvedStyle))
            
        case .element(let element):
            RenderElement(
                element: element,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize
            )
            .modifier(LayoutModifier(layout: node.layout, parentSize: parentSize))
            .modifier(DecorationModifier(style: resolvedStyle))
        }
    }
}

/// Render a container with its children.
struct RenderContainer: View {
    let container: NativeDisplayContainer
    let styleResolver: StyleResolver
    let evaluator: VariableEvaluator
    let resolvedStyle: Style
    let parentSize: CGSize
    
    var body: some View {
        let padding = container.layout?.padding
        let paddingInsets = EdgeInsets(
            top: padding?.resolveTop() ?? 0,
            leading: padding?.resolveLeft() ?? 0,
            bottom: padding?.resolveBottom() ?? 0,
            trailing: padding?.resolveRight() ?? 0
        )
        
        // Calculate available size after padding
        let availableSize = CGSize(
            width: max(0, parentSize.width - paddingInsets.leading - paddingInsets.trailing),
            height: max(0, parentSize.height - paddingInsets.top - paddingInsets.bottom)
        )
        
        Group {
            switch container.containerType {
            case .vertical:
                renderVerticalContainer(availableSize: availableSize)
                
            case .horizontal:
                renderHorizontalContainer(availableSize: availableSize)
                
            case .box:
                ZStack(alignment: .topLeading) {
                    ForEach(container.children.indices, id: \.self) { index in
                        RenderNode(
                            node: container.children[index],
                            styleResolver: styleResolver,
                            evaluator: evaluator,
                            parentStyle: resolvedStyle,
                            parentSize: availableSize
                        )
                    }
                }
                
            case .stack:
                ZStack {
                    ForEach(container.children.indices, id: \.self) { index in
                        RenderNode(
                            node: container.children[index],
                            styleResolver: styleResolver,
                            evaluator: evaluator,
                            parentStyle: resolvedStyle,
                            parentSize: availableSize
                        )
                    }
                }
                
            case .gallery:
                RenderGallery(
                    container: container,
                    styleResolver: styleResolver,
                    evaluator: evaluator,
                    resolvedStyle: resolvedStyle,
                    parentSize: availableSize
                )
            }
        }
        .padding(paddingInsets)
    }
    
    @ViewBuilder
    private func renderVerticalContainer(availableSize: CGSize) -> some View {
        let arrangement = container.layout?.arrangement ?? .default
        
        switch arrangement.strategy {
        case .spaced:
            VStack(alignment: .leading, spacing: arrangement.spacing ?? 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .spaceBetween:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                    
                    if index < container.children.count - 1 {
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .spaceEvenly:
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .spaceAround:
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                    
                    if index < container.children.count - 1 {
                        Spacer()
                        Spacer()
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .start:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .center:
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
        case .end:
            VStack(alignment: .trailing, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    private func renderHorizontalContainer(availableSize: CGSize) -> some View {
        let arrangement = container.layout?.arrangement ?? .default
        
        switch arrangement.strategy {
        case .spaced:
            HStack(alignment: .center, spacing: arrangement.spacing ?? 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
            }
            
        case .spaceBetween:
            HStack(alignment: .center, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                    
                    if index < container.children.count - 1 {
                        Spacer()
                    }
                }
            }
            
        case .spaceEvenly:
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                    Spacer()
                }
            }
            
        case .spaceAround:
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                    
                    if index < container.children.count - 1 {
                        Spacer()
                        Spacer()
                    }
                }
                Spacer(minLength: 0)
            }
            
        case .start:
            HStack(alignment: .center, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
                Spacer(minLength: 0)
            }
            
        case .center:
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
                Spacer()
            }
            
        case .end:
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentStyle: resolvedStyle,
                        parentSize: availableSize
                    )
                }
            }
        }
    }
}

/// Render an element based on its type.
struct RenderElement: View {
    let element: NativeDisplayElement
    let evaluator: VariableEvaluator
    let resolvedStyle: Style
    let parentSize: CGSize
    
    var body: some View {
        let padding = element.layout?.padding
        let paddingInsets = EdgeInsets(
            top: padding?.resolveTop() ?? 0,
            leading: padding?.resolveLeft() ?? 0,
            bottom: padding?.resolveBottom() ?? 0,
            trailing: padding?.resolveRight() ?? 0
        )
        
        Group {
            switch element.elementType {
            case .text:
                renderText()
                
            case .image:
                renderImage()
                
            case .button:
                renderButton()
                
            case .video:
                renderVideo()
                
            case .spacer:
                Color.clear
                
            case .divider:
                renderDivider()
            }
        }
        .padding(paddingInsets)
    }
    
    @ViewBuilder
    private func renderText() -> some View {
        let text = element.bindings["text"].map { evaluator.evaluateString($0) } ?? ""
        
        Text(text)
            .foregroundColor(ColorParser.parse(resolvedStyle.textColor) ?? .primary)
            .font(.system(size: resolvedStyle.fontSize ?? 14))
            .fontWeight(resolveFontWeight(resolvedStyle.fontWeight))
            .multilineTextAlignment(resolveTextAlign(resolvedStyle.textAlign))
            .lineSpacing(max(0, (resolvedStyle.lineHeight ?? 0) - (resolvedStyle.fontSize ?? 14)))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private func renderImage() -> some View {
        let imageUrl = element.bindings["url"].map { evaluator.evaluateString($0) } ?? ""
        
        if !imageUrl.isEmpty, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("No Image")
                        .foregroundColor(.gray)
                        .font(.caption)
                )
        }
    }
    
    @ViewBuilder
    private func renderButton() -> some View {
        let buttonText = element.bindings["text"].map { evaluator.evaluateString($0) } ?? "Button"
        
        Button(action: {
            // TODO: Handle actions
        }) {
            Text(buttonText)
                .foregroundColor(ColorParser.parse(resolvedStyle.textColor) ?? .white)
                .font(.system(size: resolvedStyle.fontSize ?? 16))
                .fontWeight(resolveFontWeight(resolvedStyle.fontWeight))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ColorParser.parse(resolvedStyle.backgroundColor) ?? Color.blue)
        .cornerRadius(resolvedStyle.borderRadius ?? 8)
    }
    
    @ViewBuilder
    private func renderVideo() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
            
            Text("Video Player")
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func renderDivider() -> some View {
        let dividerConfig = element.dividerConfig ?? DividerConfig()
        let dividerColor = ColorParser.parse(dividerConfig.color) ?? Color.gray.opacity(0.5)
        
        switch dividerConfig.orientation {
        case .horizontal:
            Rectangle()
                .fill(dividerColor)
                .frame(height: dividerConfig.thickness)
                .frame(maxWidth: .infinity)
                
        case .vertical:
            Rectangle()
                .fill(dividerColor)
                .frame(width: dividerConfig.thickness)
        }
    }
    
    private func resolveFontWeight(_ weight: FontWeight?) -> Font.Weight {
        switch weight {
        case .light: return .light
        case .normal: return .regular
        case .medium: return .medium
        case .bold: return .bold
        case .none: return .regular
        }
    }
    
    private func resolveTextAlign(_ align: String?) -> TextAlignment {
        switch align?.lowercased() {
        case "left": return .leading
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }
}

// MARK: - Layout Modifier

struct LayoutModifier: ViewModifier {
    let layout: Layout?
    let parentSize: CGSize
    
    func body(content: Content) -> some View {
        let width = calculateWidth()
        let height = calculateHeight()
        let maxWidth = calculateMaxWidth()
        let maxHeight = calculateMaxHeight()
        let offset = calculateOffset()
        
        content
            .frame(width: width, height: height)
            .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .topLeading)
            .offset(x: offset.x, y: offset.y)
    }
    
    private func calculateWidth() -> CGFloat? {
        guard let width = layout?.width else { return nil }
        
        if let special = width.special {
            switch special {
            case .wrapContent:
                return nil
            case .matchParent:
                return nil // Use maxWidth instead
            }
        }
        
        switch width.unit {
        case .dp, .px, .sp:
            return width.value > 0 ? width.value : nil
        case .percent:
            return parentSize.width * width.value / 100
        }
    }
    
    private func calculateHeight() -> CGFloat? {
        guard let height = layout?.height else { return nil }
        
        if let special = height.special {
            switch special {
            case .wrapContent:
                return nil
            case .matchParent:
                return nil // Use maxHeight instead
            }
        }
        
        switch height.unit {
        case .dp, .px, .sp:
            return height.value > 0 ? height.value : nil
        case .percent:
            return parentSize.height * height.value / 100
        }
    }
    
    private func calculateMaxWidth() -> CGFloat? {
        guard let width = layout?.width else { return nil }
        
        if let special = width.special {
            switch special {
            case .matchParent:
                return .infinity
            case .wrapContent:
                return nil
            }
        }
        
        if width.unit == .percent && width.value >= 100 {
            return .infinity
        }
        
        return nil
    }
    
    private func calculateMaxHeight() -> CGFloat? {
        guard let height = layout?.height else { return nil }
        
        if let special = height.special {
            switch special {
            case .matchParent:
                return .infinity
            case .wrapContent:
                return nil
            }
        }
        
        return nil
    }
    
    /// Calculate offset for absolute positioning.
    /// Supports DP and percentage-based offsets.
    private func calculateOffset() -> CGSize {
        guard let offset = layout?.offset else {
            return .zero
        }
        
        switch offset.unit {
        case .dp, .px, .sp:
            return CGSize(width: offset.x, height: offset.y)
        case .percent:
            return CGSize(
                width: parentSize.width * offset.x / 100,
                height: parentSize.height * offset.y / 100
            )
        }
    }
}

// MARK: - Decoration Modifier

struct DecorationModifier: ViewModifier {
    let style: Style
    
    func body(content: Content) -> some View {
        let cornerRadius = style.borderRadius ?? 0
        
        content
            .background(
                Group {
                    if let background = style.background {
                        BackgroundView(background: background)
                            .cornerRadius(cornerRadius)
                    } else if let bgColor = style.backgroundColor {
                        ColorParser.parse(bgColor)
                            .cornerRadius(cornerRadius)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                Group {
                    if let borderWidth = style.borderWidth, borderWidth > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                ColorParser.parse(style.borderColor) ?? .gray,
                                lineWidth: borderWidth
                            )
                    }
                }
            )
            .shadow(
                color: style.shadowRadius ?? 0 > 0
                    ? (ColorParser.parse(style.shadowColor)?.opacity(0.25) ?? Color.black.opacity(0.15))
                    : .clear,
                radius: style.shadowRadius ?? 0,
                x: style.shadowOffsetX ?? 0,
                y: style.shadowOffsetY ?? 2
            )
            .opacity(Double(style.opacity ?? 1))
    }
}

// MARK: - Color Parser

/// Utility to parse hex color strings to SwiftUI Color.
public struct ColorParser {
    /// Parse hex color string to SwiftUI Color.
    public static func parse(_ colorString: String?) -> Color? {
        guard let colorString = colorString else { return nil }
        
        var hex = colorString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        
        guard hex.count == 6 || hex.count == 8 else { return nil }
        
        var rgbValue: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgbValue) else { return nil }
        
        if hex.count == 6 {
            return Color(
                red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgbValue & 0x0000FF) / 255.0
            )
        } else {
            return Color(
                red: Double((rgbValue & 0xFF000000) >> 24) / 255.0,
                green: Double((rgbValue & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgbValue & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgbValue & 0x000000FF) / 255.0
            )
        }
    }
}
