// MARK: - Gallery Renderer
// Gallery rendering implementation for SwiftUI

import SwiftUI

/// Main gallery renderer that routes to the appropriate implementation based on mode.
struct RenderGallery: View {
    let container: NativeDisplayContainer
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    let resolvedStyle: Style
    let rootHeight: CGFloat
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?

    var body: some View {
        let config = container.galleryConfig ?? GalleryConfig()

        switch config.mode {
        case .snapping:
            SnappingGalleryView(
                container: container,
                config: config,
                resolvedStyles: resolvedStyles,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                rootHeight: rootHeight,
                actionHandler: actionHandler,
                componentListener: componentListener
            )

        case .freeFlow:
            FreeFlowGalleryView(
                container: container,
                config: config,
                resolvedStyles: resolvedStyles,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                rootHeight: rootHeight,
                actionHandler: actionHandler,
                componentListener: componentListener
            )

        case .freeFlowGrid:
            FreeFlowGridGalleryView(
                container: container,
                config: config,
                resolvedStyles: resolvedStyles,
                evaluator: evaluator,
                resolvedStyle: resolvedStyle,
                rootHeight: rootHeight,
                actionHandler: actionHandler,
                componentListener: componentListener
            )
        }
    }
}

// MARK: - Mode 1: Snapping Gallery

/// Mode 1: Snapping Gallery
/// - Full-size items with snap behavior
/// - Peek shows partial adjacent items via contentPadding
/// - Supports auto-scroll, indicators, arrows
struct SnappingGalleryView: View {
    let container: NativeDisplayContainer
    let config: GalleryConfig
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    let resolvedStyle: Style
    let rootHeight: CGFloat
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?
    
    @State private var currentPage: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            let peekBefore = container.children.count > 1 ? config.peek.before : 0
            let peekAfter  = container.children.count > 1 ? config.peek.after  : 0
            let effectiveWidth  = max(0, containerSize.width - peekBefore - peekAfter)
            let effectiveHeight = max(0, containerSize.height - peekBefore - peekAfter)

