import SwiftUI
import WatchKit

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

// MARK: - 录音状态枚举
enum RecordingState {
    case idle         // 空闲状态
    case recording    // 录音中
    case processing   // 处理中（转录、AI回复、语音合成）
    case playing      // 播放中
    case error        // 错误状态
}

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

    var body: some View {
        GeometryReader { geometry in
                ZStack {
                    // 背景纯色 - 木属性主题
                    PetUtils.getElementBackgroundColor(for: "木")
                        .ignoresSafeArea()

                    // 主内容区域
                    VStack {
                        Spacer()

                        // 主内容区域（在欢迎状态时隐藏）
                        if !demoManager.showNotificationBar || demoManager.demoState != .mainPage {
                            mainContentArea
                        }

                        Spacer()
                    }
                    .offset(x: (demoManager.demoProfile.intimacyGrade < 3 &&
                               (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction)) ? swipeOffset : 0)
                    .opacity((demoManager.demoProfile.intimacyGrade < 3 &&
                             (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction)) ? max(0.0, 1.0 - abs(swipeOffset) / 200.0) : 1.0)

                    // 底部控制区域 - 直接放在ZStack中，确保在屏幕内
                    bottomControlArea
                        .offset(x: (demoManager.demoProfile.intimacyGrade < 3 &&
                                   (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction)) ? swipeOffset : 0)
                        .opacity((demoManager.demoProfile.intimacyGrade < 3 &&
                                 (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction)) ? max(0.0, 1.0 - abs(swipeOffset) / 200.0) : 1.0)

                    // 健康检测页面预览（左滑时显示）
                    if isSwipeActive && swipeOffset < -50 && demoManager.demoProfile.intimacyGrade < 3 &&
                       (demoManager.demoState == .mainPage || demoManager.demoState == .sedentaryTrigger || demoManager.demoState == .stepDetection || demoManager.demoState == .voiceInteraction) {
                        DemoHealthDetectionView()
                            .offset(x: geometry.size.width + swipeOffset)
                            .opacity(abs(swipeOffset) / 200.0)
                            .allowsHitTesting(false) // 防止手势冲突
                    }

                    // 全屏欢迎对话框
                    if demoManager.showNotificationBar && demoManager.demoState == .mainPage {
                        welcomeOverlay
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
                // 初始化欢迎对话框状态
                isWelcomeActive = demoManager.showNotificationBar
                print("🎬 DemoMainPetView 出现 - 当前状态: \(demoManager.demoState.rawValue), 欢迎状态: \(isWelcomeActive)")
            }
            .onChange(of: demoManager.demoState) { newState in
                handleStateChange(newState)
            }
            .onChange(of: demoManager.showNotificationBar) { newValue in
                isWelcomeActive = newValue
                print("🎬 欢迎对话框状态变化: \(newValue)")
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
    }

    // MARK: - 主内容区域
    private var mainContentArea: some View {
        VStack {
            if showEvolutionAnimation {
                // 进化动画
                evolutionAnimationView
            } else if showUpgradeAnimation && isPlayingUpgradeGIF {
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
                GIFAnimationView(gifName: PetUtils.getMumuTouchGIFName(intimacyGrade: demoManager.demoProfile.intimacyGrade), isPlaying: true)
                    .frame(width: 150, height: 150)
                    .onAppear {
                        print("🎬 开始播放touch GIF: \(PetUtils.getMumuTouchGIFName(intimacyGrade: demoManager.demoProfile.intimacyGrade))")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
                .onTapGesture {
                    if demoManager.demoState == .voiceInteraction && demoManager.demoProfile.intimacyGrade >= 3 {
                        triggerInteractionAnimation()
                    }
                }
                .allowsHitTesting(demoManager.demoState == .voiceInteraction)
            }

            // 亲密度显示（在进化动画时隐藏）
            if !showEvolutionAnimation {
                intimacyDisplayView
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 0.5), value: showEvolutionAnimation)
            }
        }
    }

    // MARK: - 进化动画视图
    private var evolutionAnimationView: some View {
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
            // 3级宠物图片（最终淡入阶段）
            if evolutionPhase == .finalFadeIn3rd {
                VStack {
                    Image("mumu")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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

    // MARK: - 底部控制区域
    private var bottomControlArea: some View {
        ZStack {
            // 语音录音按钮 - 左下角，但在安全区域内
            if demoManager.demoState == .voiceInteraction && !showEvolutionAnimation {
                VStack {
                    Spacer()
                    HStack {
                        voiceRecordingButton
                            .opacity(1.0)
                            .animation(.easeInOut(duration: 0.5), value: showEvolutionAnimation)
                            .allowsHitTesting(true)
                        
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                }
            }

            // 退出按钮 - 右下角，但在安全区域内
            if demoManager.canExitDemo && !showEvolutionAnimation {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
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
                        .opacity(1.0)
                        .animation(.easeInOut(duration: 0.5), value: showEvolutionAnimation)
                    }
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    // MARK: - 语音录音按钮
    private var voiceRecordingButton: some View {
        Button(action: {}) {
            ZStack {
                // 背景圆圈 - 根据状态改变颜色
                Circle()
                    .fill(recordingState == .idle ? Color.green.opacity(0.3) : 
                          recordingState == .recording ? Color.red.opacity(0.4) :
                          recordingState == .processing ? Color.orange.opacity(0.4) :
                          recordingState == .playing ? Color.blue.opacity(0.4) :
                          Color.red.opacity(0.4))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isLongPressing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isLongPressing)
                
                // 外圈边框
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                // 录音时脉冲动画
                if recordingState == .recording {
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .scaleEffect(isLongPressing ? 1.3 : 1.0)
                        .opacity(isLongPressing ? 0.0 : 0.8)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: isLongPressing)
                }
                
                // 主图标
                Group {
                    switch recordingState {
                    case .idle:
                        ZStack {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .scaleEffect(isLongPressing ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: isLongPressing)
                            
                            // 空闲状态呼吸动画
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: 70, height: 70)
                                .scaleEffect(1.0)
                                .opacity(0.6)
                                .animation(
                                    .easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                    value: recordingState
                                )
                        }
                    case .recording:
                        ZStack {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .scaleEffect(isLongPressing ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isLongPressing)
                            
                            // 录音波形动画
                            HStack(spacing: 2) {
                                ForEach(0..<4, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.white)
                                        .frame(width: 3, height: 8 + CGFloat(index * 2))
                                        .scaleEffect(y: isLongPressing ? 1.5 : 0.8)
                                        .animation(
                                            .easeInOut(duration: 0.4)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.1),
                                            value: isLongPressing
                                        )
                                }
                            }
                            .offset(y: 25)
                        }
                    case .processing:
                        ZStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            // 处理状态旋转动画
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(recordingState == .processing ? 360 : 0))
                                .animation(
                                    .linear(duration: 1.0)
                                    .repeatForever(autoreverses: false),
                                    value: recordingState
                                )
                        }
                    case .playing:
                        ZStack {
                            Image(systemName: "speaker.wave.2.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .scaleEffect(1.1)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingState)
                            
                            // 播放声波动画
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                    .frame(width: 50 + CGFloat(index * 8), height: 50 + CGFloat(index * 8))
                                    .scaleEffect(1.0)
                                    .opacity(0.8)
                                    .animation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(index) * 0.2),
                                        value: recordingState
                                    )
                            }
                        }
                    case .error:
                        ZStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingState)
                            
                            // 错误状态闪烁动画
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: 70, height: 70)
                                .scaleEffect(1.0)
                                .opacity(0.6)
                                .animation(
                                    .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true),
                                    value: recordingState
                                )
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        .disabled(!demoManager.canExitDemo || recordingState == .processing || recordingState == .error)
        .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
            if recordingState == .processing || recordingState == .error { return }
            
            if pressing {
                if recordingState == .idle {
                    print("🎙️ 长按开始录音...")
                    WKInterfaceDevice.current().play(.start)
                    startVoiceRecording()
                }
            } else {
                if recordingState == .recording {
                    print("🎙️ 长按停止录音.")
                    WKInterfaceDevice.current().play(.stop)
                    stopVoiceRecording()
                }
            }
        }, perform: {})
    }
    

    
    // MARK: - 开始语音录音
    private func startVoiceRecording() {
        withAnimation { 
            isLongPressing = true
            recordingState = .recording
        }
        audioRecorderManager.startRecording()
        
        // 2秒后自动停止录音
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if recordingState == .recording {
                print("⏰ 自动停止录音")
                stopVoiceRecording()
            }
        }
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

    // MARK: - 语音完成阶段按钮
    private var voiceCompletedButtons: some View {
        HStack(spacing: 12) {
            // 继续互动按钮
            Button(action: {
                // 重置到语音交互状态
                demoManager.demoState = .voiceInteraction
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.red)

                    Text("继续")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // 退出Demo按钮
            Button(action: {
                demoManager.exitDemo()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)

                    Text("退出")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())
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
            // 隐藏通知栏
            withAnimation {
                demoManager.showNotificationBar = false
            }
        // case .voiceCompleted:
        //     // 显示语音完成页面
        //     showVoiceCompleted = true
        default:
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
            // 2. 淡出后等待1.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                evolutionPhase = .waitAfterFadeOut
                print("🎬 2级宠物淡出后等待1.5s")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // 3. grow gif淡入（暂停）
                    evolutionPhase = .growGifFadeIn
                    print("🎬 grow gif淡入（暂停）")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // 4. grow gif暂停2s
                        evolutionPhase = .growGifPaused
                        print("🎬 grow gif暂停2s")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            // 5. grow gif播放一次
                            evolutionPhase = .growGifPlaying
                            print("🎬 grow gif开始播放一次")
                            // 假设gif播放时间为3s
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                // 6. grow gif播放后暂停3s
                                evolutionPhase = .growGifPauseAfterPlay
                                print("🎬 grow gif播放后暂停3s")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    // 7. grow gif淡出
                                    evolutionPhase = .growGifFadeOut
                                    print("🎬 grow gif淡出")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        // 8. 3级宠物和亲密度淡入
                                        evolutionPhase = .finalFadeIn3rd
                                        print("🎬 3级宠物和亲密度淡入")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showUpgradeAnimation = false
                    }
                    print("🎬 升级动画结束，进入语音交互阶段")
                }
            }
        }
    }

    // MARK: - 全屏欢迎对话框
    private var welcomeOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // 半透明背景 - 使用木属性主题背景色
                PetUtils.getElementBackgroundColor(for: "木")
                    .opacity(demoManager.showNotificationBar ? 0.9 : 0.0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: demoManager.showNotificationBar)
                    .onTapGesture {
                        dismissWelcome()
                    }

                // 主容器 - 全屏布局
                ZStack {
                    // 对话框 - 左上角
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello，我是木木")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Text("今天是你坚持健康的\(demoManager.demoProfile.healthStreak)天")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
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
                    .position(x: 80, y: 60)
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

    // MARK: - 上滑提示（已移除）
    private var upSwipeHint: some View {
        EmptyView()
    }

    // MARK: - 关闭欢迎对话框
    private func dismissWelcome() {
        withAnimation(.easeInOut(duration: 0.3)) {
            demoManager.showNotificationBar = false
            isWelcomeActive = false
        }
        print("👋 欢迎对话框已关闭")
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
