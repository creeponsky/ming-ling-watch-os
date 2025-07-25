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
    
    // 久坐检测相关
    private var sedentaryReminderSent = false
    private var sedentaryReminderTime: Date?
    private var stepsBeforeReminder = 0
    private var followUpTimer: Timer?
    
    // 压力检测相关
    private var stressReminderSent = false
    private var stressReminderTime: Date?
    private var baselineHRV: Double = 0
    
    private init() {
        setupMonitoring()
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
    
    // MARK: - 处理步数更新
    private func handleStepCountUpdate(_ steps: Int) {
        // 久坐检测：1小时内步数<40步
        let calendar = Calendar.current
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        
        // 获取过去一小时的步数
        healthKitManager.getSteps(from: oneHourAgo, to: Date()) { [weak self] hourlySteps in
            DispatchQueue.main.async {
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
        if hourlySteps < 40 && !sedentaryReminderSent {
            sedentaryReminderSent = true
            sedentaryReminderTime = Date()
            stepsBeforeReminder = hourlySteps
            
            // 发送久坐建议通知
            let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
            systemNotificationManager.sendSuggestionNotification(
                for: userElement,
                taskType: .sedentary
            )
            
            // 开始后续检测
            startSedentaryFollowUpMonitoring()
        }
    }
    
    // MARK: - 开始久坐后续监测
    private func startSedentaryFollowUpMonitoring() {
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
        // 运动检测：心率持续>120超过10分钟
        // 这里需要实现心率持续监测逻辑
    }
    
    // MARK: - 处理HRV更新
    private func handleHRVUpdate(_ hrv: Double) {
        // 压力检测：HRV持续低于个人基线20%
        if baselineHRV == 0 {
            baselineHRV = hrv
            return
        }
        
        let hrvThreshold = baselineHRV * 0.8
        
        if hrv < hrvThreshold && !stressReminderSent {
            stressReminderSent = true
            stressReminderTime = Date()
            
            // 发送压力建议通知
            let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
            systemNotificationManager.sendSuggestionNotification(
                for: userElement,
                taskType: .stress
            )
            
            // 开始压力后续检测
            startStressFollowUpMonitoring()
        }
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
        let currentHRV = healthKitManager.heartRateVariability
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
}

// MARK: - 健康状态枚举
enum HealthStatus {
    case normal
    case warning
    case critical
} 