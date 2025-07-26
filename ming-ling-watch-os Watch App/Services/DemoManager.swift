import Foundation
import SwiftUI
import UserNotifications

// MARK: - Demo状态枚举
enum DemoState: String, CaseIterable, Codable {
    case inactive = "inactive"                    // 未激活demo
    case birthdaySelection = "birthday_selection" // 生日选择阶段
    case mainPage = "main_page"                   // 主页面阶段  
    case sedentaryTrigger = "sedentary_trigger"   // 久坐触发阶段
    case stepDetection = "step_detection"         // 步数检测阶段
    case intimacyUpgrade = "intimacy_upgrade"     // 亲密度升级阶段
    case voiceInteraction = "voice_interaction"   // 语音交互阶段
    case completed = "completed"                  // demo完成
}

// MARK: - Demo用户档案模型
struct DemoUserProfile: Codable {
    var birthday: Date?
    var sex: Int = 0 // 0男 1女
    var intimacyLevel: Int = 50 // 直接设置为2级
    var healthStreak: Int = 1
    var lastHealthCheck: Date = Date()
    var stepCount: Int = 0
    var isWoodElement: Bool = true // demo中固定为木属性
    
    var intimacyGrade: Int {
        if intimacyLevel >= 80 {
            return 3 // 亲密
        } else if intimacyLevel >= 50 {
            return 2 // 友好
        } else {
            return 1 // 陌生
        }
    }
    
    mutating func addIntimacy(_ points: Int) {
        intimacyLevel = min(100, intimacyLevel + points)
    }
}

// MARK: - Demo管理器
class DemoManager: ObservableObject {
    static let shared = DemoManager()
    
    @Published var isDemo: Bool = false
    @Published var demoState: DemoState = .inactive
    @Published var demoProfile: DemoUserProfile = DemoUserProfile()
    @Published var showNotificationBar: Bool = false
    @Published var notificationMessage: String = ""
    @Published var stepCountBeforeReminder: Int = 0
    @Published var isRecording: Bool = false
    @Published var hasShownWelcome: Bool = false
    @Published var shouldPlayEvolutionAnimation: Bool = false
    @Published var countdownSeconds: Int = 180 // 180秒倒计时
    @Published var isStepMonitoringActive: Bool = false // 步数监测是否激活
    @Published var sedentaryCountdown: Int = 10 // 久坐检测倒计时
    
    // 新增：倒计时结束时间，用于计算准确的剩余时间
    private var countdownEndTime: Date?
    private var sedentaryEndTime: Date?
    
    private var stepCheckCount: Int = 0 // 步数检查次数
    
    private let demoKey = "demoData"
    private let userDefaults = UserDefaults.standard
    private let motionManager = MotionManager()
    private let healthKitManager = HealthKitManager.shared
    private var countdownTimer: Timer?
    private var initialStepCount: Int = 0
    
    private init() {
        loadDemoData()
    }
    
    // MARK: - 开始Demo
    func startDemo() {
        isDemo = true
        demoState = .birthdaySelection
        demoProfile = DemoUserProfile()
        showNotificationBar = false
        hasShownWelcome = false
        saveDemoData()
        print("🎬 Demo开始: 进入生日选择阶段")
    }
    
    // MARK: - 退出Demo
    func exitDemo() {
        isDemo = false
        demoState = .inactive
        demoProfile = DemoUserProfile()
        showNotificationBar = false
        isRecording = false
        hasShownWelcome = false
        shouldPlayEvolutionAnimation = false
        countdownSeconds = 180
        isStepMonitoringActive = false
        // sedentaryCountdown 现在由新的倒计时逻辑管理
        
        // 重置倒计时结束时间
        countdownEndTime = nil
        sedentaryEndTime = nil
        
        // 停止所有计时器
        stopStepMonitoring()
        clearDemoData()
        print("🎬 Demo结束")
    }
    
    // MARK: - 重置Demo
    func resetDemo() {
        exitDemo()
        startDemo()
    }
    
