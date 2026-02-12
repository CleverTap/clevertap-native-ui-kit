// ============================================================================
// SDK INTERNAL IMPLEMENTATION - NOT CLIENT USAGE
// ============================================================================
// This shows SDK internal implementation. Clients only provide JSON configs.
// ============================================================================

// Complete Vertical Container Implementation (SwiftUI)

import SwiftUI

struct VerticalContainerView: View {
    let node: NativeDisplayNode
    let parentSize: CGSize
    let style: Style
    let onRenderChild: (NativeDisplayNode) -> AnyView

    var body: some View {
        VStack(
            alignment: alignment,
            spacing: spacing
        ) {
            ForEach(node.children ?? [], id: \.id) { child in
                onRenderChild(child)
            }
        }
        .frame(
            width: node.layout.width?.toCGFloat(parentSize: parentSize.width),
            height: node.layout.height?.toCGFloat(parentSize: parentSize.height)
        )
        .applyBackground(style.background)
        .padding(node.layout.padding?.toEdgeInsets() ?? EdgeInsets())
        .applyBorder(
            width: style.borderWidth,
            color: style.borderColor,
            radius: style.borderRadius
        )
    }

    private var alignment: HorizontalAlignment {
        switch node.arrangement?.strategy {
        case .start: return .leading
        case .center: return .center
        case .end: return .trailing
        default: return .leading
        }
    }

    private var spacing: CGFloat? {
        guard let arrangement = node.arrangement else { return nil }

        switch arrangement.strategy {
        case .spaced:
            return CGFloat(arrangement.spacing ?? 0)
        default:
            return nil  // SwiftUI handles spacing
        }
    }
}

// Extension: Dimension to CGFloat
extension Dimension {
    func toCGFloat(parentSize: CGFloat) -> CGFloat? {
        if let special = special {
            return special == .matchParent ? parentSize : nil
        }

        switch unit {
        case .dp: return CGFloat(value)
        case .percent: return parentSize * CGFloat(value) / 100
        case .px: return CGFloat(value)
        default: return CGFloat(value)
        }
    }
}

// Extension: Spacing to EdgeInsets
extension Spacing {
    func toEdgeInsets() -> EdgeInsets {
        if let all = all {
            return EdgeInsets(top: CGFloat(all), leading: CGFloat(all),
                            bottom: CGFloat(all), trailing: CGFloat(all))
        }

        return EdgeInsets(
            top: CGFloat(top ?? vertical ?? 0),
            leading: CGFloat(left ?? horizontal ?? 0),
            bottom: CGFloat(bottom ?? vertical ?? 0),
            trailing: CGFloat(right ?? horizontal ?? 0)
        )
    }
}

/*
USAGE:
let config = NativeDisplayConfig(
    root: NativeDisplayNode(
        id: "card",
        containerType: .vertical,
        arrangement: ChildArrangement(spacing: 12, strategy: .spaced),
        children: [...]
    )
)

VerticalContainerView(
    node: config.root,
    parentSize: geometry.size,
    style: resolvedStyle,
    onRenderChild: { child in AnyView(RenderNode(child)) }
)
*/
