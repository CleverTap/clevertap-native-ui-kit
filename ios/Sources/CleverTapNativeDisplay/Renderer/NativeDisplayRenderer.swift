// MARK: - Native Display Renderer
// Main entry point for rendering native display UI using SwiftUI

import SwiftUI
import AVKit
import AVFoundation
import UIKit
import ImageIO

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
    private let resolvedStyles: [String: Style]   // Pre-resolved, computed once in init
    private let evaluator: VariableEvaluator
    private let actionHandler: ActionHandler?
    private let componentListener: NativeDisplayComponentListener?

    public init(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.config = config
        // Pre-resolve all node styles once — views get O(1) lookup, no resolution at render time
        let resolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)
        self.resolvedStyles = resolver.resolveAll(node: config.root)
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
            resolvedStyles: resolvedStyles,
            evaluator: evaluator,
            parentSize: parentSize,
            actionHandler: actionHandler,
            componentListener: componentListener,
            isRoot: true
        )
    }
}

/// Recursively render a display node (container or element).
struct RenderNode: View {
    let node: NativeDisplayNode
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    let parentSize: CGSize
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?
    var isRoot: Bool = false
    
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
        // Look up pre-resolved style
        let resolvedStyle = resolvedStyles[node.id] ?? Style.empty
        
        let hasServerActions = node.actions != nil && !node.actions!.isEmpty
        let isClientInterested = componentListener?.getInterestedNodeIds()?.contains(node.id) ?? (componentListener != nil)
        let shouldApplyTappable = hasServerActions || isClientInterested
        let isButton = node.elementType == .button
        
        switch node {
        case .container(let container):
            let layoutMod = LayoutModifier(layout: node.layout, parentSize: parentSize, nodeId: node.id)
            let offsetValue = layoutMod.calculateOffset()

            RenderContainer(
                container: container,
                resolvedStyles: resolvedStyles,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
            .modifier(layoutMod)
            .modifier(DecorationModifier(style: resolvedStyle))
            .offset(x: offsetValue.width, y: offsetValue.height)
            .applyEntranceAnimation(node.animation)
            .applyTappable(
                nodeId: node.id,
                actions: shouldApplyTappable ? node.actions : nil,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
            .onAppear {
                if isRoot {
                    actionHandler?.fireSystemEvent(eventName: "Notification Viewed", deduplicate: true)
                }
                if let action = node.actions?[ActionTriggers.onAppear] {
                    actionHandler?.handleLifecycleAction(action, nodeId: node.id)
                }
            }
            .onDisappear {
                if let action = node.actions?[ActionTriggers.onDisappear] {
                    actionHandler?.handleLifecycleAction(action, nodeId: node.id)
                }
            }
            .id(node.id)

        case .element(let element):
            let layoutMod = LayoutModifier(layout: node.layout, parentSize: parentSize, nodeId: node.id)
            let offsetValue = layoutMod.calculateOffset()

            RenderElement(
                element: element,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize,
                actionHandler: actionHandler
            )
            .modifier(layoutMod)
            // Text elements must not be clipped by the decoration layer — text that
            // overflows its layout height should remain visible (matching Android's
            // TextView default). Truncation is managed via maxLines/overflow in JSON.
            .modifier(DecorationModifier(style: resolvedStyle, clipsContent: element.elementType != .text))
            .offset(x: offsetValue.width, y: offsetValue.height)
            .applyEntranceAnimation(node.animation)
            .applyTappable(
                nodeId: node.id,
                // Buttons handle gestures explicitly inside renderButton() via simultaneousGesture.
                // Skip applyTappable for buttons to prevent double-firing of onClick.
                actions: !isButton && shouldApplyTappable ? node.actions : nil,
                actionHandler: actionHandler,
                componentListener: !isButton ? componentListener : nil
            )
            .onAppear {
                if isRoot {
                    actionHandler?.fireSystemEvent(eventName: "Notification Viewed", deduplicate: true)
                }
                if let action = node.actions?[ActionTriggers.onAppear] {
                    actionHandler?.handleLifecycleAction(action, nodeId: node.id)
                }
            }
            .onDisappear {
                if let action = node.actions?[ActionTriggers.onDisappear] {
                    actionHandler?.handleLifecycleAction(action, nodeId: node.id)
                }
            }
        }
    }
}

/// Render a container with its children.
struct RenderContainer: View {
    let container: NativeDisplayContainer
    let resolvedStyles: [String: Style]
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

