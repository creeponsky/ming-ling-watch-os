import Foundation

// MARK: - 任务类型枚举
enum TaskType: String, CaseIterable {
    case sunExposure = "晒太阳"
    case stress = "压力大"
    case sedentary = "久坐"
    case exercise = "运动检测"
    case sleep = "睡眠监测"
    
    var title: String {
        return self.rawValue
    }
}

// MARK: - 通知类型枚举
enum NotificationType: String, CaseIterable {
    case suggestion = "建议"
    case completion = "完成"
    
    var title: String {
        return self.rawValue
    }
}

// MARK: - 元素类型
typealias ElementType = String

// MARK: - 建议内容结构
struct SuggestionContent {
    let message: String
}

// MARK: - 完成内容结构
struct CompletionContent {
    let message: String
    let intimacyPoints: Int
}

// MARK: - 任务内容结构
struct TaskContent {
    let suggestions: [ElementType: SuggestionContent]
    let completions: [ElementType: CompletionContent]
}

// MARK: - 提醒内容管理器
class ReminderContentManager {
    static let shared = ReminderContentManager()
    
    private init() {}
    
    // MARK: - 提醒内容数据
    private let reminderContents: [TaskType: TaskContent] = [
        .sunExposure: TaskContent(
            suggestions: [
                "金": SuggestionContent(message: "阳光正好，出去晒15分钟润肺气。金需要适度日晒。"),
                "木": SuggestionContent(message: "阳光助木气生发，出去走走舒肝气吧。"),
                "水": SuggestionContent(message: "太阳能温肾阳，去晒晒背补充阳气～"),
                "火": SuggestionContent(message: "阳光充足但不烈，适合补充心阳！"),
                "土": SuggestionContent(message: "晒太阳健脾胃，阳光下土气运化更好。")
            ],
            completions: [
                "金": CompletionContent(message: "很好，金气在阳光下得到滋润。", intimacyPoints: 20),
                "木": CompletionContent(message: "阳光让肝气舒展，状态不错。", intimacyPoints: 20),
                "水": CompletionContent(message: "晒太阳补肾阳，真棒～", intimacyPoints: 20),
                "火": CompletionContent(message: "心阳充足了！能量满满！", intimacyPoints: 20),
                "土": CompletionContent(message: "脾土得到阳气，消化会更好。", intimacyPoints: 20)
            ]
        ),
        .stress: TaskContent(
            suggestions: [
                "金": SuggestionContent(message: "肺气需要调理。金属性压力大时容易呼吸短促。"),
                "木": SuggestionContent(message: "肝气有点郁结了。木属性要保持心情舒畅。"),
                "水": SuggestionContent(message: "肾气不足了。水属性最忌讳熬夜伤肾。"),
                "火": SuggestionContent(message: "心火有点旺。火属性的人要注意清心。"),
                "土": SuggestionContent(message: "脾胃受压力影响了。土属性重在调理中焦。")
            ],
            completions: [
                "金": CompletionContent(message: "金气恢复不错。", intimacyPoints: 20),
                "木": CompletionContent(message: "肝气舒畅多了。", intimacyPoints: 20),
                "水": CompletionContent(message: "肾气在恢复呢～", intimacyPoints: 20),
                "火": CompletionContent(message: "心火平稳了！很好！", intimacyPoints: 20),
                "土": CompletionContent(message: "脾土安定了，不错。", intimacyPoints: 20)
            ]
        ),
        .sedentary: TaskContent(
            suggestions: [
                "金": SuggestionContent(message: "久坐肺气不畅，金需流通。"),
                "木": SuggestionContent(message: "坐久了筋脉不通，木喜舒展。"),
                "水": SuggestionContent(message: "久坐伤肾，水需流动～"),
                "火": SuggestionContent(message: "血脉要不通了！火主循环！"),
                "土": SuggestionContent(message: "久坐困脾，土气需运化。")
            ],
            completions: [
                "金": CompletionContent(message: "活动后肺气通畅多了。", intimacyPoints: 20),
                "木": CompletionContent(message: "筋骨舒展，很好。", intimacyPoints: 20),
                "水": CompletionContent(message: "动起来了～肾气也活了～", intimacyPoints: 20),
                "火": CompletionContent(message: "血液循环起来了！棒！", intimacyPoints: 20),
                "土": CompletionContent(message: "脾胃得到运化，好。", intimacyPoints: 20)
            ]
        ),
        .exercise: TaskContent(
            suggestions: [
                "金": SuggestionContent(message: "该运动了，金主气，需要流通。"),
                "木": SuggestionContent(message: "运动舒肝，让筋骨舒展。"),
                "水": SuggestionContent(message: "运动补肾，让水气流动～"),
                "火": SuggestionContent(message: "运动助心火，让血脉通畅！"),
                "土": SuggestionContent(message: "运动健脾胃，让土气运化。")
            ],
            completions: [
                "金": CompletionContent(message: "运动后记得调息，金主气。", intimacyPoints: 20),
                "木": CompletionContent(message: "运动舒肝，记得放松。", intimacyPoints: 20),
                "水": CompletionContent(message: "运动出汗，该补充水分了～", intimacyPoints: 20),
                "火": CompletionContent(message: "运动后心率恢复得不错！", intimacyPoints: 20),
                "土": CompletionContent(message: "运动助脾运化，很好。", intimacyPoints: 20)
            ]
        ),
        .sleep: TaskContent(
            suggestions: [
                "金": SuggestionContent(message: "该准备睡觉了，养肺阴。"),
                "木": SuggestionContent(message: "早睡养肝血，准备休息吧。"),
                "水": SuggestionContent(message: "早睡最养肾～该准备了～"),
                "火": SuggestionContent(message: "让心神安定，准备入睡！"),
                "土": SuggestionContent(message: "脾胃需要休息，早点睡。")
            ],
            completions: [
                "金": CompletionContent(message: "昨晚睡眠不足，今天注意养肺。", intimacyPoints: 20),
                "木": CompletionContent(message: "睡眠不足伤肝，今天要平和。", intimacyPoints: 20),
                "水": CompletionContent(message: "睡眠不足伤肾精，要补充哦～", intimacyPoints: 20),
                "火": CompletionContent(message: "睡眠影响心神，今天慢一点！", intimacyPoints: 20),
                "土": CompletionContent(message: "睡眠不足影响脾胃，注意饮食。", intimacyPoints: 20)
            ]
        )
    ]
    
