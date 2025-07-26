import SwiftUI

// MARK: - 欢迎对话框视图
struct WelcomeOverlayView: View {
    @StateObject private var demoManager = DemoManager.shared
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景遮挡层，用于遮挡底层的黑色区域
            if demoManager.showNotificationBar {
                PetUtils.getElementBackgroundColor(for: "木")
                    .opacity(0.95)
                    .ignoresSafeArea(.all)
                    .animation(.easeInOut(duration: 0.4), value: demoManager.showNotificationBar)
            }
            
            // 完全透明背景，只用于点击手势
            Color.clear
                .ignoresSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            GeometryReader { geometry in
                ZStack {
                    // 对话框 - 左上角
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello，我是木木")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Text("今天是你坚持健康的第6天")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .frame(width: 130, height: 70, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(PetUtils.getElementDialogColor(for: "木").opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(PetUtils.getElementDialogColor(for: "木"), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    // 向上挪动对话框
                    .position(x: 80, y: 45)
                    .opacity(demoManager.showNotificationBar ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.1), value: demoManager.showNotificationBar)

                    // 宠物说话图片 - 右下角，部分超出屏幕边界
                    Image("mumu_speak")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .position(x: geometry.size.width - 40, y: geometry.size.height - 40)
                        .opacity(demoManager.showNotificationBar ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: demoManager.showNotificationBar)
                }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: demoManager.showNotificationBar)
    }
}

#Preview {
    WelcomeOverlayView() {
        print("欢迎对话框被关闭")
    }
} 