        // Determine which axes are wrap_content — those axes must NOT receive a hard frame constraint.
        // wrap_content lets SwiftUI measure the intrinsic content size on that axis.
        let widthIsWrap = container.layout?.width?.special == .wrapContent
        let heightIsWrap = container.layout?.height?.special == .wrapContent

        // Available size for children is the container size (after accounting for padding)
        // This ensures children get correct space even before LayoutModifier applies
        let availableSize = containerSize

        switch container.containerType {
        case .vertical:
            renderVerticalContainer(
                availableSize: availableSize,
                containerHeight: containerSize.height,
                heightIsWrap: heightIsWrap
            )
            // Clip children to the content area BEFORE adding padding.
            // Without this, SwiftUI VStack children that overflow the content frame
            // render into the padding space, visually eating the bottom (and trailing)
            // padding. Android LinearLayout clips children by default (clipChildren=true),
            // so .clipped() here restores parity with that behaviour.
            .clipped()
            .padding(paddingInsets)

        case .horizontal:
            renderHorizontalContainer(availableSize: availableSize)
                // Same reason as vertical — clip before padding to preserve trailing padding.
                .clipped()
                .padding(paddingInsets)

        case .box:
            // For BOX containers, use ZStack with topLeading alignment
            // Children use .offset() (applied in LayoutModifier) to move from their natural position
            ZStack(alignment: .topLeading) {
                ForEach(container.children, id: \.id) { child in
                    RenderNode(
                        node: child,
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: containerSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            .frame(
                width: widthIsWrap ? nil : containerSize.width,
                height: heightIsWrap ? nil : containerSize.height,
                alignment: .topLeading
            )
            .padding(paddingInsets)

        case .gallery:
            RenderGallery(
                container: container,
                resolvedStyles: resolvedStyles,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
            .padding(paddingInsets)
        }
    }

    /// Calculate the final container size.
    /// Uses explicit layout dimensions if specified, otherwise uses parentSize.
    /// This is used as availableSize for children and for percentage-based offset calculations.
    ///
    /// When an aspect ratio is specified and dimensions are not both truly fixed (DP/PX/SP),
    /// the aspect ratio constrains the result — matching `LayoutModifier.resolvedDimensions()`
    /// and Android's behavior where aspect ratio is applied before sizing.
    private func calculateContainerSize(parentSize: CGSize, padding: EdgeInsets) -> CGSize {
        let layout = container.layout

        // Calculate raw width
        let rawWidth: CGFloat
        if let w = layout?.width {
            if w.special != nil {
                rawWidth = parentSize.width
            } else {
                switch w.unit {
                case .dp, .px, .sp:
                    rawWidth = w.value
                case .percent:
                    rawWidth = parentSize.width * w.value / 100
                }
            }
        } else {
            rawWidth = parentSize.width
        }

        // Calculate raw height
        let rawHeight: CGFloat
        if let h = layout?.height {
            if h.special != nil {
                rawHeight = parentSize.height
            } else {
                switch h.unit {
                case .dp, .px, .sp:
                    rawHeight = h.value
                case .percent:
                    rawHeight = parentSize.height * h.value / 100
                }
            }
        } else {
            rawHeight = parentSize.height
        }

        // Apply aspect ratio constraint — must match LayoutModifier.resolvedDimensions() logic.
        // Only skip when both dimensions are truly fixed (DP/PX/SP, not percent).
        let width: CGFloat
        let height: CGFloat
        if let aspectRatio = layout?.aspectRatio, aspectRatio > 0 {
            let widthIsFixed = layout?.width.map { $0.special == nil && $0.unit != .percent } ?? false
            let heightIsFixed = layout?.height.map { $0.special == nil && $0.unit != .percent } ?? false

            if widthIsFixed && heightIsFixed {
                // Both absolute — aspect ratio ignored
                width = rawWidth
                height = rawHeight
            } else {
                // Aspect ratio constrains: width is primary, derive height
                width = rawWidth
                height = rawWidth / aspectRatio
            }
        } else {
            width = rawWidth
            height = rawHeight
        }

        // Return size after accounting for padding
        return CGSize(
            width: max(0, width - padding.leading - padding.trailing),
            height: max(0, height - padding.top - padding.bottom)
        )
    }
    

    @ViewBuilder
    private func renderVerticalContainer(availableSize: CGSize, containerHeight: CGFloat, heightIsWrap: Bool) -> some View {
        let arrangement = container.layout?.arrangement ?? .default

        switch arrangement.strategy {
        case .spaced:
            VStack(alignment: .leading, spacing: arrangement.spacing ?? 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            .frame(height: heightIsWrap ? nil : containerHeight, alignment: .top)
            .frame(maxWidth: .infinity)

        case .spaceBetween:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
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
            .frame(height: heightIsWrap ? nil : containerHeight, alignment: .top)
            .frame(maxWidth: .infinity)

        case .spaceEvenly:
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                    Spacer()
                }
            }
            .frame(height: heightIsWrap ? nil : containerHeight, alignment: .top)
            .frame(maxWidth: .infinity)

        case .spaceAround:
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
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
            .frame(height: heightIsWrap ? nil : containerHeight, alignment: .top)
            .frame(maxWidth: .infinity)

        case .start:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
                Spacer(minLength: 0)
            }
            .frame(height: heightIsWrap ? nil : containerHeight, alignment: .top)
            .frame(maxWidth: .infinity)

        case .center:
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
                Spacer()
            }
            .frame(height: heightIsWrap ? nil : containerHeight, alignment: .top)
            .frame(maxWidth: .infinity)

        case .end:
            VStack(alignment: .trailing, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            .frame(height: heightIsWrap ? nil : containerHeight, alignment: .top)
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private func renderHorizontalContainer(availableSize: CGSize) -> some View {
        let arrangement = container.layout?.arrangement ?? .default
        
        switch arrangement.strategy {
        case .spaced:
            HStack(alignment: .top, spacing: arrangement.spacing ?? 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            
        case .spaceBetween:
            HStack(alignment: .top, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
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
            HStack(alignment: .top, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                    Spacer()
                }
            }
            
        case .spaceAround:
            HStack(alignment: .top, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
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
            HStack(alignment: .top, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
                Spacer(minLength: 0)
            }
            
        case .center:
            HStack(alignment: .top, spacing: 0) {
                Spacer()
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
                Spacer()
            }
            
        case .end:
            HStack(alignment: .top, spacing: 0) {
                Spacer(minLength: 0)
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
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

        case .html:
            #if os(iOS)
            renderHtml()
                .padding(paddingInsets)
            #else
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("HTML not supported on this platform")
                        .foregroundColor(.gray)
                        .font(.caption)
                )
                .padding(paddingInsets)
            #endif
        }
    }
    
    @ViewBuilder
    private func renderText() -> some View {
        let text = element.bindings["text"].map { evaluator.evaluateString($0) } ?? ""
        let textProps = resolvedStyle.extractTextProperties()
        let textAlignment = resolveTextAlign(textProps.align)

        // wrap_content elements must NOT expand — the element IS its text width.
        // All other width modes (match_parent, fixed dp, percent) need the Text to fill
        // the allocated width so that .multilineTextAlignment() is visually effective.
        // Without this, a 50pt "Hello" placed in a 300pt frame is always left-anchored
        // regardless of textAlign, because alignment happens within the Text's own bounds.
        let isWrapContent = element.layout?.width?.special == .wrapContent

        // Map TextAlignment → Alignment for the frame's horizontal axis.
        // Vertical positioning is handled by LayoutModifier's topLeading alignment.
        // Computed via closure so the switch is not inside the @ViewBuilder context.
        let frameAlignment: Alignment = {
            switch textAlignment {
            case .center:   return .center
            case .trailing: return .trailing
            default:        return .leading
            }
        }()

        // Build the styled Text as a Text value (all Text modifiers return Text).
        let coreText = Text(text)
            .foregroundColor(ColorParser.parse(textProps.color) ?? .primary)
            .font(.system(size: textProps.size ?? 14))
            .fontWeight(resolveFontWeight(textProps.weight))
            .strikethrough(textProps.decoration == .strikethrough)
            .underline(textProps.decoration == .underline)
            .multilineTextAlignment(textAlignment)
            .lineSpacing(max(0, (textProps.lineHeight ?? 0) - (textProps.size ?? 14)))

        if isWrapContent {
            coreText
                .fixedSize(horizontal: false, vertical: true)
        } else {
            coreText
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
        }
    }
    
    @ViewBuilder
    private func renderImage() -> some View {
        let imageUrl = element.bindings["url"].map { evaluator.evaluateString($0) } ?? ""

        if !imageUrl.isEmpty, let url = URL(string: imageUrl) {
            // Map ImageFit to ContentMode
            let contentMode: ContentMode = {
                switch element.imageConfig?.fit ?? .crop {
                case .crop:    return .fill   // Fill, may crop edges
                case .contain: return .fit    // Fit within bounds
                case .fill:    return .fill   // Stretch (approximation, same as crop)
                case .tile:    return .fill   // Tile not supported for single images
                }
            }()

            // Check if this is a GIF (auto-detect or explicit)
            let isGIF = isAnimatedGIF(url: url, config: element.imageConfig)

            if isGIF {
                // Use custom GIF renderer.
                // .frame(maxWidth/maxHeight: .infinity) is required so the UIViewRepresentable
                // expands to fill the space allocated by LayoutModifier — without it the
                // UIImageView uses its intrinsic pixel size instead of the layout bounds.
                GIFImage(url: url, contentMode: contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                // Use standard AsyncImage for static images
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
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

    private func isAnimatedGIF(url: URL, config: ImageConfig?) -> Bool {
        // Explicit control: if animated flag is set, use it
        if let animated = config?.animated {
            return animated
        }

        // Auto-detect using multiple strategies
        let urlString = url.absoluteString.lowercased()

        // Strategy 1: Check file extension
        if urlString.hasSuffix(".gif") || urlString.contains(".gif?") {
            return true
        }

        // Strategy 2: Check known GIF hosting domains and patterns
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        let knownGIFHosts = ["giphy.com", "tenor.com", "gfycat.com", "imgur.com"]
        let gifPathPatterns = ["/gif/", "/giphy/", "/media/"]

        for gifHost in knownGIFHosts {
            if host.contains(gifHost) {
                return true
            }
        }

        for pattern in gifPathPatterns {
            if path.contains(pattern) {
                return true
            }
        }

        // Strategy 3: If still ambiguous, default to false
        // User can set animated: true explicitly in JSON config
        return false
    }
    
    @ViewBuilder
    private func renderButton() -> some View {
        let buttonText = element.bindings["text"].map { evaluator.evaluateString($0) } ?? "Button"
        let textProps = resolvedStyle.extractTextProperties()

        let onLongPress = element.actions?[ActionTriggers.onLongPress]
        let onDoubleTap = element.actions?[ActionTriggers.onDoubleTap]

        Button(action: {
            // Fire system event for button click
            actionHandler?.fireSystemEvent(
                eventName: "Notification Clicked",
                properties: ["nodeId": element.id]
            )
            if let onClick = element.actions?[ActionTriggers.onClick] {
                actionHandler?.handleAction(onClick, nodeId: element.id, interactionType: .click)
            }
        }) {
            Text(buttonText)
                .foregroundColor(ColorParser.parse(textProps.color) ?? .white)
                .font(.system(size: textProps.size ?? 16))
                .fontWeight(resolveFontWeight(textProps.weight))
                .strikethrough(textProps.decoration == .strikethrough)
                .underline(textProps.decoration == .underline)
                .multilineTextAlignment(resolveTextAlign(textProps.align))
                .lineSpacing(max(0, (textProps.lineHeight ?? 0) - (textProps.size ?? 16)))
                .lineLimit(textProps.maxLines)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .ifLet(onLongPress) { view, action in
            view.simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        actionHandler?.handleAction(action, nodeId: element.id, interactionType: .longPress)
                    }
            )
        }
        .ifLet(onDoubleTap) { view, action in
            view.simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        actionHandler?.handleAction(action, nodeId: element.id, interactionType: .doubleTap)
                    }
            )
        }
    }

    @ViewBuilder
    private func renderVideo() -> some View {
        let videoUrl = element.bindings["url"].map { evaluator.evaluateString($0) } ?? ""

        let autoPlay = element.bindings["autoPlay"].map { evaluator.evaluateBoolean($0) } ?? false
        let loop = element.bindings["loop"].map { evaluator.evaluateBoolean($0) } ?? false
        let muted = element.bindings["muted"].map { evaluator.evaluateBoolean($0) } ?? false
        let showControls = element.bindings["showControls"].map { evaluator.evaluateBoolean($0) } ?? true
        let showFullscreen = element.bindings["showFullscreen"].map { evaluator.evaluateBoolean($0) } ?? true

        if !videoUrl.isEmpty, let url = URL(string: videoUrl) {
            VideoPlayerView(
                url: url,
                autoPlay: autoPlay,
                loop: loop,
                muted: muted,
                showControls: showControls,
                showFullscreen: showFullscreen
            )
        } else {
            // Fallback UI
            Rectangle()
                .fill(Color.black)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "video.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No Video")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                )
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
    
    #if os(iOS)
    @ViewBuilder
    private func renderHtml() -> some View {
        let html = element.bindings["html"].map { evaluator.evaluateString($0) }
        let url = element.bindings["url"].map { evaluator.evaluateString($0) }
        let config = element.htmlConfig ?? HtmlConfig()

        if (html != nil && !html!.isEmpty) || (url != nil && !url!.isEmpty) {
            HtmlWebView(
                html: html,
                url: url,
                config: config
            )
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("No HTML Content")
                        .foregroundColor(.gray)
                        .font(.caption)
                )
        }
    }
    #endif

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
        let dims = resolvedDimensions()
        let maxWidth = calculateMaxWidth()
        let maxHeight = calculateMaxHeight()

        // Apply sizing only - offset will be applied after decorations
        // alignment: .topLeading ensures content anchors to top-start when the frame
        // is larger than the content's natural size (matches Android's default top-start behaviour)
        if dims.useAspectRatioModifier, let ratio = calculateAspectRatio() {
            content
                .frame(width: dims.width, height: dims.height, alignment: .topLeading)
                .aspectRatio(ratio, contentMode: .fit)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .topLeading)
        } else {
            content
                .frame(width: dims.width, height: dims.height, alignment: .topLeading)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .topLeading)
        }
    }

    /// Resolves the final width and height, deriving the missing dimension from aspect ratio
    /// when the other dimension is a known value. Matches Android's behavior where
    /// Modifier.aspectRatio is applied BEFORE sizing constraints, so it wins over
    /// percentage-based dimensions.
    ///
    /// Aspect ratio is only skipped when both dimensions are truly fixed (DP/PX/SP),
    /// matching Android's `doesNotHaveFixedWidth = !(hasFixedWidth && hasFixedHeight)`.
    private func resolvedDimensions() -> (width: CGFloat?, height: CGFloat?, useAspectRatioModifier: Bool) {
        let explicitWidth = calculateWidth()
        let explicitHeight = calculateHeight()
        guard let ratio = calculateAspectRatio() else {
            return (explicitWidth, explicitHeight, false)
        }

        // Check if both dimensions use truly fixed units (DP/PX/SP, not percent).
        // Matches Android: hasFixedWidth = unit in [DP, PX] && special == null
        let widthIsFixed = layout?.width.map { $0.special == nil && $0.unit != .percent } ?? false
        let heightIsFixed = layout?.height.map { $0.special == nil && $0.unit != .percent } ?? false

        if widthIsFixed && heightIsFixed {
            // Both dimensions are absolute — aspect ratio is ignored (matches Android)
            return (explicitWidth, explicitHeight, false)
        }

        if let w = explicitWidth {
            // Width known → derive height from aspect ratio
            return (w, w / ratio, false)
        }
        if let h = explicitHeight {
            // Height known → derive width from aspect ratio
            return (h * ratio, h, false)
        }
        // Both unresolved (match_parent/wrap_content) → fall back to SwiftUI modifier
        return (nil, nil, true)
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

        // Only ignore aspect ratio when both dimensions are truly fixed (DP/PX/SP).
        // Percentage dimensions are flexible and should be constrained by aspect ratio.
        // Matches Android: doesNotHaveFixedWidth = !(hasFixedWidth && hasFixedHeight)
        // where hasFixed = special == nil && unit in [DP, PX]
        let widthIsFixed = hasFixedDimension(layout?.width)
        let heightIsFixed = hasFixedDimension(layout?.height)

        if widthIsFixed && heightIsFixed {
            return nil  // Both dimensions are absolute fixed values, ignore aspect ratio
        }
        
        // If height was already derived from aspect ratio in calculateHeight(),
        // don't apply the SwiftUI .aspectRatio() modifier (it would constrain
        // to the parent's proposed size which may be wrong, e.g. in ScrollView)
        if layout?.height == nil, widthIsFixed, calculateWidth() ?? 0 > 0 {
            return nil  // Height already computed from width * aspectRatio
        }

        return aspectRatio
    }

    /// Check if a dimension uses a truly fixed unit (DP/PX/SP, not percent or special).
    private func hasFixedDimension(_ dimension: Dimension?) -> Bool {
        guard let dimension = dimension else { return false }
        return dimension.special == nil && dimension.unit != .percent
    }
}

// MARK: - Clip If Needed

/// Conditionally applies `clipShape(RoundedRectangle(cornerRadius:))`.
/// Extracted as a separate ViewModifier so that `DecorationModifier.body` can
/// branch on `enabled` without violating `@ViewBuilder` result-type constraints.
private struct ClipIfNeeded: ViewModifier {
    let cornerRadius: CGFloat
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
        }
    }
}

// MARK: - Decoration Modifier

struct DecorationModifier: ViewModifier {
    let style: Style
    /// Whether to clip the content to its frame using `cornerRadius`.
    /// Pass `false` for TEXT elements so that text can overflow its layout bounds
    /// naturally (matching Android's TextView default behaviour, where clip is opt-in
    /// via `maxLines` / `overflow`, not forced by the decoration layer).
    var clipsContent: Bool = true

