import SwiftUI

struct BirthdaySelectionView: View {
    @StateObject private var baziService = BaziAPIService()
    @StateObject private var profileManager = UserProfileManager.shared
    
    @State private var selectedDate = Date()
    @State private var selectedSex = 0 // 0男 1女
    @State private var showingDatePicker = false
    @State private var showingPetRecommendation = false
    @State private var selectedFiveElements: FiveElements?
    @State private var selectedBaziData: BaziData?
    @State private var petRecommendation: PetRecommendation?
    
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
                if let error = baziService.error {
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
                                    .fill(Color(hex: fiveElements.color))
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
                                
                                ForEach(fiveElements.healthTips, id: \.self) { tip in
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
                                        .stroke(Color(hex: fiveElements.color).opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // 宠物推荐
                        if let petRec = petRecommendation {
                            VStack(spacing: 12) {
                                Text("推荐宠物")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 8) {
                                    Text(petRec.pets.first ?? "")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: fiveElements.color))
                                    
                                    Text(petRec.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: fiveElements.color).opacity(0.1))
                                )
                            }
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
                                    .fill(Color(hex: fiveElements.color))
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
                petRecommendation = baziService.getPetRecommendation(for: fiveElements.primary)
            }
        } catch {
            await MainActor.run {
                baziService.error = error.localizedDescription
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