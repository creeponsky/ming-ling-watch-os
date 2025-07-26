import SwiftUI
import WatchKit

// MARK: - Demo主宠物视图
struct DemoMainPetView: View {
    @StateObject private var demoManager = DemoManager.shared
    @StateObject private var audioRecorderManager = AudioRecorderManager.shared
    @StateObject private var transcriptionAPIService = TranscriptionAPIService.shared
    @StateObject private var chatAPIService = ChatAPIService.shared
    @StateObject private var speechAPIService = SpeechAPIService.shared
    @StateObject private var audioPlayerManager = AudioPlayerManager.shared
    
    @State private var showUpgradeAnimation = false
    @State private var isPlayingUpgradeGIF = false
    @State private var showInteractionAnimation = false
    @State private var showHealthDetection = false
    @State private var showVoiceCompleted = false
    @State private var showEvolutionAnimation = false
    @State private var evolutionPhase: EvolutionPhase = .initial
    @State private var swipeOffset: CGFloat = 0
    @State private var isSwipeActive = false
    @State private var isWelcomeActive = false // 新增：跟踪欢迎对话框状态
    @State private var recordingState: RecordingState = .idle // 新增：录音状态
    @State private var isLongPressing = false // 新增：长按状态
    @State private var shouldShowMainContent = false // 新增：控制主内容首次显示

