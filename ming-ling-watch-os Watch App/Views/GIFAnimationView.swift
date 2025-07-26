import SwiftUI

// MARK: - GIF动画视图
struct GIFAnimationView: View {
    let gifName: String
    let isPlaying: Bool
    
    @StateObject private var animationManager = GIFAnimationManager()
    
    init(gifName: String, isPlaying: Bool = true) {
        self.gifName = gifName
        self.isPlaying = isPlaying
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = animationManager.currentImage {
                    // 显示当前GIF帧
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    // 加载中状态
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            // 加载GIF动画
            animationManager.loadGIF(named: gifName)
            
            if isPlaying {
                animationManager.play()
            }
        }
        .onDisappear {
            animationManager.stop()
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                animationManager.play()
            } else {
                animationManager.pause()
            }
        }
    }
}



// MARK: - 预览
struct GIFAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GIFAnimationView(gifName: "animation1", isPlaying: true)
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
} 