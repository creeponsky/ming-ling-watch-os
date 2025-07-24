import Foundation
import HealthKit

// MARK: - 健康数据模型
struct HealthData {
    var heartRate: Double = 0
    var steps: Int = 0
    var heartRateVariability: Double = 0
    var sleepAnalysis: String = "未获取"
    var sunExposure: Double = 0
    var stressLevel: Double = 0
}

// MARK: - 五行元素模型
struct ElementData {
    let name: String
    let color: String
    let description: String
    let healthTips: [String]
}

// MARK: - 卡片数据模型
struct HealthCardData {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let color: String
    let destination: String
}

// MARK: - 用户设置模型
struct UserSettings {
    var selectedElement: String = "金"
    var notificationsEnabled: Bool = true
    var autoSyncEnabled: Bool = true
    var theme: String = "default"
} 