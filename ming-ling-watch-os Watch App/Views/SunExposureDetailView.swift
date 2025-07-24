import SwiftUI
import CoreLocation

struct SunExposureDetailView: View {
    let selectedElement: String
    @StateObject private var locationManager = LocationManager()
    @State private var uvIndex: Int = 0
    @State private var indoorTime: TimeInterval = 0
    @State private var outdoorTime: TimeInterval = 0
    @State private var currentTime = Date()
    @State private var isIndoor: Bool = true
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let sunAdvice = [
        "金": "阳光正好，出去晒15分钟润肺气。金需要适度日晒。",
        "木": "阳光助木气生发，出去走走舒肝气吧。",
        "水": "太阳能温肾阳，去晒晒背补充阳气～",
        "火": "阳光充足但不烈，适合补充心阳！",
        "土": "晒太阳健脾胃，阳光下土气运化更好。"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 状态卡片
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: isIndoor ? "house.fill" : "sun.max.fill")
                            .font(.title)
                            .foregroundColor(isIndoor ? .blue : .orange)
                        Spacer()
                        Text(isIndoor ? "室内" : "室外")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("UV指数: \(uvIndex)")
                        .font(.title2)
                        .bold()
                    
                    if isIndoor {
                        Text("室内时间: \(formatTime(indoorTime))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("户外时间: \(formatTime(outdoorTime))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 触发条件
                VStack(alignment: .leading, spacing: 8) {
                    Text("触发条件")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• UV指数 2-6 (适中)")
                        Text("• 上午9-11点或下午3-5点")
                        Text("• 室内超过2小时")
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 检测方式
                VStack(alignment: .leading, spacing: 8) {
                    Text("检测方式")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 光线传感器检测环境光")
                        Text("• GPS定位室内外")
                        Text("• UV指数API")
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 个性化建议
                VStack(alignment: .leading, spacing: 8) {
                    Text("个性化建议")
                        .font(.headline)
                    
                    Text(sunAdvice[selectedElement] ?? "享受阳光，保持健康！")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 检测依据
                VStack(alignment: .leading, spacing: 8) {
                    Text("检测依据")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 位置: \(String(format: "%.2f", locationManager.latitude)), \(String(format: "%.2f", locationManager.longitude))")
                            .font(.caption)
                        Text("• 光线强度: \(isIndoor ? "弱" : "强")")
                            .font(.caption)
                        Text("• 检测方式: GPS + 光线传感器")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 操作按钮
                Button(action: {
                    isIndoor.toggle()
                    if isIndoor {
                        outdoorTime = 0
                    } else {
                        indoorTime = 0
                    }
                }) {
                    Text(isIndoor ? "模拟外出" : "模拟回家")
                        .foregroundColor(.orange)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("晒太阳")
        .onReceive(timer) { _ in
            if isIndoor {
                indoorTime += 1
            } else {
                outdoorTime += 1
            }
            
            // 模拟UV指数变化
            if !isIndoor {
                uvIndex = Int.random(in: 3...8)
            } else {
                uvIndex = 0
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}