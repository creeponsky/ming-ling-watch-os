import SwiftUI
import UserNotifications
import WatchKit

// MARK: - 自定义通知控制器
final class NotificationController: WKUserNotificationHostingController<PetNotificationLongLookView> {
    
    // 启用交互式通知
    override class var isInteractive: Bool {
        return true
    }
    
    // 通知内容
    var content: UNNotificationContent!
    var date: Date!
    var userElement: String = "金"
    var notificationUserInfo: [String: Any] = [:]
    
    override func didReceive(_ notification: UNNotification) {
        content = notification.request.content
        date = notification.date
        
        // 解析通知数据
        let userInfo = notification.request.content.userInfo
        print("=== 通知接收调试 ===")
        print("原始 userInfo: \(userInfo)")
        
        if let element = userInfo["element"] as? String {
            self.userElement = element
            print("设置用户元素: \(element)")
        } else {
            print("⚠️ 未找到元素信息，使用默认值: \(self.userElement)")
        }
        
        self.notificationUserInfo = userInfo as? [String: Any] ?? [:]
        print("==================")
    }
    
    override var body: PetNotificationLongLookView {
        return PetNotificationLongLookView(
            content: content,
            date: date,
            userElement: userElement,
            notificationUserInfo: notificationUserInfo
        )
    }
}

// MARK: - 自定义通知视图
struct PetNotificationLongLookView: View {
    @State private var showMore = false
    
    let content: UNNotificationContent?
    let date: Date?
    let userElement: String
    let notificationUserInfo: [String: Any]
    
    var body: some View {
        ZStack {
            // 背景色
            PetUtils.getElementBackgroundColor(for: userElement)
                .ignoresSafeArea()
            
            // 主内容区域 - 只包含对话框，不受GIF影响
            VStack(spacing: 0) {
                // 对话框 - 左上角，固定大小
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(getNotificationMessage())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(PetUtils.getElementDialogColor(for: userElement), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.leading, 4)
                
                Spacer()
            }
            .frame(maxHeight: 200)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Group {
                        if let useGIFAnimation = notificationUserInfo["useGIFAnimation"] as? Bool, useGIFAnimation {
                            GIFAnimationView(gifName: PetUtils.getPetGIFName(for: userElement), isPlaying: true)
                                // .frame(width: 300, height: 300)
                                // .offset(x: 50, y: 80)
                                .frame(width: 80, height: 80)
                                .offset(x: 20, y: 40)
                        } else {
                            Image(PetUtils.getPetSpeakImageName(for: userElement))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .offset(x: 20, y: 40)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 占满整个空间
        }
        .onAppear {
            loadNotificationContent()
        }
    }
    
    // MARK: - 获取通知消息
    private func getNotificationMessage() -> String {
        if let reminderTypeString = notificationUserInfo["reminderType"] as? String,
           let reminderType = NotificationUtils.HealthReminderType(rawValue: reminderTypeString),
           let subType = notificationUserInfo["subType"] as? String {
            // 健康提醒通知
            return ReminderContentManager.shared.getReminderContent(
                for: reminderTypeString,
                subType: subType,
                element: userElement
            )
        } else if let typeString = notificationUserInfo["type"] as? String {
            // 其他类型通知
            return PetUtils.getRandomMessage(for: userElement)
        } else {
            // 默认消息
            return "今天也要加油哦！"
        }
    }
    

    
    // MARK: - 加载通知内容
    private func loadNotificationContent() {
        // 这里可以添加额外的内容加载逻辑
        print("=== 通知调试信息 ===")
        print("用户元素: \(userElement)")
        print("通知用户信息: \(notificationUserInfo)")
        print("背景颜色: \(PetUtils.getElementBackgroundColor(for: userElement))")
        print("对话框颜色: \(PetUtils.getElementDialogColor(for: userElement))")
        print("文字颜色: \(PetUtils.getElementTextColor(for: userElement))")
        
        // 检查是否使用GIF动画
        if let useGIFAnimation = notificationUserInfo["useGIFAnimation"] as? Bool, useGIFAnimation {
            print("GIF动画名称: \(PetUtils.getPetGIFName(for: userElement))")
        } else {
            print("图片名称: \(PetUtils.getPetSpeakImageName(for: userElement))")
        }
        print("==================")
    }
} 