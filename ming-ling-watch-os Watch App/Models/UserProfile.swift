import Foundation

// MARK: - 用户档案模型
struct UserProfile: Codable {
    var birthday: Date?
    var sex: Int = 0 // 0男 1女
    var fiveElements: FiveElements?
    var petRecommendation: String?
    var healthStreak: Int = 0
    var lastActiveDate: Date?
    var baziData: BaziData?
    
    // 计算连续健康天数
    mutating func updateHealthStreak() {
        let today = Date()
        let calendar = Calendar.current
        
        if let lastActive = lastActiveDate {
            let daysDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastActive), to: calendar.startOfDay(for: today)).day ?? 0
            
            if daysDifference == 1 {
                // 连续天数
                healthStreak += 1
            } else if daysDifference > 1 {
                // 中断了，重置
                healthStreak = 1
            }
        } else {
            // 第一次使用
            healthStreak = 1
        }
        
        lastActiveDate = today
    }
}

// MARK: - 五行属性模型
struct FiveElements: Codable {
    let primary: String // 主属性：金、木、水、火、土
    let secondary: String? // 次属性
    let description: String
    let color: String
    let healthTips: [String]
    
    static let elements: [String: FiveElements] = [
        "金": FiveElements(
            primary: "金",
            secondary: nil,
            description: "金主肺气，喜清润",
            color: "#FFD700",
            healthTips: ["注意呼吸调理", "保持心情舒畅", "适度运动"]
        ),
        "木": FiveElements(
            primary: "木",
            secondary: nil,
            description: "木主肝气，喜舒展",
            color: "#228B22",
            healthTips: ["保持心情舒畅", "适度运动", "注意休息"]
        ),
        "水": FiveElements(
            primary: "水",
            secondary: nil,
            description: "水主肾气，喜温润",
            color: "#4169E1",
            healthTips: ["注意保暖", "充足睡眠", "适度饮水"]
        ),
        "火": FiveElements(
            primary: "火",
            secondary: nil,
            description: "火主心气，喜清凉",
            color: "#DC143C",
            healthTips: ["保持心情平静", "适度运动", "注意饮食"]
        ),
        "土": FiveElements(
            primary: "土",
            secondary: nil,
            description: "土主脾气，喜温和",
            color: "#8B4513",
            healthTips: ["注意饮食调理", "适度运动", "保持规律作息"]
        )
    ]
}

// MARK: - 宠物推荐模型
struct PetRecommendation: Codable {
    let element: String
    let pets: [String]
    let description: String
}

extension PetRecommendation {
    static let recommendations: [String: PetRecommendation] = [
        "金": PetRecommendation(
            element: "金",
            pets: ["金鱼", "白猫", "白兔"],
            description: "金属性宠物，有助于调理肺气"
        ),
        "木": PetRecommendation(
            element: "木",
            pets: ["绿鹦鹉", "绿蜥蜴", "绿龟"],
            description: "木属性宠物，有助于舒展肝气"
        ),
        "水": PetRecommendation(
            element: "水",
            pets: ["蓝鱼", "蓝鸟", "海龟"],
            description: "水属性宠物，有助于温润肾气"
        ),
        "火": PetRecommendation(
            element: "火",
            pets: ["红鸟", "红鱼", "红兔"],
            description: "火属性宠物，有助于清凉心气"
        ),
        "土": PetRecommendation(
            element: "土",
            pets: ["黄狗", "黄猫", "仓鼠"],
            description: "土属性宠物，有助于温和脾气"
        )
    ]
} 