    var body: some View {
        GeometryReader { geometry in
                ZStack {
                    // 背景纯色 - 木属性主题
                    PetUtils.getElementBackgroundColor(for: "木")
                        .ignoresSafeArea(.all)

                    // 主内容区域
                    VStack {

                    if shouldShowMainContent {
                        Spacer()
                        mainContentArea
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.8), value: shouldShowMainContent)
                            .gesture(
                                // 使用DragGesture来更精确地控制手势
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        // 按下时的处理
                                        if demoManager.demoState == .voiceInteraction && demoManager.demoProfile.intimacyGrade >= 3 {
                                            if recordingState == .idle && !isLongPressing {
                                                // 开始长按计时
                                                isLongPressing = true
                                                // 0.5秒后开始录音
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    if isLongPressing && recordingState == .idle {
                                                        print("🎙️ 长按开始录音...")
                                                        WKInterfaceDevice.current().play(.start)
                                                        startVoiceRecording()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        // 松开时的处理
                                        if demoManager.demoState == .voiceInteraction && demoManager.demoProfile.intimacyGrade >= 3 {
                                            if recordingState == .recording {
                                                // 如果正在录音，停止录音
                                                print("🎙️ 长按停止录音.")
                                                WKInterfaceDevice.current().play(.stop)
                                                stopVoiceRecording()
                                            } else if isLongPressing && recordingState == .idle {
                                                // 如果是短按（没有开始录音），触发交互动画（只有亲密度3才有touch动画）
                                                if demoManager.demoProfile.intimacyGrade >= 3 {
                                                    showInteractionAnimation = true
                                                }
                                            }
                                            isLongPressing = false
                                        } else {
                                            // 非语音交互状态，只有亲密度3才能触发touch动画
                                            if demoManager.demoProfile.intimacyGrade >= 3 {
                                                showInteractionAnimation = true
                                            }
                                            isLongPressing = false
                                        }
                                    }
                            )
                    }

                        Spacer()
                    }
                    .offset(x: (demoManager.demoProfile.intimacyGrade < 3 &&
                               (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction)) ? swipeOffset : 0)
                    .opacity((demoManager.demoProfile.intimacyGrade < 3 &&
                             (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction)) ? max(0.0, 1.0 - abs(swipeOffset) / 200.0) : 1.0)

                    // 右上角退出按钮
                    if demoManager.canExitDemo && !showEvolutionAnimation && 
                       (recordingState == .idle || recordingState == .playing || recordingState == .error) &&
                       shouldShowMainContent {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    demoManager.exitDemo()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.3))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                            }
                            Spacer()
                        }
                        .zIndex(500) // 确保在其他内容之上，但在录音指示器和欢迎对话框之下
                        .opacity(0.6) // 半透明效果
                    }

                    // 健康检测页面预览（左滑时显示）
                    if isSwipeActive && swipeOffset < -50 && demoManager.demoProfile.intimacyGrade < 3 &&
                       (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction) {
                        DemoHealthDetectionView()
                            .offset(x: geometry.size.width + swipeOffset)
                            .opacity(abs(swipeOffset) / 200.0)
                            .allowsHitTesting(false) // 防止手势冲突
                    }

                    // 录音指示器
                    RecordingIndicatorView(recordingState: recordingState)
                        .zIndex(999) // 在欢迎对话框下方
                    
                    // 全屏欢迎对话框
                    if demoManager.showNotificationBar && demoManager.demoState == .mainPage {
                        WelcomeOverlayView {
                            dismissWelcome()
                        }
                        .zIndex(1000) // 确保在最上层
                    }
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        // 只处理左滑手势，且亲密度小于3级，且在允许的状态下，且欢迎对话框未激活
                        if value.translation.width < 0 && demoManager.demoProfile.intimacyGrade < 3 &&
                           (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction) && !isWelcomeActive {
                            isSwipeActive = true
                            swipeOffset = value.translation.width
                            print("🔄 左滑手势: translation.width = \(value.translation.width)")
                        }
                    }
                    .onEnded { value in
                        print("🔄 手势结束: translation.width = \(value.translation.width), 当前状态 = \(demoManager.demoState.rawValue)")

                        if value.translation.width < -80 {
                            print("✅ 手势距离满足条件")

                            // 如果在欢迎状态，先关闭欢迎对话框
                            if isWelcomeActive && demoManager.demoState == .mainPage {
                                print("👋 关闭欢迎对话框")
                                dismissWelcome()
                            } else if (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction) && demoManager.demoProfile.intimacyGrade < 3 {
                                print("✅ 状态满足条件，触发导航")
                                // 直接触发导航，让navigationDestination处理过渡
                                showHealthDetection = true
                                print("🔗 showHealthDetection 设置为 true")
                                // 重置滑动状态
                                swipeOffset = 0
                                isSwipeActive = false
                            } else {
                                if demoManager.demoProfile.intimacyGrade >= 3 {
                                    print("❌ 亲密度已达到3级，禁用健康检测功能")
                                } else {
                                    print("❌ 状态不满足条件，当前状态: \(demoManager.demoState.rawValue)")
                                }
                                // 重置滑动状态
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    swipeOffset = 0
                                    isSwipeActive = false
                                }
                            }
                        } else {
                            print("❌ 手势距离不满足条件，需要 < -80，实际: \(value.translation.width)")
                            // 重置滑动状态
                            withAnimation(.easeInOut(duration: 0.3)) {
                                swipeOffset = 0
                                isSwipeActive = false
                            }
                        }
                    }
            )
                    .onAppear {
            setupDemoState()
            // 初始化欢迎对话框状态 - 如果是主页面状态，等待DemoManager控制欢迎对话框显示
            if demoManager.demoState == .mainPage {
                // 主内容区域默认不显示，等待欢迎对话框关闭后再显示
                shouldShowMainContent = false
                // 根据当前showNotificationBar状态决定是否显示欢迎对话框
                isWelcomeActive = demoManager.showNotificationBar
                // 不强制设置showNotificationBar，让DemoManager控制
            } else {
                isWelcomeActive = false
                shouldShowMainContent = true
            }
            print("🎬 DemoMainPetView 出现 - 当前状态: \(demoManager.demoState.rawValue), 欢迎状态: \(isWelcomeActive), 主内容显示: \(shouldShowMainContent), showNotificationBar: \(demoManager.showNotificationBar)")
        }
            .onChange(of: demoManager.demoState) { newState in
                handleStateChange(newState)
            }
                    .onChange(of: demoManager.showNotificationBar) { newValue in
            if demoManager.demoState == .mainPage {
                isWelcomeActive = newValue
                // 只有当欢迎对话框关闭时才显示主内容
                if !newValue {
                    shouldShowMainContent = true
                }
            }
            print("🎬 欢迎对话框状态变化: \(newValue), 欢迎状态: \(isWelcomeActive), 主内容显示: \(shouldShowMainContent)")
        }
            .navigationDestination(isPresented: $showHealthDetection) {
                DemoHealthDetectionView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .onChange(of: showHealthDetection) { newValue in
                print("🔗 showHealthDetection 变化: \(newValue)")
                // 当从健康检测页面返回时，确保主内容显示
                if !newValue {
                    // 从健康检测页面返回
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            shouldShowMainContent = true
                        }
                        print("📱 从健康检测页面返回，恢复主内容显示")
                    }
                }
            }

            // 监听AI对话流程的状态变化
            .onChange(of: transcriptionAPIService.transcribedText) { newText in
                if !newText.isEmpty && recordingState == .processing {
                    print("📝 转录完成: \(newText)")
                    chatAPIService.sendMessage(content: newText)
                }
            }
            .onChange(of: chatAPIService.responseContent) { newContent in
                if !newContent.isEmpty && recordingState == .processing {
                    print("🤖 AI回复: \(newContent)")
                    speechAPIService.generateSpeech(text: newContent)
                }
            }
            .onChange(of: speechAPIService.audioData) { newData in
                if let data = newData, recordingState == .processing {
                    recordingState = .playing
                    audioPlayerManager.playAudio(data: data) {
                        DispatchQueue.main.async {
                            self.recordingState = .idle
                            // 添加完成触觉反馈
                            WKInterfaceDevice.current().play(.success)
                            print("✅ AI对话流程结束")
                        }
                    }
                }
            }
            .onChange(of: transcriptionAPIService.errorMessage) { error in
                if let error = error, recordingState == .processing {
                    print("❌ 转录失败: \(error)")
                    recordingState = .error
                    // 添加错误触觉反馈
                    WKInterfaceDevice.current().play(.failure)
                    // 3秒后自动恢复到空闲状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        recordingState = .idle
                    }
                }
            }
            .onChange(of: chatAPIService.errorMessage) { error in
                if let error = error, recordingState == .processing {
                    print("❌ 获取AI回复失败: \(error)")
                    recordingState = .error
                    // 添加错误触觉反馈
                    WKInterfaceDevice.current().play(.failure)
                    // 3秒后自动恢复到空闲状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        recordingState = .idle
                    }
                }
            }
            .onChange(of: speechAPIService.errorMessage) { error in
                if let error = error, recordingState == .processing {
                    print("❌ 语音合成失败: \(error)")
                    recordingState = .error
                    // 添加错误触觉反馈
                    WKInterfaceDevice.current().play(.failure)
                    // 3秒后自动恢复到空闲状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        recordingState = .idle
                    }
                }
            }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 主内容区域
    private var mainContentArea: some View {
        VStack {
            if showEvolutionAnimation {
                // 进化动画
                PetEvolutionAnimationView(
                    evolutionPhase: $evolutionPhase,
                    showEvolutionAnimation: $showEvolutionAnimation
                )
            } else if showUpgradeAnimation && isPlayingUpgradeGIF {
                // 升级动画
                upgradeAnimationView
            } else {
                // 正常宠物显示
                PetDisplayView(showInteractionAnimation: $showInteractionAnimation)
            }
        }
    }





    // MARK: - 升级动画视图
    private var upgradeAnimationView: some View {
        VStack {
            GIFAnimationView(gifName: "GIFs/mumu/grow/2-3", isPlaying: isPlayingUpgradeGIF)
                .frame(width: 150, height: 150)

            Text("🎉 亲密度升级！")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .scaleEffect(showUpgradeAnimation ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showUpgradeAnimation)
        }
    }






    

    
    // MARK: - 开始语音录音
    private func startVoiceRecording() {
        withAnimation { 
            isLongPressing = true
            recordingState = .recording
        }
        audioRecorderManager.startRecording()
        print("🎙️ 开始录音，按住继续录音")
    }
    
    // MARK: - 停止语音录音
    private func stopVoiceRecording() {
        withAnimation { 
            isLongPressing = false
            recordingState = .processing
        }
        audioRecorderManager.stopRecording { url in
            guard let audioURL = url else {
                print("❌ 录音文件URL无效")
                DispatchQueue.main.async {
                    self.recordingState = .error
                    // 添加错误触觉反馈
                    WKInterfaceDevice.current().play(.failure)
                    // 3秒后自动恢复到空闲状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.recordingState = .idle
                    }
                }
                return
            }
            print("▶️ 开始处理音频: \(audioURL)")
            self.transcriptionAPIService.transcribeAudio(fileURL: audioURL)
        }
    }



    // MARK: - 设置Demo状态
    private func setupDemoState() {
        // 检查是否需要播放进化动画
        if demoManager.shouldPlayEvolutionAnimation && demoManager.demoProfile.intimacyGrade >= 3 {
            print("🎬 检测到需要播放进化动画")
            startEvolutionAnimation()
            demoManager.shouldPlayEvolutionAnimation = false
            demoManager.saveDemoData()
        }

        // 标记已显示欢迎对话框（由setBirthday方法控制显示时机）
        if demoManager.demoState == .mainPage && !demoManager.hasShownWelcome {
            demoManager.hasShownWelcome = true
            demoManager.saveDemoData() // 保存状态
        }
    }

    // MARK: - 处理状态变化
    private func handleStateChange(_ newState: DemoState) {
        switch newState {
        case .intimacyUpgrade:
            startUpgradeAnimation()
        case .voiceInteraction:
            // 隐藏通知栏，确保主内容显示
            withAnimation {
                demoManager.showNotificationBar = false
                isWelcomeActive = false
                shouldShowMainContent = true
            }
        case .mainPage:
            // 如果回到主页面，检查是否需要显示欢迎对话框
            if demoManager.showNotificationBar {
                // 需要显示欢迎对话框
                shouldShowMainContent = false
                isWelcomeActive = true
            } else {
                // 直接显示主内容（比如从其他页面返回）
                shouldShowMainContent = true
                isWelcomeActive = false
            }
        case .sedentaryTrigger, .stepDetection:
            // 久坐检测和步数检测状态，确保主内容显示
            if !isWelcomeActive {
                shouldShowMainContent = true
            }
        default:
            // 对于其他状态，如果不是欢迎状态，确保主内容显示
            if !isWelcomeActive {
                shouldShowMainContent = true
            }
            break
        }
    }

    // MARK: - 开始进化动画
    private func startEvolutionAnimation() {
        print("🎬 开始进化动画流程")
        showEvolutionAnimation = true
        evolutionPhase = .initial
        // 1. 2级宠物淡出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            evolutionPhase = .fadeOut2nd
            print("🎬 2级宠物开始淡出")
            // 2. 淡出后等待0.5s（减少等待时间）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                evolutionPhase = .waitAfterFadeOut
                print("🎬 2级宠物淡出后等待0.5s")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 3. grow gif淡入（暂停）
                    evolutionPhase = .growGifFadeIn
                    print("🎬 grow gif淡入（暂停）")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 4. grow gif暂停1s（减少暂停时间）
                        evolutionPhase = .growGifPaused
                        print("🎬 grow gif暂停1s")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // 5. grow gif播放一次
                            evolutionPhase = .growGifPlaying
                            print("🎬 grow gif开始播放一次")
                            // 假设gif播放时间为3s
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                // 6. grow gif播放后暂停1s（减少停留时间）
                                evolutionPhase = .growGifPauseAfterPlay
                                print("🎬 grow gif播放后暂停1s")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    // 7. grow gif淡出
                                    evolutionPhase = .growGifFadeOut
                                    print("🎬 grow gif淡出")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        // 8. 直接显示3级idle动画（不显示静态图片）
                                        evolutionPhase = .finalFadeIn3rd
                                        print("🎬 3级idle动画淡入")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                showEvolutionAnimation = false
                                            }
                                            print("🎬 进化动画结束，恢复正常显示")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 显示升级动画
    private func startUpgradeAnimation() {
        showUpgradeAnimation = true
        isPlayingUpgradeGIF = false // 初始不播放

        // 1秒后开始播放GIF
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isPlayingUpgradeGIF = true
            print("🎬 开始播放升级GIF动画")

            // 假设GIF播放时间为2秒，然后暂停
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isPlayingUpgradeGIF = false
                print("🎬 升级GIF动画播放完成，暂停")

                // 再等待5秒后隐藏整个升级动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showUpgradeAnimation = false
                    }
                    print("🎬 升级动画结束，进入语音交互阶段")
                }
            }
        }
    }



    // MARK: - 关闭欢迎对话框
    private func dismissWelcome() {
        withAnimation(.easeInOut(duration: 0.4)) {
            demoManager.showNotificationBar = false
            isWelcomeActive = false
        }
        
        // 延迟一点时间后再显示主内容，创建更自然的过渡
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.8)) {
                shouldShowMainContent = true
            }
        }
        print("👋 欢迎对话框已关闭，主内容开始淡入")
    }


}

// MARK: - 预览
struct DemoMainPetView_Previews: PreviewProvider {
    static var previews: some View {
        DemoMainPetView()
    }
}
