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
    
    // MARK: - 发送宠物通知
    func sendPetNotification(for element: String, type: NotificationUtils.NotificationType = .encouragement) {
        let content = NotificationUtils.getNotificationContent(for: element, type: type)
        
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "type": type.rawValue
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器（立即触发）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "pet-notification-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送通知失败: \(error.localizedDescription)")
            } else {
                print("宠物通知已发送")
            }
        }
    }
    
    // MARK: - 发送健康提醒通知
    func sendHealthReminderNotification(for element: String, reminderType: NotificationUtils.HealthReminderType, subType: String = "建议", useGIFAnimation: Bool = false) {
        sendHealthReminderNotificationWithDelay(for: element, reminderType: reminderType, subType: subType, delay: 1, useGIFAnimation: useGIFAnimation)
    }
    
    // MARK: - 发送延时健康提醒通知
    func sendHealthReminderNotificationWithDelay(for element: String, reminderType: NotificationUtils.HealthReminderType, subType: String = "建议", delay: TimeInterval, useGIFAnimation: Bool = false) {
        let content = NotificationUtils.getHealthReminderContent(for: element, reminderType: reminderType, subType: subType)
        
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "reminderType": reminderType.rawValue,
            "subType": subType,
            "type": "health_reminder",
            "useGIFAnimation": useGIFAnimation
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器（延时触发）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "health-reminder-\(reminderType.rawValue)-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送健康提醒通知失败: \(error.localizedDescription)")
            } else {
                print("健康提醒通知已安排，\(delay)秒后发送")
            }
        }
    }
    
    // MARK: - 发送定时提醒通知
    func scheduleReminderNotification(for element: String, type: NotificationUtils.NotificationType, timeInterval: TimeInterval) {
        let content = NotificationUtils.getNotificationContent(for: element, type: type)
        
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.message
        notification.sound = .default
        
        // 添加自定义数据
        notification.userInfo = [
            "element": element,
            "type": type.rawValue
        ]
        
        // 设置通知类别以启用自定义 Long Look 界面
        notification.categoryIdentifier = "PET_NOTIFICATION"
        
        // 创建触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "scheduled-notification-\(UUID().uuidString)",
            content: notification,
            trigger: trigger
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送定时通知失败: \(error.localizedDescription)")
            } else {
                print("定时通知已安排")
            }
        }
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
            
            // 这里可以添加处理通知点击的逻辑
            // 比如打开特定的页面或执行特定的操作
        }
        
        completionHandler()
    }
} 