import UserNotifications
import WatchKit
import os

// MARK: - WatchOS 应用代理
class WatchOSAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching() {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (allowed, error) in
            if allowed {
                os_log(.debug, "通知权限已获取")
            } else {
                os_log(.debug, "通知权限未获取")
            }
        }
        
        // 设置通知代理
        let center = UNUserNotificationCenter.current()
        center.delegate = self
    }
    
    // MARK: - 处理远程通知
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any]) async -> WKBackgroundFetchResult {
        return .noData
    }
    
    // MARK: - 前台显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.badge, .banner, .list]
    }
    
    // MARK: - 处理通知点击
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let element = userInfo["element"] as? String,
           let typeString = userInfo["type"] as? String {
            print("用户点击了通知 - 元素: \(element), 类型: \(typeString)")
        }
        
        completionHandler()
    }
} 