    // MARK: - 设置生日和性别
    func setBirthday(_ birthday: Date, sex: Int) {
        demoProfile.birthday = birthday
        demoProfile.sex = sex
        demoState = .mainPage
        
        // 先不显示通知栏，等页面切换完成后再显示
        showNotificationBar = false
        notificationMessage = "Hello，我是木木；今天是你坚持健康的1天"
        
        saveDemoData()
        print("🎬 Demo: 设置生日完成，进入主页面")
        
        // 延迟显示欢迎界面，确保页面切换动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.showNotificationBar = true
            }
            print("🎬 Demo: 显示欢迎界面")
        }
    }
    
    // MARK: - 触发久坐检测
    func triggerSedentaryDetection() {
        demoState = .sedentaryTrigger
        stepCountBeforeReminder = demoProfile.stepCount
        
        // 设置久坐检测倒计时结束时间（10秒后）
        sedentaryEndTime = Date().addingTimeInterval(10)
        sedentaryCountdown = 10
        
        saveDemoData()
        print("🎬 Demo: 开始久坐检测，结束时间: \(sedentaryEndTime?.description ?? "nil")")
        
        // 启动倒计时更新Timer（每秒更新一次显示）
        startSedentaryCountdownTimer()
        
        // 确保UI更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - 进入步数检测
    private func enterStepDetection() {
        demoState = .stepDetection
        showNotificationBar = false // 隐藏欢迎对话框
        isStepMonitoringActive = true
        // countdownSeconds 现在由 startCountdownTimer 方法设置
        saveDemoData()
        print("🎬 Demo: 进入步数检测阶段")
        
        // 发送久坐提醒通知
        sendSedentaryReminder()
        
        // 开始实时步数监测
        startRealStepMonitoring()
        
        // 确保UI更新，触发界面切换
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - 触发亲密度升级
    private func triggerIntimacyUpgrade() {
        // 增加步数和亲密度
        demoProfile.addIntimacy(30) // 升级到3级
        
        demoState = .intimacyUpgrade
        shouldPlayEvolutionAnimation = true // 标记需要播放进化动画
        saveDemoData()
        print("🎬 Demo: 触发亲密度升级，亲密度升级到\(demoProfile.intimacyGrade)级")
        
        // 发送完成通知
        sendCompletionNotification()
        
        // 8秒后进入语音交互阶段（给升级动画足够时间：1秒延迟+2秒播放+5秒等待）
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.demoState = .voiceInteraction
            self.saveDemoData()
            print("🎬 Demo: 进入语音交互阶段")
        }
    }
    
    // MARK: - 开始真实步数监测
    private func startRealStepMonitoring() {
        print("🎬 Demo: 开始真实步数监测")
        
        // 重置步数为0，因为我们只关心增量
        demoProfile.stepCount = 0
        stepCheckCount = 0
        
        // 记录开始监测的时间
        let startTime = Date()
        print("🎬 Demo: 开始监测时间: \(startTime)")
        
        // 先启动步数监测，让MotionManager开始工作
        motionManager.startStepCounting { [weak self] currentTotalSteps in
            self?.handleStepCountUpdate(currentTotalSteps)
        }
        
        // 延迟2秒后获取初始步数，确保MotionManager已经开始工作
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            let now = Date()
            print("🎬 Demo: 获取初始步数时间: \(now)")
            
            // 获取当前时刻的步数作为初始值
            self?.healthKitManager.getSteps(from: Calendar.current.startOfDay(for: Date()), to: now) { totalSteps in
                DispatchQueue.main.async {
                    // 设置一个标记，表示倒计时即将开始，但还在准备阶段
                    self?.initialStepCount = totalSteps
                    self?.demoProfile.stepCount = 0
                    print("🎬 Demo: 设置初始步数: \(totalSteps) (准备阶段)")
                    
                    // 启动180秒倒计时
                    self?.startCountdownTimer()
                    
                    // 10秒后（准备时间结束）重新获取初始步数，开始正式计算
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                        self?.healthKitManager.getSteps(from: Calendar.current.startOfDay(for: Date()), to: Date()) { newTotalSteps in
                            DispatchQueue.main.async {
                                self?.initialStepCount = newTotalSteps
                                self?.demoProfile.stepCount = 0
                                print("🎬 Demo: 准备时间结束，重新设置初始步数: \(newTotalSteps)，开始正式计算")
                                self?.objectWillChange.send()
                            }
                        }
                    }
                    
                    // 确保UI更新
                    self?.objectWillChange.send()
                }
            }
        }
    }
    
    // MARK: - 处理步数更新
    private func handleStepCountUpdate(_ currentTotalSteps: Int) {
        guard isStepMonitoringActive else { return }
        
        stepCheckCount += 1
        
        // 如果初始步数还没有设置，先设置初始步数
        if initialStepCount == 0 {
            initialStepCount = currentTotalSteps
            demoProfile.stepCount = 0
            print("🎬 Demo: 首次设置初始步数: \(initialStepCount)")
            return
        }
        
        // 计算从开始监测后的步数增量
        let stepIncrease = currentTotalSteps - initialStepCount
        
        print("🎬 Demo: 步数处理 - 当前总步数: \(currentTotalSteps), 初始步数: \(initialStepCount), 计算增量: \(stepIncrease), 检查次数: \(stepCheckCount)")
        
        // 处理负数增量的情况（初始步数可能不准确）
        if stepIncrease < 0 {
            print("🎬 Demo: 检测到负数增量: \(stepIncrease)，重新校准初始步数")
            
            // 如果这是前几次检查，重新设置初始步数
            if stepCheckCount <= 5 {
                initialStepCount = currentTotalSteps
                demoProfile.stepCount = 0
                print("🎬 Demo: 重新校准初始步数: \(initialStepCount)，从0开始计算")
                return
            } else {
                // 如果已经检查多次还是负数，可能是数据异常，忽略此次更新
                print("🎬 Demo: 多次检查均为负数，忽略此次更新")
                return
            }
        }
        
        // 第一次检查时，如果增量过大（超过30步），重新设置初始步数
        if stepCheckCount == 1 && stepIncrease > 30 {
            print("🎬 Demo: 第一次检查增量过大(\(stepIncrease))，重新设置初始步数为当前步数")
            initialStepCount = currentTotalSteps
            demoProfile.stepCount = 0
            print("🎬 Demo: 重新设置初始步数: \(initialStepCount)，从0开始计算")
            return
        }
        
        // 如果增量异常过大（超过200步），可能是数据异常，忽略
        if stepIncrease > 200 {
            print("🎬 Demo: 步数增量异常过大: \(stepIncrease)，忽略此次更新")
            return
        }
        
        // 更新步数增量
        let newStepCount = stepIncrease
        if newStepCount != demoProfile.stepCount {
            demoProfile.stepCount = newStepCount
            print("🎬 Demo: 步数更新成功 - 新增量: \(newStepCount)")
            
            // 确保UI在主线程更新
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else {
            print("🎬 Demo: 步数无变化，跳过更新")
        }
        
        // 检查是否达到目标（20步）
        if newStepCount >= 20 {
            print("🎬 Demo: 达到步数目标！")
            stopStepMonitoring()
            triggerIntimacyUpgrade()
        }
    }
    

    
    // MARK: - 启动倒计时
    private func startCountdownTimer() {
        // 设置倒计时结束时间（180秒后）
        countdownEndTime = Date().addingTimeInterval(180)
        countdownSeconds = 180
        
        print("🎬 Demo: 开始步数检测倒计时，结束时间: \(countdownEndTime?.description ?? "nil")")
        
        // 清除旧的Timer，避免重复启动
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // 启动新的Timer，每秒更新一次
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 计算剩余时间
            let remainingTime = self.countdownEndTime?.timeIntervalSinceNow ?? 0
            
            // 确保UI在主线程更新
            DispatchQueue.main.async {
                self.countdownSeconds = Int(remainingTime)
                self.objectWillChange.send()
            }
            
            if remainingTime <= 0 {
                print("🎬 Demo: 时间到，停止步数监测")
                self.stopStepMonitoring()
                // 时间到但没有完成目标，可以显示提示或重置
                self.demoState = .mainPage
                self.saveDemoData()
            }
        }
    }
    
    // MARK: - 启动久坐倒计时更新Timer
    private func startSedentaryCountdownTimer() {
        // 清除旧的Timer，避免重复启动
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // 启动新的Timer，每秒更新一次
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 计算剩余时间
            let remainingTime = self.sedentaryEndTime?.timeIntervalSinceNow ?? 0
            
            // 确保UI在主线程更新
            DispatchQueue.main.async {
                self.sedentaryCountdown = Int(remainingTime)
                self.objectWillChange.send()
            }
            
            if remainingTime <= 0 {
                print("🎬 Demo: 久坐检测时间到，进入步数检测")
                self.enterStepDetection()
                self.countdownTimer?.invalidate() // 停止Timer
                self.countdownTimer = nil
            }
        }
    }
    
    // MARK: - 停止步数监测
    private func stopStepMonitoring() {
        isStepMonitoringActive = false
        motionManager.stopStepCounting()
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // 清除倒计时结束时间
        countdownEndTime = nil
        sedentaryEndTime = nil
        
        print("🎬 Demo: 步数监测已停止")
    }
    
    // MARK: - 重新计算倒计时（页面重新出现时调用）
    func recalculateCountdown() {
        // 重新计算久坐检测倒计时
        if let sedentaryEndTime = sedentaryEndTime, demoState == .sedentaryTrigger {
            let remainingTime = sedentaryEndTime.timeIntervalSinceNow
            sedentaryCountdown = max(0, Int(remainingTime))
            
            // 如果时间到了，立即进入步数检测
            if remainingTime <= 0 {
                print("🎬 Demo: 久坐检测时间到，进入步数检测")
                enterStepDetection()
            } else {
                // 重新启动Timer
                startSedentaryCountdownTimer()
            }
        }
        
        // 重新计算步数检测倒计时
        if let countdownEndTime = countdownEndTime, demoState == .stepDetection {
            let remainingTime = countdownEndTime.timeIntervalSinceNow
            countdownSeconds = max(0, Int(remainingTime))
            
            // 如果时间到了，停止监测
            if remainingTime <= 0 {
                print("🎬 Demo: 步数检测时间到，停止监测")
                stopStepMonitoring()
                demoState = .mainPage
                saveDemoData()
            } else {
                // 重新启动Timer
                startCountdownTimer()
            }
        }
        
        print("🎬 Demo: 倒计时重新计算完成 - 久坐: \(sedentaryCountdown)s, 步数: \(countdownSeconds)s")
    }
    
    // MARK: - 完成步数目标（保留用于兼容性）
    private func completeStepGoal() {
        // 这个方法现在被 triggerIntimacyUpgrade 替代
        triggerIntimacyUpgrade()
    }
    
    // MARK: - 开始录音
    func startRecording() {
        isRecording = true
        print("🎬 Demo: 开始录音")
        
        // 2秒后停止录音并播放回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopRecording()
        }
    }
    
    // MARK: - 停止录音
    func stopRecording() {
        isRecording = false
        print("🎬 Demo: 停止录音，播放回复")
        
        // 播放模拟回复音频
        playMockResponse()
        
        // 2秒后完成语音交互并返回主页面
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.demoState = .mainPage
            self.saveDemoData()
            print("🎬 Demo: 语音交互完成，返回主页面")
        }
    }
    
    // MARK: - 发送久坐提醒
    private func sendSedentaryReminder() {
        print("🔔 发送久坐提醒通知 - 元素: 木")
        
        // 使用现有的通知系统发送久坐建议通知
        SystemNotificationManager.shared.sendSuggestionNotification(
            for: "木", // Demo中固定为木属性
            taskType: .sedentary,
            delay: 0
        )
    }
    
    // MARK: - 发送完成通知
    private func sendCompletionNotification() {
        print("🔔 发送完成通知 - 元素: 木")
        
        // 使用现有的通知系统发送久坐完成通知
        SystemNotificationManager.shared.sendCompletionNotification(
            for: "木", // Demo中固定为木属性
            taskType: .sedentary,
            delay: 0
        )
    }
    
    // MARK: - 播放模拟回复
    private func playMockResponse() {
        print("🔊 播放模拟音频回复")
        // 这里应该播放预录的音频文件
        // 为了demo简化，我们只是打印
    }
    
    // MARK: - 保存Demo数据
    func saveDemoData() {
        let demoData = DemoData(
            isDemo: isDemo,
            demoState: demoState,
            demoProfile: demoProfile,
            showNotificationBar: showNotificationBar,
            notificationMessage: notificationMessage,
            stepCountBeforeReminder: stepCountBeforeReminder,
            hasShownWelcome: hasShownWelcome,
            shouldPlayEvolutionAnimation: shouldPlayEvolutionAnimation,
            countdownSeconds: countdownSeconds,
            isStepMonitoringActive: isStepMonitoringActive,
            sedentaryCountdown: sedentaryCountdown,
            countdownEndTime: countdownEndTime,
            sedentaryEndTime: sedentaryEndTime
        )
        
        if let data = try? JSONEncoder().encode(demoData) {
            userDefaults.set(data, forKey: demoKey)
        }
    }
    
    // MARK: - 加载Demo数据
    private func loadDemoData() {
        if let data = userDefaults.data(forKey: demoKey),
           let demoData = try? JSONDecoder().decode(DemoData.self, from: data) {
            isDemo = demoData.isDemo
            demoState = demoData.demoState
            demoProfile = demoData.demoProfile
            showNotificationBar = demoData.showNotificationBar
            notificationMessage = demoData.notificationMessage
            stepCountBeforeReminder = demoData.stepCountBeforeReminder
            hasShownWelcome = demoData.hasShownWelcome
            shouldPlayEvolutionAnimation = demoData.shouldPlayEvolutionAnimation
            countdownSeconds = demoData.countdownSeconds
            isStepMonitoringActive = demoData.isStepMonitoringActive
            sedentaryCountdown = demoData.sedentaryCountdown
            countdownEndTime = demoData.countdownEndTime
            sedentaryEndTime = demoData.sedentaryEndTime
            
            print("🎬 Demo数据已加载: 状态=\(demoState.rawValue), hasShownWelcome=\(hasShownWelcome), shouldPlayEvolutionAnimation=\(shouldPlayEvolutionAnimation), countdownSeconds=\(countdownSeconds), isStepMonitoringActive=\(isStepMonitoringActive), sedentaryCountdown=\(sedentaryCountdown)")
        }
    }
    
    // MARK: - 清除Demo数据
    private func clearDemoData() {
        userDefaults.removeObject(forKey: demoKey)
    }
}

