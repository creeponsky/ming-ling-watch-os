import SwiftUI

// MARK: - 进化阶段枚举
// 细分进化动画阶段
enum EvolutionPhase {
    case initial            // 初始状态（2级宠物和2级亲密度显示）
    case fadeOut2nd         // 2级宠物淡出
    case waitAfterFadeOut   // 2级宠物淡出后等待
    case growGifFadeIn      // grow gif淡入（暂停）
    case growGifPaused      // grow gif暂停2s
    case growGifPlaying     // grow gif播放一次
    case growGifPauseAfterPlay // grow gif播放后暂停3s
    case growGifFadeOut     // grow gif淡出
    case finalFadeIn3rd     // 3级宠物和亲密度淡入
}

// MARK: - 进化动画视图
struct PetEvolutionAnimationView: View {
    @Binding var evolutionPhase: EvolutionPhase
    @Binding var showEvolutionAnimation: Bool
    
    var body: some View {
        ZStack {
            // 2级宠物图片（初始和淡出阶段）
            if evolutionPhase == .initial || evolutionPhase == .fadeOut2nd {
                VStack {
                    Image("mumu")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .opacity(evolutionPhase == .initial ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0), value: evolutionPhase)
                    HStack {
                        ForEach(1...3, id: \.self) { level in
                            Image(systemName: level <= 2 ? "heart.fill" : "heart")
                                .foregroundColor(level <= 2 ? .red : .gray)
                                .font(.caption)
                        }
                    }
                    .opacity(evolutionPhase == .initial ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0), value: evolutionPhase)
                }
            }
            // grow gif（淡入、暂停、播放、暂停、淡出阶段）
            if evolutionPhase == .growGifFadeIn || evolutionPhase == .growGifPaused || evolutionPhase == .growGifPlaying || evolutionPhase == .growGifPauseAfterPlay || evolutionPhase == .growGifFadeOut {
                GIFAnimationView(
                    gifName: "GIFs/mumu/grow/2-3",
                    isPlaying: evolutionPhase == .growGifPlaying
                )
                .frame(width: 200, height: 200)
                .offset(y: -20)
                .opacity(evolutionPhase == .growGifFadeOut ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 1.0), value: evolutionPhase)
            }
            // 3级宠物GIF（最终淡入阶段）
            if evolutionPhase == .finalFadeIn3rd {
                VStack {
                    // 显示3级idle GIF而不是静态图片
                    GIFAnimationView(
                        gifName: PetUtils.getMumuIdleGIFName(intimacyGrade: 3),
                        isPlaying: true
                    )
                    .frame(width: 150, height: 150)
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 1.2), value: evolutionPhase)
                    
                    HStack {
                        ForEach(1...3, id: \.self) { level in
                            Image(systemName: level <= 3 ? "heart.fill" : "heart")
                                .foregroundColor(level <= 3 ? .red : .gray)
                                .font(.caption)
                        }
                    }
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 1.2), value: evolutionPhase)
                }
            }
        }
    }
    

}

#Preview {
    @State var evolutionPhase: EvolutionPhase = .initial
    @State var showEvolutionAnimation = true
    
    return PetEvolutionAnimationView(
        evolutionPhase: $evolutionPhase,
        showEvolutionAnimation: $showEvolutionAnimation
    )
} 