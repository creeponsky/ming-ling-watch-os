import SwiftUI

// MARK: - 宠物页面
struct PetPageView: View {
    let userElement: String
    @StateObject private var intimacyChangeManager = IntimacyChangeManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        ZStack {
            // 背景纯色 - 使用元素主题背景色
            PetUtils.getElementBackgroundColor(for: userElement)
                .ignoresSafeArea()
            
            // 宠物图片和亲密值通知
            VStack {
                Spacer()
                
                // 根据五行属性和亲密值等级决定显示静态图片还是GIF动画
                if userElement == "木" && profileManager.userProfile.intimacyGrade > 1 {
                    // 显示GIF动画 - 木属性且亲密值等级大于1
                    GIFAnimationView(
                        gifName: PetUtils.getMumuIdleGIFName(intimacyGrade: profileManager.userProfile.intimacyGrade),
                        isPlaying: true
                    )
                    .frame(maxWidth: 200, maxHeight: 200)
                } else {
                    // 显示静态图片 - 其他情况
                    Image(PetUtils.getPetImageName(for: userElement))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.5), value: PetUtils.getPetImageName(for: userElement))
                }
                
                // 亲密值变化通知
                if let change = intimacyChangeManager.currentChange {
                    IntimacyChangeView(points: change.points, isPositive: change.isPositive)
                        .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - 预览
struct PetPageView_Previews: PreviewProvider {
    static var previews: some View {
        PetPageView(userElement: "木")
    }
} 