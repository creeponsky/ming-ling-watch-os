import Foundation

// MARK: - 健康提醒模型
struct HealthReminder: Codable, Identifiable {
    let id = UUID()
    let type: ReminderType
    let trigger: TriggerCondition
    
    enum ReminderType: String, Codable, CaseIterable {
        case sunExposure = "晒太阳"
        case stress = "压力大"
        case sedentary = "久坐"
        case exercise = "运动检测"
        case sleep = "睡眠监测"
        
        var icon: String {
            switch self {
            case .sunExposure: return "sun.max.fill"
            case .stress: return "brain.head.profile"
            case .sedentary: return "figure.seated.seatbelt"
            case .exercise: return "figure.run"
            case .sleep: return "bed.double.fill"
            }
        }
        
        var color: String {
            switch self {
            case .sunExposure: return "#FF8C00"
            case .stress: return "#9370DB"
            case .sedentary: return "#4169E1"
            case .exercise: return "#32CD32"
            case .sleep: return "#4B0082"
            }
        }
        
        // 转换为TaskType
        var taskType: TaskType {
            switch self {
            case .sunExposure: return .sunExposure
            case .stress: return .stress
            case .sedentary: return .sedentary
            case .exercise: return .exercise
            case .sleep: return .sleep
            }
        }
    }
}

// MARK: - 触发条件
struct TriggerCondition: Codable {
    let conditions: [String]
    let detection: [String]
}

// MARK: - 健康提醒数据
extension HealthReminder {
    static let allReminders: [HealthReminder] = [
        // 晒太阳提醒
        HealthReminder(
            type: .sunExposure,
            trigger: TriggerCondition(
                conditions: [
                    "UV指数2-6（适中）",
                    "时辰：上午9-11点或下午3-5点",
                    "室内超过2小时"
                ],
                detection: [
                    "光线传感器检测到环境光变化",
                    "GPS从室内到室外（建筑物外面）",
                    "UV指数API"
                ]
            )
        ),
        
        // 压力提醒
        HealthReminder(
            type: .stress,
            trigger: TriggerCondition(
                conditions: ["HRV持续低于个人基线20%"],
                detection: ["Apple Watch HRV数据"]
            )
        ),
        
        // 久坐提醒
        HealthReminder(
            type: .sedentary,
            trigger: TriggerCondition(
                conditions: ["1小时内步数<40步"],
                detection: ["Apple Watch活动监测"]
            )
        ),
        
        // 运动检测
        HealthReminder(
            type: .exercise,
            trigger: TriggerCondition(
                conditions: ["心率持续>120超过10分钟"],
                detection: ["Apple Watch心率"]
            )
        ),
        
        // 睡眠监测
        HealthReminder(
            type: .sleep,
            trigger: TriggerCondition(
                conditions: ["早上检测到前晚睡眠<7小时"],
                detection: ["Apple Watch睡眠数据"]
            )
        )
    ]
    
    // 根据五行属性获取建议内容
    func getSuggestionContent(for element: String) -> String? {
        return ReminderContentManager.shared.getSuggestionContent(for: type.taskType, element: element)?.message
    }
    
    // 根据五行属性获取完成内容
    func getCompletionContent(for element: String) -> (message: String, intimacyPoints: Int)? {
        guard let completion = ReminderContentManager.shared.getCompletionContent(for: type.taskType, element: element) else {
            return nil
        }
        return (completion.message, completion.intimacyPoints)
    }
} 