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
        switch element {
        case "金":
            return "jinjin_speak"
        case "木":
            return "mumu_speak"
        case "水":
            return "shuishui_speak"
        case "火":
            return "huohuo_speak"
        case "土":
            return "tutu_speak"
        default:
            return "tutu_speak"
        }
    }
    
    // MARK: - 获取元素背景色
    static func getElementBackgroundColor(for element: String) -> Color {
        switch element {
        case "金":
            return Color(hex: "FCFFE4")
        case "木":
            return Color(hex: "C9FFDC")
        case "水":
            return Color(hex: "CCFFEF")
        case "火":
            return Color(hex: "FFF7DD")
        case "土":
            return Color(hex: "FFD3B0")
        default:
            return Color(hex: "FCFFE4")
        }
    }
    
    // MARK: - 获取元素对话框色
    static func getElementDialogColor(for element: String) -> Color {
        switch element {
        case "金":
            return Color(hex: "FFE6AA")
        case "木":
            return Color(hex: "A8E6CF")
        case "水":
            return Color(hex: "A8D8EA")
        case "火":
            return Color(hex: "FFE6AA")
        case "土":
            return Color(hex: "FFB347")
        default:
            return Color(hex: "FFE6AA")
        }
    }
    
    // MARK: - 获取元素文字颜色
    static func getElementTextColor(for element: String) -> Color {
        switch element {
        case "金":
            return Color(hex: "8B4513") // 深棕色
        case "木":
            return Color(hex: "228B22") // 深绿色
        case "水":
            return Color(hex: "4169E1") // 深蓝色
        case "火":
            return Color(hex: "661A00") // 深红棕色
        case "土":
            return Color(hex: "8B4513") // 深棕色
        default:
            return Color(hex: "8B4513")
        }
    }
    
    // MARK: - 获取随机消息
    static func getRandomMessage(for element: String) -> String {
        let messages: [String: [String]] = [
            "金": [
                "今天你的能量很充沛呢！记得多运动哦～",
                "金元素的朋友，保持积极的心态很重要！",
                "你的坚持让我很感动，继续加油！",
                "今天是个好日子，适合做一些重要决定。"
            ],
            "木": [
                "木元素的朋友，记得多接触大自然哦！",
                "你的成长速度让我很惊讶，继续保持！",
                "今天适合学习新知识，加油！",
                "木元素代表生机，你也要充满活力哦～"
            ],
            "水": [
                "水元素的朋友，保持内心的平静很重要。",
                "你的智慧让我很佩服，继续保持！",
                "今天适合冥想和放松，给自己一些时间。",
                "水元素代表智慧，你也要保持冷静思考哦～"
            ],
            "火": [
                "火元素的朋友，你的热情感染了我！",
                "今天你的创造力很强，适合做创意工作。",
                "保持你的热情，但也要注意休息哦～",
                "火元素代表活力，你也要保持激情！"
            ],
            "土": [
                "土元素的朋友，你的稳重让我很安心。",
                "今天适合做一些实际的事情，你很棒！",
                "你的踏实让我很感动，继续保持！",
                "土元素代表稳定，你也要保持这份稳重哦～"
            ]
        ]
        
        let elementMessages = messages[element] ?? messages["土"]!
        return elementMessages.randomElement() ?? "今天也要加油哦！"
    }
    
    // MARK: - 获取元素主题色配置
    static func getElementThemeConfig(for element: String) -> ElementThemeConfig {
        return ElementThemeConfig(
            background: getElementBackgroundColor(for: element),
            dialog: getElementDialogColor(for: element),
            imageName: getPetImageName(for: element)
        )
    }
}

// MARK: - 元素主题配置
struct ElementThemeConfig {
    let background: Color
    let dialog: Color
    let imageName: String
} 