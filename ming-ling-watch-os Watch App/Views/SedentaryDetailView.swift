import SwiftUI

struct SedentaryDetailView: View {
    let selectedElement: String
    let steps: Int
    @State private var isSitting = false
    @State private var sittingTime: TimeInterval = 0
    @State private var standingTime: TimeInterval = 0
    @State private var dailySitCount = 0
    @State private var dailyStandCount = 0
    @State private var history: [ActivityRecord] = []
    @State private var showFollowUp = false
    @State private var followUpMessage = ""
    
    private let sedentaryAdvice = [
        "金": "久坐肺气不畅，金需流通。",
        "木": "坐久了筋脉不通，木喜舒展。",
        "水": "久坐伤肾，水需流动～",
        "火": "血脉要不通了！火主循环！",
        "土": "久坐困脾，土气需运化。"
    ]
    
    struct ActivityRecord: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: String // "sit" or "stand"
        let duration: TimeInterval
    }
    
    private let followUpAdvice = [
        "moved": [
            "金": "活动后肺气通畅多了。",
            "木": "筋骨舒展，很好。",
            "水": "动起来了～肾气也活了～",
            "火": "血液循环起来了！棒！",
            "土": "脾胃得到运化，好。"
        ]
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 当前状态卡片
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: isSitting ? "figure.seated.seatbelt" : "figure.stand")
                            .font(.title2)
                            .foregroundColor(isSitting ? .orange : .green)
                        Spacer()
                        Text(isSitting ? "坐姿" : "站姿")
                            .font(.caption)
                            .foregroundColor(isSitting ? .orange : .green)
                    }
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text(formatTime(sittingTime))
                                .font(.title3)
                                .bold()
                            Text("坐姿时长")
                                .font(.caption)
                        }
                        
                        VStack {
                            Text(formatTime(standingTime))
                                .font(.title3)
                                .bold()
                            Text("站姿时长")
                                .font(.caption)
                        }
                    }
                    
                    Text("今日步数: \(steps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 触发条件
                VStack(alignment: .leading, spacing: 8) {
                    Text("触发条件")
                        .font(.headline)
                    
                    Text("1小时内步数<40步")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 检测方式
                VStack(alignment: .leading, spacing: 8) {
                    Text("检测方式")
                        .font(.headline)
                    
                    Text("Apple Watch活动监测")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 历史记录
//                if !history.isEmpty {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("今日记录")
//                            .font(.headline)
//                        
//                        ForEach(history.prefix(5)) { record in
//                            HStack {
//                                VStack(alignment: .leading) {
//                                    Text(formatTime(record.timestamp))
//                                        .font(.caption)
//                                    Text(record.type == "sit" ? "坐姿" : "站姿")
//                                        .font(.caption2)
//                                }
//                                Spacer()
//                                Text(formatTime(record.duration))
//                                    .font(.caption)
//                            }
//                            .padding(.vertical, 2)
//                        }
//                    }
//                    .padding()
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(12)
//                }
                
                // 统计信息
                VStack(spacing: 8) {
                    HStack {
                        Text("今日坐起次数")
                        Spacer()
                        Text("\(dailySitCount)次")
                    }
                    HStack {
                        Text("今日站起次数")
                        Spacer()
                        Text("\(dailyStandCount)次")
                    }
                }
                .font(.caption)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 个性化建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selectedElement)属性建议")
                        .font(.headline)
                    
                    Text(sedentaryAdvice[selectedElement] ?? "建议获取中...")
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 切换按钮
                Button(action: {
                    let now = Date()
                    if isSitting {
                        // 从坐姿转为站姿
                        let record = ActivityRecord(timestamp: now, type: "sit", duration: sittingTime)
                        history.insert(record, at: 0)
                        standingTime = 0
                        dailyStandCount += 1
                    } else {
                        // 从站姿转为坐姿
                        let record = ActivityRecord(timestamp: now, type: "stand", duration: standingTime)
                        history.insert(record, at: 0)
                        sittingTime = 0
                        dailySitCount += 1
                    }
                    isSitting.toggle()
                }) {
                    Text(isSitting ? "站起来了" : "坐下了")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("久坐提醒")
        .onAppear {
            // 初始化计时器
            startTimer()
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if isSitting {
                sittingTime += 1
            } else {
                standingTime += 1
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
