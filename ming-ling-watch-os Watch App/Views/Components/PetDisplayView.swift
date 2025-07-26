import SwiftUI

// MARK: - 宠物显示视图
struct PetDisplayView: View {
    @Binding var showInteractionAnimation: Bool
    var forceGrade: Int? = nil // 新增：强制显示特定等级
    
    @StateObject private var demoManager = DemoManager.shared
    
    var body: some View {
        // 获取当前应该显示的等级
        let displayGrade: Int = {
            // 如果亲密度已达到3级，但还不能显示3级gif（grow动画未播放完成），强制显示2级
            if demoManager.demoProfile.intimacyGrade >= 3 && !demoManager.canShowLevel3Gif {
                print("🎬 PetDisplayView: 亲密度3级但未允许显示3级gif，显示2级")
                return 2
            } 
            // 如果正在等待播放grow动画，也显示2级
            else if demoManager.shouldPlayEvolutionAnimation && demoManager.demoProfile.intimacyGrade >= 3 {
                print("🎬 PetDisplayView: 等待播放grow动画，显示2级")
                return 2
            } 
            else {
                // 否则显示当前亲密度等级
                print("🎬 PetDisplayView: 显示等级 \(demoManager.demoProfile.intimacyGrade)")
                return demoManager.demoProfile.intimacyGrade
            }
        }()
        
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
                    if displayGrade >= 2 {
                        // 2级和3级显示idle GIF
                        GIFAnimationView(
                            gifName: PetUtils.getMumuIdleGIFName(intimacyGrade: displayGrade),
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