import SwiftUI
import UserNotifications

// MARK: - 健康数据页面
struct HealthDashboardPageView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var environmentManager = EnvironmentSensorManager.shared
    @StateObject private var systemNotificationManager = SystemNotificationManager.shared
    @StateObject private var gifAnimationManager = GIFAnimationManager()
    @StateObject private var audioRecorderManager = AudioRecorderManager.shared
    @StateObject private var transcriptionAPIService = TranscriptionAPIService.shared
    @StateObject private var chatAPIService = ChatAPIService.shared
    @StateObject private var speechAPIService = SpeechAPIService.shared
    @StateObject private var audioPlayerManager = AudioPlayerManager.shared
    @StateObject private var demoManager = DemoManager.shared

    @State private var isDelayedNotification: Bool = false
    @State private var isRecording = false
    @State private var isLongPressing = false // 用于新按钮的UI状态
    @State private var isProcessingConversation = false // 用于跟踪整个对话流程的状态

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Demo模块+音频识别模块 - 移到最前面
                demoAndVoiceSection
                // 问候语和压力状态
                greetingSection

                // 健康卡片
                healthCardsSection

                // 通知测试模块
                notificationTestSection
                // 完整对话流程模块
                conversationChainSection

                // 设置入口
                settingsSection

                // 添加底部间距确保可以滚动到底部
                Spacer(minLength: 20)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(PetUtils.getElementBackgroundColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
        .onAppear {
            healthKitManager.requestAuthorization()
            profileManager.updateHealthStreak()
            // 设置通知代理
            UNUserNotificationCenter.current().delegate = systemNotificationManager

            // 延迟刷新数据，确保授权完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                healthKitManager.objectWillChange.send()
            }
        }
    }

    // MARK: - 问候语区域
    private var greetingSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                            .font(.title3)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(profileManager.getGreeting())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                    Text(profileManager.getStressStatusDescription())
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - 健康卡片区域
    private var healthCardsSection: some View {
        VStack(spacing: 16) {
            Text("今日健康监测")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(HealthReminder.allReminders, id: \.id) { reminder in
                    NavigationLink(destination: HealthDetailView(
                        reminder: reminder,
                        userElement: profileManager.userProfile.fiveElements?.primary ?? "金",
                        healthData: getHealthData(for: reminder.type)
                    )) {
                        HealthCardView(
                            reminder: reminder,
                            healthData: getHealthData(for: reminder.type),
                            userElement: profileManager.userProfile.fiveElements?.primary ?? "金"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onTapGesture {
                        print("点击了健康卡片: \(reminder.type.rawValue)")
                    }
                }
            }
        }
    }

    // MARK: - 通知测试模块
    private var notificationTestSection: some View {
        VStack(spacing: 16) {
            Text("通知测试")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

            VStack(spacing: 12) {
                // 延迟发送开关
                HStack {
                    Toggle("10秒后发送", isOn: $isDelayedNotification)
                        .toggleStyle(SwitchToggleStyle(tint: PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金")))
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                    Spacer()
                }
                .padding(.horizontal, 4)

                // 发送建议通知按钮
                Button(action: {
                    sendSuggestionTest()
                }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("发送建议通知")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                            Text("随机选择一个建议进行推送")
                                .font(.caption)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // 发送完成通知按钮
                Button(action: {
                    sendCompletionTest()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("发送完成通知")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                            Text("发送完成通知并增加亲密度")
                                .font(.caption)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // 发送聊天请求按钮
                Button(action: {
                    chatAPIService.sendMessage(content: "hi")
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("发送聊天请求")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                            Text("向AI助手发送一条消息")
                                .font(.caption)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                if chatAPIService.isRequesting {
                    ProgressView("正在发送...")
                }

                if let errorMessage = chatAPIService.errorMessage {
                    Text("错误: \(errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if !chatAPIService.responseContent.isEmpty {
                    Text("AI回复: \(chatAPIService.responseContent)")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                }

                // 发送语音请求按钮
                Button(action: {
                    speechAPIService.generateSpeech(text: "早睡养肝血，准备休息吧。")
                }) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("播放养生提醒")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                            Text("点击收听一条健康建议")
                                .font(.caption)
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                if speechAPIService.isRequesting || audioPlayerManager.isPlaying {
                    ProgressView(audioPlayerManager.isPlaying ? "正在播放..." : "正在请求...")
                }

                if let errorMessage = speechAPIService.errorMessage {
                    Text("错误: \(errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .onChange(of: speechAPIService.audioData) { newData in
            if let data = newData {
                // 如果是对话流程的一部分，则播放并处理后续逻辑
                if isProcessingConversation {
                    audioPlayerManager.playAudio(data: data) {
                        DispatchQueue.main.async {
                            self.isProcessingConversation = false
                            print("✅ 对话流程结束")
                        }
                    }
                } else {
                    // 否则，仅播放
                    audioPlayerManager.playAudio(data: data) {}
                }
            }
        }
        .onChange(of: transcriptionAPIService.transcribedText) { newText in
            if !newText.isEmpty && isProcessingConversation {
                print("📝 转录完成: \(newText)")
                chatAPIService.sendMessage(content: newText)
            }
        }
        .onChange(of: chatAPIService.responseContent) { newContent in
            if !newContent.isEmpty && isProcessingConversation {
                print("🤖 AI回复: \(newContent)")
                speechAPIService.generateSpeech(text: newContent)
            }
        }
        .onChange(of: transcriptionAPIService.errorMessage) { error in
            if let error = error {
                print("❌ 转录失败: \(error)")
                isProcessingConversation = false
            }
        }
        .onChange(of: chatAPIService.errorMessage) { error in
            if let error = error {
                print("❌ 获取AI回复失败: \(error)")
                isProcessingConversation = false
            }
        }
        .onChange(of: speechAPIService.errorMessage) { error in
            if let error = error {
                print("❌ 语音合成失败: \(error)")
                isProcessingConversation = false
            }
        }
    }

    // MARK: - 综合模块：Demo + 语音识别
    private var demoAndVoiceSection: some View {
        VStack(spacing: 32) {

            // MARK: - Demo模块
            VStack(spacing: 16) {
                Text("Demo体验")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                VStack(spacing: 12) {
                    // Demo状态显示
                    if demoManager.isDemo {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)

                            VStack(alignment: .leading) {
                                Text("Demo进行中")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                            }

                            Spacer()

                            if demoManager.canExitDemo {
                                Button("退出") {
                                    demoManager.exitDemo()
                                }
                                .font(.caption2)
                                .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // Demo按钮
                    Button(action: {
                        if demoManager.isDemo {
                            demoManager.resetDemo()
                        } else {
                            demoManager.startDemo()
                        }
                    }) {
                        HStack {
                            Image(systemName: demoManager.isDemo ? "arrow.clockwise" : "play.fill")
                                .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(demoManager.isDemo ? "重置Demo" : "开始Demo")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                                Text(demoManager.isDemo ? "重新开始Demo流程" : "体验完整功能演示")
                                    .font(.caption)
                                    .foregroundColor(demoManager.isDemo ? PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7) : .blue.opacity(0.9))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                                .font(.caption)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // MARK: - 语音识别模块
            VStack(spacing: 16) {
                Text("语音识别")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                VStack(spacing: 12) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .foregroundColor(isRecording ? .red : PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(isRecording ? "正在录音..." : "按住说话")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                                Text("松开结束识别")
                                    .font(.caption)
                                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isRecording ? Color.red.opacity(0.1) : PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isRecording ? Color.red.opacity(0.5) : PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                        if pressing {
                            isRecording = true
                            audioRecorderManager.startRecording()
                        } else {
                            isRecording = false
                            audioRecorderManager.stopRecording { url in
                                if let url = url {
                                    transcriptionAPIService.transcribeAudio(fileURL: url)
                                }
                            }
                        }
                    }, perform: {})

                    if transcriptionAPIService.isTranscribing {
                        ProgressView("正在识别...")
                    }

                    if let errorMessage = transcriptionAPIService.errorMessage {
                        Text("错误: \(errorMessage)")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if !transcriptionAPIService.transcribedText.isEmpty {
                        Text("识别结果: \(transcriptionAPIService.transcribedText)")
                            .font(.caption)
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                    }
                }
            }
        }
    }

    // MARK: - 设置卡片
    private var settingsSection: some View {
        NavigationLink(destination: SettingsView()) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("设置与数据")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                    Text("查看所有数据并更改设置")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 获取健康数据
    private func getHealthData(for type: HealthReminder.ReminderType) -> String {
        switch type {
        case .sunExposure:
            return "紫外线: \(environmentManager.getUVStatus())"
        case .stress:
            let hrv = Int(healthKitManager.heartRateVariability)
            return hrv > 0 ? "\(hrv)ms" : "暂无数据"
        case .sedentary:
            return "\(healthKitManager.steps) 步"
        case .exercise:
            let hr = healthKitManager.heartRate
            return hr > 0 ? "\(hr) BPM" : "暂无数据"
        case .sleep:
            return healthKitManager.sleepAnalysis
        }
    }

    // MARK: - 发送建议通知
    private func sendSuggestionTest() {
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        let delay = isDelayedNotification ? 10.0 : 1.0

        print("发送建议通知 - 用户元素: \(userElement), 延迟: \(delay)秒")

        systemNotificationManager.sendRandomSuggestionNotification(
            for: userElement,
            delay: delay
        )
    }

    // MARK: - 发送完成通知
    private func sendCompletionTest() {
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        let delay = isDelayedNotification ? 10.0 : 1.0

        print("发送完成通知 - 用户元素: \(userElement), 延迟: \(delay)秒")

        systemNotificationManager.sendRandomCompletionNotification(
            for: userElement,
            delay: delay
        )
    }

    // MARK: - 完整对话流程模块
    private var conversationChainSection: some View {
        VStack(spacing: 16) {
            Text("AI 对话")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

            Button(action: {}) {
                HStack {
                    ZStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(isLongPressing ? .red.opacity(0.8) : .green.opacity(0.8))
                            .scaleEffect(isLongPressing ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isLongPressing)

                        if isProcessingConversation {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        }
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isProcessingConversation ? "处理中..." : (isLongPressing ? "正在录音..." : "按住对话"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))

                        Text("松开后自动回复并朗读")
                            .font(.caption)
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isLongPressing ? Color.red.opacity(0.15) : PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isLongPressing ? Color.red.opacity(0.5) : PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
                if isProcessingConversation { return }

                if pressing {
                    if !audioRecorderManager.isRecording {
                        print("🎙️ 开始录音...")
                        withAnimation { isLongPressing = true }
                        audioRecorderManager.startRecording()
                    }
                } else {
                    if audioRecorderManager.isRecording {
                        print("🎙️ 停止录音.")
                        withAnimation { isLongPressing = false }
                        audioRecorderManager.stopRecording { url in
                            guard let audioURL = url else {
                                print("❌ 录音文件URL无效")
                                return
                            }
                            print("▶️ 开始处理音频: \(audioURL)")
                            processAudio(url: audioURL)
                        }
                    }
                }
            }, perform: {})
            .disabled(isProcessingConversation)
        }
    }

    // MARK: - 处理音频流程
    private func processAudio(url: URL) {
        isProcessingConversation = true
        transcriptionAPIService.transcribeAudio(fileURL: url)
    }
}

// MARK: - 预览
struct HealthDashboardPageView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDashboardPageView()
    }
}
