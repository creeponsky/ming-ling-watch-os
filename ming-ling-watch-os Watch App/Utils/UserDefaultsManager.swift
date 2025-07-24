import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - 五行元素相关
    func saveSelectedElement(_ element: String) {
        defaults.set(element, forKey: "selectedElement")
    }
    
    func getSelectedElement() -> String {
        return defaults.string(forKey: "selectedElement") ?? "金"
    }
    
    // MARK: - 健康数据缓存
    func saveHealthData(_ data: [String: Any], forKey key: String) {
        defaults.set(data, forKey: key)
    }
    
    func getHealthData(forKey key: String) -> [String: Any]? {
        return defaults.dictionary(forKey: key)
    }
    
    // MARK: - 用户设置
    func saveUserSettings(_ settings: [String: Any]) {
        defaults.set(settings, forKey: "userSettings")
    }
    
    func getUserSettings() -> [String: Any] {
        return defaults.dictionary(forKey: "userSettings") ?? [:]
    }
    
    // MARK: - 清除缓存
    func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }
    
    func clearHealthData() {
        let healthKeys = ["heartRate", "steps", "sleepData", "stressData"]
        for key in healthKeys {
            defaults.removeObject(forKey: key)
        }
    }
} 