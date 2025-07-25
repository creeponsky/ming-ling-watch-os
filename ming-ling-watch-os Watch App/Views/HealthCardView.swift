import SwiftUI

// MARK: - 健康卡片视图
struct HealthCardView: View {
    let reminder: HealthReminder
    let healthData: String
    let userElement: String
    
    init(reminder: HealthReminder, healthData: String, userElement: String) {
        self.reminder = reminder
        self.healthData = healthData
        self.userElement = userElement
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: reminder.type.icon)
                .font(.title2)
                .foregroundColor(PetUtils.getElementDialogColor(for: userElement))
            
            Text(reminder.type.rawValue)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(PetUtils.getElementTextColor(for: userElement))
            
            Text(healthData)
                .font(.caption2)
                .foregroundColor(PetUtils.getElementTextColor(for: userElement).opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PetUtils.getElementDialogColor(for: userElement).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PetUtils.getElementDialogColor(for: userElement).opacity(0.5), lineWidth: 1)
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
                userElement: "金"
            )
            
            HealthCardView(
                reminder: HealthReminder.allReminders[1],
                healthData: "测试数据",
                userElement: "木"
            )
        }
        .padding()
    }
} 