import Foundation

// MARK: - 健康提醒模型
struct HealthReminder: Codable, Identifiable {
    let id = UUID()
    let type: ReminderType
    let trigger: TriggerCondition
    // 移除重复的提醒内容，统一使用 ReminderContentManager
    let followUp: FollowUpReminders?
    
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
    }
}

// MARK: - 触发条件
struct TriggerCondition: Codable {
    let conditions: [String]
    let detection: [String]
}

// MARK: - 后续提醒
struct FollowUpReminders: Codable {
    let improved: [String: String]?
    let stillLow: [String: String]?
    let moved: [String: String]?
    let postExercise: [String: String]?
    let morning: [String: String]?
    let evening: [String: String]?
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
            ),
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: nil,
                postExercise: nil,
                morning: nil,
                evening: nil
            )
        ),
        
        // 压力提醒
        HealthReminder(
            type: .stress,
            trigger: TriggerCondition(
                conditions: ["HRV持续低于个人基线20%"],
                detection: ["Apple Watch HRV数据"]
            ),
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: nil,
                postExercise: nil,
                morning: nil,
                evening: nil
            )
        ),
        
        // 久坐提醒
        HealthReminder(
            type: .sedentary,
            trigger: TriggerCondition(
                conditions: ["1小时内步数<40步"],
                detection: ["Apple Watch活动监测"]
            ),
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: nil,
                postExercise: nil,
                morning: nil,
                evening: nil
            )
        ),
        
        // 运动检测
        HealthReminder(
            type: .exercise,
            trigger: TriggerCondition(
                conditions: ["心率持续>120超过10分钟"],
                detection: ["Apple Watch心率"]
            ),
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: nil,
                postExercise: nil,
                morning: nil,
                evening: nil
            )
        ),
        
        // 睡眠监测
        HealthReminder(
            type: .sleep,
            trigger: TriggerCondition(
                conditions: ["早上检测到前晚睡眠<7小时"],
                detection: ["Apple Watch睡眠数据"]
            ),
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: nil,
                postExercise: nil,
                morning: nil,
                evening: nil
            )
        )
    ]
    
    // 根据五行属性获取提醒内容
    func getReminder(for element: String) -> String {
        return ReminderContentManager.shared.getReminderContent(
            for: type.rawValue,
            subType: "建议",
            element: element
        )
    }
    
    // 获取后续提醒
    func getFollowUp(for element: String, type: FollowUpType) -> String? {
        let subType: String
        switch type {
        case .improved:
            subType = "improved"
        case .stillLow:
            subType = "still_low"
        case .moved:
            subType = "moved"
        case .postExercise:
            subType = "post_exercise"
        case .morning:
            subType = "morning"
        case .evening:
            subType = "evening"
        }
        
        return ReminderContentManager.shared.getReminderContent(
            for: self.type.rawValue,
            subType: subType,
            element: element
        )
    }
}

enum FollowUpType {
    case improved
    case stillLow
    case moved
    case postExercise
    case morning
    case evening
} 