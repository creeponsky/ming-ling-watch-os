import SwiftUI
import UserNotifications
import WatchKit

// MARK: - 通知工具类
class NotificationUtils {
    
    // MARK: - 通知类型
    enum NotificationType: String, CaseIterable {
        case suggestion = "建议"
        case completion = "完成"
        
        var title: String {
            return self.rawValue
        }
    }
    
    // 安排本地通知
    static func scheduleLocalNotification(at date: Date, title: String, body: String) {
        print(" 安排本地通知: \(title) - \(body)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // 计算时间间隔
        let timeInterval = max(1, date.timeIntervalSinceNow)
        print("⏰ 通知将在 \(timeInterval) 秒后发送")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "stepDetection", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 安排通知失败: \(error)")
            } else {
                print("✅ 通知已安排")
            }
        }
    }
    
    // 取消所有通知
    static func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ 已取消所有待发送通知")
    }
    
    // 请求通知权限
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知权限已获取")
            } else {
                print("❌ 通知权限被拒绝: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    // MARK: - 获取建议通知内容
    static func getSuggestionContent(for element: String, taskType: TaskType) -> NotificationContent? {
        guard let suggestion = ReminderContentManager.shared.getSuggestionContent(for: taskType, element: element) else {
            return nil
        }
        
        let themeConfig = PetUtils.getElementThemeConfig(for: element)
        
        return NotificationContent(
            title: taskType.title,
            message: suggestion.message,
            element: element,
            themeConfig: themeConfig,
            type: .suggestion
        )
    }
    
    // MARK: - 获取完成通知内容
    static func getCompletionContent(for element: String, taskType: TaskType) -> NotificationContent? {
        guard let completion = ReminderContentManager.shared.getCompletionContent(for: taskType, element: element) else {
            return nil
        }
        
        let themeConfig = PetUtils.getElementThemeConfig(for: element)
        
        return NotificationContent(
            title: taskType.title,
            message: completion.message,
            element: element,
            themeConfig: themeConfig,
            type: .completion
        )
    }
    
    // MARK: - 随机获取建议通知内容
    static func getRandomSuggestionContent(for element: String) -> NotificationContent? {
        guard let (taskType, suggestion) = ReminderContentManager.shared.getRandomSuggestionContent(for: element) else {
            return nil
        }
        
        let themeConfig = PetUtils.getElementThemeConfig(for: element)
        
        return NotificationContent(
            title: taskType.title,
            message: suggestion.message,
            element: element,
            themeConfig: themeConfig,
            type: .suggestion
        )
    }
    
    // MARK: - 随机获取完成通知内容
    static func getRandomCompletionContent(for element: String) -> NotificationContent? {
        guard let (taskType, completion) = ReminderContentManager.shared.getRandomCompletionContent(for: element) else {
            return nil
        }
        
        let themeConfig = PetUtils.getElementThemeConfig(for: element)
        
        return NotificationContent(
            title: taskType.title,
            message: completion.message,
            element: element,
            themeConfig: themeConfig,
            type: .completion
        )
    }
}

// MARK: - 通知内容模型
struct NotificationContent {
    let title: String
    let message: String
    let element: String
    let themeConfig: ElementThemeConfig
    let type: NotificationUtils.NotificationType
} 