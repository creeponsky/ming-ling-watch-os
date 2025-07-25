import SwiftUI

// MARK: - 健康卡片视图
struct HealthCardView: View {
    let reminder: HealthReminder
    let healthData: String
    let userElement: String
    let isDarkMode: Bool
    
    @State private var isPressed = false
    
    init(reminder: HealthReminder, healthData: String, userElement: String, isDarkMode: Bool = false) {
        self.reminder = reminder
        self.healthData = healthData
        self.userElement = userElement
        self.isDarkMode = isDarkMode
    }
    
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