    // MARK: - 获取建议内容
    func getSuggestionContent(for taskType: TaskType, element: ElementType) -> SuggestionContent? {
        guard let taskContent = reminderContents[taskType],
              let suggestion = taskContent.suggestions[element] else {
            return nil
        }
        return suggestion
    }
    
    // MARK: - 获取完成内容
    func getCompletionContent(for taskType: TaskType, element: ElementType) -> CompletionContent? {
        guard let taskContent = reminderContents[taskType],
              let completion = taskContent.completions[element] else {
            return nil
        }
        return completion
    }
    
    // MARK: - 随机获取建议内容
    func getRandomSuggestionContent(for element: ElementType) -> (TaskType, SuggestionContent)? {
        let availableTasks = TaskType.allCases.filter { taskType in
            getSuggestionContent(for: taskType, element: element) != nil
        }
        
        guard let randomTask = availableTasks.randomElement(),
              let suggestion = getSuggestionContent(for: randomTask, element: element) else {
            return nil
        }
        
        return (randomTask, suggestion)
    }
    
    // MARK: - 随机获取完成内容
    func getRandomCompletionContent(for element: ElementType) -> (TaskType, CompletionContent)? {
        let availableTasks = TaskType.allCases.filter { taskType in
            getCompletionContent(for: taskType, element: element) != nil
        }
        
        guard let randomTask = availableTasks.randomElement(),
              let completion = getCompletionContent(for: randomTask, element: element) else {
            return nil
        }
        
        return (randomTask, completion)
    }
    
    // MARK: - 获取所有任务类型
    func getAllTaskTypes() -> [TaskType] {
        return Array(reminderContents.keys)
    }
    
    // MARK: - 检查任务类型是否支持指定元素
    func isTaskSupported(for taskType: TaskType, element: ElementType) -> Bool {
        return getSuggestionContent(for: taskType, element: element) != nil
    }
} 