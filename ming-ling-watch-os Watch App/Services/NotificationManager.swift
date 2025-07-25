import Foundation
import UserNotifications
import WatchKit

// MARK: - 通知管理器
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var lastNotification: HealthNotification?
    
    private init() {
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    // MARK: - 检查授权状态
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 请求通知权限
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - 发送健康提醒通知
    func sendHealthReminder(type: HealthReminder.ReminderType, message: String, userElement: String) {
        let content = UNMutableNotificationContent()
        content.title = getNotificationTitle(for: type)
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "PET_NOTIFICATION"
        
        // 添加自定义数据
        content.userInfo = [
            "type": type.rawValue,
            "userElement": userElement,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "health_reminder_\(type.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.lastNotification = HealthNotification(
                        type: type,
                        message: message,
                        timestamp: Date(),
                        userElement: userElement
                    )
                }
            }
        }
    }
    
    // MARK: - 发送后续提醒通知
    func sendFollowUpReminder(type: HealthReminder.ReminderType, followUpType: FollowUpType, message: String, userElement: String) {
        let content = UNMutableNotificationContent()
        content.title = getFollowUpTitle(for: type, followUpType: followUpType)
        content.body = message
        content.sound = .default
        
        // 添加自定义数据
        content.userInfo = [
            "type": type.rawValue,
            "followUpType": getFollowUpTypeString(followUpType),
            "userElement": userElement,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "follow_up_\(type.rawValue)_\(getFollowUpTypeString(followUpType))_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending follow-up notification: \(error)")
            }
        }
    }
    
    // MARK: - 发送定时提醒
    func scheduleTimedReminder(type: HealthReminder.ReminderType, message: String, userElement: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = getNotificationTitle(for: type)
        content.body = message
        content.sound = .default
        
        content.userInfo = [
            "type": type.rawValue,
            "userElement": userElement,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "timed_reminder_\(type.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling timed notification: \(error)")
            }
        }
    }
    
    // MARK: - 获取通知标题
    private func getNotificationTitle(for type: HealthReminder.ReminderType) -> String {
        switch type {
        case .sunExposure:
            return "晒太阳提醒"
        case .stress:
            return "压力提醒"
        case .sedentary:
            return "久坐提醒"
        case .exercise:
            return "运动检测"
        case .sleep:
            return "睡眠提醒"
        }
    }
    
    // MARK: - 获取后续提醒标题
    private func getFollowUpTitle(for type: HealthReminder.ReminderType, followUpType: FollowUpType) -> String {
        switch followUpType {
        case .improved:
            return "进步很大！"
        case .stillLow:
            return "继续加油"
        case .moved:
            return "做得很好！"
        case .postExercise:
            return "运动完成"
        case .morning:
            return "早安"
        case .evening:
            return "晚安"
        }
    }
    
    // MARK: - 获取后续提醒类型字符串
    private func getFollowUpTypeString(_ type: FollowUpType) -> String {
        switch type {
        case .improved: return "improved"
        case .stillLow: return "stillLow"
        case .moved: return "moved"
        case .postExercise: return "postExercise"
        case .morning: return "morning"
        case .evening: return "evening"
        }
    }
    
    // MARK: - 清除所有通知
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // MARK: - 清除特定类型的通知
    func clearNotifications(for type: HealthReminder.ReminderType) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.filter { request in
                request.content.userInfo["type"] as? String == type.rawValue
            }.map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // MARK: - 设置通知类别
    private func setupNotificationCategories() {
        // 创建宠物通知类别，用于 Long Look 自定义界面
        let petCategory = UNNotificationCategory(
            identifier: "PET_NOTIFICATION",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 注册通知类别
        UNUserNotificationCenter.current().setNotificationCategories([petCategory])
    }
    
    // MARK: - 发送测试通知
    func sendTestNotification(userElement: String) {
        let content = UNMutableNotificationContent()
        content.title = "宠物消息"
        content.body = "点击查看自定义界面"
        content.sound = .default
        content.categoryIdentifier = "PET_NOTIFICATION"
        
        // 添加自定义数据
        content.userInfo = [
            "type": "test",
            "userElement": userElement,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending test notification: \(error)")
            } else {
                print("Test notification sent successfully")
            }
        }
    }
}

// MARK: - 健康通知模型
struct HealthNotification: Identifiable {
    let id = UUID()
    let type: HealthReminder.ReminderType
    let message: String
    let timestamp: Date
    let userElement: String
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
} 