            ZStack {
                // Main Pager
                if config.orientation == .horizontal {
                    TabView(selection: $currentPage) {
                        ForEach(Array(container.children.enumerated()), id: \.element.id) { index, child in
                            RenderNode(
                                node: child,
                                resolvedStyles: resolvedStyles,
                                evaluator: evaluator,
                                parentSize: CGSize(width: effectiveWidth, height: containerSize.height),
                                rootHeight: rootHeight,
                                actionHandler: actionHandler,
                                componentListener: componentListener
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding(EdgeInsets(top: 0, leading: peekBefore, bottom: 0, trailing: peekAfter))
                } else {
                    // Vertical scrolling with snapping
                    // Use TabView with rotation for vertical paging (iOS 15 compatible)
                    TabView(selection: $currentPage) {
                        ForEach(Array(container.children.enumerated()), id: \.element.id) { index, child in
                            RenderNode(
                                node: child,
                                resolvedStyles: resolvedStyles,
                                evaluator: evaluator,
                                parentSize: CGSize(width: containerSize.width, height: effectiveHeight),
                                rootHeight: rootHeight,
                                actionHandler: actionHandler,
                                componentListener: componentListener
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(index)
                            .rotationEffect(.degrees(-90))
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .rotationEffect(.degrees(90))
                    .padding(EdgeInsets(top: peekBefore, leading: 0, bottom: peekAfter, trailing: 0))
                }
                
                // Navigation arrows
                if config.showArrows && container.children.count > 1 {
                    GalleryArrows(
                        currentPage: $currentPage,
                        pageCount: container.children.count,
                        config: config
                    )
                }
                
                // Page indicators
                if config.showIndicators && container.children.count > 1 {
                    GalleryIndicators(
                        currentPage: currentPage,
                        pageCount: container.children.count,
                        config: config
                    )
                }
            }
        }
        .onAppear {
            currentPage = min(config.initialPage, max(0, container.children.count - 1))
            NDLogger.d(Self.self, "Snapping gallery '\(container.id)' appeared — initialPage=\(currentPage)")
            startAutoScrollIfNeeded()
        }
        .onDisappear {
            NDLogger.d(Self.self, "Snapping gallery '\(container.id)' disappeared — invalidating timer")
            timer?.invalidate()
        }
        .onChange(of: currentPage) { page in
            NDLogger.d(Self.self, "Gallery '\(container.id)' page changed to \(page)")
        }
    }

    private func startAutoScrollIfNeeded() {
        guard config.autoScrollInterval > 0, container.children.count > 1 else { return }
        NDLogger.d(Self.self, "Gallery '\(container.id)' auto-scroll started: interval=\(config.autoScrollInterval)ms infinite=\(config.infiniteScroll)")

        timer = Timer.scheduledTimer(withTimeInterval: Double(config.autoScrollInterval) / 1000.0, repeats: true) { _ in
            withAnimation {
                if config.infiniteScroll {
                    currentPage = (currentPage + 1) % container.children.count
                } else {
                    currentPage = min(currentPage + 1, container.children.count - 1)
                }
            }
        }
    }
}

// MARK: - Mode 2: Free Flow Gallery

/// Mode 2: Free Flow - Independent Sizing
/// - Items define their own size via Layout properties
/// - Natural scrolling, no snap, no peek
/// - Use case: Tag lists, chips, varying-width items
struct FreeFlowGalleryView: View {
    let container: NativeDisplayContainer
    let config: GalleryConfig
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    let resolvedStyle: Style
    let rootHeight: CGFloat
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?
    
    var body: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            
            if config.orientation == .horizontal {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .center, spacing: config.spacing) {
                        ForEach(container.children, id: \.id) { child in
                            RenderNode(
                                node: child,
                                resolvedStyles: resolvedStyles,
                                evaluator: evaluator,
                                parentSize: containerSize,
                                rootHeight: rootHeight,
                                actionHandler: actionHandler,
                                componentListener: componentListener
                            )
                        }
                    }
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: config.spacing) {
                        ForEach(container.children, id: \.id) { child in
                            RenderNode(
                                node: child,
                                resolvedStyles: resolvedStyles,
                                evaluator: evaluator,
                                parentSize: containerSize,
                                rootHeight: rootHeight,
                                actionHandler: actionHandler,
                                componentListener: componentListener
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Mode 3: Free Flow Grid Gallery

/// Mode 3: Free Flow - Grid with Peek
/// - Fixed number of items per view (e.g., 2.5 items)
/// - Equal-sized items, natural scrolling
/// - Peek via itemsPerView (2.5 = 2 full + 0.5 peek on each side)
/// - Use case: Product grids, movie posters
struct FreeFlowGridGalleryView: View {
    let container: NativeDisplayContainer
    let config: GalleryConfig
    let resolvedStyles: [String: Style]
    let evaluator: VariableEvaluator
    let resolvedStyle: Style
    let rootHeight: CGFloat
    let actionHandler: ActionHandler?
    let componentListener: NativeDisplayComponentListener?
    
    var body: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            let itemsPerView = max(0.1, config.effectiveItemsPerView)
            
            if config.orientation == .horizontal {
                let totalSpacing = config.spacing * (itemsPerView - 1)
                let itemWidth = (containerSize.width - totalSpacing) / itemsPerView
                
                // Calculate peek offset for centering
                let fullItems = floor(itemsPerView)
                let partialItem = itemsPerView - fullItems
                let peekOffset = partialItem > 0 ? itemWidth * partialItem / 2 : 0
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: config.spacing) {
                        ForEach(container.children, id: \.id) { child in
                            RenderNode(
                                node: child,
                                resolvedStyles: resolvedStyles,
                                evaluator: evaluator,
                                parentSize: CGSize(width: itemWidth, height: containerSize.height),
                                rootHeight: rootHeight,
                                actionHandler: actionHandler,
                                componentListener: componentListener
                            )
                            .frame(maxWidth: .infinity)
                            .frame(width: itemWidth)
                        }
                    }
                    .padding(.horizontal, peekOffset)
                }
            } else {
                let totalSpacing = config.spacing * (itemsPerView - 1)
                let itemHeight = (containerSize.height - totalSpacing) / itemsPerView

                // Calculate peek offset for centering
                let fullItems = floor(itemsPerView)
                let partialItem = itemsPerView - fullItems
                let peekOffset = partialItem > 0 ? itemHeight * partialItem / 2 : 0

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: config.spacing) {
                        ForEach(container.children, id: \.id) { child in
                            RenderNode(
                                node: child,
                                resolvedStyles: resolvedStyles,
                                evaluator: evaluator,
                                parentSize: CGSize(width: containerSize.width, height: itemHeight),
                                rootHeight: rootHeight,
                                actionHandler: actionHandler,
                                componentListener: componentListener
                            )
                            .frame(maxHeight: .infinity)
                            .frame(height: itemHeight)
                        }
                    }
                    .padding(.vertical, peekOffset)
                }
            }
        }
    }
}

// MARK: - Gallery Navigation Arrows

struct GalleryArrows: View {
    @Binding var currentPage: Int
    let pageCount: Int
    let config: GalleryConfig
    
