// MARK: - Native Display Renderer
// Main entry point for rendering native display UI using SwiftUI

import SwiftUI

// MARK: - Environment Key for Parent Size

/// Environment key for explicitly setting parent size (overrides GeometryReader)
public struct ParentSizeEnvironmentKey: EnvironmentKey {
    public static let defaultValue: CGSize? = nil
}

extension EnvironmentValues {
    /// Explicit parent size for NativeDisplayView layout calculations.
    /// Set this to provide a fixed parent size and avoid GeometryReader overhead.
    public var nativeDisplayParentSize: CGSize? {
        get { self[ParentSizeEnvironmentKey.self] }
        set { self[ParentSizeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Native Display View

/// Main entry point for rendering native display UI.
public struct NativeDisplayView: View {
    @Environment(\.nativeDisplayParentSize) private var environmentParentSize

    private let config: ResolvedConfig
    private let styleResolver: StyleResolver
    private let evaluator: VariableEvaluator
    private let actionHandler: ActionHandler?
    private let componentListener: NativeDisplayComponentListener?

    public init(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.config = config
        self.styleResolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)
        self.evaluator = VariableEvaluator(variables: config.variables)

        self.actionHandler = ActionHandler(
                    actionListener: actionListener,
                    componentListener: componentListener
                )
        self.componentListener = componentListener
    }

    public var body: some View {
        renderWithSizeResolution()
    }

    @ViewBuilder
    private func renderWithSizeResolution() -> some View {
        // ═══════════════════════════════════════════════════════════════
        // PRIORITY 1: Environment Override (ABSOLUTE PRIORITY)
        // ═══════════════════════════════════════════════════════════════
        // If integrator sets environment value, use it ALWAYS
        // - Bypasses ALL other logic (no config scanning, no GeometryReader)
        // - Works even if config has percentages, dynamic root, etc.
        // - This is the ONLY way to avoid GeometryReader when needed
        if let explicitSize = environmentParentSize {
            renderContent(parentSize: explicitSize)
        }
        // ═══════════════════════════════════════════════════════════════
        // Below logic only runs if NO environment override
        // ═══════════════════════════════════════════════════════════════
        else if let rootSize = config.rootExplicitSize() {
            // Priority 2: Root container has explicit fixed dimensions
            // Example: root is { width: 300dp, height: 400dp }
            // Even if children have percentages, they calculate from this fixed base
            // → Skip GeometryReader (performance win)
            renderContent(parentSize: rootSize)
        } else if !config.usesPercentageDimensions() {
            // Priority 3: No percentages anywhere → use screen size
            // Config uses only DP/SP/PX dimensions throughout entire tree
            // → Skip GeometryReader (performance win)
            let screenSize = UIScreen.main.bounds.size
            renderContent(parentSize: screenSize)
        } else {
            // Priority 4: GeometryReader (ONLY when truly needed)
            // Conditions to reach here:
            // - NO environment override AND
            // - Root uses percentages/match_parent/wrap_content AND
            // - Config contains percentages somewhere
            // → MUST use GeometryReader to measure parent constraints
            GeometryReader { geometry in
                renderContent(parentSize: geometry.size)
            }
        }
    }

    private func renderContent(parentSize: CGSize) -> some View {
        RenderNode(
            node: config.root,
            styleResolver: styleResolver,
            evaluator: evaluator,
            parentSize: parentSize,
            actionHandler: actionHandler,
            componentListener: componentListener
        )
    }
}

/// Recursively render a display node (container or element).
struct RenderNode: View {
    let node: NativeDisplayNode
    let styleResolver: StyleResolver
    let evaluator: VariableEvaluator
    let parentSize: CGSize
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?
    
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
        // Resolve style
        let resolvedStyle = styleResolver.resolveWithColors(node: node)
        
        let hasServerActions = node.actions != nil && !node.actions!.isEmpty
        let isClientInterested = componentListener?.getInterestedNodeIds()?.contains(node.id) ?? (componentListener != nil)
        let shouldApplyTappable = hasServerActions || isClientInterested
        let isButton = node.elementType == .button
        
        switch node {
        case .container(let container):
            let layoutModifier = LayoutModifier(layout: node.layout, parentSize: parentSize, nodeId: node.id)
            let offset = layoutModifier.calculateOffset()

            RenderContainer(
                container: container,
                styleResolver: styleResolver,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
            .modifier(layoutModifier)
            .modifier(DecorationModifier(style: resolvedStyle))
            .offset(x: offset.width, y: offset.height)
            .applyEntranceAnimation(node.animation)
            .applyTappable(
                            nodeId: node.id,
                            actions: shouldApplyTappable ? node.actions : nil,
                            actionHandler: actionHandler,
                            componentListener: componentListener
                        )
            .id(node.id)

        case .element(let element):
            let layoutModifier = LayoutModifier(layout: node.layout, parentSize: parentSize, nodeId: node.id)
            let offset = layoutModifier.calculateOffset()

            RenderElement(
                element: element,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize,
                actionHandler: actionHandler
            )
            .modifier(layoutModifier)
            .modifier(DecorationModifier(style: resolvedStyle))
            .offset(x: offset.width, y: offset.height)
            .applyEntranceAnimation(node.animation)
            .applyTappable(
                            nodeId: node.id,
                            actions: !isButton && shouldApplyTappable ? node.actions : nil,
                            actionHandler: actionHandler,
                            componentListener: !isButton ? componentListener : nil
                        )
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
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?

    var body: some View {
        let padding = container.layout?.padding
        let paddingInsets = EdgeInsets(
            top: padding?.resolveTop() ?? 0,
            leading: padding?.resolveLeft() ?? 0,
            bottom: padding?.resolveBottom() ?? 0,
            trailing: padding?.resolveRight() ?? 0
        )

        // Calculate the container's actual dimensions (considering explicit layout dimensions)
        let containerSize = calculateContainerSize(parentSize: parentSize, padding: paddingInsets)

        // Available size for children is the container size (after accounting for padding)
        // This ensures children get correct space even before LayoutModifier applies
        let availableSize = containerSize

        switch container.containerType {
        case .vertical:
            renderVerticalContainer(availableSize: availableSize)
                .padding(paddingInsets)

        case .horizontal:
            renderHorizontalContainer(availableSize: availableSize)
                .padding(paddingInsets)

        case .box:
            // For BOX containers, use ZStack with topLeading alignment
            // Children use .offset() (applied in LayoutModifier) to move from their natural position

            // DEBUG: Remove after fixing percentage offset issue
            let _ = print("🔷 BOX CONTAINER: id=\(container.id), containerSize=\(containerSize), children.count=\(container.children.count)")
            let _ = container.children.enumerated().forEach { index, child in
                print("  🔹 BOX CHILD [\(index)]: id=\(child.id), type=\(child), hasOffset=\(child.layout?.offset != nil)")
            }
            ZStack(alignment: .topLeading) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentSize: containerSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            .frame(width: containerSize.width, height: containerSize.height, alignment: .topLeading)
            .padding(paddingInsets)

        case .stack:
            // For STACK containers, use ZStack with center alignment (default for STACK)
            // Children use .offset() (applied in LayoutModifier) to move from their natural position
            ZStack(alignment: .center) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        styleResolver: styleResolver,
                        evaluator: evaluator,
                        parentSize: containerSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            .frame(width: containerSize.width, height: containerSize.height, alignment: .center)
            .padding(paddingInsets)

        case .gallery:
            RenderGallery(
                container: container,
                styleResolver: styleResolver,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: availableSize,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
            .padding(paddingInsets)
        }
    }

    /// Calculate the final container size.
    /// Uses explicit layout dimensions if specified, otherwise uses parentSize.
    /// This is used as availableSize for children and for percentage-based offset calculations.
    private func calculateContainerSize(parentSize: CGSize, padding: EdgeInsets) -> CGSize {
        let layout = container.layout

        // Calculate width
        let width: CGFloat
        if let w = layout?.width {
            if let special = w.special {
                width = special == .matchParent ? parentSize.width : 0
            } else {
                switch w.unit {
                case .dp, .px, .sp:
                    width = w.value
                case .percent:
                    width = parentSize.width * w.value / 100
                }
            }
        } else {
            width = parentSize.width
        }

        // Calculate height
        let height: CGFloat
        if let h = layout?.height {
            if let special = h.special {
                height = special == .matchParent ? parentSize.height : 0
            } else {
                switch h.unit {
                case .dp, .px, .sp:
                    height = h.value
                case .percent:
                    height = parentSize.height * h.value / 100
                }
            }
        } else {
            height = parentSize.height
        }

        // Return size after accounting for padding
        let finalSize = CGSize(
            width: max(0, width - padding.leading - padding.trailing),
            height: max(0, height - padding.top - padding.bottom)
        )

        // DEBUG: Remove after fixing percentage offset issue
        print("🔵 CONTAINER SIZE: container.id=\(container.id), type=\(container.containerType), parentSize=\(parentSize), calculatedSize=\(finalSize)")

        return finalSize
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
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
    let actionHandler: ActionHandler?
    
    var body: some View {
        let padding = element.layout?.padding
        let paddingInsets = EdgeInsets(
            top: padding?.resolveTop() ?? 0,
            leading: padding?.resolveLeft() ?? 0,
            bottom: padding?.resolveBottom() ?? 0,
            trailing: padding?.resolveRight() ?? 0
        )

        switch element.elementType {
        case .text:
            renderText()
                .padding(paddingInsets)

        case .image:
            renderImage()
                .padding(paddingInsets)

        case .button:
            renderButton()
                .padding(paddingInsets)

        case .video:
            renderVideo()
                .padding(paddingInsets)

        case .spacer:
            Color.clear
                .padding(paddingInsets)

        case .divider:
            renderDivider()
                .padding(paddingInsets)
        }
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
            if let onClick = element.actions?[ActionTriggers.onClick] {
                actionHandler?.handleAction(onClick, nodeId: element.id, interactionType: .click)
            }
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
    let nodeId: String?  // For debug logging

    init(layout: Layout?, parentSize: CGSize, nodeId: String? = nil) {
        self.layout = layout
        self.parentSize = parentSize
        self.nodeId = nodeId
    }

    func body(content: Content) -> some View {
        let width = calculateWidth()
        let height = calculateHeight()
        let maxWidth = calculateMaxWidth()
        let maxHeight = calculateMaxHeight()
        let aspectRatio = calculateAspectRatio()

        // DEBUG: Remove after fixing percentage offset issue
        let _ = nodeId.map { nodeId in
            print("📐 LAYOUT: nodeId=\(nodeId), width=\(width?.description ?? "nil"), height=\(height?.description ?? "nil")")
        }

        // Apply sizing only - offset will be applied after decorations
        if let ratio = aspectRatio {
            content
                .frame(width: width, height: height)
                .aspectRatio(ratio, contentMode: .fit)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .topLeading)
        } else {
            content
                .frame(width: width, height: height)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .topLeading)
        }
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
    /// Supports both DP and percentage-based offsets.
    /// All calculations are done upfront based on parentSize.
    func calculateOffset() -> CGSize {
        guard let offset = layout?.offset else {
            return .zero
        }

        // DEBUG: Remove after fixing percentage offset issue
        if let nodeId = nodeId {
            print("🟢 OFFSET: nodeId=\(nodeId), unit=\(offset.unit), x=\(offset.x), y=\(offset.y), parentSize=\(parentSize)")
        }

        let result: CGSize
        switch offset.unit {
        case .dp, .px, .sp:
            result = CGSize(width: offset.x, height: offset.y)
        case .percent:
            // Calculate percentage offset based on parent container size
            let offsetX = parentSize.width * offset.x / 100
            let offsetY = parentSize.height * offset.y / 100
            result = CGSize(width: offsetX, height: offsetY)
        }

        // DEBUG: Remove after fixing percentage offset issue
        if let nodeId = nodeId {
            print("🟢 OFFSET: nodeId=\(nodeId), CALCULATED: x=\(result.width), y=\(result.height)")
        }

        return result
    }

    /// Calculate aspect ratio if specified and valid.
    /// Returns nil if aspectRatio is not set, ≤ 0, or if both width AND height are explicitly set.
    private func calculateAspectRatio() -> CGFloat? {
        guard let aspectRatio = layout?.aspectRatio, aspectRatio > 0 else {
            return nil
        }

        // If both width and height are explicitly set (not WRAP_CONTENT or MATCH_PARENT),
        // aspect ratio is ignored to honor explicit dimensions
        let hasExplicitWidth = hasExplicitDimension(layout?.width)
        let hasExplicitHeight = hasExplicitDimension(layout?.height)

        if hasExplicitWidth && hasExplicitHeight {
            return nil  // Both dimensions explicit, ignore aspect ratio
        }

        return aspectRatio
    }

    /// Check if a dimension is explicitly set (not WRAP_CONTENT or MATCH_PARENT).
    private func hasExplicitDimension(_ dimension: Dimension?) -> Bool {
        guard let dimension = dimension else { return false }
        return dimension.special == nil  // Has value, not special dimension
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

extension NativeDisplayNode {
    var elementType: ElementType? {
        switch self {
        case .element(let element):
            return element.elementType
        case .container:
            return nil
        }
    }
}

