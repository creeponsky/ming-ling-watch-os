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
                
                // 后续提醒（如果有）
                if let followUp = reminder.followUp {
                    followUpSection(followUp)
                }
                
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
            
            ForEach(reminder.trigger.conditions, id: \.self) { condition in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text(condition)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            
            if !reminder.trigger.detection.isEmpty {
                Text("检测方式")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                ForEach(reminder.trigger.detection, id: \.self) { detection in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(detection)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
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
            
            Text(reminder.getReminder(for: userElement))
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
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
    
    // MARK: - 后续提醒区域
    private func followUpSection(_ followUp: FollowUpReminders) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("后续提醒")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let improved = followUp.improved {
                VStack(alignment: .leading, spacing: 8) {
                    Text("改善后")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text(improved[userElement] ?? "继续保持良好的状态！")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            if let stillLow = followUp.stillLow {
                VStack(alignment: .leading, spacing: 8) {
                    Text("仍需改善")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text(stillLow[userElement] ?? "继续努力改善健康状况")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            if let moved = followUp.moved {
                VStack(alignment: .leading, spacing: 8) {
                    Text("活动后")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text(moved[userElement] ?? "活动后记得适当休息")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 预览
struct HealthDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HealthDetailView(
                reminder: HealthReminder.allReminders[0],
                userElement: "金"
            )
        }
    }
} 