import SwiftUI

// MARK: - 通知工具类
class NotificationUtils {
    
    // MARK: - 通知类型
    enum NotificationType: String, CaseIterable {
        case health = "health"
        case reminder = "reminder"
        case encouragement = "encouragement"
        case achievement = "achievement"
        
        var title: String {
            switch self {
            case .health:
                return "健康提醒"
            case .reminder:
                return "温馨提醒"
            case .encouragement:
                return "鼓励"
            case .achievement:
                return "成就"
            }
        }
    }
    
    // MARK: - 健康提醒类型
    enum HealthReminderType: String, CaseIterable {
        case sunExposure = "晒太阳"
        case stress = "压力大"
        case sedentary = "久坐"
        case exercise = "运动检测"
        case sleep = "睡眠监测"
        
        var title: String {
            return self.rawValue
        }
    }
    
    // MARK: - 获取通知内容
    static func getNotificationContent(for element: String, type: NotificationType = .encouragement) -> NotificationContent {
        let message = PetUtils.getRandomMessage(for: element)
        let themeConfig = PetUtils.getElementThemeConfig(for: element)
        
        return NotificationContent(
            title: type.title,
            message: message,
            element: element,
            themeConfig: themeConfig,
            type: type
        )
    }
    
    // MARK: - 获取健康提醒内容
    static func getHealthReminderContent(for element: String, reminderType: HealthReminderType, subType: String = "建议") -> NotificationContent {
        let message = getHealthReminderMessage(for: element, reminderType: reminderType, subType: subType)
        let themeConfig = PetUtils.getElementThemeConfig(for: element)
        
        return NotificationContent(
            title: reminderType.title,
            message: message,
            element: element,
            themeConfig: themeConfig,
            type: .health
        )
    }
    
    // MARK: - 获取健康提醒消息
    private static func getHealthReminderMessage(for element: String, reminderType: HealthReminderType, subType: String) -> String {
        return ReminderContentManager.shared.getReminderContent(
            for: reminderType.rawValue,
            subType: subType,
            element: element
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