    func body(content: Content) -> some View {
        // Extract property groups for better code organization
        let borderProps = style.extractBorderProperties()
        let shadowProps = style.extractShadowProperties()
        let visualProps = style.extractVisualProperties()

        let cornerRadius = borderProps.radius ?? 0

        content
            // Apply background
            .background(
                Group {
                    if let background = visualProps.background {
                        BackgroundView(background: background)
                            .cornerRadius(cornerRadius)
                    } else if let bgColor = visualProps.backgroundColor {
                        ColorParser.parse(bgColor)
                            .cornerRadius(cornerRadius)
                    }
                }
            )
            // Apply clip — skipped for text elements so text is not hard-clipped to
            // its frame height. Truncation is controlled by maxLines/overflow instead.
            .modifier(ClipIfNeeded(cornerRadius: cornerRadius, enabled: clipsContent))
            // Apply border
            .overlay(
                Group {
                    if let borderWidth = borderProps.width, borderWidth > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                ColorParser.parse(borderProps.color) ?? .gray,
                                lineWidth: borderWidth
                            )
                    }
                }
            )
            // Apply shadow
            .shadow(
                color: shadowProps.radius ?? 0 > 0
                    ? (ColorParser.parse(shadowProps.color)?.opacity(0.25) ?? Color.black.opacity(0.15))
                    : .clear,
                radius: shadowProps.radius ?? 0,
                x: shadowProps.offsetX ?? 0,
                y: shadowProps.offsetY ?? 2
            )
            // Apply opacity
            .opacity(Double(visualProps.opacity ?? 1))
    }
}

