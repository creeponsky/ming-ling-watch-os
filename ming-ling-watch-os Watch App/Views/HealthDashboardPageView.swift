import SwiftUI
import UserNotifications

// MARK: - 健康数据页面
struct HealthDashboardPageView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var environmentManager = EnvironmentSensorManager.shared
    @StateObject private var systemNotificationManager = SystemNotificationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 问候语和压力状态
                greetingSection
                
                // 健康卡片
                healthCardsSection
                
                // 系统通知按钮
                systemNotificationButton
                
                // 设置入口
                settingsSection
            }
            .padding()
        }
        .background(PetUtils.getElementBackgroundColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
        .onAppear {
            healthKitManager.requestAuthorization()
            profileManager.updateHealthStreak()
            // 设置通知代理
            UNUserNotificationCenter.current().delegate = systemNotificationManager
        }

    }
    
    // MARK: - 问候语区域
    private var greetingSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                            .font(.title3)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profileManager.getGreeting())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                    
                    Text(profileManager.getStressStatusDescription())
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
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
                .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(HealthReminder.allReminders, id: \.id) { reminder in
                    HealthCardView(
                        reminder: reminder,
                        healthData: getHealthData(for: reminder.type),
                        userElement: profileManager.userProfile.fiveElements?.primary ?? "金",
                        isDarkMode: true
                    )
                }
            }
        }
    }
    
    // MARK: - 系统通知按钮
    private var systemNotificationButton: some View {
        VStack(spacing: 12) {
            // 立即测试按钮
            Button(action: {
                let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
                print("发送通知 - 用户元素: \(userElement)")
                systemNotificationManager.sendHealthReminderNotification(
                    for: userElement,
                    reminderType: .sunExposure,
                    subType: "建议"
                )
            }) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("立即测试")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                        
                        Text("立即发送通知测试界面")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 晒太阳提醒测试（延时20秒）
            Button(action: {
                systemNotificationManager.sendHealthReminderNotificationWithDelay(
                    for: profileManager.userProfile.fiveElements?.primary ?? "金",
                    reminderType: .sunExposure,
                    subType: "建议",
                    delay: 20
                )
            }) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("晒太阳提醒")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                        
                        Text("20秒后发送，测试抬腕亮屏")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                        .font(.caption)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 压力提醒测试（延时20秒）
            Button(action: {
                systemNotificationManager.sendHealthReminderNotificationWithDelay(
                    for: profileManager.userProfile.fiveElements?.primary ?? "金",
                    reminderType: .stress,
                    subType: "建议",
                    delay: 20
                )
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("压力提醒")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                        
                        Text("20秒后发送，测试抬腕亮屏")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                        .font(.caption)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 设置卡片
    private var settingsSection: some View {
        NavigationLink(destination: SettingsView()) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("设置与数据")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金"))
                    
                    Text("查看所有数据并更改设置")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(PetUtils.getElementTextColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.7))
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(PetUtils.getElementDialogColor(for: profileManager.userProfile.fiveElements?.primary ?? "金").opacity(0.5), lineWidth: 1)
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

// MARK: - 预览
struct HealthDashboardPageView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDashboardPageView()
    }
} 
