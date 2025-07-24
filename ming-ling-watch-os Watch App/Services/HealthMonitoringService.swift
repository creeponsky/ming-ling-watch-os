import Foundation
import HealthKit
import UserNotifications
import WatchKit

// MARK: - 健康监测服务
class HealthMonitoringService: ObservableObject {
    static let shared = HealthMonitoringService()
    
    @Published var isMonitoring = false
    @Published var lastNotification: HealthNotification?
    
    private let healthStore = HKHealthStore()
    private let profileManager = UserProfileManager.shared
    private let notificationManager = NotificationManager.shared
    private let environmentManager = EnvironmentSensorManager.shared
    private var monitoringTimer: Timer?
    
    // 监测间隔（秒）
    private let monitoringInterval: TimeInterval = 300 // 5分钟
    
    private init() {
        // 请求通知权限
        Task {
            await notificationManager.requestPermission()
        }
    }
    
    // MARK: - 开始监测
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // 启动环境监测
        environmentManager.startLocationMonitoring()
        
        // 监听晒太阳机会通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSunExposureOpportunity),
            name: .sunExposureOpportunity,
            object: nil
        )
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { _ in
            Task {
                await self.checkHealthConditions()
            }
        }
        
        // 立即执行一次检查
        Task {
            await checkHealthConditions()
        }
    }
    
    // MARK: - 停止监测
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        // 停止环境监测
        environmentManager.stopLocationMonitoring()
        
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 检查健康条件
    private func checkHealthConditions() async {
        guard let userElement = profileManager.userProfile.fiveElements?.primary else {
            return
        }
        
        // 检查各种健康条件
        await checkStressLevel(userElement: userElement)
        await checkSedentaryStatus(userElement: userElement)
        await checkExerciseStatus(userElement: userElement)
        await checkSleepStatus(userElement: userElement)
        await checkSunExposure(userElement: userElement)
    }
    
    // MARK: - 检查压力水平
    private func checkStressLevel(userElement: String) async {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        do {
            let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else { return }
                
                let hrvValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                
                                 // 简单的HRV阈值判断（实际应用中需要更复杂的算法）
                 if hrvValue < 30 { // 假设30ms是低HRV阈值
                     let reminder = HealthReminder.allReminders.first { $0.type == .stress }
                     let message = reminder?.getReminder(for: userElement) ?? "Take a break and relax."
                     
                     self.notificationManager.sendHealthReminder(
                         type: .stress,
                         message: message,
                         userElement: userElement
                     )
                     
                     // 30分钟后检查改善情况
                     self.scheduleFollowUpCheck(type: .stress, userElement: userElement, delay: 1800)
                 }
            }
            
            healthStore.execute(query)
        } catch {
            print("Error checking stress level: \(error)")
        }
    }
    
        // MARK: - 检查久坐状态
    private func checkSedentaryStatus(userElement: String) async {
        // 检查时间：晚上10点到早上6点不提醒久坐
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        if hour >= 22 || hour < 6 {
            return // 晚上不提醒久坐
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: oneHourAgo, end: now, options: .strictStartDate)
        
        do {
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else { return }
                
                let steps = sum.doubleValue(for: HKUnit.count())
                
                if steps < 40 {
                    let reminder = HealthReminder.allReminders.first { $0.type == .sedentary }
                    let message = reminder?.getReminder(for: userElement) ?? "Time to move around!"
                    
                    self.notificationManager.sendHealthReminder(
                        type: .sedentary,
                        message: message,
                        userElement: userElement
                    )
                }
            }
            
            healthStore.execute(query)
        } catch {
            print("Error checking sedentary status: \(error)")
        }
    }
    
        // MARK: - 检查运动状态
    private func checkExerciseStatus(userElement: String) async {
        // 检查时间：晚上9点到早上6点不提醒运动
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        if hour >= 21 || hour < 6 {
            return // 晚上不提醒运动
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let tenMinutesAgo = calendar.date(byAdding: .minute, value: -10, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: tenMinutesAgo, end: now, options: .strictStartDate)
        
        do {
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
                
                let highHeartRateSamples = samples.filter { sample in
                    sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) > 120
                }
                
                if highHeartRateSamples.count >= 5 { // 如果超过5个样本心率都高于120
                    let reminder = HealthReminder.allReminders.first { $0.type == .exercise }
                    let message = reminder?.getReminder(for: userElement) ?? "Great workout! Remember to rest."
                    
                    // 运动后15分钟提醒
                    self.notificationManager.scheduleTimedReminder(
                        type: .exercise,
                        message: message,
                        userElement: userElement,
                        delay: 900 // 15分钟
                    )
                }
            }
            
            healthStore.execute(query)
        } catch {
            print("Error checking exercise status: \(error)")
        }
    }
    
    // MARK: - 检查睡眠状态
    private func checkSleepStatus(userElement: String) async {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: endOfYesterday, options: .strictStartDate)
        
        do {
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                guard let samples = samples as? [HKCategorySample] else { return }
                
                let totalSleepTime = samples.reduce(0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }
                
                                let sleepHours = totalSleepTime / 3600
                
                // 只在早上6-10点检查睡眠状态（用户醒来后）
                let hour = calendar.component(.hour, from: now)
                if hour >= 6 && hour <= 10 && sleepHours < 7 {
                    let reminder = HealthReminder.allReminders.first { $0.type == .sleep }
                    let message = reminder?.getReminder(for: userElement) ?? "You need more sleep tonight."
                    
                    self.notificationManager.sendHealthReminder(
                        type: .sleep,
                        message: message,
                        userElement: userElement
                    )
                }
            }
            
            healthStore.execute(query)
        } catch {
            print("Error checking sleep status: \(error)")
        }
    }
    
        // MARK: - 检查晒太阳状态
    private func checkSunExposure(userElement: String) async {
        // 检查时间：晚上6点到早上8点不提醒晒太阳
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        if hour >= 18 || hour < 8 {
            return // 晚上不提醒晒太阳
        }
        
        // 使用环境传感器管理器检查晒太阳条件
        if environmentManager.isGoodTimeForSunExposure() && environmentManager.checkIndoorToOutdoorTransition() {
            let reminder = HealthReminder.allReminders.first { $0.type == .sunExposure }
            let message = reminder?.getReminder(for: userElement) ?? "Perfect time for some sun!"
            
            self.notificationManager.sendHealthReminder(
                type: .sunExposure,
                message: message,
                userElement: userElement
            )
        }
    }
    
    // MARK: - 处理晒太阳机会通知
    @objc private func handleSunExposureOpportunity(_ notification: Notification) {
        guard let userElement = profileManager.userProfile.fiveElements?.primary else { return }
        
        let reminder = HealthReminder.allReminders.first { $0.type == .sunExposure }
        let message = reminder?.getReminder(for: userElement) ?? "Perfect time for some sun!"
        
        self.notificationManager.sendHealthReminder(
            type: .sunExposure,
            message: message,
            userElement: userElement
        )
    }
    
         // MARK: - 安排后续检查
     private func scheduleFollowUpCheck(type: HealthReminder.ReminderType, userElement: String, delay: TimeInterval) {
         DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
             Task {
                 await self.performFollowUpCheck(type: type, userElement: userElement)
             }
         }
     }
     
     // MARK: - 执行后续检查
     private func performFollowUpCheck(type: HealthReminder.ReminderType, userElement: String) async {
         switch type {
         case .stress:
             await checkStressFollowUp(userElement: userElement)
         case .sedentary:
             await checkSedentaryFollowUp(userElement: userElement)
         case .exercise:
             // 运动检查不需要后续检查
             break
         case .sleep:
             // 睡眠检查不需要后续检查
             break
         case .sunExposure:
             // 晒太阳检查不需要后续检查
             break
         }
     }
     
     // MARK: - 检查压力后续状态
     private func checkStressFollowUp(userElement: String) async {
         let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
         
         do {
             let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                 guard let sample = samples?.first as? HKQuantitySample else { return }
                 
                 let hrvValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                 let reminder = HealthReminder.allReminders.first { $0.type == .stress }
                 
                 if hrvValue >= 30 {
                     // HRV有改善
                     let message = reminder?.getFollowUp(for: userElement, type: .improved) ?? "Great progress! Your stress level has improved."
                     self.notificationManager.sendFollowUpReminder(
                         type: .stress,
                         followUpType: .improved,
                         message: message,
                         userElement: userElement
                     )
                 } else {
                     // HRV仍然低
                     let message = reminder?.getFollowUp(for: userElement, type: .stillLow) ?? "Keep going! Your body needs more time to recover."
                     self.notificationManager.sendFollowUpReminder(
                         type: .stress,
                         followUpType: .stillLow,
                         message: message,
                         userElement: userElement
                     )
                 }
             }
             
             healthStore.execute(query)
         } catch {
             print("Error checking stress follow-up: \(error)")
         }
     }
     
     // MARK: - 检查久坐后续状态
     private func checkSedentaryFollowUp(userElement: String) async {
         let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
         let calendar = Calendar.current
         let now = Date()
         let thirtyMinutesAgo = calendar.date(byAdding: .minute, value: -30, to: now)!
         
         let predicate = HKQuery.predicateForSamples(withStart: thirtyMinutesAgo, end: now, options: .strictStartDate)
         
         do {
             let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                 guard let result = result, let sum = result.sumQuantity() else { return }
                 
                 let steps = sum.doubleValue(for: HKUnit.count())
                 let reminder = HealthReminder.allReminders.first { $0.type == .sedentary }
                 
                 if steps > 100 {
                     // 用户有活动
                     let message = reminder?.getFollowUp(for: userElement, type: .moved) ?? "Well done! You've been active."
                     self.notificationManager.sendFollowUpReminder(
                         type: .sedentary,
                         followUpType: .moved,
                         message: message,
                         userElement: userElement
                     )
                 }
             }
             
             healthStore.execute(query)
         } catch {
             print("Error checking sedentary follow-up: \(error)")
         }
     }
    
    // MARK: - 获取监测状态描述
    func getMonitoringStatusDescription() -> String {
        if isMonitoring {
            return "Health monitoring is active"
        } else {
            return "Health monitoring is inactive"
        }
    }
} 