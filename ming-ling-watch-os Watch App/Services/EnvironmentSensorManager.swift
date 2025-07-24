import Foundation
import CoreLocation
import WatchKit

// MARK: - 环境传感器管理器
class EnvironmentSensorManager: NSObject, ObservableObject {
    static let shared = EnvironmentSensorManager()
    
    @Published var isIndoor = true
    @Published var ambientLightLevel: Double = 0
    @Published var uvIndex: Double = 0
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private let device = WKInterfaceDevice.current()
    
    private override init() {
        super.init()
        setupLocationManager()
        startAmbientLightMonitoring()
    }
    
    // MARK: - 设置位置管理器
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10米更新一次
    }
    
    // MARK: - 请求位置权限
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - 开始位置监测
    func startLocationMonitoring() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - 停止位置监测
    func stopLocationMonitoring() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - 开始环境光监测
    private func startAmbientLightMonitoring() {
        // 在watchOS中，我们可以通过系统API获取环境光信息
        // 这里使用定时器模拟环境光变化
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateAmbientLightLevel()
        }
    }
    
    // MARK: - 更新环境光水平
    private func updateAmbientLightLevel() {
        // 模拟环境光传感器数据
        // 在实际应用中，这里应该从系统API获取真实数据
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<9:
            // 早晨，光线逐渐增强
            ambientLightLevel = Double.random(in: 0.3...0.7)
        case 9..<17:
            // 白天，光线充足
            ambientLightLevel = Double.random(in: 0.7...1.0)
        case 17..<20:
            // 傍晚，光线逐渐减弱
            ambientLightLevel = Double.random(in: 0.4...0.8)
        default:
            // 夜晚，光线很弱
            ambientLightLevel = Double.random(in: 0.0...0.3)
        }
        
        // 更新UV指数
        updateUVIndex()
    }
    
    // MARK: - 更新UV指数
    private func updateUVIndex() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // 根据时间和环境光估算UV指数
        if hour >= 10 && hour <= 16 && ambientLightLevel > 0.6 {
            // 白天且光线充足时，UV指数较高
            uvIndex = Double.random(in: 3...8)
        } else if hour >= 9 && hour <= 17 && ambientLightLevel > 0.4 {
            // 适合晒太阳的时间段
            uvIndex = Double.random(in: 2...6)
        } else {
            // 其他时间UV指数较低
            uvIndex = Double.random(in: 0...2)
        }
    }
    
    // MARK: - 检查是否适合晒太阳
    func isGoodTimeForSunExposure() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let isGoodTime = (hour >= 9 && hour <= 11) || (hour >= 15 && hour <= 17)
        let isGoodUV = uvIndex >= 2 && uvIndex <= 6
        let isGoodLight = ambientLightLevel > 0.5
        
        return isGoodTime && isGoodUV && isGoodLight
    }
    
    // MARK: - 检查是否从室内到室外
    func checkIndoorToOutdoorTransition() -> Bool {
        // 这里应该基于位置变化和环境光变化来判断
        // 简化实现：基于环境光变化
        let lightThreshold: Double = 0.6
        return ambientLightLevel > lightThreshold && isIndoor
    }
    
    // MARK: - 获取环境状态描述
    func getEnvironmentStatus() -> String {
        if isGoodTimeForSunExposure() {
            return "适合晒太阳"
        } else if ambientLightLevel > 0.7 {
            return "环境明亮"
        } else if ambientLightLevel > 0.4 {
            return "光线适中"
        } else {
            return "光线较暗"
        }
    }
    
    // MARK: - 获取UV状态描述
    func getUVStatus() -> String {
        switch uvIndex {
        case 0..<2:
            return "低"
        case 2..<6:
            return "适中"
        case 6..<8:
            return "高"
        default:
            return "很高"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension EnvironmentSensorManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = location
            self.updateIndoorOutdoorStatus(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startLocationMonitoring()
            }
        }
    }
    
    // MARK: - 更新室内外状态
    private func updateIndoorOutdoorStatus(location: CLLocation) {
        // 这里应该基于位置信息和环境光来判断室内外状态
        // 简化实现：基于环境光水平
        let wasIndoor = isIndoor
        isIndoor = ambientLightLevel < 0.5
        
        // 如果从室内到室外，触发晒太阳提醒
        if wasIndoor && !isIndoor && isGoodTimeForSunExposure() {
            NotificationCenter.default.post(
                name: .sunExposureOpportunity,
                object: nil,
                userInfo: ["location": location]
            )
        }
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let sunExposureOpportunity = Notification.Name("sunExposureOpportunity")
} 