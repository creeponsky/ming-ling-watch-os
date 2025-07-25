import SwiftUI

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