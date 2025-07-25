import SwiftUI

struct BirthdaySelectionView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    private let baziService = BaziAPIService()
    
    @State private var selectedDate = Date()
    @State private var selectedSex = 0 // 0男 1女
    @State private var showingDatePicker = false
    @State private var selectedFiveElements: FiveElements?
    @State private var selectedBaziData: BaziData?
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Text("欢迎使用健康助手")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("让我们先了解您的体质")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 性别选择
                VStack(spacing: 12) {
                    Text("性别")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            selectedSex = 0
                        }) {
                            HStack {
                                Image(systemName: selectedSex == 0 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedSex == 0 ? .blue : .gray)
                                Text("男")
                                    .foregroundColor(selectedSex == 0 ? .primary : .secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            selectedSex = 1
                        }) {
                            HStack {
                                Image(systemName: selectedSex == 1 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedSex == 1 ? .blue : .gray)
                                Text("女")
                                    .foregroundColor(selectedSex == 1 ? .primary : .secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 生日选择
                VStack(spacing: 12) {
                    Text("选择您的生日")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            
                            Text(formatDate(selectedDate))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 获取五行属性按钮
                Button(action: {
                    Task {
                        await getFiveElements()
                    }
                }) {
                    HStack {
                        if baziService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                        }
                        
                        Text(baziService.isLoading ? "分析中..." : "获取我的体质")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(baziService.isLoading ? Color.gray : Color.blue)
                    )
                }
                .disabled(baziService.isLoading)
                .buttonStyle(PlainButtonStyle())
                
                // 错误信息
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // 五行属性显示
                if let fiveElements = selectedFiveElements, let baziData = selectedBaziData {
                    VStack(spacing: 16) {
                        Text("您的体质")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(getElementColor(for: fiveElements.primary))
                                    .frame(width: 20, height: 20)
                                
                                Text(fiveElements.primary)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Spacer()
                            }
                            
                            Text(fiveElements.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("健康建议:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                ForEach(getHealthTips(for: fiveElements.primary), id: \.self) { tip in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.blue)
                                        Text(tip)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(getElementColor(for: fiveElements.primary).opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // 宠物推荐
                        VStack(spacing: 12) {
                            Text("推荐宠物")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                Text(getPetName(for: fiveElements.primary))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(getElementColor(for: fiveElements.primary))
                                
                                Text(getPetDescription(for: fiveElements.primary))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(getElementColor(for: fiveElements.primary).opacity(0.1))
                            )
                        }
                        
                        // 进入应用按钮
                        Button(action: {
                            profileManager.setProfile(birthday: selectedDate, sex: selectedSex, fiveElements: fiveElements, baziData: baziData)
                        }) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.white)
                                
                                Text("开始我的健康之旅")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(getElementColor(for: fiveElements.primary))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
    }
    
    // MARK: - 获取五行属性
    private func getFiveElements() async {
        do {
            let (fiveElements, baziData) = try await baziService.getFiveElements(birthday: selectedDate, sex: selectedSex)
            await MainActor.run {
                selectedFiveElements = fiveElements
                selectedBaziData = baziData
                error = nil
            }
        } catch let errorMessage {
            await MainActor.run {
                error = errorMessage.localizedDescription
            }
        }
    }
    
    // MARK: - 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - 获取元素颜色
    private func getElementColor(for element: String) -> Color {
        switch element {
        case "金":
            return Color(hex: "FFD700")
        case "木":
            return Color(hex: "228B22")
        case "水":
            return Color(hex: "4169E1")
        case "火":
            return Color(hex: "DC143C")
        case "土":
            return Color(hex: "8B4513")
        default:
            return Color.blue
        }
    }
    
    // MARK: - 获取健康建议
    private func getHealthTips(for element: String) -> [String] {
        switch element {
        case "金":
            return ["注意呼吸调理", "保持心情舒畅", "适度运动"]
        case "木":
            return ["保持心情舒畅", "适度运动", "注意休息"]
        case "水":
            return ["注意保暖", "充足睡眠", "适度饮水"]
        case "火":
            return ["保持心情平静", "适度运动", "注意饮食"]
        case "土":
            return ["注意饮食调理", "适度运动", "保持规律作息"]
        default:
            return ["保持健康，注意休息"]
        }
    }
    
    // MARK: - 获取宠物名称
    private func getPetName(for element: String) -> String {
        switch element {
        case "金":
            return "金金"
        case "木":
            return "木木"
        case "水":
            return "水水"
        case "火":
            return "火火"
        case "土":
            return "土土"
        default:
            return "土土"
        }
    }
    
    // MARK: - 获取宠物描述
    private func getPetDescription(for element: String) -> String {
        switch element {
        case "金":
            return "金属性宠物，有助于调理肺气"
        case "木":
            return "木属性宠物，有助于舒展肝气"
        case "水":
            return "水属性宠物，有助于温润肾气"
        case "火":
            return "火属性宠物，有助于清凉心气"
        case "土":
            return "土属性宠物，有助于温和脾气"
        default:
            return "健康助手宠物"
        }
    }
}

// MARK: - 日期选择器视图
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Birthday",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("完成") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Birthday")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 