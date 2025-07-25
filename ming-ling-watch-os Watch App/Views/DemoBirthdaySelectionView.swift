import SwiftUI

// MARK: - Demo生日选择视图
struct DemoBirthdaySelectionView: View {
    @StateObject private var demoManager = DemoManager.shared
    @State private var selectedDate = Date()
    @State private var selectedSex = 0 // 0男 1女
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                headerSection
                
                // 性别选择
                sexSelectionSection
                
                // 生日选择
                birthdaySection
                
                // 确认按钮
                confirmButtonSection
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color.green.opacity(0.1)) // 木属性主题
        .navigationTitle("Demo设置")
        .navigationBarTitleDisplayMode(.inline)
        .opacity(1.0)
        .animation(.easeInOut(duration: 0.5), value: true)
    }
    
    // MARK: - 标题部分
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("mumu")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                )
            
            Text("欢迎体验Demo")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("设置你的基本信息\n(Demo中将固定为木属性)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.green.opacity(0.7))
        }
    }
    
    // MARK: - 性别选择
    private var sexSelectionSection: some View {
        VStack(spacing: 12) {
            Text("选择性别")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.green)
            
            HStack(spacing: 20) {
                // 男性选项
                Button(action: {
                    selectedSex = 0
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(selectedSex == 0 ? .white : .green)
                        
                        Text("男")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedSex == 0 ? .white : .green)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedSex == 0 ? Color.green : Color.green.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: selectedSex == 0 ? 2 : 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 女性选项
                Button(action: {
                    selectedSex = 1
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(selectedSex == 1 ? .white : .green)
                        
                        Text("女")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedSex == 1 ? .white : .green)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedSex == 1 ? Color.green : Color.green.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: selectedSex == 1 ? 2 : 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 生日选择
    private var birthdaySection: some View {
        VStack(spacing: 12) {
            Text("选择生日")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.green)
            
            DatePicker(
                "生日",
                selection: $selectedDate,
                in: Calendar.current.date(byAdding: .year, value: -100, to: Date())!...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .frame(height: 120)
        }
    }
    
    // MARK: - 确认按钮
    private var confirmButtonSection: some View {
        Button(action: {
            confirmSelection()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                }
                
                Text(isLoading ? "设置中..." : "确认设置")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
    
    // MARK: - 确认选择
    private func confirmSelection() {
        isLoading = true
        
        // 模拟API调用延时
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Demo中固定设置为木属性并进入主页面
            demoManager.setBirthday(selectedDate, sex: selectedSex)
            isLoading = false
        }
    }
}

// MARK: - 预览
struct DemoBirthdaySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DemoBirthdaySelectionView()
        }
    }
}