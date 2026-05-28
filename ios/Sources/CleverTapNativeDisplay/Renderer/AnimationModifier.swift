// MARK: - Animation Modifier
// Entrance animation support for native display components

import SwiftUI

/// Apply entrance animation to a component.
/// Animation plays once when the component first appears.
///
/// This modifier wraps the entire view (including decorations) to ensure
/// backgrounds, borders, and shadows animate together with content.
struct EntranceAnimationModifier: ViewModifier {
    let animation: Animation?
    
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        Group {
            if let animation = animation, animation.type != .none {
                content
                    .opacity(animatedOpacity)
                    .offset(x: animatedOffsetX, y: animatedOffsetY)
                    .scaleEffect(x: animatedScaleX, y: animatedScaleY)
                    .onAppear {
                        // Trigger animation after a brief delay to ensure layout is complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            withAnimation(resolveSwiftUIAnimation(animation)) {
                                hasAppeared = true
                            }
                        }
                    }
            } else {
                content
            }
        }
    }
    
    // MARK: - Animation Values
    
    private var animatedOpacity: Double {
        guard let animation = animation else { return 1.0 }
        
        switch animation.type {
        case .fadeIn, .slideInLeft, .slideInRight, .slideInTop, .slideInBottom,
             .scaleIn, .fadeScaleIn, .fadeSlideIn:
            return hasAppeared ? 1.0 : 0.0
        case .none:
            return 1.0
        }
    }
    
    private var animatedOffsetX: CGFloat {
        guard let animation = animation, !hasAppeared else { return 0 }
        
        switch animation.type {
        case .slideInLeft:
            return -300
        case .slideInRight:
            return 300
        default:
            return 0
        }
    }
    
    private var animatedOffsetY: CGFloat {
        guard let animation = animation, !hasAppeared else { return 0 }
        
        switch animation.type {
        case .slideInTop:
            return -300
        case .slideInBottom:
            return 300
        case .fadeSlideIn:
            return 30  // Subtle slide
        default:
            return 0
        }
    }
    
    private var animatedScaleX: CGFloat {
        guard let animation = animation, !hasAppeared else { return 1.0 }
        
        switch animation.type {
        case .scaleIn:
            return 0.8
        case .fadeScaleIn:
            return 0.9  // Subtle scale
        default:
            return 1.0
        }
    }
    
    private var animatedScaleY: CGFloat {
        guard let animation = animation, !hasAppeared else { return 1.0 }
        
        switch animation.type {
        case .scaleIn:
            return 0.8
        case .fadeScaleIn:
            return 0.9  // Subtle scale
        default:
            return 1.0
        }
    }
    
    // MARK: - Animation Resolution
    
    /// Convert Animation config to SwiftUI Animation.
    private func resolveSwiftUIAnimation(_ animation: Animation) -> SwiftUI.Animation {
        let duration = Double(animation.duration) / 1000.0  // Convert ms to seconds
        let delay = Double(animation.delay) / 1000.0
        
        let timingCurve = resolveTimingCurve(animation.easing, duration: duration)
        
        return timingCurve.delay(delay)
    }
    
    /// Resolve easing enum to SwiftUI timing curve with proper duration.
    private func resolveTimingCurve(_ easing: Easing, duration: Double) -> SwiftUI.Animation {
        switch easing {
        case .linear:
            return .linear(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        case .easeInBack:
            // Approximate back easing with easeInOut for more bounce
            return .easeInOut(duration: duration)
        case .easeOutBack:
            // Approximate back easing with easeOut
            return .easeOut(duration: duration)
        case .spring:
            // For spring, we use response instead of duration
            return .spring(response: duration, dampingFraction: 0.7)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply entrance animation to this view.
    ///
    /// - Parameter animation: Animation configuration from JSON
    /// - Returns: View with animation modifier applied
    ///
    /// Note: This should be applied AFTER all decorations (background, border, shadow)
    /// to ensure the entire styled view animates together.
    func applyEntranceAnimation(_ animation: Animation?) -> some View {
        self.modifier(EntranceAnimationModifier(animation: animation))
    }
}
