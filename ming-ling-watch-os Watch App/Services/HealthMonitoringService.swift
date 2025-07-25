import Foundation
import HealthKit
import CoreMotion
import CoreLocation
import WatchKit

// MARK: - 健康监测服务
class HealthMonitoringService: ObservableObject {
    static let shared = HealthMonitoringService()
    
    @Published var currentHealthStatus: HealthStatus = .normal
    @Published var lastReminderTime: Date?
    @Published var isMonitoringFollowUp = false
    
    private let healthKitManager = HealthKitManager()
    private let motionManager = MotionManager()
    private let locationManager = LocationManager()
    private let systemNotificationManager = SystemNotificationManager.shared
    private let profileManager = UserProfileManager.shared
    
    // 每日提醒限制
    private var dailyReminderCounts: [TaskType: Int] = [:]
    private var lastResetDate: Date?
    
    // 久坐检测相关
    private var sedentaryReminderSent = false
    private var sedentaryReminderTime: Date?
    private var stepsBeforeReminder = 0
    private var followUpTimer: Timer?
    private var lastSedentaryCheckTime: Date?
    
    // 压力检测相关
    private var stressReminderSent = false
    private var stressReminderTime: Date?
    private var baselineHRV: Double = 0
    private var lastStressCheckTime: Date?
    
    // 运动检测相关
    private var exerciseReminderSent = false
    private var exerciseReminderTime: Date?
    private var lastExerciseCheckTime: Date?
    
    // 睡眠检测相关
    private var sleepReminderSent = false
    private var lastSleepCheckTime: Date?
    
    // 晒太阳检测相关
    private var sunExposureReminderSent = false
    private var lastSunExposureCheckTime: Date?
    
    private init() {
        setupMonitoring()
        checkAndResetDailyCounts()
    }
    
    // MARK: - 设置监测
    private func setupMonitoring() {
        // 启动步数监测
        motionManager.startStepCounting { [weak self] steps in
            self?.handleStepCountUpdate(steps)
        }
        
        // 启动心率监测
        healthKitManager.startHeartRateMonitoring { [weak self] heartRate in
            self?.handleHeartRateUpdate(heartRate)
        }
        
        // 启动HRV监测
        healthKitManager.startHRVMonitoring { [weak self] hrv in
            self?.handleHRVUpdate(hrv)
        }
        
        // 启动环境监测
        EnvironmentSensorManager.shared.startLocationMonitoring()
    }
    
    // MARK: - 开始监测
    func startMonitoring() {
        print("开始健康监测")
        setupMonitoring()
    }
    
    // MARK: - 停止监测
    func stopMonitoring() {
        motionManager.stopStepCounting()
        healthKitManager.stopHeartRateMonitoring()
        healthKitManager.stopHRVMonitoring()
        followUpTimer?.invalidate()
        followUpTimer = nil
    }
    
