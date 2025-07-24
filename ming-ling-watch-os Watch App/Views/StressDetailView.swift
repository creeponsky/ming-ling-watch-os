import SwiftUI

struct StressDetailView: View {
    let selectedElement: String
    let hrv: Double
    @State private var isStressed = false
    @State private var showFollowUp = false
    @State private var followUpMessage = ""
    @State private var stressHistory: [StressRecord] = []
    @State private var currentTime = Date()
    
    private let stressAdvice = [
        "金": "肺气需要调理。金属性压力大时容易呼吸短促。",
        "木": "肝气有点郁结了。木属性要保持心情舒畅。",
        "水": "肾气不足了。水属性最忌讳熬夜伤肾。",
        "火": "心火有点旺。火属性的人要注意清心。",
        "土": "脾胃受压力影响了。土属性重在调理中焦。"
    ]
    
    struct StressRecord: Identifiable {
        let id = UUID()
        let timestamp: Date
        let hrv: Double
        let isStressed: Bool
    }
    
    private let followUpAdvice = [
        "improved": [
            "金": "金气恢复不错。",
            "木": "肝气舒畅多了。",
            "水": "肾气在恢复呢～",
            "火": "心火平稳了！很好！",
            "土": "脾土安定了，不错。"
        ],
        "still_low": [
            "金": "肺气仍需调养，别着急。",
            "木": "慢慢来，肝气需要时间恢复。",
            "水": "肾气恢复需要时间哦～",
            "火": "心火还是有点急，放轻松！",
            "土": "脾胃恢复需要过程，不急。"
        ]
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 当前状态
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: isStressed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(isStressed ? .red : .green)
                        Spacer()
                        Text(isStressed ? "压力偏高" : "状态良好")
                            .font(.caption)
                            .foregroundColor(isStressed ? .red : .green)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前HRV")
                            .font(.headline)
                        Text("\(Int(hrv)) ms")
                            .font(.title)
                            .bold()
                        
                        Text(hrv < 50 ? "压力偏高" : (hrv < 100 ? "轻度压力" : "状态良好"))
                            .font(.body)
                            .foregroundColor(hrv < 50 ? .red : (hrv < 100 ? .orange : .green))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 触发条件
                VStack(alignment: .leading, spacing: 8) {
                    Text("触发条件")
                        .font(.headline)
                    
                    Text("HRV持续低于个人基线20%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 检测方式
                VStack(alignment: .leading, spacing: 8) {
                    Text("检测方式")
                        .font(.headline)
                    
                    Text("Apple Watch HRV数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 历史记录
                if !stressHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("历史记录")
                            .font(.headline)
                        
                        ForEach(stressHistory.prefix(5)) { record in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(formatTime(record.timestamp))
                                        .font(.caption)
                                    Text("HRV: \(Int(record.hrv)) ms")
                                        .font(.caption)
                                }
                                Spacer()
                                Image(systemName: record.isStressed ? "exclamationmark.triangle" : "checkmark.circle")
                                    .foregroundColor(record.isStressed ? .red : .green)
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
                    Text("\(selectedElement)属性建议")
                        .font(.headline)
                    
                    Text(stressAdvice[selectedElement] ?? "建议获取中...")
                        .font(.body)
                        .foregroundColor(.purple)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 操作按钮
                VStack(spacing: 8) {
                    Button(action: {
                        let newHRV = Double.random(in: 20...150)
                        let stressed = newHRV < 50
                        let newRecord = StressRecord(timestamp: Date(), hrv: newHRV, isStressed: stressed)
                        stressHistory.insert(newRecord, at: 0)
                        isStressed = stressed
                        showFollowUp = true
                    }) {
                        Text("检测压力")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .cornerRadius(20)
                    }
                    
                    if showFollowUp {
                        Button(action: {
                            let improved = Bool.random()
                            followUpMessage = improved ? 
                                followUpAdvice["improved"]?[selectedElement] ?? "" : 
                                followUpAdvice["still_low"]?[selectedElement] ?? ""
                        }) {
                            Text("模拟30分钟后")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.7))
                                .cornerRadius(16)
                        }
                        
                        if !followUpMessage.isEmpty {
                            Text(followUpMessage)
                                .font(.caption)
                                .foregroundColor(.purple)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("压力监测")
        .onAppear {
            // 初始化一些历史数据
            if stressHistory.isEmpty {
                for i in 0..<3 {
                    let timestamp = Calendar.current.date(byAdding: .hour, value: -i, to: Date()) ?? Date()
                    let randomHRV = Double.random(in: 40...120)
                    let record = StressRecord(timestamp: timestamp, hrv: randomHRV, isStressed: randomHRV < 50)
                    stressHistory.append(record)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}