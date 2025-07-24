import SwiftUI
import CoreMotion

// MARK: - 宠物动画视图
struct PetAnimationView: View {
    let userElement: String
    @State private var currentEmoji = "🐱"
    @State private var isAnimating = false
    @State private var animationScale: CGFloat = 1.0
    @State private var animationRotation: Double = 0.0
    @State private var showHeart = false
    @State private var heartOffset: CGFloat = 0
    
    private let motionManager = CMMotionManager()
    
    var body: some View {
        ZStack {
            // 背景
            Color.clear
            
            // 宠物表情
            Text(currentEmoji)
                .font(.system(size: 80))
                .scaleEffect(animationScale)
                .rotationEffect(.degrees(animationRotation))
                .animation(.easeInOut(duration: 0.3), value: animationScale)
                .animation(.easeInOut(duration: 0.5), value: animationRotation)
                .onTapGesture {
                    petThePet()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isAnimating {
                                petThePet()
                            }
                        }
                )
            
            // 爱心效果
            if showHeart {
                Text("❤️")
                    .font(.system(size: 30))
                    .offset(y: heartOffset)
                    .opacity(showHeart ? 1 : 0)
                    .animation(.easeOut(duration: 1.0), value: heartOffset)
                    .animation(.easeOut(duration: 1.0), value: showHeart)
            }
        }
        .onAppear {
            setupPet()
            startMotionDetection()
        }
        .onDisappear {
            stopMotionDetection()
        }
    }
    
    // MARK: - 设置宠物
    private func setupPet() {
        switch userElement {
        case "金":
            currentEmoji = "🐯"
        case "木":
            currentEmoji = "🐱"
        case "水":
            currentEmoji = "🐬"
        case "火":
            currentEmoji = "🦁"
        case "土":
            currentEmoji = "🐮"
        default:
            currentEmoji = "🐱"
        }
    }
    
    // MARK: - 抚摸宠物
    private func petThePet() {
        guard !isAnimating else { return }
        
        isAnimating = true
        
        // 缩放动画
        withAnimation(.easeInOut(duration: 0.2)) {
            animationScale = 1.2
        }
        
        // 旋转动画
        withAnimation(.easeInOut(duration: 0.3)) {
            animationRotation = 10
        }
        
        // 显示爱心
        showHeart = true
        heartOffset = -50
        
        // 重置动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animationScale = 1.0
                animationRotation = 0
            }
        }
        
        // 隐藏爱心
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showHeart = false
            heartOffset = 0
        }
        
        // 重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
        }
    }
    
    // MARK: - 摇一摇动画
    private func shakeThePet() {
        guard !isAnimating else { return }
        
        isAnimating = true
        
        // 剧烈摇晃动画
        withAnimation(.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)) {
            animationRotation = 15
        }
        
        // 缩放动画
        withAnimation(.easeInOut(duration: 0.2)) {
            animationScale = 1.3
        }
        
        // 切换表情
        let shakeEmojis = ["😵", "😱", "😨", "😰"]
        let randomEmoji = shakeEmojis.randomElement() ?? "😵"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentEmoji = randomEmoji
        }
        
        // 重置动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animationScale = 1.0
                animationRotation = 0
            }
        }
        
        // 恢复原表情
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            setupPet()
        }
        
        // 重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAnimating = false
        }
    }
    
    // MARK: - 开始运动检测
    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data else { return }
            
            let acceleration = sqrt(
                data.acceleration.x * data.acceleration.x +
                data.acceleration.y * data.acceleration.y +
                data.acceleration.z * data.acceleration.z
            )
            
            // 检测摇一摇（加速度大于2.0）
            if acceleration > 2.0 && !isAnimating {
                shakeThePet()
            }
        }
    }
    
    // MARK: - 停止运动检测
    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - 预览
struct PetAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        PetAnimationView(userElement: "木")
    }
} 