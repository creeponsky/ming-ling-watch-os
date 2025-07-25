import Foundation
import UserNotifications
import WatchKit

// MARK: - 系统通知管理器
class SystemNotificationManager: NSObject, ObservableObject {
    static let shared = SystemNotificationManager()
    
    override init() {
        super.init()
        requestNotificationPermission()
        setupNotificationCategories()
    }
    
    // MARK: - 请求通知权限
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 设置通知类别
    func setupNotificationCategories() {
        // 创建宠物通知类别，支持自定义 Long Look 界面
        let petCategory = UNNotificationCategory(
            identifier: "PET_NOTIFICATION",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 注册通知类别
        UNUserNotificationCenter.current().setNotificationCategories([petCategory])
    }
    
    // MARK: - 发送建议通知
    func sendSuggestionNotification(for element: String, taskType: TaskType, delay: TimeInterval = 1) {
        guard let content = NotificationUtils.getSuggestionContent(for: element, taskType: taskType) else {
            print("无法获取建议内容")
            return
        }
        
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "taskType": taskType.rawValue,
            "type": "suggestion",
            "useGIFAnimation": false
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "suggestion-\(taskType.rawValue)-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送建议通知失败: \(error.localizedDescription)")
            } else {
                print("建议通知已发送")
            }
        }
    }
    
    // MARK: - 发送完成通知
    func sendCompletionNotification(for element: String, taskType: TaskType, delay: TimeInterval = 1) {
        guard let content = NotificationUtils.getCompletionContent(for: element, taskType: taskType) else {
            print("无法获取完成内容")
            return
        }
        
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "taskType": taskType.rawValue,
            "type": "completion",
            "useGIFAnimation": true
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "completion-\(taskType.rawValue)-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送完成通知失败: \(error.localizedDescription)")
            } else {
                print("完成通知已发送")
            }
        }
    }
    
    // MARK: - 发送随机建议通知
    func sendRandomSuggestionNotification(for element: String, delay: TimeInterval = 1) {
        guard let (taskType, suggestion) = ReminderContentManager.shared.getRandomSuggestionContent(for: element) else {
            print("无法获取随机建议内容")
            return
        }
        
        let notification = UNMutableNotificationContent()
        notification.title = taskType.title
        notification.body = suggestion.message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "taskType": taskType.rawValue,
            "type": "suggestion",
            "useGIFAnimation": false
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "random-suggestion-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送随机建议通知失败: \(error.localizedDescription)")
            } else {
                print("随机建议通知已发送")
            }
        }
    }
    
    // MARK: - 发送随机完成通知
    func sendRandomCompletionNotification(for element: String, delay: TimeInterval = 1) {
        guard let (taskType, completion) = ReminderContentManager.shared.getRandomCompletionContent(for: element) else {
            print("无法获取随机完成内容")
            return
        }
        
        let notification = UNMutableNotificationContent()
        notification.title = taskType.title
        notification.body = completion.message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "taskType": taskType.rawValue,
            "type": "completion",
            "useGIFAnimation": true
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "random-completion-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送随机完成通知失败: \(error.localizedDescription)")
            } else {
                print("随机完成通知已发送")
            }
        }
    }
    
    // MARK: - 发送GIF通知（兼容旧接口）
    func sendGIFNotification(for element: String, intimacyGrade: Int, emotion: String, message: String, delay: TimeInterval = 1) {
        let notification = UNMutableNotificationContent()
        notification.title = "宠物消息"
        notification.body = message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "intimacyGrade": intimacyGrade,
            "emotion": emotion,
            "type": "gif",
            "useGIFAnimation": true
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "gif-notification-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送GIF通知失败: \(error.localizedDescription)")
            } else {
                print("GIF通知已发送")
            }
        }
    }
    
    // MARK: - 发送延时GIF通知（兼容旧接口）
    func sendGIFNotificationWithDelay(for element: String, intimacyGrade: Int, emotion: String, message: String, delay: TimeInterval) {
        sendGIFNotification(for: element, intimacyGrade: intimacyGrade, emotion: emotion, message: message, delay: delay)
    }
    
    // MARK: - 取消所有通知
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("所有通知已取消")
    }
    
    // MARK: - 获取待处理通知数量
    func getPendingNotificationCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.count)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension SystemNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使应用在前台也显示通知
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知点击事件
        let userInfo = response.notification.request.content.userInfo
        
        if let element = userInfo["element"] as? String,
           let typeString = userInfo["type"] as? String {
            print("用户点击了通知 - 元素: \(element), 类型: \(typeString)")
            
            // 如果是完成通知，增加亲密度
            if typeString == "completion" {
                if let taskTypeString = userInfo["taskType"] as? String,
                   let taskType = TaskType(rawValue: taskTypeString),
                   let completion = ReminderContentManager.shared.getCompletionContent(for: taskType, element: element) {
                    // 增加亲密度
                    UserProfileManager.shared.addIntimacy(completion.intimacyPoints)
                    print("完成通知：增加亲密度 \(completion.intimacyPoints) 点")
                }
            }
        }
        
        completionHandler()
    }
} 