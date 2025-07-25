import SwiftUI
import HealthKit

struct HealthDetailView: View {
    let reminder: HealthReminder
    let userElement: String
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var todayRecords: [HealthRecord] = []
    @State private var weeklyData: [DailyHealthData] = []
    @State private var isLoading = true
    
    // 从主页面传递健康数据
    let healthData: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题和当前状态
                headerSection
                
                // 今日数据概览
                todayOverviewSection
                
                // 今日触发记录
                todayRecordsSection
                
                // 最近7天数据
                weeklyDataSection
            }
            .padding()
        }
        .background(PetUtils.getElementBackgroundColor(for: userElement))
        .navigationTitle(reminder.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - 标题和当前状态
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: reminder.icon)
                    .font(.title)
                    .foregroundColor(PetUtils.getElementDialogColor(for: userElement))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                    
                    Text(reminder.description)
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
                }
                
                Spacer()
            }
            
            // 当前状态指示器
            HStack {
                Circle()
                    .fill(getStatusColor())
                    .frame(width: 12, height: 12)
                
                Text(getStatusText())
                    .font(.caption)
                    .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PetUtils.getElementDialogColor(for: userElement).opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 今日数据概览
    private var todayOverviewSection: some View {
        VStack(spacing: 16) {
            Text("今日数据")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PetUtils.getElementTextColor(for: userElement))
            
            HStack(spacing: 16) {
                // 当前值
                VStack(spacing: 8) {
                    Text(getCurrentValue())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                    
                    Text("当前值")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.1))
                )
                
                // 目标值
                VStack(spacing: 8) {
                    Text(getTargetValue())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                    
                    Text("目标值")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - 今日触发记录
    private var todayRecordsSection: some View {
        VStack(spacing: 16) {
            Text("今日触发记录")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PetUtils.getElementTextColor(for: userElement))
            
            if todayRecords.isEmpty {
                Text("暂无触发记录")
                    .font(.caption)
                    .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.1))
                    )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todayRecords, id: \.id) { record in
                        HealthRecordRow(record: record, userElement: userElement)
                    }
                }
            }
        }
    }
    
    // MARK: - 最近7天数据
    private var weeklyDataSection: some View {
        VStack(spacing: 16) {
            Text("最近7天")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PetUtils.getElementTextColor(for: userElement))
            
            LazyVStack(spacing: 8) {
                ForEach(weeklyData, id: \.date) { data in
                    WeeklyDataRow(data: data, userElement: userElement)
                }
            }
        }
    }
    
    // MARK: - 获取当前值
    private func getCurrentValue() -> String {
        // 优先使用从主页面传递的数据，如果没有则从HealthKitManager获取
        if healthData != "暂无数据" && !healthData.isEmpty {
            return healthData
        }
        
        // 从HealthKitManager获取最新数据
        switch reminder.type {
        case .sunExposure:
            return "紫外线: \(EnvironmentSensorManager.shared.getUVStatus())"
        case .stress:
            let hrv = Int(healthKitManager.heartRateVariability)
            return hrv > 0 ? "\(hrv)ms" : "暂无数据"
        case .sedentary:
            return "\(healthKitManager.steps) 步"
        case .exercise:
            let hr = healthKitManager.heartRate
            return hr > 0 ? "\(hr) BPM" : "暂无数据"
        case .sleep:
            return healthKitManager.sleepAnalysis
        }
    }
    
    // MARK: - 获取目标值
    private func getTargetValue() -> String {
        switch reminder.type {
        case .sunExposure:
            return "15-30分钟"
        case .stress:
            return "< 50ms"
        case .sedentary:
            return "10,000步"
        case .exercise:
            return "120-180 BPM"
        case .sleep:
            return "7-9小时"
        }
    }
    
    // MARK: - 获取状态颜色
    private func getStatusColor() -> Color {
        // 这里可以根据实际数据判断状态
        return .green
    }
    
    // MARK: - 获取状态文本
    private func getStatusText() -> String {
        // 这里可以根据实际数据判断状态
        return "状态良好"
    }
    
    // MARK: - 加载数据
    private func loadData() {
        isLoading = true
        
        // 模拟加载今日记录
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.todayRecords = self.generateMockRecords()
            self.weeklyData = self.generateMockWeeklyData()
            self.isLoading = false
        }
    }
    
    // MARK: - 生成模拟记录
    private func generateMockRecords() -> [HealthRecord] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            HealthRecord(
                id: UUID(),
                timestamp: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                value: healthData,
                status: .completed,
                description: "完成目标"
            ),
            HealthRecord(
                id: UUID(),
                timestamp: calendar.date(byAdding: .hour, value: -4, to: now) ?? now,
                value: healthData,
                status: .triggered,
                description: "触发提醒"
            )
        ]
    }
    
    // MARK: - 生成模拟周数据
    private func generateMockWeeklyData() -> [DailyHealthData] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            return DailyHealthData(
                date: date,
                value: healthData,
                isCompleted: Bool.random(),
                triggerCount: Int.random(in: 0...3)
            )
        }.reversed()
    }
}

// MARK: - 健康记录模型
struct HealthRecord: Identifiable {
    let id: UUID
    let timestamp: Date
    let value: String
    let status: RecordStatus
    let description: String
    
    enum RecordStatus {
        case completed
        case triggered
        case warning
    }
}

// MARK: - 每日健康数据模型
struct DailyHealthData: Identifiable {
    let id = UUID()
    let date: Date
    let value: String
    let isCompleted: Bool
    let triggerCount: Int
}

// MARK: - 健康记录行视图
struct HealthRecordRow: View {
    let record: HealthRecord
    let userElement: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
            Image(systemName: getStatusIcon())
                .font(.title3)
                .foregroundColor(getStatusColor())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.description)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                
                Text(record.value)
                    .font(.caption)
                    .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
            }
            
            Spacer()
            
            Text(formatTime(record.timestamp))
                .font(.caption)
                .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.1))
        )
    }
    
    private func getStatusIcon() -> String {
        switch record.status {
        case .completed:
            return "checkmark.circle.fill"
        case .triggered:
            return "exclamationmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func getStatusColor() -> Color {
        switch record.status {
        case .completed:
            return .green
        case .triggered:
            return .orange
        case .warning:
            return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 周数据行视图
struct WeeklyDataRow: View {
    let data: DailyHealthData
    let userElement: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 日期
            VStack(spacing: 4) {
                Text(formatDay(data.date))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(PetUtils.getElementTextColor(for: userElement))
                
                Text(formatDate(data.date))
                    .font(.caption)
                    .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
            }
            .frame(width: 60)
            
            // 数据值
            Text(data.value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(PetUtils.getElementTextColor(for: userElement))
            
            Spacer()
            
            // 状态指示器
            HStack(spacing: 8) {
                if data.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                if data.triggerCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("\(data.triggerCount)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.1))
        )
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - 预览
struct HealthDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDetailView(
            reminder: HealthReminder.allReminders[0],
            userElement: "金",
            healthData: "测试数据"
        )
    }
} 