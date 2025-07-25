import SwiftUI

// MARK: - 宠物页面
struct PetPageView: View {
    let userElement: String
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    PetUtils.getElementBackgroundColor(for: userElement).opacity(0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 宠物图片
            VStack {
                Spacer()
                
                Image(PetUtils.getPetImageName(for: userElement))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.5), value: PetUtils.getPetImageName(for: userElement))
                
                Spacer()
            }
        }
    }
}

// MARK: - 预览
struct PetPageView_Previews: PreviewProvider {
    static var previews: some View {
        PetPageView(userElement: "金")
    }
} 