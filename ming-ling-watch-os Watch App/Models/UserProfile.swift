import Foundation

// MARK: - 用户档案模型
struct UserProfile: Codable {
    var birthday: Date?
    var sex: Int = 0 // 0男 1女
    var fiveElements: FiveElements?
    var baziData: BaziData?
    var petRecommendation: String?
    var healthStreak: Int = 0
    var lastHealthCheck: Date?
    
    // 亲密值系统
    var intimacyLevel: Int = 0 // 0-100
    var intimacyPoints: Int = 0 // 累计积分
    
    // 亲密值等级
    var intimacyGrade: Int {
        if intimacyLevel >= 80 {
            return 3 // 亲密
        } else if intimacyLevel >= 50 {
            return 2 // 友好
        } else {
            return 1 // 陌生
        }
    }
    
    // 亲密值等级名称
    var intimacyGradeName: String {
        switch intimacyGrade {
        case 3:
            return "亲密"
        case 2:
            return "友好"
        case 1:
            return "陌生"
        default:
            return "陌生"
        }
    }
    
    // 亲密值等级图标
    var intimacyGradeIcon: String {
        switch intimacyGrade {
        case 3:
            return "heart.fill"
        case 2:
            return "heart"
        case 1:
            return "heart.slash"
        default:
            return "heart.slash"
        }
    }
    
    // 亲密值等级颜色
    var intimacyGradeColor: String {
        switch intimacyGrade {
        case 3:
            return "#FF6B6B" // 红色
        case 2:
            return "#FFB347" // 橙色
        case 1:
            return "#87CEEB" // 蓝色
        default:
            return "#87CEEB"
        }
    }
    
    // 增加亲密值
    mutating func addIntimacy(_ points: Int) {
        intimacyPoints += points
        intimacyLevel = min(100, intimacyLevel + points)
    }
    
    // 减少亲密值
    mutating func reduceIntimacy(_ points: Int) {
        intimacyLevel = max(0, intimacyLevel - points)
    }
    
    // 获取亲密值进度百分比
    var intimacyProgress: Double {
        return Double(intimacyLevel) / 100.0
    }
    
    // 获取下一等级所需积分
    var pointsToNextGrade: Int {
        switch intimacyGrade {
        case 1:
            return max(0, 50 - intimacyLevel)
        case 2:
            return max(0, 80 - intimacyLevel)
        case 3:
            return 0 // 已经是最高等级
        default:
            return 0
        }
    }
    
    // 更新健康天数
    mutating func updateHealthStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        if let lastCheck = lastHealthCheck {
            let daysSinceLastCheck = calendar.dateComponents([.day], from: lastCheck, to: today).day ?? 0
            
            if daysSinceLastCheck == 1 {
                // 连续天数
                healthStreak += 1
            } else if daysSinceLastCheck > 1 {
                // 中断了，重置为1
                healthStreak = 1
            }
        } else {
            // 第一次检查
            healthStreak = 1
        }
        
        lastHealthCheck = today
    }
}

// MARK: - 五行属性模型
struct FiveElements: Codable {
    let primary: String
    let secondary: String
    let tertiary: String
    let description: String
    
    init(primary: String, secondary: String, tertiary: String, description: String) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
        self.description = description
    }
} 