// MARK: - Demo数据存储模型
private struct DemoData: Codable {
    let isDemo: Bool
    let demoState: DemoState
    let demoProfile: DemoUserProfile
    let showNotificationBar: Bool
    let notificationMessage: String
    let stepCountBeforeReminder: Int
    let hasShownWelcome: Bool
    let shouldPlayEvolutionAnimation: Bool
    let countdownSeconds: Int
    let isStepMonitoringActive: Bool
    let sedentaryCountdown: Int
    let countdownEndTime: Date?
    let sedentaryEndTime: Date?
}

// MARK: - Demo工具扩展
extension DemoManager {
    // 获取demo状态描述
    var stateDescription: String {
        switch demoState {
        case .inactive:
            return "Demo未激活"
        case .birthdaySelection:
            return "生日选择阶段"
        case .mainPage:
            return "主页面阶段"
        case .sedentaryTrigger:
            return "久坐触发阶段"
        case .stepDetection:
            return "步数检测阶段"
        case .intimacyUpgrade:
            return "亲密度升级阶段"
        case .voiceInteraction:
            return "语音交互阶段"
        case .completed:
            return "Demo完成"
        }
    }
    
    // 检查是否可以退出demo
    var canExitDemo: Bool {
        return demoState == .completed || demoState == .voiceInteraction
    }
}