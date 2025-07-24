import SwiftUI
import HealthKit

struct NewMainDashboardView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var environmentManager = EnvironmentSensorManager.shared
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 宠物动画区域
                petAnimationSection
                
                // 问候语区域
                greetingSection
                
                // 健康卡片网格
                healthCardsSection
                
                // 设置卡片
                settingsCard
            }
            .padding(.horizontal)
        }
        .navigationTitle("健康助手")
        .onAppear {
            healthKitManager.requestAuthorization()
            profileManager.updateHealthStreak()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - 宠物动画区域
    private var petAnimationSection: some View {
        VStack(spacing: 8) {
            Text("我的宠物")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            PetAnimationView(userElement: profileManager.userProfile.fiveElements?.primary ?? "金")
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(profileManager.getThemeColor().opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(profileManager.getThemeColor().opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - 问候语区域
    private var greetingSection: some View {
        VStack(spacing: 12) {
            // 宠物头像和问候语
            HStack(spacing: 12) {
                Circle()
                    .fill(profileManager.getThemeColor())
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profileManager.getGreeting())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    
                    Text(profileManager.getStressStatusDescription())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(profileManager.getThemeColor().opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(profileManager.getThemeColor().opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - 健康卡片区域
    private var healthCardsSection: some View {
        VStack(spacing: 16) {
                            Text("今日健康监测")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(HealthReminder.allReminders, id: \.id) { reminder in
                    HealthCardView(
                        reminder: reminder,
                        healthData: getHealthData(for: reminder.type),
                        userElement: profileManager.userProfile.fiveElements?.primary ?? "金"
                    )
                }
            }
        }
    }
    
    // MARK: - 设置卡片
    private var settingsCard: some View {
        Button(action: {
            showingSettings = true
        }) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(profileManager.getThemeColor())
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("设置与数据")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("查看所有数据并更改设置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(profileManager.getThemeColor().opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 获取健康数据
    private func getHealthData(for type: HealthReminder.ReminderType) -> String {
        switch type {
        case .sunExposure:
            return "紫外线: \(environmentManager.getUVStatus())"
        case .stress:
            return "心率变异性: \(Int(healthKitManager.heartRateVariability))ms"
        case .sedentary:
            return "步数: \(healthKitManager.steps)"
        case .exercise:
            return "心率: \(healthKitManager.heartRate) BPM"
        case .sleep:
            return healthKitManager.sleepAnalysis
        }
    }
}

// MARK: - 健康卡片视图
struct HealthCardView: View {
    let reminder: HealthReminder
    let healthData: String
    let userElement: String
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: HealthDetailView(reminder: reminder, userElement: userElement)) {
            VStack(spacing: 8) {
                Image(systemName: reminder.type.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: reminder.type.color))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(reminder.type.rawValue)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.primary)
                
                Text(healthData)
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
                            .stroke(Color(hex: reminder.type.color).opacity(0.3), lineWidth: 1)
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

// MARK: - 健康详情视图
struct HealthDetailView: View {
    let reminder: HealthReminder
    let userElement: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: reminder.type.icon)
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: reminder.type.color))
                    
                    Text(reminder.type.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // 触发条件
                VStack(alignment: .leading, spacing: 12) {
                                    Text("触发条件")
                    .font(.headline)
                    .fontWeight(.semibold)
                    
                    ForEach(reminder.trigger.conditions, id: \.self) { condition in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(condition)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
                
                // 个性化建议
                VStack(alignment: .leading, spacing: 12) {
                                    Text("个性化建议")
                    .font(.headline)
                    .fontWeight(.semibold)
                    
                    Text(reminder.getReminder(for: userElement))
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: reminder.type.color).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: reminder.type.color).opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .navigationTitle(reminder.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
} 