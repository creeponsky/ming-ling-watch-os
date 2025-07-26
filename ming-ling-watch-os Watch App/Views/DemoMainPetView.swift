import SwiftUI

// MARK: - 进化阶段枚举
enum EvolutionPhase {
    case initial      // 初始状态
    case fadeOut      // 2级图片淡出
    case gifFadeIn    // GIF淡入（暂停）
    case playing      // GIF播放
    case gifFadeOut   // GIF淡出
    case finalFadeIn  // 3级UI淡入
}

// MARK: - Demo主宠物视图
struct DemoMainPetView: View {
    @StateObject private var demoManager = DemoManager.shared
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

                        // 底部控制区域
                        bottomControlArea
                    }
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
            // .navigationDestination(isPresented: $showVoiceCompleted) {
                // DemoVoiceCompletedView()
            // }
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
            // 2级宠物图片（淡出阶段）
            if evolutionPhase == .initial || evolutionPhase == .fadeOut {
                VStack {
                    Image("mumu")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .opacity(evolutionPhase == .initial ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0), value: evolutionPhase)

                    // 2级亲密度显示
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

            // 进化GIF（淡入、播放、淡出阶段）
            if evolutionPhase == .gifFadeIn || evolutionPhase == .playing || evolutionPhase == .gifFadeOut {
                GIFAnimationView(gifName: "GIFs/mumu/grow/2-3", isPlaying: evolutionPhase == .gifFadeIn || evolutionPhase == .playing)
                    .frame(width: 200, height: 200)
                    .offset(y: -20) // 往上移动20点
                    .opacity(evolutionPhase == .gifFadeOut ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 1.0), value: evolutionPhase)
            }

            // 3级宠物图片（最终淡入阶段）
            if evolutionPhase == .finalFadeIn {
                VStack {
                    Image("mumu")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .opacity(1.0)
                        .animation(.easeInOut(duration: 1.0), value: evolutionPhase)

                    // 3级亲密度显示
                    HStack {
                        ForEach(1...3, id: \.self) { level in
                            Image(systemName: level <= 3 ? "heart.fill" : "heart")
                                .foregroundColor(level <= 3 ? .red : .gray)
                                .font(.caption)
                        }
                    }
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 1.0), value: evolutionPhase)
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
        HStack {
            Spacer()

            // 语音录音按钮
            if demoManager.demoState == .voiceInteraction && !showEvolutionAnimation {
                voiceRecordingButton
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 0.5), value: showEvolutionAnimation)
            }

            // 语音完成阶段的按钮
            // if demoManager.demoState == .voiceCompleted && !showEvolutionAnimation {
            //     voiceCompletedButtons
            //         .opacity(1.0)
            //         .animation(.easeInOut(duration: 0.5), value: showEvolutionAnimation)
            // }

            // 退出按钮
            if demoManager.canExitDemo && !showEvolutionAnimation {
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
        
        // 立即开始淡出2级图片
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            evolutionPhase = .fadeOut
            print("🎬 2级图片开始淡出")
            
            // 0.5秒后GIF淡入
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                evolutionPhase = .gifFadeIn
                print("🎬 GIF开始淡入")
                
                // 暂停2秒后再开始播放
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    evolutionPhase = .playing
                    print("🎬 开始播放进化GIF")
                    
                    // 假设GIF播放时间为3秒，然后暂停3秒
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        evolutionPhase = .gifFadeOut
                        print("🎬 GIF播放完成，开始淡出")
                        
                        // 0.5秒后显示3级UI和其他图标
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            evolutionPhase = .finalFadeIn
                            print("🎬 3级UI和其他图标开始淡入")
                            
                            // 0.5秒后结束动画
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
