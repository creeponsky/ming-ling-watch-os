import SwiftUI
import HealthKit

struct MainDashboardView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedElement: String = UserDefaultsManager.shared.getSelectedElement()
    @State private var currentPage = 0
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 第一页：动画元素选择器
                VStack {
                    AnimatedElementView(selectedElement: $selectedElement)
                        .frame(minHeight: 200)
                        .padding(.top, 20)
                    
                    // 向下滑动提示
                    VStack(spacing: 8) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                        
                        Text("向下滑动查看健康功能")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal)
                
                // 第二页：健康功能卡片
                VStack(spacing: 16) {
                    Text("健康功能")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 20)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        // 晒太阳卡片
                        HealthCardView(
                            icon: "sun.max.fill",
                            title: "晒太阳",
                            subtitle: "获取维生素D",
                            color: .orange,
                            destination: AnyView(SunExposureDetailView(selectedElement: selectedElement))
                        )
                        
                        // 压力监测卡片
                        HealthCardView(
                            icon: "brain.head.profile",
                            title: "压力监测",
                            subtitle: "HRV: \(Int(healthKitManager.heartRateVariability))ms",
                            color: .purple,
                            destination: AnyView(StressDetailView(selectedElement: selectedElement, hrv: healthKitManager.heartRateVariability))
                        )
                        
                        // 久坐提醒卡片
                        HealthCardView(
                            icon: "figure.seated.seatbelt",
                            title: "久坐提醒",
                            subtitle: "步数: \(healthKitManager.steps)",
                            color: .blue,
                            destination: AnyView(SedentaryDetailView(selectedElement: selectedElement, steps: healthKitManager.steps))
                        )
                        
                        // 运动检测卡片
                        HealthCardView(
                            icon: "figure.run",
                            title: "运动检测",
                            subtitle: "心率: \(healthKitManager.heartRate) BPM",
                            color: .green,
                            destination: AnyView(ExerciseDetailView(selectedElement: selectedElement, heartRate: healthKitManager.heartRate))
                        )
                        
                        // 睡眠监测卡片
                        HealthCardView(
                            icon: "bed.double.fill",
                            title: "睡眠监测",
                            subtitle: healthKitManager.sleepAnalysis,
                            color: .indigo,
                            destination: AnyView(SleepDetailView(selectedElement: selectedElement, sleepStatus: healthKitManager.sleepAnalysis))
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("健康助手")
        .onAppear {
            healthKitManager.requestAuthorization()
        }
        .onChange(of: selectedElement) { newValue in
            UserDefaultsManager.shared.saveSelectedElement(newValue)
        }
    }
}

struct HealthCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let destination: AnyView
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}