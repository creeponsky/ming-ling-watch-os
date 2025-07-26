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
    

    @State private var showInteractionAnimation = false
    // 新增：防止重复触发touch动画
    @State private var touchAnimationCooldown = false
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
    // 新增：控制grow动画前的显示状态
    @State private var isWaitingForGrowAnimation = false
    @State private var isPageActive = false // 新增：页面是否处于活跃状态
    @Environment(\.scenePhase) private var scenePhase // 新增：场景状态

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
                                // 使用DragGesture来更精确地控制手势，但排除右上角区域
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // 检查点击位置是否在右上角退出按钮区域（约60x60的区域）
                                        let location = value.startLocation
                                        let screenWidth = WKInterfaceDevice.current().screenBounds.width
                                        let isInExitButtonArea = location.x > screenWidth - 60 && location.y < 60
                                        
                                        // 如果在退出按钮区域，不处理宠物手势
                                        if isInExitButtonArea {
                                            return
                                        }
                                        
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
                                    .onEnded { value in
                                        // 检查点击位置是否在右上角退出按钮区域
                                        let location = value.startLocation
                                        let screenWidth = WKInterfaceDevice.current().screenBounds.width
                                        let isInExitButtonArea = location.x > screenWidth - 60 && location.y < 60
                                        
                                        // 如果在退出按钮区域，不处理宠物手势
                                        if isInExitButtonArea {
                                            isLongPressing = false
                                            return
                                        }
                                        
                                        // 松开时的处理
                                        if demoManager.demoState == .voiceInteraction && demoManager.demoProfile.intimacyGrade >= 3 {
                                            if recordingState == .recording {
                                                // 如果正在录音，停止录音
                                                print("🎙️ 长按停止录音.")
                                                WKInterfaceDevice.current().play(.stop)
                                                stopVoiceRecording()
                                            } else if isLongPressing && recordingState == .idle {
                                                // 如果是短按（没有开始录音），触发交互动画（只有亲密度3才有touch动画）
                                                if demoManager.demoProfile.intimacyGrade >= 3 && !touchAnimationCooldown {
                                                    triggerTouchAnimation()
                                                }
                                            }
                                            isLongPressing = false
                                        } else {
                                            // 非语音交互状态，只有亲密度3才能触发touch动画
                                            if demoManager.demoProfile.intimacyGrade >= 3 && !touchAnimationCooldown {
                                                triggerTouchAnimation()
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
                                    print("🚪 点击退出Demo按钮")
                                    demoManager.exitDemo()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.title2) // 放大字体
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40) // 放大点击区域（2倍）
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.3))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                                .allowsHitTesting(true) // 确保按钮可以接收点击
                                .scaleEffect(1.0) // 保持正常大小
                            }
                            Spacer()
                        }
                        .zIndex(1001) // 提高 zIndex，确保在所有内容之上（包括欢迎对话框）
                        .opacity(0.1) // 降低透明度到 10%
                        .allowsHitTesting(true) // 确保整个区域可以接收点击
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
                        // 检查起始位置是否在右上角退出按钮区域
                        let location = value.startLocation
                        let screenWidth = WKInterfaceDevice.current().screenBounds.width
                        let isInExitButtonArea = location.x > screenWidth - 60 && location.y < 60
                        
                        // 如果在退出按钮区域，不处理左滑手势
                        if isInExitButtonArea {
                            return
                        }
                        
                        // 只处理左滑手势，且亲密度小于3级，且在允许的状态下，且欢迎对话框未激活
                        if value.translation.width < 0 && demoManager.demoProfile.intimacyGrade < 3 &&
                           (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction) && !isWelcomeActive {
                            isSwipeActive = true
                            swipeOffset = value.translation.width
                            // print("🔄 左滑手势: translation.width = \(value.translation.width)")
                        }
                    }
                    .onEnded { value in
                        // 检查起始位置是否在右上角退出按钮区域
                        let location = value.startLocation
                        let screenWidth = WKInterfaceDevice.current().screenBounds.width
                        let isInExitButtonArea = location.x > screenWidth - 60 && location.y < 60
                        
                        // 如果在退出按钮区域，不处理左滑手势
                        if isInExitButtonArea {
                            return
                        }
                        
                        // print("🔄 手势结束: translation.width = \(value.translation.width), 当前状态 = \(demoManager.demoState.rawValue)")

                        if value.translation.width < -80 {
                            // print("✅ 手势距离满足条件")

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
                            // print("❌ 手势距离不满足条件，需要 < -80，实际: \(value.translation.width)")
                            // 重置滑动状态
                            withAnimation(.easeInOut(duration: 0.3)) {
                                swipeOffset = 0
                                isSwipeActive = false
                            }
                        }
                    }
            )
                    .onAppear {
            // 设置页面为活跃状态
            isPageActive = true
            
            setupDemoState()
            // 重新计算倒计时，确保后台状态恢复正常
            demoManager.recalculateCountdown()
            
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
            
            // 检查是否需要显示grow动画（仅在页面活跃时）
            checkForGrowAnimation()
        }
        .onDisappear {
            // 设置页面为非活跃状态
            isPageActive = false
            print("🎬 DemoMainPetView onDisappear - 页面离开")
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
            .onChange(of: scenePhase) { phase in
                handleScenePhaseChange(phase)
            }
            .onChange(of: demoManager.demoProfile.stepGoalCompleted) { completed in
                // 监听步数目标完成状态变化，仅在页面活跃时触发grow动画
                if completed && isPageActive {
                    print("🎬 步数目标完成且页面活跃，检查grow动画")
                    checkForGrowAnimation()
                }
            }
            .onChange(of: demoManager.shouldPlayEvolutionAnimation) { shouldPlay in
                // 监听进化动画标记变化，仅在页面活跃时触发
                if shouldPlay && isPageActive {
                    print("🎬 进化动画标记激活且页面活跃，检查grow动画")
                    checkForGrowAnimation()
                }
            }
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
            } else {
                // 正常宠物显示
                PetDisplayView(showInteractionAnimation: $showInteractionAnimation)
            }
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
        // 标记已显示欢迎对话框（由setBirthday方法控制显示时机）
        if demoManager.demoState == .mainPage && !demoManager.hasShownWelcome {
            demoManager.hasShownWelcome = true
            demoManager.saveDemoData() // 保存状态
        }
        
        // 注意：进化动画的检查和触发移到了checkForGrowAnimation()方法中
        // 这样避免在setupDemoState中重复处理动画逻辑
    }

    // MARK: - 处理状态变化
    private func handleStateChange(_ newState: DemoState) {
        switch newState {
        case .voiceInteraction:
            // 隐藏通知栏，确保主内容显示
            withAnimation {
                demoManager.showNotificationBar = false
                isWelcomeActive = false
                shouldShowMainContent = true
            }
            
            // 检查是否需要播放grow动画
            checkForGrowAnimation()
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
            
            // 检查是否需要播放grow动画
            checkForGrowAnimation()
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
        
        // 检查页面是否活跃
        guard isPageActive else {
            print("⚠️ 页面不活跃，延迟播放grow动画")
            isWaitingForGrowAnimation = false
            return
        }
        
        // 确保只播放一次
        guard demoManager.shouldPlayEvolutionAnimation else {
            print("⚠️ 不需要播放进化动画")
            isWaitingForGrowAnimation = false
            return
        }
        
        showEvolutionAnimation = true
        evolutionPhase = .initial
        
        // 清除播放标记
        demoManager.shouldPlayEvolutionAnimation = false
        demoManager.saveDemoData()
        
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
                                                isWaitingForGrowAnimation = false // 重置等待状态
                                            }
                                            // 通知DemoManager grow动画播放完成
                                            DemoManager.shared.onGrowAnimationCompleted()
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

    // MARK: - 触发Touch动画
    private func triggerTouchAnimation() {
        print("👆 触发touch动画")
        showInteractionAnimation = true
        
        // 2秒后自动停止动画（确保只播放一次）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showInteractionAnimation = false
            print("👆 touch动画结束")
        }
    }
    
    // MARK: - 处理场景状态变化
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isPageActive = true
            print("🎬 App变为活跃状态")
            // 当app变为活跃时，检查是否需要播放grow动画
            // 这对于通过通知进入app的情况特别重要
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.checkForGrowAnimation()
            }
        case .inactive, .background:
            isPageActive = false
            print("🎬 App变为非活跃状态")
        @unknown default:
            break
        }
    }
    
    // MARK: - 检查grow动画
    private func checkForGrowAnimation() {
        print("🎬 检查grow动画条件 - 页面活跃: \(isPageActive), 步数目标完成: \(demoManager.demoProfile.stepGoalCompleted), 已播放动画: \(demoManager.hasPlayedGrowAnimation), 应播放动画: \(demoManager.shouldPlayEvolutionAnimation)")
        
        // 只有在页面活跃、步数目标完成、还未播放过grow动画且标记需要播放时才触发
        guard isPageActive && 
              demoManager.demoProfile.stepGoalCompleted && 
              !demoManager.hasPlayedGrowAnimation &&
              demoManager.shouldPlayEvolutionAnimation else {
            print("🎬 不满足grow动画触发条件")
            return
        }
        
        print("🎬 满足grow动画触发条件，准备播放")
        
        // 检查是否已经在等待动画
        guard !isWaitingForGrowAnimation else {
            print("🎬 已在等待grow动画，跳过")
            return
        }
        
        // 触发grow动画
        isWaitingForGrowAnimation = true
        startEvolutionAnimation()
    }


}

// MARK: - 预览
struct DemoMainPetView_Previews: PreviewProvider {
    static var previews: some View {
        DemoMainPetView()
    }
}
