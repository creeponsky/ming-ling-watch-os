//
//  HealthKitManager.swift
//  test-app Watch App
//
//  Created by CreepOnSky on 2025/7/24.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var heartRate: Int = 0
    @Published var activeEnergy: Double = 0
    @Published var steps: Int = 0
    @Published var distance: Double = 0
    @Published var flightsClimbed: Int = 0
    @Published var exerciseTime: Int = 0
    @Published var standHours: Int = 0
    @Published var vo2Max: Double = 0
    @Published var restingHeartRate: Int = 0
    @Published var walkingHeartRate: Int = 0
    @Published var heartRateVariability: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var bodyTemperature: Double = 0
    @Published var respiratoryRate: Double = 0
    @Published var sleepAnalysis: String = "暂无数据"
    
    private var heartRateQuery: HKQuery?
    private var activeEnergyQuery: HKQuery?
    private var hrvQuery: HKQuery?
    @Published var isUpdating = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.startHeartRateUpdates()
                    self?.fetchTodayData()
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        isAuthorized = status == .sharingAuthorized
    }
    
    // MARK: - 心率监测
    func startHeartRateMonitoring(completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples, completion: completion)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples, completion: completion)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?, completion: @escaping (Double) -> Void) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            if let lastSample = heartRateSamples.last {
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let heartRate = lastSample.quantity.doubleValue(for: heartRateUnit)
                self.heartRate = Int(heartRate)
                completion(heartRate)
            }
        }
    }
    
    // MARK: - HRV监测
    func startHRVMonitoring(completion: @escaping (Double) -> Void) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let query = HKAnchoredObjectQuery(type: hrvType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples, completion: completion)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples, completion: completion)
        }
        
        healthStore.execute(query)
        hrvQuery = query
    }
    
    func stopHRVMonitoring() {
        if let query = hrvQuery {
            healthStore.stop(query)
            hrvQuery = nil
        }
    }
    
    private func processHRVSamples(_ samples: [HKSample]?, completion: @escaping (Double) -> Void) {
        guard let hrvSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            if let lastSample = hrvSamples.last {
                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let hrv = lastSample.quantity.doubleValue(for: hrvUnit)
                self.heartRateVariability = hrv
                completion(hrv)
            }
        }
    }
    
    // MARK: - 获取当前HRV
    func getCurrentHRV(completion: @escaping (Double) -> Void) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(0)
            return
        }
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(0)
                return
            }
            
            let hrvUnit = HKUnit.secondUnit(with: .milli)
            let hrv = sample.quantity.doubleValue(for: hrvUnit)
            completion(hrv)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - 获取指定时间段步数
    func getSteps(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    private func startHeartRateUpdates() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples) { _ in }
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples) { _ in }
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    private func fetchTodayData() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        fetchQuantityData(for: .activeEnergyBurned, unit: .kilocalorie(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.activeEnergy = value
            }
        }
        
        fetchQuantityData(for: .stepCount, unit: .count(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.steps = Int(value)
            }
        }
        
        fetchQuantityData(for: .distanceWalkingRunning, unit: .meter(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.distance = value
            }
        }
        
        fetchQuantityData(for: .flightsClimbed, unit: .count(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.flightsClimbed = Int(value)
            }
        }
        
        fetchQuantityData(for: .appleExerciseTime, unit: .minute(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.exerciseTime = Int(value)
            }
        }
        
        fetchQuantityData(for: .appleStandTime, unit: .hour(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.standHours = Int(value)
            }
        }
        
        fetchQuantityData(for: .vo2Max, unit: HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute()), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.vo2Max = value
            }
        }
        
        fetchQuantityData(for: .restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.restingHeartRate = Int(value)
            }
        }
        
        fetchQuantityData(for: .walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.walkingHeartRate = Int(value)
            }
        }
        
        fetchQuantityData(for: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.heartRateVariability = value
            }
        }
        
        fetchQuantityData(for: .oxygenSaturation, unit: .percent(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.bloodOxygen = value * 100
            }
        }
        
        fetchQuantityData(for: .bodyTemperature, unit: .degreeCelsius(), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.bodyTemperature = value
            }
        }
        
        fetchQuantityData(for: .respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()), predicate: predicate) { [weak self] value in
            DispatchQueue.main.async {
                self?.respiratoryRate = value
            }
        }
        
        fetchSleepAnalysis(predicate: predicate)
    }
    
    private func fetchQuantityData(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(0)
            return
        }
        
        // 确定使用哪种统计选项
        let options: HKStatisticsOptions
        switch identifier {
        case .vo2Max, .restingHeartRate, .walkingHeartRateAverage, .heartRateVariabilitySDNN, .oxygenSaturation, .bodyTemperature, .respiratoryRate:
            // 离散数据使用平均值
            options = .discreteAverage
        default:
            // 累积数据使用累积和
            options = .cumulativeSum
        }
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options) { _, result, _ in
            if options == .discreteAverage {
                guard let result = result, let average = result.averageQuantity() else {
                    completion(0)
                    return
                }
                completion(average.doubleValue(for: unit))
            } else {
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(0)
                    return
                }
                completion(sum.doubleValue(for: unit))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleepAnalysis(predicate: NSPredicate) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let sleepSamples = samples as? [HKCategorySample] else { return }
            
            var totalSleepTime: TimeInterval = 0
            for sample in sleepSamples {
                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                    totalSleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            let hours = Int(totalSleepTime / 3600)
            let minutes = Int((totalSleepTime.truncatingRemainder(dividingBy: 3600)) / 60)
            
            DispatchQueue.main.async {
                self?.sleepAnalysis = "\(hours)h \(minutes)m"
            }
        }
        
        healthStore.execute(query)
    }
} 