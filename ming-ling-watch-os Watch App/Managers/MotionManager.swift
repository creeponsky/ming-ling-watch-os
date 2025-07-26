//
//  MotionManager.swift
//  test-app Watch App
//
//  Created by CreepOnSky on 2025/7/24.
//

import Foundation
import CoreMotion
import WatchKit

struct Vector3D {
    var x: Double = 0
    var y: Double = 0
    var z: Double = 0
}

struct DeviceMotionData {
    var roll: Double = 0
    var pitch: Double = 0
    var yaw: Double = 0
}

class MotionManager: NSObject, ObservableObject {
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    
    @Published var accelerometerData = Vector3D()
    @Published var gyroscopeData = Vector3D()
    @Published var magnetometerData = Vector3D()
    @Published var deviceMotion = DeviceMotionData()
    @Published var gravity = Vector3D()
    @Published var userAcceleration = Vector3D()
    @Published var rotationRate = Vector3D()
    @Published var magneticField = Vector3D()
    @Published var magneticFieldAccuracy: String = "Unknown"
    
    @Published var barometricPressure: Double = 0
    @Published var temperature: Double = 0
    @Published var humidity: Double = 0
    
    @Published var currentActivity: String = "Unknown"
    @Published var activityConfidence: Int = 0
    @Published var pedometerSteps: Int = 0
    @Published var pedometerDistance: Double = 0
    @Published var pedometerFloorsAscended: Int = 0
    @Published var pedometerFloorsDescended: Int = 0
    @Published var pedometerCadence: Double = 0
    @Published var pedometerAverageActivePace: Double = 0
    
    private var isUpdating = false
    private var stepCountingCallback: ((Int) -> Void)?
    
    override init() {
        super.init()
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.gyroUpdateInterval = 0.1
        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.deviceMotionUpdateInterval = 0.1
    }
    
    // MARK: - 步数监测
    func startStepCounting(callback: @escaping (Int) -> Void) {
        stepCountingCallback = callback
        
        guard CMPedometer.isStepCountingAvailable() else {
            print("❌ [MotionManager] 步数监测不可用")
            return
        }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        print("📱 [MotionManager] 开始步数监测，起始时间: \(startDate)")
        
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            if let error = error {
                print("❌ [MotionManager] 步数监测错误: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("⚠️ [MotionManager] 步数数据为空")
                return
            }
            
            DispatchQueue.main.async {
                let steps = data.numberOfSteps.intValue
                self?.pedometerSteps = steps
                self?.pedometerDistance = data.distance?.doubleValue ?? 0
                self?.pedometerFloorsAscended = data.floorsAscended?.intValue ?? 0
                self?.pedometerFloorsDescended = data.floorsDescended?.intValue ?? 0
                self?.pedometerCadence = data.currentCadence?.doubleValue ?? 0
                self?.pedometerAverageActivePace = data.averageActivePace?.doubleValue ?? 0
                
                print("📱 [MotionManager] 步数更新: \(steps), 距离: \(data.distance?.doubleValue ?? 0)m")
                
                // 调用回调函数
                self?.stepCountingCallback?(steps)
            }
        }
    }
    
    func stopStepCounting() {
        print("📱 [MotionManager] 停止步数监测")
        pedometer.stopUpdates()
        stepCountingCallback = nil
    }
    
    func startUpdates() {
        guard !isUpdating else { return }
        isUpdating = true
        
        startAccelerometerUpdates()
        startGyroscopeUpdates()
        startMagnetometerUpdates()
        startDeviceMotionUpdates()
        startPedometerUpdates()
        startActivityUpdates()
        updateEnvironmentalData()
    }
    
    func stopUpdates() {
        isUpdating = false
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        activityManager.stopActivityUpdates()
    }
    
    private func startAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                self?.accelerometerData.x = data.acceleration.x
                self?.accelerometerData.y = data.acceleration.y
                self?.accelerometerData.z = data.acceleration.z
            }
        }
    }
    
    private func startGyroscopeUpdates() {
        guard motionManager.isGyroAvailable else { return }
        
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                self?.gyroscopeData.x = data.rotationRate.x
                self?.gyroscopeData.y = data.rotationRate.y
                self?.gyroscopeData.z = data.rotationRate.z
            }
        }
    }
    
    private func startMagnetometerUpdates() {
        guard motionManager.isMagnetometerAvailable else { return }
        
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                self?.magnetometerData.x = data.magneticField.x
                self?.magnetometerData.y = data.magneticField.y
                self?.magnetometerData.z = data.magneticField.z
                
                // CMMagneticField没有accuracy属性，使用固定值
                self?.magneticFieldAccuracy = "Medium"
            }
        }
    }
    
    private func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                self?.deviceMotion.roll = data.attitude.roll
                self?.deviceMotion.pitch = data.attitude.pitch
                self?.deviceMotion.yaw = data.attitude.yaw
                
                self?.gravity.x = data.gravity.x
                self?.gravity.y = data.gravity.y
                self?.gravity.z = data.gravity.z
                
                self?.userAcceleration.x = data.userAcceleration.x
                self?.userAcceleration.y = data.userAcceleration.y
                self?.userAcceleration.z = data.userAcceleration.z
                
                self?.rotationRate.x = data.rotationRate.x
                self?.rotationRate.y = data.rotationRate.y
                self?.rotationRate.z = data.rotationRate.z
                
                self?.magneticField.x = data.magneticField.field.x
                self?.magneticField.y = data.magneticField.field.y
                self?.magneticField.z = data.magneticField.field.z
            }
        }
    }
    
    private func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                self?.pedometerSteps = data.numberOfSteps.intValue
                self?.pedometerDistance = data.distance?.doubleValue ?? 0
                self?.pedometerFloorsAscended = data.floorsAscended?.intValue ?? 0
                self?.pedometerFloorsDescended = data.floorsDescended?.intValue ?? 0
                self?.pedometerCadence = data.currentCadence?.doubleValue ?? 0
                self?.pedometerAverageActivePace = data.averageActivePace?.doubleValue ?? 0
            }
        }
    }
    
    private func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity = activity else { return }
            
            DispatchQueue.main.async {
                var activityString = "Unknown"
                
                if activity.walking {
                    activityString = "Walking"
                } else if activity.running {
                    activityString = "Running"
                } else if activity.automotive {
                    activityString = "Automotive"
                } else if activity.cycling {
                    activityString = "Cycling"
                } else if activity.stationary {
                    activityString = "Stationary"
                }
                
                self?.currentActivity = activityString
                self?.activityConfidence = Int(activity.confidence.rawValue * 100)
            }
        }
    }
    
    // 模拟环境数据（实际Apple Watch可能不提供这些数据）
    private func updateEnvironmentalData() {
        // 这些数据在实际Apple Watch上可能不可用
        // 这里只是示例实现
        DispatchQueue.main.async {
            self.barometricPressure = 1013.25 + Double.random(in: -10...10) // 标准大气压 ± 变化
            self.temperature = 20.0 + Double.random(in: -5...5) // 室温 ± 变化
            self.humidity = 50.0 + Double.random(in: -10...10) // 相对湿度 ± 变化
        }
        
        // 定期更新环境数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.updateEnvironmentalData()
        }
    }
} 