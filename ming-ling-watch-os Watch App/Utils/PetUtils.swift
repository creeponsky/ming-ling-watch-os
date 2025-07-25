import SwiftUI

// MARK: - 宠物工具类
class PetUtils {
    
    // MARK: - 获取宠物图片名称
    static func getPetImageName(for element: String) -> String {
        switch element {
        case "金":
            return "jinjin"
        case "木":
            return "mumu"
        case "水":
            return "shuishui"
        case "火":
            return "huohuo"
        case "土":
            return "tutu"
        default:
            return "tutu"
        }
    }
    
    // MARK: - 获取宠物说话图片名称
    static func getPetSpeakImageName(for element: String) -> String {
        return "\(getPetImageName(for: element))_speak"
    }
    
    // MARK: - 获取GIF动画名称
    static func getGIFName(for element: String, intimacyGrade: Int, emotion: String) -> String {
        // 暂时所有五行都使用mumu
        let petName = "mumu"
        return "\(petName)/gif/\(emotion)/\(intimacyGrade)"
    }
    
    // MARK: - 获取宠物GIF动画名称（简化版本）
    static func getPetGIFName(for element: String) -> String {
        // 暂时所有五行都使用mumu的happy动画
        return "GIFs/mumu/happy/1"
    }
    
    // MARK: - 获取宠物GIF动画名称（根据亲密度等级）
    static func getPetGIFName(for element: String, intimacyGrade: Int) -> String {
        // 根据亲密度等级选择GIF文件
        let gifNumber: Int
        switch intimacyGrade {
        case 1:
            gifNumber = 1
        case 2:
            gifNumber = 2
        case 3:
            gifNumber = 3
        default:
            gifNumber = 1
        }
        
        // 暂时所有五行都使用mumu
        return "GIFs/mumu/happy/\(gifNumber)"
    }
    
    // MARK: - 获取宠物图片名称（根据亲密度）
    static func getPetImageName(for element: String, intimacyGrade: Int) -> String {
        // 暂时所有五行都使用mumu
        let petName = "mumu"
        return "\(petName)/image/\(intimacyGrade)"
    }
    
    // MARK: - 获取元素主题配置
    static func getElementThemeConfig(for element: String) -> ElementThemeConfig {
        switch element {
        case "金":
            return ElementThemeConfig(
                primaryColor: Color(hex: "FFD700"),
                secondaryColor: Color(hex: "FFF8DC"),
                textColor: Color(hex: "8B4513"),
                backgroundColor: Color(hex: "FFFACD")
            )
        case "木":
            return ElementThemeConfig(
                primaryColor: Color(hex: "228B22"),
                secondaryColor: Color(hex: "F0FFF0"),
                textColor: Color(hex: "006400"),
                backgroundColor: Color(hex: "E0F7E0")
            )
        case "水":
            return ElementThemeConfig(
                primaryColor: Color(hex: "4169E1"),
                secondaryColor: Color(hex: "F0F8FF"),
                textColor: Color(hex: "000080"),
                backgroundColor: Color(hex: "E6F3FF")
            )
        case "火":
            return ElementThemeConfig(
                primaryColor: Color(hex: "DC143C"),
                secondaryColor: Color(hex: "FFF5EE"),
                textColor: Color(hex: "8B0000"),
                backgroundColor: Color(hex: "FFE6E6")
            )
        case "土":
            return ElementThemeConfig(
                primaryColor: Color(hex: "8B4513"),
                secondaryColor: Color(hex: "F5F5DC"),
                textColor: Color(hex: "654321"),
                backgroundColor: Color(hex: "F0E6D2")
            )
        default:
            return ElementThemeConfig(
                primaryColor: Color(hex: "8B4513"),
                secondaryColor: Color(hex: "F5F5DC"),
                textColor: Color(hex: "654321"),
                backgroundColor: Color(hex: "F0E6D2")
            )
        }
    }
    
    // MARK: - 获取元素背景颜色
    static func getElementBackgroundColor(for element: String) -> Color {
        return getElementThemeConfig(for: element).backgroundColor
    }
    
    // MARK: - 获取元素对话框颜色
    static func getElementDialogColor(for element: String) -> Color {
        return getElementThemeConfig(for: element).primaryColor
    }
    
    // MARK: - 获取元素文本颜色
    static func getElementTextColor(for element: String) -> Color {
        return getElementThemeConfig(for: element).textColor
    }
}

// MARK: - 元素主题配置
struct ElementThemeConfig {
    let primaryColor: Color
    let secondaryColor: Color
    let textColor: Color
    let backgroundColor: Color
} 