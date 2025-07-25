import Foundation

// MARK: - 提醒内容管理器
class ReminderContentManager {
    static let shared = ReminderContentManager()
    
    private init() {}
    
    // MARK: - 提醒内容数据
    private let reminderContents: [String: [String: [String: String]]] = [
        "晒太阳": [
            "建议": [
                "金": "阳光正好，出去晒15分钟润肺气。金需要适度日晒。",
                "木": "阳光助木气生发，出去走走舒肝气吧。",
                "水": "太阳能温肾阳，去晒晒背补充阳气～",
                "火": "阳光充足但不烈，适合补充心阳！",
                "土": "晒太阳健脾胃，阳光下土气运化更好。"
            ],
            "检测到晒太阳": [
                "金": "很好，金气在阳光下得到滋润。",
                "木": "阳光让肝气舒展，状态不错。",
                "水": "晒太阳补肾阳，真棒～",
                "火": "心阳充足了！能量满满！",
                "土": "脾土得到阳气，消化会更好。"
            ]
        ],
        "压力大": [
            "建议": [
                "金": "肺气需要调理。金属性压力大时容易呼吸短促。",
                "木": "肝气有点郁结了。木属性要保持心情舒畅。",
                "水": "肾气不足了。水属性最忌讳熬夜伤肾。",
                "火": "心火有点旺。火属性的人要注意清心。",
                "土": "脾胃受压力影响了。土属性重在调理中焦。"
            ],
            "improved": [
                "金": "金气恢复不错。",
                "木": "肝气舒畅多了。",
                "水": "肾气在恢复呢～",
                "火": "心火平稳了！很好！",
                "土": "脾土安定了，不错。"
            ],
            "still_low": [
                "金": "肺气仍需调养，别着急。",
                "木": "慢慢来，肝气需要时间恢复。",
                "水": "肾气恢复需要时间哦～",
                "火": "心火还是有点急，放轻松！",
                "土": "脾胃恢复需要过程，不急。"
            ]
        ],
        "久坐": [
            "建议": [
                "金": "久坐肺气不畅，金需流通。",
                "木": "坐久了筋脉不通，木喜舒展。",
                "水": "久坐伤肾，水需流动～",
                "火": "血脉要不通了！火主循环！",
                "土": "久坐困脾，土气需运化。"
            ],
            "moved": [
                "金": "活动后肺气通畅多了。",
                "木": "筋骨舒展，很好。",
                "水": "动起来了～肾气也活了～",
                "火": "血液循环起来了！棒！",
                "土": "脾胃得到运化，好。"
            ]
        ],
        "运动检测": [
            "post_exercise": [
                "金": "运动后记得调息，金主气。",
                "木": "运动舒肝，记得放松。",
                "水": "运动出汗，该补充水分了～",
                "火": "运动后心率恢复得不错！",
                "土": "运动助脾运化，很好。"
            ]
        ],
        "睡眠监测": [
            "morning": [
                "金": "昨晚睡眠不足，今天注意养肺。",
                "木": "睡眠不足伤肝，今天要平和。",
                "水": "睡眠不足伤肾精，要补充哦～",
                "火": "睡眠影响心神，今天慢一点！",
                "土": "睡眠不足影响脾胃，注意饮食。"
            ],
            "evening": [
                "金": "该准备睡觉了，养肺阴。",
                "木": "早睡养肝血，准备休息吧。",
                "水": "早睡最养肾～该准备了～",
                "火": "让心神安定，准备入睡！",
                "土": "脾胃需要休息，早点睡。"
            ]
        ]
    ]
    
    // MARK: - 获取提醒内容
    func getReminderContent(for reminderType: String, subType: String, element: String) -> String {
        guard let typeContents = reminderContents[reminderType],
              let subTypeContents = typeContents[subType],
              let content = subTypeContents[element] else {
            return getDefaultContent(for: element)
        }
        return content
    }
    
    // MARK: - 获取默认内容
    private func getDefaultContent(for element: String) -> String {
        let defaultContents = [
            "金": "保持健康，注意休息。",
            "木": "保持健康，注意休息。",
            "水": "保持健康，注意休息。",
            "火": "保持健康，注意休息。",
            "土": "保持健康，注意休息。"
        ]
        return defaultContents[element] ?? "保持健康，注意休息。"
    }
    
    // MARK: - 获取所有提醒类型
    func getAllReminderTypes() -> [String] {
        return Array(reminderContents.keys)
    }
    
    // MARK: - 获取提醒的子类型
    func getSubTypes(for reminderType: String) -> [String] {
        guard let typeContents = reminderContents[reminderType] else {
            return []
        }
        return Array(typeContents.keys)
    }
} 