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
        print("通知标题: \(notification.request.content.title)")
        print("通知内容: \(notification.request.content.body)")
        
        if let element = userInfo["element"] as? String {
            self.userElement = element
            print("✅ 设置用户元素: \(element)")
        } else {
            print("⚠️ 未找到元素信息，使用默认值: \(self.userElement)")
        }
        
        if let taskType = userInfo["taskType"] as? String {
            print("✅ 任务类型: \(taskType)")
        } else {
            print("⚠️ 未找到任务类型")
        }
        
        if let type = userInfo["type"] as? String {
            print("✅ 通知类型: \(type)")
        } else {
            print("⚠️ 未找到通知类型")
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
        // 主容器 - 只包含背景和对话框
        ZStack {
            // 背景色
            PetUtils.getElementBackgroundColor(for: userElement)
                .ignoresSafeArea()
            
            // 对话框
            VStack(alignment: .leading, spacing: 4) {
                Text(getNotificationMessage())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(width: 130, height: 70, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(PetUtils.getElementDialogColor(for: userElement), lineWidth: 1.5)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .position(x: 96, y: 45)
        }
        .frame(width: 250, height: 250)
        // 使用overlay添加其他元素，实现真正的绝对定位
//        .overlay(
            // // 亲密度显示
            // Group {
            //     if isCompletionNotification() {
            //         HStack(spacing: 4) {
            //             Image(systemName: getIntimacyIcon())
            //                 .font(.caption2)
            //                 .foregroundColor(Color(hex: profileManager.userProfile.intimacyGradeColor))
                        
            //             Text("+\(getIntimacyPoints())")
            //                 .font(.system(size: 10, weight: .bold, design: .rounded))
            //                 .foregroundColor(PetUtils.getElementTextColor(for: userElement))
            //         }
            //         .padding(.horizontal, 14)
            //         .padding(.vertical, 2)
            //         .position(x: 95, y: 65)
            //     }
            // }
//        )
        .overlay(
            // GIF动画层
            Group {
                if let useGIFAnimation = notificationUserInfo["useGIFAnimation"] as? Bool, useGIFAnimation {
                    GIFAnimationView(gifName: getGIFName(), isPlaying: true)
                        .frame(width: 240, height: 240)
                        .position(x: 165, y: 165)
                        .allowsHitTesting(false) // 防止影响其他UI交互
                } else {
                    Image(PetUtils.getPetSpeakImageName(for: userElement))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 168, height: 168) // 210 * 0.8 = 168
                        .position(x: 155, y: 165) // 往右移动30像素
                        .allowsHitTesting(false) // 防止影响其他UI交互
                }
            }
        )
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
        // 检查是否在Demo模式
        let intimacyGrade: Int
        if DemoManager.shared.isDemo {
            // Demo模式：使用DemoManager的亲密度，但考虑显示限制
            let realGrade = DemoManager.shared.demoProfile.intimacyGrade
            if realGrade >= 3 && !DemoManager.shared.canShowLevel3Gif {
                intimacyGrade = 2 // 如果不能显示3级gif，图标也使用2级
            } else {
                intimacyGrade = realGrade
            }
        } else {
            // 正常模式：使用UserProfileManager的亲密度
            intimacyGrade = profileManager.userProfile.intimacyGrade
        }
        
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
        // 检查是否在Demo模式
        if DemoManager.shared.isDemo {
            // Demo模式：使用DemoManager的亲密度和限制
            let intimacyGrade = DemoManager.shared.demoProfile.intimacyGrade
            
            // 如果亲密度为3级但还不能显示3级gif（grow动画未播放完成），使用2级
            let effectiveGrade: Int
            if intimacyGrade >= 3 && !DemoManager.shared.canShowLevel3Gif {
                effectiveGrade = 2
                print("🎬 通知系统(Demo): 亲密度3级但未允许显示3级gif，使用2级 (intimacyGrade: \(intimacyGrade), canShowLevel3Gif: \(DemoManager.shared.canShowLevel3Gif))")
            } else {
                effectiveGrade = intimacyGrade
                print("🎬 通知系统(Demo): 使用等级 \(effectiveGrade) (intimacyGrade: \(intimacyGrade), canShowLevel3Gif: \(DemoManager.shared.canShowLevel3Gif))")
            }
            
            return PetUtils.getPetGIFName(for: userElement, intimacyGrade: effectiveGrade)
        } else {
            // 正常模式：使用UserProfileManager的亲密度
            let intimacyGrade = profileManager.userProfile.intimacyGrade
            print("🎬 通知系统(正常): 使用等级 \(intimacyGrade)")
            return PetUtils.getPetGIFName(for: userElement, intimacyGrade: intimacyGrade)
        }
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
        print("⚠️ 通知控制器: 使用默认消息，userElement=\(userElement), notificationUserInfo=\(notificationUserInfo)")
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
            let petSpeakImageName = PetUtils.getPetSpeakImageName(for: userElement)
            print("宠物说话图片名称: \(petSpeakImageName)")
            print("宠物图片名称: \(PetUtils.getPetImageName(for: userElement))")
        }
        print("==================")
    }
} 
