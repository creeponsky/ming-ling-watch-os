import SwiftUI

struct AnimationUtils {
    // 弹性动画
    static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    
    // 缓入缓出动画
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    
    // 快速动画
    static let quick = Animation.easeInOut(duration: 0.15)
    
    // 慢速动画
    static let slow = Animation.easeInOut(duration: 0.8)
    
    // 脉冲动画
    static func pulse(duration: Double = 1.0) -> Animation {
        return Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)
    }
    
    // 呼吸动画
    static func breathing(duration: Double = 2.0) -> Animation {
        return Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)
    }
}

// 动画修饰符
struct PulseAnimation: ViewModifier {
    @State private var isAnimating = false
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(AnimationUtils.pulse(duration: duration), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct BreathingAnimation: ViewModifier {
    @State private var isAnimating = false
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.7 : 1.0)
            .animation(AnimationUtils.breathing(duration: duration), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func pulseAnimation(duration: Double = 1.0) -> some View {
        modifier(PulseAnimation(duration: duration))
    }
    
    func breathingAnimation(duration: Double = 2.0) -> some View {
        modifier(BreathingAnimation(duration: duration))
    }
} 