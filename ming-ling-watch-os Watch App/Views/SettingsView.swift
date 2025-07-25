import SwiftUI

struct SettingsView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var healthKitManager = HealthKitManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingBirthdaySelection = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户信息卡片
                    userInfoCard
                    
                    // 亲密值卡片
                    intimacyCard
                    
                    // 健康数据概览
                    healthDataOverview
                    
                    // 设置选项
                    settingsOptions
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingBirthdaySelection) {
            BirthdaySelectionView()
        }
        .alert("重置档案", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                profileManager.resetProfile()
                dismiss()
            }
        } message: {
            Text("这将重置所有数据和设置。您确定吗？")
        }
    }
    
    // MARK: - 用户信息卡片
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // 头像和基本信息
            HStack(spacing: 16) {
                Circle()
                    .fill(profileManager.getThemeColor())
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    if let petName = profileManager.userProfile.petRecommendation {
                        Text(petName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(profileManager.getThemeColor())
                    }
                    
                    if let element = profileManager.userProfile.fiveElements {
                        Text(element.primary + " 体质")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("健康坚持: \(profileManager.userProfile.healthStreak) 天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 生日信息
            if let birthday = profileManager.userProfile.birthday {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text("生日: \(formatDate(birthday))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("更改") {
                        showingBirthdaySelection = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
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
    
    // MARK: - 亲密值卡片
    private var intimacyCard: some View {
        VStack(spacing: 16) {
            Text("亲密值")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 亲密值等级和进度
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: profileManager.userProfile.intimacyGradeIcon)
                        .foregroundColor(Color(hex: profileManager.userProfile.intimacyGradeColor))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profileManager.userProfile.intimacyGradeName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("等级 \(profileManager.userProfile.intimacyGrade)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(profileManager.userProfile.intimacyLevel)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: profileManager.userProfile.intimacyGradeColor))
                        
                        Text("积分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 进度条
                VStack(spacing: 4) {
                    ProgressView(value: profileManager.userProfile.intimacyProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: profileManager.userProfile.intimacyGradeColor)))
                    
                    HStack {
                        Text("0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if profileManager.userProfile.pointsToNextGrade > 0 {
                            Text("距离下一等级还需 \(profileManager.userProfile.pointsToNextGrade) 积分")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("已达到最高等级")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Text("100")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 测试按钮
            VStack(spacing: 8) {
                Text("测试功能")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    Button(action: {
                        profileManager.addIntimacy(10)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("+10")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        profileManager.reduceIntimacy(10)
                    }) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                            Text("-10")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: profileManager.userProfile.intimacyGradeColor).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 健康数据概览
    private var healthDataOverview: some View {
        VStack(spacing: 16) {
            Text("健康数据概览")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DataCardView(
                    title: "心率",
                    value: "\(healthKitManager.heartRate) BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                DataCardView(
                    title: "心率变异性",
                    value: "\(Int(healthKitManager.heartRateVariability))ms",
                    icon: "waveform.path.ecg",
                    color: .purple
                )
                
                DataCardView(
                    title: "步数",
                    value: "\(healthKitManager.steps)",
                    icon: "figure.walk",
                    color: .green
                )
                
                DataCardView(
                    title: "睡眠",
                    value: healthKitManager.sleepAnalysis,
                    icon: "bed.double.fill",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - 设置选项
    private var settingsOptions: some View {
        VStack(spacing: 12) {
            Text("设置")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                // 重新选择生日
                Button(action: {
                    showingBirthdaySelection = true
                }) {
                    SettingsRowView(
                        icon: "calendar.badge.plus",
                        title: "更改生日",
                        subtitle: "重新计算您的体质",
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 通知设置
                Button(action: {
                    // 通知设置逻辑
                }) {
                    SettingsRowView(
                        icon: "bell.fill",
                        title: "通知",
                        subtitle: "管理健康提醒",
                        color: .orange
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 八字详情
                if let baziData = profileManager.userProfile.baziData {
                    NavigationLink(destination: BaziDetailView(baziData: baziData, userElement: profileManager.userProfile.fiveElements?.primary ?? "金")) {
                        SettingsRowView(
                            icon: "sparkles",
                            title: "八字分析",
                            subtitle: "查看您的生辰八字详情",
                            color: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 数据导出
                Button(action: {
                    // 数据导出逻辑
                }) {
                    SettingsRowView(
                        icon: "square.and.arrow.up",
                        title: "导出数据",
                        subtitle: "下载您的健康数据",
                        color: .green
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 功能测试
                NavigationLink(destination: TestView()) {
                    SettingsRowView(
                        icon: "testtube.2",
                        title: "功能测试",
                        subtitle: "测试健康监测和亲密值系统",
                        color: .purple
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 重置数据
                Button(action: {
                    showingResetAlert = true
                }) {
                    SettingsRowView(
                        icon: "trash.fill",
                        title: "重置所有数据",
                        subtitle: "清除所有设置和数据",
                        color: .red
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - 数据卡片视图
struct DataCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 设置行视图
struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
} 