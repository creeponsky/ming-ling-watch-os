import Foundation
import SwiftUI
import UserNotifications

// MARK: - Demo状态枚举
enum DemoState: String, CaseIterable, Codable {
    case inactive = "inactive"                    // 未激活demo
    case birthdaySelection = "birthday_selection" // 生日选择阶段
    case mainPage = "main_page"                   // 主页面阶段  
    case sedentaryTrigger = "sedentary_trigger"   // 久坐触发阶段
    case stepDetection = "step_detection"         // 步数检测阶段
    case intimacyUpgrade = "intimacy_upgrade"     // 亲密度升级阶段
    case voiceInteraction = "voice_interaction"   // 语音交互阶段
    case voiceCompleted = "voice_completed"       // 语音完成阶段
    case completed = "completed"                  // demo完成
}

// MARK: - Demo用户档案模型
struct DemoUserProfile: Codable {
    var birthday: Date?
    var sex: Int = 0 // 0男 1女
    var intimacyLevel: Int = 50 // 直接设置为2级
    var healthStreak: Int = 1
    var lastHealthCheck: Date = Date()
    var stepCount: Int = 0
    var isWoodElement: Bool = true // demo中固定为木属性
    
    var intimacyGrade: Int {
        if intimacyLevel >= 80 {
            return 3 // 亲密
        } else if intimacyLevel >= 50 {
            return 2 // 友好
        } else {
            return 1 // 陌生
        }
    }
    
    mutating func addIntimacy(_ points: Int) {
        intimacyLevel = min(100, intimacyLevel + points)
    }
}

// MARK: - Demo管理器
class DemoManager: ObservableObject {
    static let shared = DemoManager()
    
    @Published var isDemo: Bool = false
    @Published var demoState: DemoState = .inactive
    @Published var demoProfile: DemoUserProfile = DemoUserProfile()
    @Published var showNotificationBar: Bool = false
    @Published var notificationMessage: String = ""
    @Published var stepCountBeforeReminder: Int = 0
    @Published var isRecording: Bool = false
    @Published var hasShownWelcome: Bool = false
    @Published var shouldPlayEvolutionAnimation: Bool = false
    
