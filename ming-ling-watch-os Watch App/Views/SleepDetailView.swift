import SwiftUI

struct SleepDetailView: View {
    let selectedElement: String
    let sleepStatus: String
    @State private var sleepHours: Double = 0
    @State private var sleepRecords: [SleepRecord] = []
    @State private var lastSleepStart: Date?
    @State private var lastSleepEnd: Date?
    @State private var showEveningReminder = false
    
    private let morningAdvice = [
        "金": "昨晚睡眠不足，今天注意养肺。",
        "木": "睡眠不足伤肝，今天要平和。",
        "水": "睡眠不足伤肾精，要补充哦～",
        "火": "睡眠影响心神，今天慢一点！",
        "土": "睡眠不足影响脾胃，注意饮食。"
    ]
    
    private let eveningAdvice = [
        "金": "该准备睡觉了，养肺阴。",
        "木": "早睡养肝血，准备休息吧。",
        "水": "早睡最养肾～该准备了～",
        "火": "让心神安定，准备入睡！",
        "土": "脾胃需要休息，早点睡。"
    ]
    
    struct SleepRecord: Identifiable {
        let id = UUID()
        let startTime: Date
        let endTime: Date
        let duration: TimeInterval
        
        var formattedDuration: String {
            let hours = duration / 3600
            return String(format: "%.1f小时", hours)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 当前睡眠状态
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        Text("昨晚睡眠")
                            .font(.headline)
                        
                        Text(String(format: "%.1f小时", sleepHours))
                            .font(.title)
                            .bold()
                            .foregroundColor(sleepHours < 7 ? .orange : .green)
                        
                        if let start = lastSleepStart, let end = lastSleepEnd {
                            Text("\(formatTime(start)) - \(formatTime(end))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: sleepHours < 7 ? "exclamationmark.triangle" : "checkmark.circle")
                            Text(sleepHours < 7 ? "睡眠不足" : "睡眠充足")
                                .foregroundColor(sleepHours < 7 ? .orange : .green)
                        }
                        .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 触发条件
                VStack(alignment: .leading, spacing: 8) {
                    Text("触发条件")
                        .font(.headline)
                    
                    Text("早上检测到前晚睡眠<7小时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 检测方式
                VStack(alignment: .leading, spacing: 8) {
                    Text("检测方式")
                        .font(.headline)
                    
                    Text("Apple Watch睡眠数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 早上提醒
                VStack(alignment: .leading, spacing: 8) {
                    Text("早上提醒")
                        .font(.headline)
                    
                    Text(morningAdvice[selectedElement] ?? "建议获取中...")
                        .font(.body)
                        .foregroundColor(.indigo)
                        .padding()
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 晚上提醒
                VStack(alignment: .leading, spacing: 8) {
                    Text("晚上提醒")
                        .font(.headline)
                    
                    Text("晚上11点提醒")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if showEveningReminder {
                        Text(eveningAdvice[selectedElement] ?? "建议获取中...")
                            .font(.body)
                            .foregroundColor(.indigo)
                            .padding()
                            .background(Color.indigo.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 睡眠历史
                if !sleepRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("近期睡眠记录")
                            .font(.headline)
                        
                        ForEach(sleepRecords.prefix(3)) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(formatDate(record.startTime))
                                        .font(.caption)
                                    Spacer()
                                    Text(record.formattedDuration)
                                        .font(.caption)
                                        .foregroundColor(record.duration < 25200 ? .orange : .green)
                                }
                                Text("\(formatTime(record.startTime)) - \(formatTime(record.endTime))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // 个性化建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("个性化建议")
                        .font(.headline)
                    
                    Text(sleepHours == 0 ? eveningAdvice[selectedElement] ?? "建议获取中..." : morningAdvice[selectedElement] ?? "建议获取中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 更新按钮
                Button(action: {
                    // 模拟添加一条睡眠记录
                    let now = Date()
                    let duration = Double.random(in: 6...9) * 3600
                    let startTime = now.addingTimeInterval(-duration)
                    
                    let record = SleepRecord(
                        startTime: startTime,
                        endTime: now,
                        duration: duration
                    )
                    
                    sleepRecords.insert(record, at: 0)
                    sleepHours = duration / 3600
                    lastSleepStart = startTime
                    lastSleepEnd = now
                }) {
                    Text(sleepHours == 0 ? "添加睡眠记录" : "更新睡眠记录")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("睡眠监测")
        .onAppear {
            // 初始化示例数据
            if sleepRecords.isEmpty {
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                let record = SleepRecord(
                    startTime: yesterday.addingTimeInterval(-8 * 3600),
                    endTime: yesterday,
                    duration: 8 * 3600
                )
                sleepRecords = [record]
                sleepHours = 8
                lastSleepStart = record.startTime
                lastSleepEnd = record.endTime
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
