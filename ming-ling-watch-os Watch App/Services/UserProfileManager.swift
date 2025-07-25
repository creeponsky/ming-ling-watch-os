import Foundation
import SwiftUI

// MARK: - 用户档案管理器
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var userProfile: UserProfile = UserProfile()
    @Published var isProfileComplete: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "userProfile"
    private let intimacyChangeManager = IntimacyChangeManager.shared
    
    private init() {
        loadProfile()
    }
    
    // MARK: - 加载用户档案
    private func loadProfile() {
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
            isProfileComplete = profile.birthday != nil && profile.fiveElements != nil
        }
    }
    
    // MARK: - 保存用户档案
    private func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }
    
    // MARK: - 设置生日和五行属性
    func setProfile(birthday: Date, sex: Int, fiveElements: FiveElements, baziData: BaziData) {
        userProfile.birthday = birthday
        userProfile.sex = sex
        userProfile.fiveElements = fiveElements
        userProfile.baziData = baziData
        userProfile.petRecommendation = getPetName(for: fiveElements.primary)
        userProfile.updateHealthStreak()
        
        isProfileComplete = true
        saveProfile()
    }
    
    // MARK: - 更新健康天数
    func updateHealthStreak() {
        userProfile.updateHealthStreak()
        saveProfile()
    }
    
    // MARK: - 重置档案
    func resetProfile() {
        userProfile = UserProfile()
        isProfileComplete = false
        userDefaults.removeObject(forKey: profileKey)
    }
    
    // MARK: - 亲密值管理
    func addIntimacy(_ points: Int) {
        userProfile.addIntimacy(points)
        saveProfile()
        
        // 显示亲密值增加通知
        intimacyChangeManager.showChange(points: points, isPositive: true)
    }
    
    func reduceIntimacy(_ points: Int) {
        userProfile.reduceIntimacy(points)
        saveProfile()
        
        // 显示亲密值减少通知
        intimacyChangeManager.showChange(points: points, isPositive: false)
    }
    
    // MARK: - 获取主题颜色
    func getThemeColor() -> Color {
        guard let element = userProfile.fiveElements?.primary else {
            return Color.blue
        }
        
        switch element {
        case "金":
            return Color(hex: "FFD700")
        case "木":
            return Color(hex: "228B22")
        case "水":
            return Color(hex: "4169E1")
        case "火":
            return Color(hex: "DC143C")
        case "土":
            return Color(hex: "8B4513")
        default:
            return Color.blue
        }
    }
    
    // MARK: - 获取宠物名称
    private func getPetName(for element: String) -> String {
        switch element {
        case "金":
            return "金金"
        case "木":
            return "木木"
        case "水":
            return "水水"
        case "火":
            return "火火"
        case "土":
            return "土土"
        default:
            return "土土"
        }
    }
    
    // MARK: - 获取问候语
    func getGreeting() -> String {
        guard let petName = userProfile.petRecommendation else {
            return "你好，我是您的健康助手！"
        }
        
        let streak = userProfile.healthStreak
        return "你好，我是\(petName)！今天是您坚持健康的第\(streak)天。"
    }
    
    // MARK: - 获取压力状态描述
    func getStressStatusDescription() -> String {
        guard let element = userProfile.fiveElements?.primary else {
            return "您目前的压力状态："
        }
        
        switch element {
        case "金":
            return "您的肺气状态："
        case "木":
            return "您的肝气状态："
        case "水":
            return "您的肾气状态："
        case "火":
            return "您的心气状态："
        case "土":
            return "您的脾气状态："
        default:
            return "您目前的压力状态："
        }
    }
}

 
 