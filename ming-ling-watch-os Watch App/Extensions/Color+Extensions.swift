import SwiftUI

extension Color {
    // 五行元素颜色
    static let elementGold = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let elementWood = Color(red: 0.2, green: 0.8, blue: 0.2)
    static let elementWater = Color(red: 0.0, green: 0.6, blue: 1.0)
    static let elementFire = Color(red: 1.0, green: 0.3, blue: 0.0)
    static let elementEarth = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    // 健康状态颜色
    static let healthGood = Color.green
    static let healthWarning = Color.orange
    static let healthDanger = Color.red
    static let healthNeutral = Color.gray
    
    // 自定义颜色初始化
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 