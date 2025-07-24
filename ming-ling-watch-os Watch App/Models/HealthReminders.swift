import Foundation

// MARK: - 健康提醒模型
struct HealthReminder: Codable, Identifiable {
    let id = UUID()
    let type: ReminderType
    let trigger: TriggerCondition
    let reminders: [String: String] // 五行属性 -> 提醒内容
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
            reminders: [
                "金": "阳光正好，出去晒15分钟润肺气。金需要适度日晒。",
                "木": "阳光助木气生发，出去走走舒肝气吧。",
                "水": "太阳能温肾阳，去晒晒背补充阳气～",
                "火": "阳光充足但不烈，适合补充心阳！",
                "土": "晒太阳健脾胃，阳光下土气运化更好。"
            ],
            followUp: FollowUpReminders(
                improved: [
                    "金": "很好，金气在阳光下得到滋润。",
                    "木": "阳光让肝气舒展，状态不错。",
                    "水": "晒太阳补肾阳，真棒～",
                    "火": "心阳充足了！能量满满！",
                    "土": "脾土得到阳气，消化会更好。"
                ],
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
            reminders: [
                "金": "肺气需要调理。金属性压力大时容易呼吸短促。",
                "木": "肝气有点郁结了。木属性要保持心情舒畅。",
                "水": "肾气不足了。水属性最忌讳熬夜伤肾。",
                "火": "心火有点旺。火属性的人要注意清心。",
                "土": "脾胃受压力影响了。土属性重在调理中焦。"
            ],
            followUp: FollowUpReminders(
                improved: [
                    "金": "金气恢复不错。",
                    "木": "肝气舒畅多了。",
                    "水": "肾气在恢复呢～",
                    "火": "心火平稳了！很好！",
                    "土": "脾土安定了，不错。"
                ],
                stillLow: [
                    "金": "肺气仍需调养，别着急。",
                    "木": "慢慢来，肝气需要时间恢复。",
                    "水": "肾气恢复需要时间哦～",
                    "火": "心火还是有点急，放轻松！",
                    "土": "脾胃恢复需要过程，不急。"
                ],
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
            reminders: [
                "金": "久坐肺气不畅，金需流通。",
                "木": "坐久了筋脉不通，木喜舒展。",
                "水": "久坐伤肾，水需流动～",
                "火": "血脉要不通了！火主循环！",
                "土": "久坐困脾，土气需运化。"
            ],
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: [
                    "金": "活动后肺气通畅多了。",
                    "木": "筋骨舒展，很好。",
                    "水": "动起来了～肾气也活了～",
                    "火": "血液循环起来了！棒！",
                    "土": "脾胃得到运化，好。"
                ],
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
            reminders: [
                "金": "运动后记得调息，金主气。",
                "木": "运动舒肝，记得放松。",
                "水": "运动出汗，该补充水分了～",
                "火": "运动后心率恢复得不错！",
                "土": "运动助脾运化，很好。"
            ],
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: nil,
                postExercise: [
                    "金": "运动后记得调息，金主气。",
                    "木": "运动舒肝，记得放松。",
                    "水": "运动出汗，该补充水分了～",
                    "火": "运动后心率恢复得不错！",
                    "土": "运动助脾运化，很好。"
                ],
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
            reminders: [
                "金": "昨晚睡眠不足，今天注意养肺。",
                "木": "睡眠不足伤肝，今天要平和。",
                "水": "睡眠不足伤肾精，要补充哦～",
                "火": "睡眠影响心神，今天慢一点！",
                "土": "睡眠不足影响脾胃，注意饮食。"
            ],
            followUp: FollowUpReminders(
                improved: nil,
                stillLow: nil,
                moved: nil,
                postExercise: nil,
                morning: [
                    "金": "昨晚睡眠不足，今天注意养肺。",
                    "木": "睡眠不足伤肝，今天要平和。",
                    "水": "睡眠不足伤肾精，要补充哦～",
                    "火": "睡眠影响心神，今天慢一点！",
                    "土": "睡眠不足影响脾胃，注意饮食。"
                ],
                evening: [
                    "金": "该准备睡觉了，养肺阴。",
                    "木": "早睡养肝血，准备休息吧。",
                    "水": "早睡最养肾～该准备了～",
                    "火": "让心神安定，准备入睡！",
                    "土": "脾胃需要休息，早点睡。"
                ]
            )
        )
    ]
    
    // 根据五行属性获取提醒内容
    func getReminder(for element: String) -> String {
        return reminders[element] ?? "保持健康，注意休息。"
    }
    
    // 获取后续提醒
    func getFollowUp(for element: String, type: FollowUpType) -> String? {
        switch type {
        case .improved:
            return followUp?.improved?[element]
        case .stillLow:
            return followUp?.stillLow?[element]
        case .moved:
            return followUp?.moved?[element]
        case .postExercise:
            return followUp?.postExercise?[element]
        case .morning:
            return followUp?.morning?[element]
        case .evening:
            return followUp?.evening?[element]
        }
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