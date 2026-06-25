// MARK: - Native Display Renderer
// Main entry point for rendering native display UI using SwiftUI

import SwiftUI
import AVKit
import AVFoundation
import UIKit
import ImageIO

// MARK: - Environment Key for Parent Size

/// Environment key for explicitly setting parent size (overrides GeometryReader)
struct ParentSizeEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGSize? = nil
}

extension EnvironmentValues {
    /// Explicit parent size for NativeDisplayView layout calculations.
    /// Set this to provide a fixed parent size and avoid GeometryReader overhead.
    public var nativeDisplayParentSize: CGSize? {
        get { self[ParentSizeEnvironmentKey.self] }
        set { self[ParentSizeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Environment Keys for Font Customization

/// Environment key for client-provided default font family name (HIGHEST priority).
struct DefaultFontFamilyKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

/// Environment key for a custom font resolver closure.
/// Called when JSON specifies a fontFamily and no client default overrides it.
struct FontFamilyResolverKey: EnvironmentKey {
    static let defaultValue: ((String, CGFloat, Font.Weight) -> Font)? = nil
}

extension EnvironmentValues {
    /// Client-provided default font family. When set, ALL text in the SDK uses this font,
    /// overriding any fontFamily specified in JSON.
    public var nativeDisplayFontFamily: String? {
        get { self[DefaultFontFamilyKey.self] }
        set { self[DefaultFontFamilyKey.self] = newValue }
    }

    /// Custom font resolver for JSON-specified font families.
    /// Called with (familyName, size, weight) when JSON specifies a fontFamily
    /// and no client default font is set.
    public var nativeDisplayFontResolver: ((String, CGFloat, Font.Weight) -> Font)? {
        get { self[FontFamilyResolverKey.self] }
        set { self[FontFamilyResolverKey.self] = newValue }
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
    private let unitId: String?

    /// Render-only initializer. No `unitId` is wired, so attribution events
    /// (`Notification Viewed` / `Notification Clicked`) do not fire. Use this for
    /// previews, tests, and raw-JSON browsers that do not have a parsed
    /// `NativeDisplayUnit`. For bridge- or placement-delivered content, prefer
    /// `init(unit:actionListener:componentListener:)`.
    public init(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.init(
            config: config,
            actionListener: actionListener,
            componentListener: componentListener,
            unitId: nil,
            preResolvedStyles: nil
        )
    }

    /// Attribution-aware initializer. Uses the unit's pre-resolved style map
    /// (computed off-main by the bridge parser) and the `unitId` needed to fire
    /// `Notification Viewed` / `Notification Clicked` events.
    public init(
        unit: NativeDisplayUnit,
        actionListener: NativeDisplayActionListener? = nil,
        componentListener: NativeDisplayComponentListener? = nil
    ) {
        self.init(
            config: unit.config,
            actionListener: actionListener,
            componentListener: componentListener,
            unitId: unit.unitId,
            preResolvedStyles: unit.resolvedStyles
        )
    }

    private init(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?,
        unitId: String?,
        preResolvedStyles: [String: Style]?
    ) {
        self.config = config
        self.unitId = unitId
        if let preResolvedStyles {
            self.resolvedStyles = preResolvedStyles
        } else {
            let resolver = StyleResolver(theme: config.theme, styleClasses: config.styleClasses)
            self.resolvedStyles = resolver.resolveAll(node: config.root)
        }
        self.evaluator = VariableEvaluator(variables: config.variables)
        self.actionHandler = ActionHandler(
            actionListener: actionListener,
            componentListener: componentListener,
            unitId: unitId
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
            // Mirror the GeometryReader path's `.frame(width:)` wrapper so the
            // rendered root occupies the offered width even when its layout
            // spec doesn't intrinsically claim it (e.g. wrap_content root).
            // Without this, SwiftUI sizes the content to its small intrinsic
            // width and centers it inside the hosting view.
            renderContent(parentSize: explicitSize)
                .frame(width: explicitSize.width, alignment: .center)
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
        } else if let ar = config.root.layout?.aspectRatio, ar > 0 {
            // Priority 3.5: Aspect ratio present → derive height from offered width.
            // .frame(maxWidth: .infinity) fills the parent's offered width.
            // .aspectRatio(.fit) in a vertical ScrollView sets height = width / ar.
            // GeometryReader is constrained by both, so geo.size is always accurate —
            // avoids the unreliable initial-pass sizes of a bare GeometryReader in LazyVStack.
            // This respects host-applied padding / safe-area / multi-column insets,
            // which a UIScreen.main.bounds fallback would ignore.
            GeometryReader { geo in
                renderContent(parentSize: geo.size)
            }
            .aspectRatio(ar, contentMode: .fit)
            .frame(maxWidth: .infinity)
        } else {
            // Priority 4: GeometryReader (ONLY when truly needed)
            // Conditions to reach here:
            // - NO environment override AND
            // - Root has no aspect ratio AND
            // - Root uses percentages/match_parent/wrap_content AND
            // - Config contains percentages somewhere
            // → MUST use GeometryReader to measure parent constraints
            GeometryReader { geometry in
                renderContent(parentSize: geometry.size)
                    .frame(width: geometry.size.width, alignment: .center)
            }
        }
    }

    private func renderContent(parentSize: CGSize) -> some View {
        let rootHeight = Self.resolveRootHeight(layout: config.root.layout, parentSize: parentSize)
        return RenderNode(
            node: config.root,
            resolvedStyles: resolvedStyles,
            evaluator: evaluator,
            parentSize: parentSize,
            rootHeight: rootHeight,
            actionHandler: actionHandler,
            componentListener: componentListener,
            isRoot: true
        )
    }

    /// Resolve the root container's height for TextDimension percentage calculations.
    ///
    /// Priority:
    /// 1. Fixed height (dp/sp/px) → use directly
    /// 2. Aspect ratio + resolvable width → height = width / aspectRatio
    /// 3. Percent height → compute from parent
    /// 4. Fallback → parent height (or screen height if 0)
    private static func resolveRootHeight(layout: Layout?, parentSize: CGSize) -> CGFloat {
        guard let layout = layout else { return parentSize.height > 0 ? parentSize.height : UIScreen.main.bounds.height }

        let height = layout.height

        // 1. Fixed height
        if let h = height, h.special == nil {
            switch h.unit {
            case .dp, .sp, .px:
                if h.value > 0 { return h.value }
            case .percent:
                break // handled in step 3
            }
        }

        // 2. Aspect ratio + known width
        if let ar = layout.aspectRatio, ar > 0 {
            let rootWidth = resolveRootWidth(layout: layout, parentWidth: parentSize.width)
            if rootWidth > 0 { return rootWidth / ar }
        }

        // 3. Percent height
        if let h = height, h.special == nil, h.unit == .percent, parentSize.height > 0 {
            return parentSize.height * h.value / 100
        }

        // 4. Fallback
        return parentSize.height > 0 ? parentSize.height : UIScreen.main.bounds.height
    }

    private static func resolveRootWidth(layout: Layout?, parentWidth: CGFloat) -> CGFloat {
        guard let w = layout?.width else { return parentWidth }
        if w.special != nil { return parentWidth } // match_parent / wrap_content
        switch w.unit {
        case .dp, .sp, .px: return w.value
        case .percent:
            // Aspect ratio present → percent is ignored, width fills parent.
            // Keeps rootHeight (used for TextDimension %) consistent with the frame.
            guard (layout?.aspectRatio ?? 0) <= 0 else { return parentWidth }
            return parentWidth > 0 ? parentWidth * w.value / 100 : 0
        }
    }
}

/// Recursively render a display node (container or element).
struct RenderNode: View {
    let node: NativeDisplayNode
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    let parentSize: CGSize
    let rootHeight: CGFloat
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?
    var isRoot: Bool = false
    /// True when this node is a direct child of a BOX container.
    /// The parent BOX applies the offset externally via padding overlay, so this node
    /// must NOT also apply offset internally (which would double it).
    var inBoxContainer: Bool = false
    
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
        let isImage = node.elementType == .image
        
        switch node {
        case .container(let container):
            let layoutMod = LayoutModifier(layout: node.layout, parentSize: parentSize, nodeId: node.id)
            let offsetValue = layoutMod.calculateOffset()

            let containerView = RenderContainer(
                container: container,
                resolvedStyles: resolvedStyles,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize,
                rootHeight: rootHeight,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
            .modifier(layoutMod)
            .modifier(DecorationModifier(style: resolvedStyle, rootHeight: rootHeight))

            Group {
                if inBoxContainer {
                    containerView
                } else {
                    containerView.offset(x: offsetValue.width, y: offsetValue.height)
                }
            }
            .applyEntranceAnimation(node.animation)
            .applyTappable(
                nodeId: node.id,
                actions: shouldApplyTappable ? node.actions : nil,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
            .onAppear {
                if isRoot {
                    actionHandler?.fireSystemEvent(eventName: "Notification Viewed")
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
            // Video elements handle their own tap interaction (controls show/hide) internally.
            // Passing a componentListener here would add a competing gesture that blocks the
            // internal Color.clear tap layer. Explicit onClick actions still work via `actions`.
            let isVideo = element.elementType == .video

            let elementView = RenderElement(
                element: element,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                parentSize: parentSize,
                rootHeight: rootHeight,
                actionHandler: actionHandler
            )
            .modifier(layoutMod)
            .modifier(DecorationModifier(style: resolvedStyle, rootHeight: rootHeight))

            // BOX container children: offset is applied externally via padding overlay
            // in RenderContainer.box, so hit-testing and visual position always align.
            // Non-BOX children: use .offset() for visual-only displacement.
            Group {
                if inBoxContainer {
                    elementView
                } else {
                    elementView.offset(x: offsetValue.width, y: offsetValue.height)
                }
            }
            .applyEntranceAnimation(node.animation)
            .applyTappable(
                nodeId: node.id,
                actions: !isButton && shouldApplyTappable ? node.actions : nil,
                actionHandler: actionHandler,
                componentListener: (!isButton && !isVideo) ? componentListener : nil,
                onSystemClick: isImage ? {
                    guard let onClick = node.actions?[ActionTriggers.onClick] else { return }
                    let extras = ActionAttributionExtras.from(action: onClick)
                    actionHandler?.fireSystemEvent(eventName: "Notification Clicked", properties: extras)
                } : nil
            )
            .onAppear {
                if isRoot {
                    actionHandler?.fireSystemEvent(eventName: "Notification Viewed")
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
    let rootHeight: CGFloat
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
            .padding(paddingInsets)

        case .horizontal:
            renderHorizontalContainer(availableSize: availableSize)
                .padding(paddingInsets)

        case .box:
            // BOX uses absolute positioning. Each child is placed on a full-size transparent
            // canvas via .overlay + .padding. This approach correctly aligns both visual
            // rendering and hit-testing, unlike .offset() (visual only) or .position()
            // (unreliable hit-test alignment for UIViewRepresentable subtrees).
            ZStack(alignment: .topLeading) {
                ForEach(container.children, id: \.id) { child in
                    let childOffset = LayoutModifier(
                        layout: child.layout,
                        parentSize: containerSize,
                        nodeId: child.id
                    ).calculateOffset()

                    Color.clear
                        .frame(width: containerSize.width, height: containerSize.height)
                        .overlay(alignment: .topLeading) {
                            RenderNode(
                                node: child,
                                resolvedStyles: resolvedStyles,
                                evaluator: evaluator,
                                parentSize: containerSize,
                                rootHeight: rootHeight,
                                actionHandler: actionHandler,
                                componentListener: componentListener,
                                inBoxContainer: true
                            )
                            .padding(.top, childOffset.height)
                            .padding(.leading, childOffset.width)
                        }
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
                rootHeight: rootHeight,
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
                // Aspect ratio present + non-fixed width → fill parent width.
                // Matches resolveRootWidth(): percent is ignored when aspectRatio is set.
                width = widthIsFixed ? rawWidth : parentSize.width
                height = width / aspectRatio
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
                        rootHeight: rootHeight,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            // Clip children to the content area BEFORE adding padding.
            // Without this, SwiftUI VStack children that overflow the content frame
            // render into the padding space, visually eating the bottom (and trailing)
            // padding. Android LinearLayout clips children by default (clipChildren=true),
            // so .clipped() here restores parity with that behaviour.
            .clipped()
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
                        actionHandler: actionHandler,
                        componentListener: componentListener
                    )
                }
            }
            // Same reason as vertical — clip before padding to preserve trailing padding.
            .clipped()

        case .spaceBetween:
            HStack(alignment: .top, spacing: 0) {
                ForEach(container.children.indices, id: \.self) { index in
                    RenderNode(
                        node: container.children[index],
                        resolvedStyles: resolvedStyles,
                        evaluator: evaluator,
                        parentSize: availableSize,
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
                        rootHeight: rootHeight,
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
    let rootHeight: CGFloat
    let actionHandler: ActionHandler?

    @Environment(\.nativeDisplayFontFamily) private var clientFontFamily
    @Environment(\.nativeDisplayFontResolver) private var fontResolver

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

        // Build font with weight and italic baked in (iOS 15 compatible).
        let isPercentMode = textProps.size?.unit == .percent
        let resolvedSize = textProps.size?.resolve(containerHeight: rootHeight) ?? 14
        let font = resolveFont(
            family: textProps.family,
            size: resolvedSize,
            weight: resolveFontWeight(textProps.weight),
            isItalic: textProps.style == .italic
        )

        // Compute line spacing (SwiftUI .lineSpacing = EXTRA space between lines, not total line height):
        // - If lineHeight is explicitly set: extra = totalLineHeight - fontSize (approximate)
        // - If percentage mode with no lineHeight: 0 (SwiftUI's natural ~1.2× already matches CSS)
        // - If platform mode with no lineHeight: legacy default (fontSize * 1.5)
        let lineSpacingValue: CGFloat = {
            if let lh = textProps.lineHeight {
                // Subtract natural line height (~1.2× fontSize) since SwiftUI adds this automatically
                let resolvedLH = lh.resolve(containerHeight: rootHeight)
                return max(0, resolvedLH - resolvedSize * 1.2)
            } else if isPercentMode {
                return 0  // SwiftUI natural line height ≈ 1.2× already matches CSS line-height:1.2
            } else {
                return max(0, resolvedSize * 1.5 - resolvedSize)  // Platform mode: legacy default
            }
        }()

        // Build the styled Text as a Text value (all Text modifiers return Text).
        let coreText = Text(text)
            .foregroundColor(ColorParser.parse(textProps.color) ?? .black)
            .font(font)
            .kerning(textProps.letterSpacing ?? 0)
            .underline(textProps.decoration == .underline, color: nil)
            .strikethrough(textProps.decoration == .strikethrough, color: nil)
            .multilineTextAlignment(textAlignment)
            .lineSpacing(lineSpacingValue)

        if isWrapContent {
            coreText
                .lineLimit(textProps.maxLines)
                .truncationMode(resolveTextOverflow(textProps.overflow))
                .fixedSize(horizontal: false, vertical: true)
        } else {
            coreText
                .lineLimit(textProps.maxLines)
                .truncationMode(resolveTextOverflow(textProps.overflow))
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
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        } else {
            EmptyView()
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
        let onLongPress = element.actions?[ActionTriggers.onLongPress]
        let onDoubleTap = element.actions?[ActionTriggers.onDoubleTap]
        let buttonText = element.bindings["text"].map { evaluator.evaluateString($0) } ?? "Button"

        let textProps = resolvedStyle.extractTextProperties()

        let isPercentMode = textProps.size?.unit == .percent
        let resolvedSize = textProps.size?.resolve(containerHeight: rootHeight) ?? 16

        let btnLineSpacing: CGFloat = {
            if let lh = textProps.lineHeight {
                let resolvedLH = lh.resolve(containerHeight: rootHeight)
                return max(0, resolvedLH - resolvedSize * 1.2)
            } else if isPercentMode {
                return 0  // SwiftUI natural line height ≈ 1.2× already matches CSS line-height:1.2
            } else {
                return max(0, resolvedSize * 1.5 - resolvedSize)
            }
        }()

        Button(action: {
            // Fire system event for button click, carrying the click action's KVs
            // so attribution events surface the URL / custom KVs / metadata.
            let onClickAction = element.actions?[ActionTriggers.onClick]
            let extras = ActionAttributionExtras.from(action: onClickAction)
            actionHandler?.fireSystemEvent(
                eventName: "Notification Clicked",
                properties: extras
            )
            if let onClick = onClickAction {
                actionHandler?.handleAction(onClick, nodeId: element.id, interactionType: .click)
            }
        }) {
            // Fill the allocated frame so the tappable area covers the full element bounds.
            // Text is centered within the button — center alignment is the conventional default for buttons.
            Text(buttonText)
                .foregroundColor(ColorParser.parse(textProps.color) ?? .white)
                .font(resolveFont(
                    family: textProps.family,
                    size: resolvedSize,
                    weight: resolveFontWeight(textProps.weight),
                    isItalic: textProps.style == .italic
                ))
                .kerning(textProps.letterSpacing ?? 0)
                .underline(textProps.decoration == .underline, color: nil)
                .strikethrough(textProps.decoration == .strikethrough, color: nil)
                .multilineTextAlignment(resolveTextAlign(textProps.align))
                .lineSpacing(btnLineSpacing)
                .lineLimit(textProps.maxLines)
                .truncationMode(resolveTextOverflow(textProps.overflow))
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
        let openUrl = element.bindings["openUrl"].map { evaluator.evaluateString($0) }.flatMap { $0.isEmpty ? nil : $0 }

        if !videoUrl.isEmpty, let url = URL(string: videoUrl) {
            VideoPlayerView(
                url: url,
                autoPlay: autoPlay,
                loop: loop,
                muted: muted,
                showControls: showControls,
                showFullscreen: showFullscreen,
                openUrl: openUrl
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

    /// 3-layer font resolution:
    /// 1. Client default font family (environment) — HIGHEST priority
    /// 2. JSON fontFamily from server config — MEDIUM priority
    /// 3. Platform system font — LOWEST priority (fallback)
    private func resolveFont(family: String?, size: CGFloat, weight: Font.Weight, isItalic: Bool) -> Font {
        // Layer 1: Client default (HIGHEST)
        if let clientFamily = clientFontFamily {
            let font = Font.custom(clientFamily, size: size).weight(weight)
            return isItalic ? font.italic() : font
        }
        // Layer 2: JSON fontFamily
        if let family = family {
            if let resolver = fontResolver {
                return isItalic ? resolver(family, size, weight).italic() : resolver(family, size, weight)
            }
            let font = Font.custom(family, size: size).weight(weight)
            return isItalic ? font.italic() : font
        }
        // Layer 3: System default
        let font = Font.system(size: size, weight: weight)
        return isItalic ? font.italic() : font
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

    private func resolveTextOverflow(_ overflow: TextOverflow?) -> Text.TruncationMode {
        switch overflow {
        case .ellipsis: return .tail
        case .clip: return .tail
        case .visible: return .tail
        case .none: return .tail
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
            // When width is percent (not fixed dp/px/sp), aspect ratio wins: fill parent width.
            // Matches resolveRootWidth() rule: "Aspect ratio present → percent is ignored, width fills parent."
            let frameWidth = widthIsFixed ? w : parentSize.width
            return (frameWidth, frameWidth / ratio, false)
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

        return aspectRatio
    }

    /// Check if a dimension uses a truly fixed unit (DP/PX/SP, not percent or special).
    private func hasFixedDimension(_ dimension: Dimension?) -> Bool {
        guard let dimension = dimension else { return false }
        return dimension.special == nil && dimension.unit != .percent
    }
}

// MARK: - Decoration Modifier

struct DecorationModifier: ViewModifier {
    let style: Style
    let rootHeight: CGFloat

    func body(content: Content) -> some View {
        DecorationView(style: style, rootHeight: rootHeight, content: content)
    }
}

/// Internal view that applies visual decoration (background, border, shadow, clip, opacity).
///
/// Separated from `DecorationModifier` as a dedicated `View` struct so that `@State` can
/// be stored properly. SwiftUI's `ViewModifier.body` does not own state the same way a
/// `View.body` does, and complex chaining on `@ViewBuilder` results causes type-checker
/// failures in some Xcode/Swift versions.
///
/// Percent-based `borderRadius` requires knowing the element's rendered size. We measure it
/// via `.background(GeometryReader)` which is non-greedy (does NOT affect the parent's
/// layout), unlike wrapping content directly in `GeometryReader` which expands to fill all
/// available space and returns wrong sizes inside `ScrollView` / `LazyVStack` / `LazyHStack`.
private struct DecorationView<Content: View>: View {
    let style: Style
    let rootHeight: CGFloat
    let content: Content

    var body: some View {
        let borderProps = style.extractBorderProperties()
        let shadowProps = style.extractShadowProperties()
        let visualProps = style.extractVisualProperties()
        let cornerRadius = resolvedCornerRadius(borderProps: borderProps)
        // FE formula: containerHeight * borderWidth / 1000
        let effectiveBorderWidth: CGFloat = {
            guard let w = borderProps.width, w > 0, rootHeight > 0 else { return borderProps.width ?? 0 }
            return rootHeight * CGFloat(w) / 1000
        }()

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
            // Apply clip
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Apply border
            .overlay(
                Group {
                    if effectiveBorderWidth > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                ColorParser.parse(borderProps.color) ?? .gray,
                                lineWidth: effectiveBorderWidth
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

    /// Resolves the corner radius to a concrete CGFloat.
    /// - For `.percent` units: FE formula `rootHeight * value / 100`
    /// - For all other units (dp, sp, px): use the raw value directly as points
    private func resolvedCornerRadius(borderProps: BorderProperties) -> CGFloat {
        guard let dim = borderProps.radius else { return 0 }
        switch dim.unit {
        case .percent:
            return rootHeight * (CGFloat(dim.value) / 100.0)
        default:
            return CGFloat(dim.value)
        }
    }
}

// MARK: - Color Parser

/// Utility to parse hex color strings to SwiftUI Color.
/// Supports #RRGGBB (6 chars) and #RRGGBBAA (8 chars, RGBA format).
struct ColorParser {
    /// Parse hex color string to SwiftUI Color.
    /// - #RRGGBB: 6-character RGB (full opacity)
    /// - #RRGGBBAA: 8-character RGBA (alpha in last byte)
    static func parse(_ colorString: String?) -> Color? {
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
fileprivate class PlayerManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var isEnded: Bool = false
    /// Non-nil when the AVPlayerItem reports `.failed` status. Drives the
    /// error overlay in VideoPlayerView / VideoFullscreenView. Mirrors the
    /// Android side's `errorMessage` state for cross-platform parity —
    /// without this, unsupported formats (e.g. .webm, .mkv) and unreachable
    /// URLs render as a silent black surface on iOS.
    @Published var errorMessage: String?

    var player: AVPlayer?
    private var playerObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var timeObserver: Any?

    func setupPlayer(url: URL, autoPlay: Bool, loop: Bool, muted: Bool) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = muted
        self.isMuted = muted
        // Reset any prior error state when reattaching to a new URL.
        self.errorMessage = nil

        // Setup end-of-video observer (used for both loop and ended-state tracking)
        playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,  // IMPORTANT: prevents memory leaks
            queue: .main
        ) { [weak self] _ in
            if loop {
                self?.player?.seek(to: .zero)
                self?.player?.play()
            } else {
                self?.isEnded = true
            }
        }

        // Surface AVPlayerItem.status transitions to `.failed` — covers
        // unsupported formats, network errors, decoder failures. Without this,
        // bad URLs produce a silent black surface with no UX feedback. KVO
        // closures can fire on any thread, so hop to main before mutating
        // @Published state.
        statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            let detail = item.error?.localizedDescription ?? "unknown error"
            DispatchQueue.main.async {
                guard let self = self, self.player?.currentItem === item else { return }
                self.errorMessage = "Video playback failed"
                NDLogger.e(Self.self, "Playback error: \(detail)")
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
            if isEnded {
                isEnded = false
                player?.seek(to: .zero)
            }
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

        statusObservation?.invalidate()
        statusObservation = nil

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

/// UIView subclass that keeps AVPlayerLayer filling its bounds on every layout pass,
/// including device rotation.
private final class PlayerLayerView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

/// UIViewRepresentable wrapper for AVPlayerLayer
private struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerLayerView {
        PlayerLayerView()
    }

    func updateUIView(_ uiView: PlayerLayerView, context: Context) {
        // Only reassign if the player instance actually changed — avoids a black flash
        // on rotation when SwiftUI rebuilds the view body but the player is the same.
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    static func dismantleUIView(_ uiView: PlayerLayerView, coordinator: ()) {
        // Do not nil out the player here — the PlayerManager's cleanup() handles
        // release on onDisappear. Nilling here causes a black flash on rotation
        // because SwiftUI dismantles/remakes UIViewRepresentable during layout rebuilds.
    }
}

private struct VideoControlIcon: View {
    let systemName: String
    let accessibilityLabel: String
    /// Stable XCUITest identifier. Distinct from `accessibilityLabel` (which
    /// VoiceOver reads aloud and flips with state — "Play" ↔ "Pause"); this
    /// is the state-independent automation handle, e.g.
    /// `app.buttons[NDVideoAccessibilityID.play]` in XCUITest.
    let accessibilityIdentifier: String
    var size: CGFloat = 32
    let action: () -> Void

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Public test identifiers
//
// Stable XCUITest accessibility identifiers applied to the VIDEO element's
// control buttons. Public API so consumers can identify controls in XCUITest
// (`app.buttons[NDVideoAccessibilityID.play]`) and cross-platform automation
// (Maestro, Appium) without depending on the user-visible accessibilityLabel
// (which flips with state — "Play" ↔ "Pause" — and localizes).
//
// String values match the Android side's `ND_VIDEO_TEST_TAG_*` constants
// verbatim so cross-platform Appium/Maestro suites use one ID per control.
//
// Inline and fullscreen modes are mutually exclusive at any moment, so
// `play`, `mute` and `actionUrl` re-use the same identifier across both
// modes — a test "tap play" works regardless of which mode the player is in.
public enum NDVideoAccessibilityID {
    public static let play: String       = "nd_video_play"
    public static let mute: String       = "nd_video_mute"
    public static let actionUrl: String  = "nd_video_action_url"
    public static let expand: String     = "nd_video_expand"
    public static let close: String      = "nd_video_close"
    public static let collapse: String   = "nd_video_collapse"
}

/// Main video player view with custom controls
private struct VideoPlayerView: View {
    let url: URL
    let autoPlay: Bool
    let loop: Bool
    let muted: Bool
    let showControls: Bool
    let showFullscreen: Bool
    let openUrl: String?

    @StateObject private var playerManager = PlayerManager()
    @State private var showControlsUI = false
    @State private var isFullscreen = false
    @State private var hideControlsWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            // Custom AVPlayerLayer — hidden when fullscreen (shared AVPlayer instance)
            VideoPlayerLayer(player: playerManager.player)
                .opacity(isFullscreen ? 0 : 1)

            // Error overlay — mirrors Android's failure UI. Shown when the
            // AVPlayerItem reports `.failed` (unsupported format, 404, decoder
            // error, etc.). Suppresses the otherwise-silent black surface.
            if let message = playerManager.errorMessage, !isFullscreen {
                Rectangle()
                    .fill(Color(.darkGray))
                    .overlay(
                        Text(message)
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    )
            }

            // Transparent tap layer — detects taps reliably as a pure SwiftUI view
            if showControls && !isFullscreen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showControlsUI.toggle()
                    }
            }

            // Custom controls overlay
            if showControls && playerManager.errorMessage == nil {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        VideoControlIcon(
                            systemName: playerManager.isPlaying ? "pause.fill" : "play.fill",
                            accessibilityLabel: playerManager.isPlaying ? "Pause" : "Play",
                            accessibilityIdentifier: NDVideoAccessibilityID.play
                        ) {
                            playerManager.togglePlayPause()
                        }
                        if let url = openUrl {
                            VideoControlIcon(
                                systemName: "arrow.up.right.square",
                                accessibilityLabel: "Open URL",
                                accessibilityIdentifier: NDVideoAccessibilityID.actionUrl
                            ) {
                                if let u = URL(string: url) {
                                    UIApplication.shared.open(u)
                                }
                            }
                        }
                        VideoControlIcon(
                            systemName: playerManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                            accessibilityLabel: playerManager.isMuted ? "Unmute" : "Mute",
                            accessibilityIdentifier: NDVideoAccessibilityID.mute
                        ) {
                            playerManager.toggleMute()
                        }
                        if showFullscreen {
                            VideoControlIcon(
                                systemName: "arrow.up.left.and.arrow.down.right",
                                accessibilityLabel: "Enter fullscreen",
                                accessibilityIdentifier: NDVideoAccessibilityID.expand
                            ) {
                                isFullscreen = true
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .opacity(showControlsUI ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showControlsUI)
                .allowsHitTesting(showControlsUI)
            }
        }
        .fullScreenCover(isPresented: $isFullscreen) {
            VideoFullscreenView(
                playerManager: playerManager,
                openUrl: openUrl,
                isPresented: $isFullscreen
            )
        }
        .onAppear {
            playerManager.setupPlayer(url: url, autoPlay: autoPlay, loop: loop, muted: muted)
        }
        .onDisappear {
            playerManager.cleanup()
        }
        .onChange(of: showControlsUI) { isShown in
            hideControlsWorkItem?.cancel()
            guard isShown else { return }
            let workItem = DispatchWorkItem { showControlsUI = false }
            hideControlsWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }
}

private struct VideoFullscreenView: View {
    @ObservedObject var playerManager: PlayerManager
    let openUrl: String?
    @Binding var isPresented: Bool
    @State private var showControlsUI = true
    @State private var hideControlsWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VideoPlayerLayer(player: playerManager.player)
                .ignoresSafeArea()

            // Fullscreen error overlay (same source of truth as the inline view).
            if let message = playerManager.errorMessage {
                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    showControlsUI.toggle()
                }

            if showControlsUI && playerManager.errorMessage == nil {
                // Close — top right
                VStack {
                    HStack {
                        Spacer()
                        VideoControlIcon(
                            systemName: "xmark",
                            accessibilityLabel: "Close fullscreen",
                            accessibilityIdentifier: NDVideoAccessibilityID.close
                        ) {
                            isPresented = false
                        }
                        .padding(12)
                    }
                    Spacer()
                }

                // Center play/pause
                VideoControlIcon(
                    systemName: playerManager.isPlaying ? "pause.fill" : "play.fill",
                    accessibilityLabel: playerManager.isPlaying ? "Pause" : "Play",
                    accessibilityIdentifier: NDVideoAccessibilityID.play,
                    size: 40
                ) {
                    playerManager.togglePlayPause()
                }

                // Bottom row
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        if let urlStr = openUrl, let url = URL(string: urlStr) {
                            VideoControlIcon(
                                systemName: "arrow.up.right.square",
                                accessibilityLabel: "Open URL",
                                accessibilityIdentifier: NDVideoAccessibilityID.actionUrl
                            ) {
                                UIApplication.shared.open(url)
                            }
                        }
                        VideoControlIcon(
                            systemName: playerManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                            accessibilityLabel: playerManager.isMuted ? "Unmute" : "Mute",
                            accessibilityIdentifier: NDVideoAccessibilityID.mute
                        ) {
                            playerManager.toggleMute()
                        }
                        VideoControlIcon(
                            systemName: "arrow.down.right.and.arrow.up.left",
                            accessibilityLabel: "Exit fullscreen",
                            accessibilityIdentifier: NDVideoAccessibilityID.collapse
                        ) {
                            isPresented = false
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onChange(of: showControlsUI) { isShown in
            hideControlsWorkItem?.cancel()
            guard isShown else { return }
            let workItem = DispatchWorkItem {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControlsUI = false
                }
            }
            hideControlsWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
        .onAppear {
            let workItem = DispatchWorkItem {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControlsUI = false
                }
            }
            hideControlsWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
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