    // MARK: - 检查并重置每日计数
    private func checkAndResetDailyCounts() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if lastResetDate == nil || !calendar.isDate(lastResetDate!, inSameDayAs: today) {
            // 重置每日计数
            dailyReminderCounts = [:]
            lastResetDate = today
            
            // 重置所有提醒状态
            resetAllMonitoringStates()
            
            print("每日提醒计数已重置")
        }
    }
    
    // MARK: - 重置所有监测状态
    private func resetAllMonitoringStates() {
        sedentaryReminderSent = false
        sedentaryReminderTime = nil
        stepsBeforeReminder = 0
        isMonitoringFollowUp = false
        followUpTimer?.invalidate()
        followUpTimer = nil
        lastSedentaryCheckTime = nil
        
        stressReminderSent = false
        stressReminderTime = nil
        lastStressCheckTime = nil
        
        exerciseReminderSent = false
        exerciseReminderTime = nil
        lastExerciseCheckTime = nil
        
        sleepReminderSent = false
        lastSleepCheckTime = nil
        
        sunExposureReminderSent = false
        lastSunExposureCheckTime = nil
    }
    
    // MARK: - 检查每日提醒限制
    private func canSendReminder(for taskType: TaskType) -> Bool {
        checkAndResetDailyCounts()
        
        let currentCount = dailyReminderCounts[taskType] ?? 0
        let maxDailyReminders = getMaxDailyReminders(for: taskType)
        
        return currentCount < maxDailyReminders
    }
    
    // MARK: - 获取每日最大提醒次数
    private func getMaxDailyReminders(for taskType: TaskType) -> Int {
        switch taskType {
        case .sedentary:
            return 2 // 久坐提醒每天最多2次
        case .stress:
            return 2 // 压力提醒每天最多2次
        case .exercise:
            return 1 // 运动提醒每天最多1次
        case .sleep:
            return 1 // 睡眠提醒每天最多1次
        case .sunExposure:
            return 2 // 晒太阳提醒每天最多2次
        }
    }
    
    // MARK: - 记录提醒发送
    private func recordReminderSent(for taskType: TaskType) {
        let currentCount = dailyReminderCounts[taskType] ?? 0
        dailyReminderCounts[taskType] = currentCount + 1
        print("\(taskType.title) 提醒已发送，今日第 \(currentCount + 1) 次")
    }
    
    // MARK: - 处理步数更新
    private func handleStepCountUpdate(_ steps: Int) {
        // 检查是否需要重置每日计数
        checkAndResetDailyCounts()
        
        // 防止频繁检查（至少间隔5分钟）
        let now = Date()
        if let lastCheck = lastSedentaryCheckTime,
           now.timeIntervalSince(lastCheck) < 300 { // 5分钟
            print("久坐检测：距离上次检查不足5分钟，跳过")
            return
        }
        lastSedentaryCheckTime = now
        
        print("久坐检测：开始检查步数状态，当前总步数 \(steps)")
        
        // 久坐检测：1小时内步数<40步
        let calendar = Calendar.current
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        
        // 获取过去一小时的步数
        healthKitManager.getSteps(from: oneHourAgo, to: now) { [weak self] hourlySteps in
            DispatchQueue.main.async {
                print("久坐检测：过去1小时步数 \(hourlySteps) 步")
                self?.checkSedentaryCondition(hourlySteps)
            }
        }
        
        // 久坐后续检测
        if sedentaryReminderSent {
            checkSedentaryFollowUp(steps)
        }
    }
    
    // MARK: - 检查久坐条件
    private func checkSedentaryCondition(_ hourlySteps: Int) {
        // 检查是否已经发送过提醒
        if sedentaryReminderSent {
            return
        }
        
        // 检查每日限制
        if !canSendReminder(for: .sedentary) {
            print("久坐提醒已达到每日限制")
            return
        }
        
        // 检查步数条件：1小时内步数<40步
        if hourlySteps < 40 {
            print("检测到久坐：过去1小时步数 \(hourlySteps) 步")
            
            sedentaryReminderSent = true
            sedentaryReminderTime = Date()
            stepsBeforeReminder = hourlySteps
            
            // 记录提醒发送
            recordReminderSent(for: .sedentary)
            
            // 发送久坐建议通知
            let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
            systemNotificationManager.sendSuggestionNotification(
                for: userElement,
                taskType: .sedentary
            )
            
            // 开始后续检测
            startSedentaryFollowUpMonitoring()
        } else {
            print("久坐检测：过去1小时步数 \(hourlySteps) 步，未达到久坐条件")
        }
    }
    
    // MARK: - 开始久坐后续监测
    private func startSedentaryFollowUpMonitoring() {
        isMonitoringFollowUp = true
        
        // 10分钟后检查步数变化
        followUpTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { [weak self] _ in
            self?.checkSedentaryFollowUp(0)
        }
    }
    
    // MARK: - 检查久坐后续
    private func checkSedentaryFollowUp(_ currentSteps: Int) {
        guard sedentaryReminderSent else { return }
        
        let calendar = Calendar.current
        let reminderTime = sedentaryReminderTime ?? Date()
        let tenMinutesAfterReminder = calendar.date(byAdding: .minute, value: 10, to: reminderTime) ?? Date()
        
        // 获取提醒后10分钟内的步数
        healthKitManager.getSteps(from: reminderTime, to: tenMinutesAfterReminder) { [weak self] stepsAfterReminder in
            DispatchQueue.main.async {
                self?.evaluateSedentaryFollowUp(stepsAfterReminder)
            }
        }
    }
    
    // MARK: - 评估久坐后续
    private func evaluateSedentaryFollowUp(_ stepsAfterReminder: Int) {
        let stepsIncrease = stepsAfterReminder - stepsBeforeReminder
        
        if stepsIncrease >= 100 {
            // 成功活动，发送完成通知
            let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
            systemNotificationManager.sendCompletionNotification(
                for: userElement,
                taskType: .sedentary
            )
            
            print("久坐后续检测成功：步数增加 \(stepsIncrease) 步")
        } else {
            print("久坐后续检测：步数增加不足，仅增加 \(stepsIncrease) 步")
        }
        
        // 重置监测状态
        resetSedentaryMonitoring()
    }
    
    // MARK: - 重置久坐监测
    private func resetSedentaryMonitoring() {
        sedentaryReminderSent = false
        sedentaryReminderTime = nil
        stepsBeforeReminder = 0
        isMonitoringFollowUp = false
        followUpTimer?.invalidate()
        followUpTimer = nil
    }
    
    // MARK: - 处理心率更新
    private func handleHeartRateUpdate(_ heartRate: Double) {
        // 防止频繁检查（至少间隔10分钟）
        let now = Date()
        if let lastCheck = lastExerciseCheckTime,
           now.timeIntervalSince(lastCheck) < 600 { // 10分钟
            return
        }
        lastExerciseCheckTime = now
        
        // 运动检测：心率持续>120超过10分钟
        // 这里需要实现心率持续监测逻辑
        if heartRate > 120 && !exerciseReminderSent {
            checkExerciseCondition(heartRate)
        }
    }
    
    // MARK: - 检查运动条件
    private func checkExerciseCondition(_ heartRate: Double) {
        // 检查是否已经发送过提醒
        if exerciseReminderSent {
            return
        }
        
        // 检查每日限制
        if !canSendReminder(for: .exercise) {
            print("运动提醒已达到每日限制")
            return
        }
        
        exerciseReminderSent = true
        exerciseReminderTime = Date()
        
        // 记录提醒发送
        recordReminderSent(for: .exercise)
        
        // 发送运动建议通知
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        systemNotificationManager.sendSuggestionNotification(
            for: userElement,
            taskType: .exercise
        )
        
        print("检测到运动：心率 \(heartRate) BPM")
    }
    
    // MARK: - 处理HRV更新
    private func handleHRVUpdate(_ hrv: Double) {
        // 防止频繁检查（至少间隔15分钟）
        let now = Date()
        if let lastCheck = lastStressCheckTime,
           now.timeIntervalSince(lastCheck) < 900 { // 15分钟
            return
        }
        lastStressCheckTime = now
        
        // 压力检测：HRV持续低于个人基线20%
        if baselineHRV == 0 {
            baselineHRV = hrv
            return
        }
        
        let hrvThreshold = baselineHRV * 0.8
        
        if hrv < hrvThreshold && !stressReminderSent {
            checkStressCondition(hrv, threshold: hrvThreshold)
        }
    }
    
    // MARK: - 检查压力条件
    private func checkStressCondition(_ hrv: Double, threshold: Double) {
        // 检查是否已经发送过提醒
        if stressReminderSent {
            return
        }
        
        // 检查每日限制
        if !canSendReminder(for: .stress) {
            print("压力提醒已达到每日限制")
            return
        }
        
        stressReminderSent = true
        stressReminderTime = Date()
        
        // 记录提醒发送
        recordReminderSent(for: .stress)
        
        // 发送压力建议通知
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        systemNotificationManager.sendSuggestionNotification(
            for: userElement,
            taskType: .stress
        )
        
        // 开始压力后续检测
        startStressFollowUpMonitoring()
        
        print("检测到压力：HRV \(hrv)ms，低于阈值 \(threshold)ms")
    }
    
    // MARK: - 开始压力后续监测
    private func startStressFollowUpMonitoring() {
        // 30分钟后检查HRV是否改善
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: false) { [weak self] _ in
            self?.checkStressFollowUp()
        }
    }
    
    // MARK: - 检查压力后续
    private func checkStressFollowUp() {
        guard stressReminderSent else { return }
        
        // 获取当前HRV
        healthKitManager.getCurrentHRV { [weak self] currentHRV in
            DispatchQueue.main.async {
                self?.evaluateStressFollowUp(currentHRV)
            }
        }
    }
    
    // MARK: - 评估压力后续
    private func evaluateStressFollowUp(_ currentHRV: Double) {
        let hrvThreshold = baselineHRV * 0.8
        
        if currentHRV >= hrvThreshold {
            // HRV改善，发送完成通知
            let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
            systemNotificationManager.sendCompletionNotification(
                for: userElement,
                taskType: .stress
            )
            
            print("压力后续检测成功：HRV恢复到 \(currentHRV)ms")
        } else {
            print("压力后续检测：HRV仍未改善，当前值 \(currentHRV)ms")
        }
        
        // 重置监测状态
        resetStressMonitoring()
    }
    
    // MARK: - 重置压力监测
    private func resetStressMonitoring() {
        stressReminderSent = false
        stressReminderTime = nil
    }
    
    // MARK: - 获取当前监测状态
    func getCurrentMonitoringStatus() -> [String: Any] {
        return [
            "dailyCounts": dailyReminderCounts,
            "sedentaryReminderSent": sedentaryReminderSent,
            "stressReminderSent": stressReminderSent,
            "exerciseReminderSent": exerciseReminderSent,
            "isMonitoringFollowUp": isMonitoringFollowUp,
            "lastResetDate": lastResetDate ?? Date()
        ]
    }
}

// MARK: - 健康状态枚举
enum HealthStatus {
    case normal
    case warning
    case critical
} 