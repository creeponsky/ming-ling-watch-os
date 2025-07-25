import SwiftUI

// MARK: - 健康卡片视图
struct HealthCardView: View {
    let reminder: HealthReminder
    let healthData: String
    let userElement: String
    let isDarkMode: Bool
    
    init(reminder: HealthReminder, healthData: String, userElement: String, isDarkMode: Bool = false) {
        self.reminder = reminder
        self.healthData = healthData
        self.userElement = userElement
        self.isDarkMode = isDarkMode
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: reminder.type.icon)
                .font(.title2)
                .foregroundColor(Color(hex: reminder.type.color))
            
            Text(reminder.type.rawValue)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(isDarkMode ? .white : .primary)
            
            Text(healthData)
                .font(.caption2)
                .foregroundColor(isDarkMode ? .white.opacity(0.7) : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: reminder.type.color).opacity(isDarkMode ? 0.5 : 0.3), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}

// MARK: - 预览
struct HealthCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HealthCardView(
                reminder: HealthReminder.allReminders[0],
                healthData: "测试数据",
                userElement: "金",
                isDarkMode: false
            )
            
            HealthCardView(
                reminder: HealthReminder.allReminders[1],
                healthData: "测试数据",
                userElement: "木",
                isDarkMode: true
            )
        }
        .padding()
    }
} 