// MARK: - Color Parser

/// Utility to parse hex color strings to SwiftUI Color.
/// Supports #RRGGBB (6 chars) and #RRGGBBAA (8 chars, RGBA format).
public struct ColorParser {
    /// Parse hex color string to SwiftUI Color.
    /// - #RRGGBB: 6-character RGB (full opacity)
    /// - #RRGGBBAA: 8-character RGBA (alpha in last byte)
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
            // Format: #RRGGBBAA (alpha in lowest byte, RGBA web standard)
            return Color(
                red: Double((rgbValue & 0xFF000000) >> 24) / 255.0,      // RR byte
                green: Double((rgbValue & 0x00FF0000) >> 16) / 255.0,    // GG byte
                blue: Double((rgbValue & 0x0000FF00) >> 8) / 255.0,     // BB byte
                opacity: Double((rgbValue & 0x000000FF)) / 255.0         // AA byte
            )
        }
    }
}

// MARK: - Video Player Components

/// Manages AVPlayer lifecycle and state for video playback
private class PlayerManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false

    var player: AVPlayer?
    private var playerObserver: NSObjectProtocol?
    private var timeObserver: Any?

    func setupPlayer(url: URL, autoPlay: Bool, loop: Bool, muted: Bool) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = muted
        self.isMuted = muted

        // Setup loop observer (BEST PRACTICE: specify object parameter)
        if loop {
            playerObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,  // IMPORTANT: prevents memory leaks
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }

        // Observe playback state
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in  // BEST PRACTICE: [weak self] prevents retain cycle
            self?.isPlaying = self?.player?.rate ?? 0 > 0
        }

        if autoPlay {
            player?.play()
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
    }

    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    func cleanup() {
        player?.pause()

        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
            playerObserver = nil
        }

        if let timeObs = timeObserver {
            player?.removeTimeObserver(timeObs)
            timeObserver = nil
        }

        player = nil
    }

    deinit {
        cleanup()
    }
}

