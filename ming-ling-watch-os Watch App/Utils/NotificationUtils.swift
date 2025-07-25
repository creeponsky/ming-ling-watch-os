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
    
    // MARK: - 获取健康相关通知
    static func getHealthNotification(for element: String, healthData: String) -> NotificationContent {
        let healthMessages: [String: [String]] = [
            "金": [
                "检测到你的呼吸频率有些快，建议深呼吸放松一下～",
                "金元素的朋友，记得保持肺部健康，多呼吸新鲜空气！",
                "你的肺气需要调理，建议做一些温和的运动。"
            ],
            "木": [
                "检测到你的肝气有些郁结，建议多活动一下～",
                "木元素的朋友，记得舒展身体，保持心情舒畅！",
                "你的肝气需要调理，建议做一些伸展运动。"
            ],
            "水": [
                "检测到你的肾气有些不足，建议多休息一下～",
                "水元素的朋友，记得保持充足睡眠，注意保暖！",
                "你的肾气需要调理，建议多喝温水。"
            ],
            "火": [
                "检测到你的心气有些亢奋，建议冷静一下～",
                "火元素的朋友，记得保持心情平静，避免过度兴奋！",
                "你的心气需要调理，建议做一些冥想。"
            ],
            "土": [
                "检测到你的脾气有些虚弱，建议调理一下～",
                "土元素的朋友，记得注意饮食，保持规律作息！",
                "你的脾气需要调理，建议多吃温性食物。"
            ]
        ]
        
        let elementMessages = healthMessages[element] ?? healthMessages["土"]!
        let message = elementMessages.randomElement() ?? "注意身体健康哦～"
        
        return NotificationContent(
            title: "健康提醒",
            message: message,
            element: element,
            themeConfig: PetUtils.getElementThemeConfig(for: element),
            type: .health
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