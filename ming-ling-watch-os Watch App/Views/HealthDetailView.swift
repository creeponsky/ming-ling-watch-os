import SwiftUI

// MARK: - 健康详情视图
struct HealthDetailView: View {
    let reminder: HealthReminder
    let userElement: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题区域
                titleSection
                
                // 触发条件
                triggerConditionsSection
                
                // 个性化建议
                personalizedAdviceSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .navigationTitle(reminder.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .background(PetUtils.getElementBackgroundColor(for: userElement))
    }
    
    // MARK: - 标题区域
    private var titleSection: some View {
        VStack(spacing: 12) {
            Image(systemName: reminder.type.icon)
                .font(.largeTitle)
                .foregroundColor(Color(hex: reminder.type.color))
            
            Text(reminder.type.rawValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("根据你的五行属性提供个性化建议")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 触发条件区域
    private var triggerConditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("触发条件")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(reminder.trigger.conditions, id: \.self) { condition in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(condition)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 个性化建议区域
    private var personalizedAdviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("个性化建议")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let suggestion = reminder.getSuggestionContent(for: userElement) {
                Text(suggestion)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            } else {
                Text("暂无个性化建议")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: reminder.type.color).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: reminder.type.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 预览
struct HealthDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDetailView(
            reminder: HealthReminder.allReminders[0],
            userElement: "金"
        )
    }
} 