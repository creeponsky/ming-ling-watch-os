import SwiftUI

// MARK: - 宠物显示视图
struct PetDisplayView: View {
    @StateObject private var demoManager = DemoManager.shared
    @Binding var showInteractionAnimation: Bool
    
    var body: some View {
        VStack {
            // 使用GIF动画或静态图片
            if showInteractionAnimation {
                // 点击交互动画
                GIFAnimationView(gifName: PetUtils.getMumuTouchGIFName(intimacyGrade: demoManager.demoProfile.intimacyGrade), isPlaying: true)
                    .frame(width: 150, height: 150)
                    .onAppear {
                        print("🎬 开始播放touch GIF: \(PetUtils.getMumuTouchGIFName(intimacyGrade: demoManager.demoProfile.intimacyGrade))")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            showInteractionAnimation = false
                            print("🎬 touch GIF播放结束")
                        }
                    }
            } else {
                // 正常状态显示 - 使用idle GIF
                Group {
                    if demoManager.demoProfile.intimacyGrade >= 2 {
                        // 2级和3级显示idle GIF
                        GIFAnimationView(
                            gifName: PetUtils.getMumuIdleGIFName(intimacyGrade: demoManager.demoProfile.intimacyGrade),
                            isPlaying: true
                        )
                        .frame(width: 150, height: 150)
                    } else {
                        // 1级显示静态图片
                        Image("mumu")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .scaleEffect(1.0)
                    }
                }
            }

            // 亲密度显示
            intimacyDisplayView
        }
    }
    
    // MARK: - 亲密度显示
    private var intimacyDisplayView: some View {
        HStack {
            ForEach(1...3, id: \.self) { level in
                Image(systemName: level <= demoManager.demoProfile.intimacyGrade ? "heart.fill" : "heart")
                    .foregroundColor(level <= demoManager.demoProfile.intimacyGrade ? .red : .gray)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - 触发交互动画
    private func triggerInteractionAnimation() {
        showInteractionAnimation = true
    }
}

#Preview {
    @State var showInteractionAnimation = false
    
    return PetDisplayView(showInteractionAnimation: $showInteractionAnimation)
} 