/// UIViewRepresentable wrapper for AVPlayerLayer
private struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)

        context.coordinator.playerLayer = playerLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.playerLayer?.player = player

        // Update layer frame to match view bounds
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.playerLayer?.removeFromSuperlayer()
        coordinator.playerLayer = nil
    }

    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}

/// Main video player view with custom controls
private struct VideoPlayerView: View {
    let url: URL
    let autoPlay: Bool
    let loop: Bool
    let muted: Bool
    let showControls: Bool
    let showFullscreen: Bool

    @StateObject private var playerManager = PlayerManager()
    @State private var showControlsUI = false
    @State private var controlsOpacity: Double = 0

    var body: some View {
        ZStack {
            // Custom AVPlayerLayer
            VideoPlayerLayer(player: playerManager.player)
                .onTapGesture {
                    if showControls {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControlsUI.toggle()
                            controlsOpacity = showControlsUI ? 1.0 : 0.0
                        }
                    }
                }

            // Custom controls overlay
            if showControls && controlsOpacity > 0 {
                VStack {
                    Spacer()

                    HStack(spacing: 16) {
                        // Play/Pause button
                        Button(action: {
                            playerManager.togglePlayPause()
                        }) {
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }

                        // Mute/Unmute button
                        Button(action: {
                            playerManager.toggleMute()
                        }) {
                            Image(systemName: playerManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }

                        // Fullscreen button (if enabled)
                        if showFullscreen {
                            Button(action: {
                                // TODO: Implement fullscreen functionality
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        Color.black.opacity(0.5 * controlsOpacity)
                    )
                }
                .opacity(controlsOpacity)
            }
        }
        .onAppear {
            playerManager.setupPlayer(url: url, autoPlay: autoPlay, loop: loop, muted: muted)
        }
        .onDisappear {
            playerManager.cleanup()
        }
        .onChange(of: showControlsUI) { isShown in
            if isShown {
                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControlsUI = false
                        controlsOpacity = 0
                    }
                }
            }
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