    var body: some View {
        let arrowStyle = config.arrowStyle ?? ArrowStyle()
        let arrowColor = ColorParser.parse(arrowStyle.color) ?? .white
        let arrowBgColor = arrowStyle.backgroundColor.flatMap { ColorParser.parse($0) }
        
        if config.orientation == .horizontal {
            HStack {
                // Previous arrow
                Button(action: {
                    withAnimation {
                        if config.infiniteScroll && currentPage == 0 {
                            NDLogger.d(Self.self, "Gallery arrow: wrap-around to last page \(pageCount - 1)")
                            currentPage = pageCount - 1
                        } else {
                            NDLogger.d(Self.self, "Gallery arrow: previous page \(currentPage - 1)")
                            currentPage = max(0, currentPage - 1)
                        }
                    }
                }) {
                    arrowIcon(systemName: "chevron.left", style: arrowStyle, color: arrowColor, bgColor: arrowBgColor)
                }
                .disabled(!config.infiniteScroll && currentPage == 0)

                Spacer()

                // Next arrow
                Button(action: {
                    withAnimation {
                        if config.infiniteScroll && currentPage == pageCount - 1 {
                            NDLogger.d(Self.self, "Gallery arrow: wrap-around to page 0")
                            currentPage = 0
                        } else {
                            NDLogger.d(Self.self, "Gallery arrow: next page \(currentPage + 1)")
                            currentPage = min(pageCount - 1, currentPage + 1)
                        }
                    }
                }) {
                    arrowIcon(systemName: "chevron.right", style: arrowStyle, color: arrowColor, bgColor: arrowBgColor)
                }
                .disabled(!config.infiniteScroll && currentPage == pageCount - 1)
            }
            .padding(.horizontal, 16)
        } else {
            VStack {
                // Previous arrow
                Button(action: {
                    withAnimation {
                        if config.infiniteScroll && currentPage == 0 {
                            NDLogger.d(Self.self, "Gallery arrow (vertical): wrap-around to last page \(pageCount - 1)")
                            currentPage = pageCount - 1
                        } else {
                            NDLogger.d(Self.self, "Gallery arrow (vertical): previous page \(currentPage - 1)")
                            currentPage = max(0, currentPage - 1)
                        }
                    }
                }) {
                    arrowIcon(systemName: "chevron.up", style: arrowStyle, color: arrowColor, bgColor: arrowBgColor)
                }
                .disabled(!config.infiniteScroll && currentPage == 0)

                Spacer()

                // Next arrow
                Button(action: {
                    withAnimation {
                        if config.infiniteScroll && currentPage == pageCount - 1 {
                            NDLogger.d(Self.self, "Gallery arrow (vertical): wrap-around to page 0")
                            currentPage = 0
                        } else {
                            NDLogger.d(Self.self, "Gallery arrow (vertical): next page \(currentPage + 1)")
                            currentPage = min(pageCount - 1, currentPage + 1)
                        }
                    }
                }) {
                    arrowIcon(systemName: "chevron.down", style: arrowStyle, color: arrowColor, bgColor: arrowBgColor)
                }
                .disabled(!config.infiniteScroll && currentPage == pageCount - 1)
            }
            .padding(.vertical, 16)
        }
    }
    
    @ViewBuilder
    private func arrowIcon(systemName: String, style: ArrowStyle, color: Color, bgColor: Color?) -> some View {
        Image(systemName: systemName)
            .font(.system(size: style.size))
            .foregroundColor(color)
            .padding(style.padding)
            .background(bgColor.map { AnyView($0.clipShape(Circle())) } ?? AnyView(EmptyView()))
    }
}

// MARK: - Gallery Page Indicators

struct GalleryIndicators: View {
    let currentPage: Int
    let pageCount: Int
    let config: GalleryConfig
    
    var body: some View {
        let indicatorStyle = config.indicatorStyle ?? IndicatorStyle()
        let activeColor = ColorParser.parse(indicatorStyle.activeColor) ?? .blue
        let inactiveColor = ColorParser.parse(indicatorStyle.inactiveColor) ?? .gray.opacity(0.5)
        
        VStack {
            if indicatorStyle.position == "top" {
                indicatorRow(style: indicatorStyle, activeColor: activeColor, inactiveColor: inactiveColor)
                    .padding(.top, 16)
                Spacer()
            } else {
                Spacer()
                indicatorRow(style: indicatorStyle, activeColor: activeColor, inactiveColor: inactiveColor)
                    .padding(.bottom, 16)
            }
        }
    }
    
    @ViewBuilder
    private func indicatorRow(style: IndicatorStyle, activeColor: Color, inactiveColor: Color) -> some View {
        if config.orientation == .horizontal {
            HStack(spacing: style.spacing) {
                ForEach(0..<pageCount, id: \.self) { index in
                    indicatorDot(
                        isActive: index == currentPage,
                        style: style,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor
                    )
                }
            }
        } else {
            VStack(spacing: style.spacing) {
                ForEach(0..<pageCount, id: \.self) { index in
                    indicatorDot(
                        isActive: index == currentPage,
                        style: style,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func indicatorDot(isActive: Bool, style: IndicatorStyle, activeColor: Color, inactiveColor: Color) -> some View {
        if style.shape == "circle" {
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: style.size, height: style.size)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: style.size, height: style.size)
        }
    }
}