    private let demoKey = "demoData"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadDemoData()
    }
    
    // MARK: - 开始Demo
    func startDemo() {
        isDemo = true
        demoState = .birthdaySelection
        demoProfile = DemoUserProfile()
        showNotificationBar = false
        hasShownWelcome = false
        saveDemoData()
        print("🎬 Demo开始: 进入生日选择阶段")
    }
    
    // MARK: - 退出Demo
    func exitDemo() {
        isDemo = false
        demoState = .inactive
        demoProfile = DemoUserProfile()
        showNotificationBar = false
        isRecording = false
        hasShownWelcome = false
        clearDemoData()
        print("🎬 Demo结束")
    }
    
    // MARK: - 重置Demo
    func resetDemo() {
        exitDemo()
        startDemo()
    }
    
    // MARK: - 设置生日和性别
    func setBirthday(_ birthday: Date, sex: Int) {
        demoProfile.birthday = birthday
        demoProfile.sex = sex
        demoState = .mainPage
        
        // 先不显示通知栏，等页面切换完成后再显示
        showNotificationBar = false
        notificationMessage = "Hello，我是木木；今天是你坚持健康的1天"
        
        saveDemoData()
        print("🎬 Demo: 设置生日完成，进入主页面")
        
        // 延迟显示欢迎界面，确保页面切换动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.showNotificationBar = true
            }
            print("🎬 Demo: 显示欢迎界面")
        }
    }
    
    // MARK: - 触发久坐检测
    func triggerSedentaryDetection() {
        demoState = .sedentaryTrigger
        stepCountBeforeReminder = demoProfile.stepCount
        saveDemoData()
        print("🎬 Demo: 开始久坐检测")
        
        // 10秒后进入步数检测阶段
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.enterStepDetection()
        }
    }
    
    // MARK: - 进入步数检测
    private func enterStepDetection() {
        demoState = .stepDetection
        showNotificationBar = false // 隐藏欢迎对话框
        saveDemoData()
        print("🎬 Demo: 进入步数检测阶段")
        
        // 发送久坐提醒通知
        sendSedentaryReminder()
        
        // 10秒后自动完成步数目标（模拟用户走路）
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.triggerIntimacyUpgrade()
        }
    }
    
    // MARK: - 触发亲密度升级
    private func triggerIntimacyUpgrade() {
        // 增加步数和亲密度
        demoProfile.stepCount += 20
        demoProfile.addIntimacy(30) // 升级到3级
        
        demoState = .intimacyUpgrade
        shouldPlayEvolutionAnimation = true // 标记需要播放进化动画
        saveDemoData()
        print("🎬 Demo: 触发亲密度升级，亲密度升级到\(demoProfile.intimacyGrade)级")
        
        // 发送完成通知
        sendCompletionNotification()
        
        // 8秒后进入语音交互阶段（给升级动画足够时间：1秒延迟+2秒播放+5秒等待）
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.demoState = .voiceInteraction
            self.saveDemoData()
            print("🎬 Demo: 进入语音交互阶段")
        }
    }
    
    // MARK: - 完成步数目标（保留用于兼容性）
    private func completeStepGoal() {
        // 这个方法现在被 triggerIntimacyUpgrade 替代
        triggerIntimacyUpgrade()
    }
    
    // MARK: - 开始录音
    func startRecording() {
        isRecording = true
        print("🎬 Demo: 开始录音")
        
        // 2秒后停止录音并播放回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopRecording()
        }
    }
    
    // MARK: - 停止录音
    func stopRecording() {
        isRecording = false
        print("🎬 Demo: 停止录音，播放回复")
        
        // 播放模拟回复音频
        playMockResponse()
        
        // 进入语音完成阶段，而不是直接完成demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.demoState = .voiceCompleted
            self.saveDemoData()
            print("🎬 Demo: 进入语音完成阶段")
        }
    }
    
    // MARK: - 发送久坐提醒
    private func sendSedentaryReminder() {
        print("🔔 发送久坐提醒通知 - 元素: 木")
        
        // 使用现有的通知系统发送久坐建议通知
        SystemNotificationManager.shared.sendSuggestionNotification(
            for: "木", // Demo中固定为木属性
            taskType: .sedentary,
            delay: 1
        )
    }
    
    // MARK: - 发送完成通知
    private func sendCompletionNotification() {
        print("🔔 发送完成通知 - 元素: 木")
        
        // 使用现有的通知系统发送久坐完成通知
        SystemNotificationManager.shared.sendCompletionNotification(
            for: "木", // Demo中固定为木属性
            taskType: .sedentary,
            delay: 1
        )
    }
    
    // MARK: - 播放模拟回复
    private func playMockResponse() {
        print("🔊 播放模拟音频回复")
        // 这里应该播放预录的音频文件
        // 为了demo简化，我们只是打印
    }
    
    // MARK: - 保存Demo数据
    func saveDemoData() {
        let demoData = DemoData(
            isDemo: isDemo,
            demoState: demoState,
            demoProfile: demoProfile,
            showNotificationBar: showNotificationBar,
            notificationMessage: notificationMessage,
            stepCountBeforeReminder: stepCountBeforeReminder,
            hasShownWelcome: hasShownWelcome,
            shouldPlayEvolutionAnimation: shouldPlayEvolutionAnimation
        )
        
        if let data = try? JSONEncoder().encode(demoData) {
            userDefaults.set(data, forKey: demoKey)
        }
    }
    
    // MARK: - 加载Demo数据
    private func loadDemoData() {
        if let data = userDefaults.data(forKey: demoKey),
           let demoData = try? JSONDecoder().decode(DemoData.self, from: data) {
            isDemo = demoData.isDemo
            demoState = demoData.demoState
            demoProfile = demoData.demoProfile
            showNotificationBar = demoData.showNotificationBar
            notificationMessage = demoData.notificationMessage
            stepCountBeforeReminder = demoData.stepCountBeforeReminder
            hasShownWelcome = demoData.hasShownWelcome
            shouldPlayEvolutionAnimation = demoData.shouldPlayEvolutionAnimation
            
            print("🎬 Demo数据已加载: 状态=\(demoState.rawValue), hasShownWelcome=\(hasShownWelcome), shouldPlayEvolutionAnimation=\(shouldPlayEvolutionAnimation)")
        }
    }
    
    // MARK: - 清除Demo数据
    private func clearDemoData() {
        userDefaults.removeObject(forKey: demoKey)
    }
}

// MARK: - Demo数据存储模型
private struct DemoData: Codable {
    let isDemo: Bool
    let demoState: DemoState
    let demoProfile: DemoUserProfile
    let showNotificationBar: Bool
    let notificationMessage: String
    let stepCountBeforeReminder: Int
    let hasShownWelcome: Bool
    let shouldPlayEvolutionAnimation: Bool
}

// MARK: - Demo工具扩展
extension DemoManager {
    // 获取demo状态描述
    var stateDescription: String {
        switch demoState {
        case .inactive:
            return "Demo未激活"
        case .birthdaySelection:
            return "生日选择阶段"
        case .mainPage:
            return "主页面阶段"
        case .sedentaryTrigger:
            return "久坐触发阶段"
        case .stepDetection:
            return "步数检测阶段"
        case .intimacyUpgrade:
            return "亲密度升级阶段"
        case .voiceInteraction:
            return "语音交互阶段"
        case .voiceCompleted:
            return "语音完成阶段"
        case .completed:
            return "Demo完成"
        }
    }
    
    // 检查是否可以退出demo
    var canExitDemo: Bool {
        return demoState == .completed || demoState == .voiceInteraction || demoState == .voiceCompleted
    }
}