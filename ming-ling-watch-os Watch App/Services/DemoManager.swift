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
    var hasCompletedDemo: Bool = false // 新增：是否已完成Demo
    var stepGoalCompleted: Bool = false // 新增：步数目标是否已完成
    
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
    
    mutating func completeStepGoal() {
        stepGoalCompleted = true
    }
    
    mutating func completeDemo() {
        hasCompletedDemo = true
        stepGoalCompleted = true
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
    
    // 新增：倒计时目标时间持久化
    var countdownTargetDate: Date? {
        get {
            UserDefaults.standard.object(forKey: "countdownTargetDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "countdownTargetDate")
        }
    }
    
    // 新增：防止重复播放grow动画
    var hasPlayedGrowAnimation: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasPlayedGrowAnimation")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasPlayedGrowAnimation")
        }
    }
    
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
        print("🎬 Demo: 开始退出Demo流程")
        
        isDemo = false
        demoState = .inactive
        demoProfile = DemoUserProfile()
        showNotificationBar = false
        isRecording = false
        hasShownWelcome = false
        shouldPlayEvolutionAnimation = false
        countdownSeconds = 180
        sedentaryCountdown = 10
        isStepMonitoringActive = false
        
        // 重置步数相关状态
        initialStepCount = 0
        stepCheckCount = 0
        
        // 重置倒计时结束时间
        countdownEndTime = nil
        sedentaryEndTime = nil
        
        // 停止所有计时器和监测
        stopStepMonitoring()
        
        // 确保恢复其他健康监测服务
        HealthMonitoringService.shared.startMonitoring()
        
        clearDemoData()
        
        print("🎬 Demo结束，所有状态已重置")
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
    
    // MARK: - 完成步数目标
    private func completeStepGoal() {
        // 检查是否已经完成过Demo
        guard !demoProfile.hasCompletedDemo else {
            print("⚠️ Demo已完成，跳过步数完成处理")
            return
        }
        
        // 增加步数和亲密度
        demoProfile.addIntimacy(30) // 升级到3级
        demoProfile.completeDemo() // 标记Demo完成
        
        // 直接进入语音交互阶段，标记需要播放进化动画
        demoState = .voiceInteraction
        shouldPlayEvolutionAnimation = true // 标记需要播放进化动画
        saveDemoData()
        print("🎬 Demo: 步数目标完成，直接进入语音交互阶段，准备播放进化动画")
        
        // 发送完成通知
        sendCompletionNotification()
    }
    
    // MARK: - 开始真实步数监测
    private func startRealStepMonitoring() {
        print("🎬 Demo: 开始真实步数监测")
        
        // 检查是否已经完成过Demo
        guard !demoProfile.hasCompletedDemo && !demoProfile.stepGoalCompleted else {
            print("⚠️ Demo已完成或步数目标已达成，跳过步数监测")
            return
        }
        
        // 停止其他健康监测服务，避免回调冲突
        print("🔧 [Demo] 暂停其他健康监测服务，避免步数监测冲突")
        HealthMonitoringService.shared.stopMonitoring()
        
        // 重置步数为0，因为我们只关心增量
        demoProfile.stepCount = 0
        stepCheckCount = 0
        
        // 记录开始监测的时间
        let startTime = Date()
        print("🎬 Demo: 开始监测时间: \(startTime)")
        
        // 延迟2秒后先获取MotionManager的当前步数作为基准
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // 再次检查Demo状态，确保没有被中断或重置
            guard self.isStepMonitoringActive && self.demoState == .stepDetection else {
                print("⚠️ Demo状态已改变，停止步数监测初始化")
                return
            }
            
            // 先从MotionManager获取当前步数作为基准
            let motionManagerSteps = self.motionManager.pedometerSteps
            print("📱 [MotionManager] 当前步数: \(motionManagerSteps)")
            
            // 设置初始步数（使用MotionManager的数据作为基准）
            self.initialStepCount = motionManagerSteps
            self.demoProfile.stepCount = 0
            print("🎬 Demo: 设置初始步数: \(motionManagerSteps) (使用MotionManager数据)")
            
            // 启动MotionManager步数监测
            self.motionManager.startStepCounting { [weak self] currentTotalSteps in
                print("📱 [Demo-MotionManager回调] 步数更新: \(currentTotalSteps)")
                self?.handleStepCountUpdate(currentTotalSteps)
            }
            
            // 启动180秒倒计时
            self.startCountdownTimer()
            
            // 确保UI更新
            self.objectWillChange.send()
        }
    }
    
    // MARK: - 处理步数更新
    private func handleStepCountUpdate(_ currentTotalSteps: Int) {
        // 确保在主线程执行
        DispatchQueue.main.async {
            // 检查是否还在步数监测状态
            guard self.isStepMonitoringActive && self.demoState == .stepDetection else {
                print("⚠️ [步数处理] 步数监测已停止或状态已改变，忽略更新")
                return
            }
            
            // 检查是否已经完成目标
            guard !self.demoProfile.stepGoalCompleted && !self.demoProfile.hasCompletedDemo else {
                print("⚠️ [步数处理] 步数目标已完成，停止处理更新")
                self.stopStepMonitoring()
                return
            }
            
            self.stepCheckCount += 1
            
            // 获取当前MotionManager的原始数据用于对比
            let motionManagerRaw = self.motionManager.pedometerSteps
            
            print("📊 [数据源对比] MotionManager原始: \(motionManagerRaw), 回调传入: \(currentTotalSteps)")
            
            // 如果初始步数还没有设置，先设置初始步数
            if self.initialStepCount == 0 {
                self.initialStepCount = currentTotalSteps
                self.demoProfile.stepCount = 0
                print("🎬 [步数处理] 首次设置初始步数: \(self.initialStepCount)")
                self.objectWillChange.send()
                return
            }
            
            // 计算从开始监测后的步数增量
            let stepIncrease = currentTotalSteps - self.initialStepCount
            
            print("🎬 [步数处理] 当前总步数: \(currentTotalSteps), 初始步数: \(self.initialStepCount), 计算增量: \(stepIncrease), 检查次数: \(self.stepCheckCount)")
            
            // 处理负数增量的情况
            if stepIncrease < 0 {
                print("⚠️ [步数处理] 检测到负数增量: \(stepIncrease)")
                print("📊 [数据源分析] 可能原因：数据源不一致或步数计算器重置")
                
                // 如果这是前几次检查，重新设置初始步数
                if self.stepCheckCount <= 5 {
                    self.initialStepCount = currentTotalSteps
                    self.demoProfile.stepCount = 0
                    print("🔧 [步数处理] 重新校准初始步数: \(self.initialStepCount)，从0开始计算")
                    self.objectWillChange.send()
                    return
                } else {
                    // 如果已经检查多次还是负数，可能是数据异常，忽略此次更新
                    print("❌ [步数处理] 多次检查均为负数，忽略此次更新")
                    return
                }
            }
            
            // 第一次检查时，如果增量过大（超过30步），重新设置初始步数
            if self.stepCheckCount == 1 && stepIncrease > 30 {
                print("⚠️ [步数处理] 第一次检查增量过大(\(stepIncrease))，重新设置初始步数为当前步数")
                self.initialStepCount = currentTotalSteps
                self.demoProfile.stepCount = 0
                print("🔧 [步数处理] 重新设置初始步数: \(self.initialStepCount)，从0开始计算")
                self.objectWillChange.send()
                return
            }
            
            // 如果增量异常过大（超过200步），可能是数据异常，忽略
            if stepIncrease > 200 {
                print("❌ [步数处理] 步数增量异常过大: \(stepIncrease)，忽略此次更新")
                return
            }
            
            // 更新步数增量
            let newStepCount = stepIncrease
            if newStepCount != self.demoProfile.stepCount {
                self.demoProfile.stepCount = newStepCount
                print("✅ [步数处理] 步数更新成功 - 新增量: \(newStepCount)")
                
                // 保存状态
                self.saveDemoData()
                
                // 触发UI更新
                self.objectWillChange.send()
            } else {
                print("📍 [步数处理] 步数无变化，跳过更新")
            }
            
            // 检查是否达到目标（10步）
            if newStepCount >= 10 && !self.demoProfile.stepGoalCompleted {
                print("🎉 [步数处理] 达到步数目标！")
                self.demoProfile.completeStepGoal()
                self.saveDemoData()
                self.stopStepMonitoring()
                self.completeStepGoal()
            }
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
        
        // 恢复其他健康监测服务
        print("🔧 [Demo] 恢复其他健康监测服务")
        HealthMonitoringService.shared.startMonitoring()
        
        print("🎬 Demo: 步数监测已停止")
    }
    
    // MARK: - 重新计算倒计时（页面重新出现时调用）
    func recalculateCountdown() {
        print("🎬 Demo: 开始重新计算倒计时 - 当前状态: \(demoState.rawValue)")
        
        // 重新计算久坐检测倒计时
        if let sedentaryEndTime = sedentaryEndTime, demoState == .sedentaryTrigger {
            let remainingTime = sedentaryEndTime.timeIntervalSinceNow
            sedentaryCountdown = max(0, Int(remainingTime))
            
            print("🎬 Demo: 久坐检测剩余时间: \(remainingTime)s")
            
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
            
            print("🎬 Demo: 步数检测剩余时间: \(remainingTime)s")
            
            // 如果时间到了，但没有完成目标，返回主页面
            if remainingTime <= 0 {
                if !demoProfile.stepGoalCompleted {
                    print("🎬 Demo: 步数检测时间到，未完成目标，返回主页面")
                    stopStepMonitoring()
                    demoState = .mainPage
                    saveDemoData()
                } else {
                    print("🎬 Demo: 步数检测时间到，但目标已完成")
                }
            } else {
                // 重新启动Timer和步数监测
                startCountdownTimer()
                
                // 如果步数监测未激活，重新启动
                if !isStepMonitoringActive {
                    isStepMonitoringActive = true
                    startRealStepMonitoring()
                }
            }
        }
        
        // 如果从其他状态恢复到步数检测状态，需要确保监测正常运行
        if demoState == .stepDetection && !isStepMonitoringActive && !demoProfile.stepGoalCompleted {
            print("🎬 Demo: 检测到步数检测状态但监测未激活，重新启动监测")
            isStepMonitoringActive = true
            startRealStepMonitoring()
        }
        
        print("🎬 Demo: 倒计时重新计算完成 - 久坐: \(sedentaryCountdown)s, 步数: \(countdownSeconds)s, 监测状态: \(isStepMonitoringActive)")
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
            sedentaryEndTime: sedentaryEndTime,
            initialStepCount: initialStepCount,
            stepCheckCount: stepCheckCount
        )
        
        if let data = try? JSONEncoder().encode(demoData) {
            userDefaults.set(data, forKey: demoKey)
        }
    }
    
    // MARK: - 加载Demo数据
    func loadDemoData() {
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
            initialStepCount = demoData.initialStepCount
            stepCheckCount = demoData.stepCheckCount
            
            print("🎬 Demo数据已加载: 状态=\(demoState.rawValue), hasShownWelcome=\(hasShownWelcome), shouldPlayEvolutionAnimation=\(shouldPlayEvolutionAnimation), countdownSeconds=\(countdownSeconds), isStepMonitoringActive=\(isStepMonitoringActive), sedentaryCountdown=\(sedentaryCountdown), stepGoalCompleted=\(demoProfile.stepGoalCompleted), hasCompletedDemo=\(demoProfile.hasCompletedDemo)")
        }
    }
    
    // MARK: - 清除Demo数据
    private func clearDemoData() {
        userDefaults.removeObject(forKey: demoKey)
    }
    
    // MARK: - 应用恢复时的状态检查
    func handleAppResume() {
        print("🎬 Demo: 应用从后台恢复，检查状态")
        
        // 重新计算倒计时
        recalculateCountdown()
        
        // 如果在步数检测阶段但监测未激活，重新启动
        if demoState == .stepDetection && !isStepMonitoringActive && !demoProfile.stepGoalCompleted {
            print("🎬 Demo: 检测到步数检测状态但监测未激活，重新启动监测")
            isStepMonitoringActive = true
            startRealStepMonitoring()
        }
        
        // 确保UI更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
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
    let initialStepCount: Int
    let stepCheckCount: Int
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