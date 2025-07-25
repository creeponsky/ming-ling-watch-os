import SwiftUI

// MARK: - 测试视图
struct TestView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var healthMonitoringService = HealthMonitoringService.shared
    @StateObject private var intimacyChangeManager = IntimacyChangeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 亲密值测试
                intimacyTestSection
                
                // 久坐检测测试
                sedentaryTestSection
                
                // 压力检测测试
                stressTestSection
                
                // 健康监测状态
                monitoringStatusSection
            }
            .padding()
        }
        .navigationTitle("功能测试")
    }
    
    // MARK: - 亲密值测试区域
    private var intimacyTestSection: some View {
        VStack(spacing: 12) {
            Text("亲密值测试")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                HStack {
                    Text("当前亲密值: \(profileManager.userProfile.intimacyLevel)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("等级: \(profileManager.userProfile.intimacyGradeName)")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: profileManager.userProfile.intimacyGradeColor))
                }
                
                ProgressView(value: profileManager.userProfile.intimacyProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: profileManager.userProfile.intimacyGradeColor)))
                
                HStack(spacing: 12) {
                    Button("+5") {
                        profileManager.addIntimacy(5)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("+10") {
                        profileManager.addIntimacy(10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("+15") {
                        profileManager.addIntimacy(15)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("+20") {
                        profileManager.addIntimacy(20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                HStack(spacing: 12) {
                    Button("-5") {
                        profileManager.reduceIntimacy(5)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                    Button("-10") {
                        profileManager.reduceIntimacy(10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - 久坐检测测试区域
    private var sedentaryTestSection: some View {
        VStack(spacing: 12) {
            Text("久坐检测测试")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Text("模拟久坐检测")
                    .font(.subheadline)
                
                HStack(spacing: 12) {
                    Button("模拟久坐提醒") {
                        simulateSedentaryReminder()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    
                    Button("模拟开始活动") {
                        simulateActivityStart()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                
                if healthMonitoringService.isMonitoringFollowUp {
                    Text("正在监测后续活动...")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - 压力检测测试区域
    private var stressTestSection: some View {
        VStack(spacing: 12) {
            Text("压力检测测试")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Text("模拟压力检测")
                    .font(.subheadline)
                
                HStack(spacing: 12) {
                    Button("模拟压力提醒") {
                        simulateStressReminder()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    
                    Button("模拟压力改善") {
                        simulateStressImprovement()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - 监测状态区域
    private var monitoringStatusSection: some View {
        VStack(spacing: 12) {
            Text("监测状态")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                HStack {
                    Text("健康监测:")
                    Spacer()
                    Text("运行中")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("后续监测:")
                    Spacer()
                    Text(healthMonitoringService.isMonitoringFollowUp ? "是" : "否")
                        .foregroundColor(healthMonitoringService.isMonitoringFollowUp ? .orange : .gray)
                }
                
                HStack {
                    Text("当前状态:")
                    Spacer()
                    Text(getHealthStatusText())
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - 测试方法
    private func simulateSedentaryReminder() {
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        let message = ReminderContentManager.shared.getReminderContent(
            for: "久坐",
            subType: "建议",
            element: userElement
        )
        
        NotificationManager.shared.sendHealthReminder(
            type: .sedentary,
            message: message,
            userElement: userElement
        )
    }
    
    private func simulateActivityStart() {
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        let message = ReminderContentManager.shared.getReminderContent(
            for: "久坐",
            subType: "moved",
            element: userElement
        )
        
        NotificationManager.shared.sendFollowUpReminder(
            type: .sedentary,
            followUpType: .moved,
            message: message,
            userElement: userElement
        )
        
        // 增加亲密值
        profileManager.addIntimacy(10)
    }
    
    private func simulateStressReminder() {
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        let message = ReminderContentManager.shared.getReminderContent(
            for: "压力大",
            subType: "建议",
            element: userElement
        )
        
        NotificationManager.shared.sendHealthReminder(
            type: .stress,
            message: message,
            userElement: userElement
        )
    }
    
    private func simulateStressImprovement() {
        let userElement = profileManager.userProfile.fiveElements?.primary ?? "金"
        let message = ReminderContentManager.shared.getReminderContent(
            for: "压力大",
            subType: "improved",
            element: userElement
        )
        
        NotificationManager.shared.sendFollowUpReminder(
            type: .stress,
            followUpType: .improved,
            message: message,
            userElement: userElement
        )
        
        // 增加亲密值
        profileManager.addIntimacy(15)
    }
    
    private func getHealthStatusText() -> String {
        switch healthMonitoringService.currentHealthStatus {
        case .normal:
            return "正常"
        case .sedentary:
            return "久坐"
        case .stressed:
            return "压力大"
        case .exercising:
            return "运动中"
        case .sleeping:
            return "睡眠中"
        }
    }
}

// MARK: - 预览
struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
} 