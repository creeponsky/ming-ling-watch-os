//
//  DeviceManager.swift
//  test-app Watch App
//
//  Created by CreepOnSky on 2025/7/24.
//

import Foundation
import WatchKit
import UIKit

class DeviceManager: NSObject, ObservableObject {
    private let device = WKInterfaceDevice.current()
    private var updateTimer: Timer?
    
    @Published var deviceName: String = ""
    @Published var systemName: String = ""
    @Published var systemVersion: String = ""
    @Published var model: String = ""
    @Published var batteryLevel: Double = 0
    @Published var batteryState: String = "Unknown"
    @Published var screenBrightness: Double = 0
    @Published var crownOrientation: String = "Unknown"
    @Published var digitalCrownStatus: String = "Unknown"
    @Published var waterLockStatus: String = "Unknown"
    @Published var complicationFamily: String = "Unknown"
    @Published var wristLocation: String = "Unknown"
    @Published var crownDirection: String = "Unknown"
    @Published var timeZone: String = ""
    @Published var locale: String = ""
    @Published var availableStorage: Double = 0
    @Published var totalStorage: Double = 0
    @Published var memoryUsage: Double = 0
    @Published var cpuUsage: Double = 0
    
    override init() {
        super.init()
        updateDeviceInfo()
    }
    
    func startUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDeviceInfo()
        }
    }
    
    func stopUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateDeviceInfo() {
        // 设备基本信息
        deviceName = device.name
        systemName = device.systemName
        systemVersion = device.systemVersion
        model = device.model
        
        // 电池信息
        batteryLevel = Double(device.batteryLevel)
        switch device.batteryState {
        case .charging:
            batteryState = "Charging"
        case .full:
            batteryState = "Full"
        case .unplugged:
            batteryState = "Unplugged"
        case .unknown:
            batteryState = "Unknown"
        @unknown default:
            batteryState = "Unknown"
        }
        
        // 屏幕亮度
        screenBrightness = 0.5 // WKInterfaceDevice没有screenBrightness属性，使用默认值
        
        // 表冠信息
        crownOrientation = getCrownOrientation()
        digitalCrownStatus = getDigitalCrownStatus()
        
        // 防水锁状态
        waterLockStatus = getWaterLockStatus()
        
        // 表盘信息
        complicationFamily = getComplicationFamily()
        
        // 手腕位置
        wristLocation = getWristLocation()
        
        // 表冠方向
        crownDirection = getCrownDirection()
        
        // 时区和地区
        timeZone = TimeZone.current.identifier
        locale = Locale.current.identifier
        
        // 存储信息
        updateStorageInfo()
        
        // 内存和CPU使用情况
        updateSystemResources()
    }
    
    private func getCrownOrientation() -> String {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        return "Right"
    }
    
    private func getDigitalCrownStatus() -> String {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        return "Available"
    }
    
    private func getWaterLockStatus() -> String {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        return "Unlocked"
    }
    
    private func getComplicationFamily() -> String {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        return "Modular Small"
    }
    
    private func getWristLocation() -> String {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        return "Left"
    }
    
    private func getCrownDirection() -> String {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        return "Clockwise"
    }
    
    private func updateStorageInfo() {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSize = attributes[.systemSize] as? NSNumber {
                totalStorage = Double(truncating: totalSize) / (1024 * 1024 * 1024) // Convert to GB
            }
            if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                availableStorage = Double(truncating: freeSize) / (1024 * 1024 * 1024) // Convert to GB
            }
        } catch {
            totalStorage = 32.0 // 默认值
            availableStorage = 16.0 // 默认值
        }
    }
    
    private func updateSystemResources() {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        memoryUsage = getMemoryUsage()
        cpuUsage = getCPUUsage()
    }
    
    private func getMemoryUsage() -> Double {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        }
        
        return 0.0
    }
    
    private func getCPUUsage() -> Double {
        // 注意：这些API可能在实际Apple Watch上不可用
        // 这里提供示例实现
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            // 这里只是示例，实际CPU使用率需要更复杂的计算
            return Double.random(in: 10...50) // 随机值作为示例
        }
        
        return 0.0
    }
} 