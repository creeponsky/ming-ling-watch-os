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
    @StateObject private var profileManager = UserProfileManager.shared
    
    let content: UNNotificationContent?
    let date: Date?
    let userElement: String
    let notificationUserInfo: [String: Any]
    
    var body: some View {
        ZStack {
            // 背景色
            PetUtils.getElementBackgroundColor(for: userElement)
                .ignoresSafeArea()
            
            // 对话框card - 固定大小，不受其他元素影响
            VStack(alignment: .leading, spacing: 6) {
                Text(getNotificationMessage())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 112, height: 80, alignment: .leading) // 缩小宽度到70%：160 * 0.7 = 112
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(PetUtils.getElementDialogColor(for: userElement), lineWidth: 1.5)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            .position(x: 70, y: 50) // 更靠左上角
            
            // 亲密度显示 - 绝对定位在对话框右下角
            if isCompletionNotification() {
                HStack(spacing: 4) {
                    Image(systemName: getIntimacyIcon())
                        .font(.caption2)
                        .foregroundColor(Color(hex: profileManager.userProfile.intimacyGradeColor))
                    
                    Text("+\(getIntimacyPoints())")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.8))
                )
                .position(x: 110, y: 75) // 调整到新的对话框右下角
            }
            
            // GIF动画层 - 使用绝对定位，不影响其他元素
            Group {
                if let useGIFAnimation = notificationUserInfo["useGIFAnimation"] as? Bool, useGIFAnimation {
                    GIFAnimationView(gifName: getGIFName(), isPlaying: true)
                        .frame(width: 240, height: 240) // 1.5倍：160 * 1.5 = 240
                } else {
                    Image(PetUtils.getPetSpeakImageName(for: userElement))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160) // speak保持原大小
                }
            }
            .position(x: 140, y: 140) // 往下移动：120 -> 140
        }
        .onAppear {
            loadNotificationContent()
        }
    }
    
    // MARK: - 判断是否为完成通知
    private func isCompletionNotification() -> Bool {
        return notificationUserInfo["type"] as? String == "completion"
    }
    
    // MARK: - 获取亲密度图标
    private func getIntimacyIcon() -> String {
        let intimacyGrade = profileManager.userProfile.intimacyGrade
        switch intimacyGrade {
        case 1:
            return "heart"
        case 2:
            return "heart.fill"
        case 3:
            return "heart.circle.fill"
        default:
            return "heart"
        }
    }
    
    // MARK: - 获取亲密度奖励点数
    private func getIntimacyPoints() -> Int {
        if let taskTypeString = notificationUserInfo["taskType"] as? String,
           let taskType = TaskType(rawValue: taskTypeString),
           let completion = ReminderContentManager.shared.getCompletionContent(for: taskType, element: userElement) {
            return completion.intimacyPoints
        }
        return 20 // 默认奖励
    }
    
    // MARK: - 获取GIF名称
    private func getGIFName() -> String {
        let intimacyGrade = profileManager.userProfile.intimacyGrade
        return PetUtils.getPetGIFName(for: userElement, intimacyGrade: intimacyGrade)
    }
    
    // MARK: - 获取通知消息
    private func getNotificationMessage() -> String {
        if let typeString = notificationUserInfo["type"] as? String {
            switch typeString {
            case "suggestion":
                // 建议通知
                if let taskTypeString = notificationUserInfo["taskType"] as? String,
                   let taskType = TaskType(rawValue: taskTypeString),
                   let suggestion = ReminderContentManager.shared.getSuggestionContent(for: taskType, element: userElement) {
                    return suggestion.message
                } else {
                    // 如果没有找到具体的任务类型，尝试获取随机建议
                    if let suggestion = ReminderContentManager.shared.getRandomSuggestionContent(for: userElement) {
                        return suggestion.1.message
                    }
                }
            case "completion":
                // 完成通知
                if let taskTypeString = notificationUserInfo["taskType"] as? String,
                   let taskType = TaskType(rawValue: taskTypeString),
                   let completion = ReminderContentManager.shared.getCompletionContent(for: taskType, element: userElement) {
                    return completion.message
                } else {
                    // 如果没有找到具体的任务类型，尝试获取随机完成
                    if let completion = ReminderContentManager.shared.getRandomCompletionContent(for: userElement) {
                        return completion.1.message
                    }
                }
            case "gif":
                // GIF通知
                if let message = content?.body {
                    return message
                }
            default:
                break
            }
        }
        
        // 默认消息
        return "今天也要加油哦！"
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
            let gifName = getGIFName()
            print("GIF动画名称: \(gifName)")
        } else {
            print("图片名称: \(PetUtils.getPetSpeakImageName(for: userElement))")
        }
        print("==================")
    }
} 