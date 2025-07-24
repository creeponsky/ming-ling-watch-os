import SwiftUI

struct ExerciseDetailView: View {
    let selectedElement: String
    let heartRate: Int
    @State private var isExercising = false
    @State private var exerciseDuration: Int = 0
    @State private var currentHeartRate: Int = 75
    @State private var maxHeartRate: Int = 75
    @State private var avgHeartRate: Int = 75
    @State private var exerciseRecords: [ExerciseRecord] = []
    @State private var showPostExercise = false
    
    private let exerciseAdvice = [
        "金": "运动后记得调息，金主气。",
        "木": "运动舒肝，记得放松。",
        "水": "运动出汗，该补充水分了～",
        "火": "运动后心率恢复得不错！",
        "土": "运动助脾运化，很好。"
    ]
    
    struct ExerciseRecord: Identifiable {
        let id = UUID()
        let startTime: Date
        let duration: TimeInterval
        let maxHeartRate: Int
        let avgHeartRate: Int
        let calories: Int
        
        var formattedDuration: String {
            let minutes = Int(duration / 60)
            return "\(minutes)分钟"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 实时心率卡片
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Text("\(currentHeartRate)")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.red)
                        
                        Text("BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack {
                                Text("\(maxHeartRate)")
                                    .font(.title3)
                                    .bold()
                                Text("最高")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(avgHeartRate)")
                                    .font(.title3)
                                    .bold()
                                Text("平均")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 触发条件
                VStack(alignment: .leading, spacing: 8) {
                    Text("触发条件")
                        .font(.headline)
                    
                    Text("心率持续>120超过10分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 检测方式
                VStack(alignment: .leading, spacing: 8) {
                    Text("检测方式")
                        .font(.headline)
                    
                    Text("Apple Watch心率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 运动记录
                if !exerciseRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("近期运动记录")
                            .font(.headline)
                        
                        ForEach(exerciseRecords.prefix(3)) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(formatDate(record.startTime))
                                        .font(.caption)
                                    Spacer()
                                    Text(record.formattedDuration)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                HStack {
                                    Text("最高: \(record.maxHeartRate) BPM")
                                        .font(.caption2)
                                    Spacer()
                                    Text("\(record.calories) 卡")
                                        .font(.caption2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // 运动提醒
                VStack(alignment: .leading, spacing: 8) {
                    Text("运动提醒")
                        .font(.headline)
                    
                    Text("运动中不打扰，运动后15分钟提醒")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 个性化建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selectedElement)属性建议")
                        .font(.headline)
                    
                    Text(exerciseAdvice[selectedElement] ?? "建议获取中...")
                        .font(.body)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 模拟按钮
                VStack(spacing: 8) {
                    Button(action: {
                        if !isExercising {
                            // 开始运动
                            isExercising = true
                            exerciseDuration = 0
                            maxHeartRate = currentHeartRate
                            avgHeartRate = currentHeartRate
                            
                            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { timer in
                                if isExercising {
                                    exerciseDuration += 1
                                    
                                    // 模拟心率变化
                                    currentHeartRate = 120 + Int.random(in: -10...30)
                                    maxHeartRate = max(maxHeartRate, currentHeartRate)
                                    avgHeartRate = (avgHeartRate + currentHeartRate) / 2
                                    
                                    if exerciseDuration >= 10 {
                                        timer.invalidate()
                                        
                                        // 记录运动数据
                                        let record = ExerciseRecord(
                                            startTime: Date().addingTimeInterval(-TimeInterval(exerciseDuration * 60)),
                                            duration: TimeInterval(exerciseDuration * 60),
                                            maxHeartRate: maxHeartRate,
                                            avgHeartRate: avgHeartRate,
                                            calories: exerciseDuration * 5
                                        )
                                        exerciseRecords.insert(record, at: 0)
                                        
                                        isExercising = false
                                        showPostExercise = true
                                    }
                                }
                            }
                        } else {
                            // 手动结束运动
                            let record = ExerciseRecord(
                                startTime: Date().addingTimeInterval(-TimeInterval(exerciseDuration * 60)),
                                duration: TimeInterval(exerciseDuration * 60),
                                maxHeartRate: maxHeartRate,
                                avgHeartRate: avgHeartRate,
                                calories: exerciseDuration * 5
                            )
                            exerciseRecords.insert(record, at: 0)
                            isExercising = false
                        }
                    }) {
                        Text(isExercising ? "结束运动" : "开始运动")
                            .font(.headline)
                            .foregroundColor(isExercising ? .red : .green)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isExercising)
                    
                    if showPostExercise {
                        Text("运动后提醒已触发")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("运动检测")
        .onAppear {
            // 初始化示例数据
            if exerciseRecords.isEmpty {
                let sampleRecords = [
                    ExerciseRecord(
                        startTime: Date().addingTimeInterval(-86400),
                        duration: 1800,
                        maxHeartRate: 145,
                        avgHeartRate: 128,
                        calories: 180
                    ),
                    ExerciseRecord(
                        startTime: Date().addingTimeInterval(-172800),
                        duration: 2400,
                        maxHeartRate: 152,
                        avgHeartRate: 135,
                        calories: 250
                    )
                ]
                exerciseRecords = sampleRecords
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}