import Foundation
import WatchKit
import UserNotifications

// MARK: - WatchOS 应用代理
class WatchOSAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching() {
        print("📱 WatchOS App启动")
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 请求通知权限
        NotificationUtils.requestNotificationPermission()
        
        // 初始化DemoManager
        DemoManager.shared.loadDemoData()
    }
    
    func applicationWillEnterForeground() {
        print("📱 App进入前台")
        
        // 重新计算倒计时
        DemoManager.shared.recalculateCountdown()
    }
    
    func applicationDidEnterBackground() {
        print("📱 App进入后台")
        
        // 可以在这里做一些后台清理工作
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // 当App在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 前台收到通知: \(notification.request.identifier)")
        
        // 允许在前台显示通知
        completionHandler([.banner, .sound])
    }
    
    // 用户点击通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📱 用户点击通知: \(response.notification.request.identifier)")
        
        // 处理步数检测通知
        if response.notification.request.identifier == "stepDetection" {
            // 确保DemoManager状态正确
            DemoManager.shared.recalculateCountdown()
        }
        
        completionHandler()
    }
} 