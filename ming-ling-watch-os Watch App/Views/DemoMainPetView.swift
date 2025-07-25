import SwiftUI

// MARK: - Demo主宠物视图
struct DemoMainPetView: View {
    @StateObject private var demoManager = DemoManager.shared
    @StateObject private var gifAnimationManager = GIFAnimationManager.shared
    @State private var dragOffset: CGFloat = 0
    @State private var showUpgradeAnimation = false
    @State private var isPlayingUpgradeGIF = false
    @State private var showInteractionAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变 - 木属性主题
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // 通知栏
                    if demoManager.showNotificationBar {
                        notificationBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // 主内容区域
                    mainContentArea
                    
                    Spacer()
                    
                    // 底部控制区域
                    bottomControlArea
                }
                
                // 上滑健康检测面板
                if dragOffset < -50 {
                    healthDetectionPanel
                        .offset(y: max(0, 100 + dragOffset))
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.y
                }
                .onEnded { value in
                    if value.translation.y < -100 {
                        // 上滑超过阈值，显示健康检测面板
                        withAnimation(.spring()) {
                            dragOffset = -200
                        }
                    } else {
                        // 回弹
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            setupDemoState()
        }
        .onChange(of: demoManager.demoState) { newState in
            handleStateChange(newState)
        }
    }
    
    // MARK: - 通知栏
    private var notificationBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text(demoManager.notificationMessage)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - 主内容区域
    private var mainContentArea: some View {
        VStack {
            if showUpgradeAnimation && isPlayingUpgradeGIF {
                // 升级动画
                upgradeAnimationView
            } else {
                // 正常宠物显示
                petDisplayView
            }
        }
    }
    
    // MARK: - 宠物显示视图
    private var petDisplayView: some View {
        VStack {
            // 使用GIF动画或静态图片
            if showInteractionAnimation {
                // 点击交互动画
                GIFAnimationView(gifName: "GIFs/mumu/happy/\(demoManager.demoProfile.intimacyGrade)")
                    .frame(width: 150, height: 150)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showInteractionAnimation = false
                        }
                    }
            } else {
                // 正常状态显示
                Image("mumu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .scaleEffect(1.0)
                    .onTapGesture {
                        if demoManager.demoState == .voiceInteraction && demoManager.demoProfile.intimacyGrade >= 3 {
                            triggerInteractionAnimation()
                        }
                    }
            }
            
            // 亲密度显示
            intimacyDisplayView
        }
    }
    
    // MARK: - 升级动画视图
    private var upgradeAnimationView: some View {
        VStack {
            GIFAnimationView(gifName: "GIFs/mumu/happy/1")
                .frame(width: 150, height: 150)
            
            Text("🎉 亲密度升级！")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .scaleEffect(showUpgradeAnimation ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showUpgradeAnimation)
        }
    }
    
    // MARK: - 亲密度显示
    private var intimacyDisplayView: some View {
        VStack(spacing: 4) {
            HStack {
                ForEach(1...3, id: \.self) { level in
                    Image(systemName: level <= demoManager.demoProfile.intimacyGrade ? "heart.fill" : "heart")
                        .foregroundColor(level <= demoManager.demoProfile.intimacyGrade ? .red : .gray)
                        .font(.caption)
                }
            }
            
            Text("等级 \(demoManager.demoProfile.intimacyGrade)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - 底部控制区域
    private var bottomControlArea: some View {
        HStack {
            Spacer()
            
            // 语音录音按钮
            if demoManager.demoState == .voiceInteraction {
                voiceRecordingButton
            }
            
            // 退出按钮
            if demoManager.canExitDemo {
                Button(action: {
                    demoManager.exitDemo()
                }) {
                    Text("退出")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 语音录音按钮
    private var voiceRecordingButton: some View {
        Button(action: {
            if demoManager.isRecording {
                demoManager.stopRecording()
            } else {
                demoManager.startRecording()
            }
        }) {
            Image(systemName: demoManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.title)
                .foregroundColor(demoManager.isRecording ? .red : .green)
                .scaleEffect(demoManager.isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: demoManager.isRecording)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!demoManager.canExitDemo)
    }
    
    // MARK: - 健康检测面板
    private var healthDetectionPanel: some View {
        VStack(spacing: 16) {
            Text("健康检测")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            Button(action: {
                demoManager.triggerSedentaryDetection()
                withAnimation(.spring()) {
                    dragOffset = 0
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("开始久坐检测")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("10秒后触发提醒")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(demoManager.demoState != .mainPage)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - 设置Demo状态
    private func setupDemoState() {
        // 确保在主页面状态时显示通知栏
        if demoManager.demoState == .mainPage && !demoManager.showNotificationBar {
            demoManager.showNotificationBar = true
            demoManager.notificationMessage = "Hello，我是木木；今天是你坚持健康的1天"
        }
    }
    
    // MARK: - 处理状态变化
    private func handleStateChange(_ newState: DemoState) {
        switch newState {
        case .intimacyUpgrade:
            showUpgradeAnimation()
        case .voiceInteraction:
            // 隐藏通知栏
            withAnimation {
                demoManager.showNotificationBar = false
            }
        default:
            break
        }
    }
    
    // MARK: - 显示升级动画
    private func showUpgradeAnimation() {
        showUpgradeAnimation = true
        isPlayingUpgradeGIF = true
        
        // 3秒后隐藏升级动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showUpgradeAnimation = false
                isPlayingUpgradeGIF = false
            }
        }
    }
    
    // MARK: - 触发交互动画
    private func triggerInteractionAnimation() {
        showInteractionAnimation = true
    }
}

// MARK: - 预览
struct DemoMainPetView_Previews: PreviewProvider {
    static var previews: some View {
        DemoMainPetView()
    }
}