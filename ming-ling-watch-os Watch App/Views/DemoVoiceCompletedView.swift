import SwiftUI

// MARK: - Demo语音完成页面
struct DemoVoiceCompletedView: View {
    @StateObject private var demoManager = DemoManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变 - 木属性主题
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 标题栏
                    titleBar
                    
                    Spacer()
                    
                    // 主要内容区域
                    mainContentArea
                    
                    Spacer()
                    
                    // 底部按钮区域
                    bottomButtonArea
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - 标题栏
    private var titleBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                    Text("返回")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("语音交互完成")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            Spacer()
            
            // 占位符保持对称
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.caption)
                Text("返回")
                    .font(.caption)
            }
            .foregroundColor(.clear)
        }
    }
    
    // MARK: - 主要内容区域
    private var mainContentArea: some View {
        VStack(spacing: 24) {
            // 成功图标
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            // 完成标题
            Text("语音交互完成！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            // 完成描述
            VStack(spacing: 12) {
                Text("木木已经听到了您的声音")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("并给出了温暖的回复")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // 亲密度信息
            intimacyInfo
        }
    }
    
    // MARK: - 亲密度信息
    private var intimacyInfo: some View {
        VStack(spacing: 12) {
            Text("当前亲密度")
                .font(.caption)
                .foregroundColor(.green.opacity(0.7))
            
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { level in
                    Image(systemName: level <= demoManager.demoProfile.intimacyGrade ? "heart.fill" : "heart")
                        .foregroundColor(level <= demoManager.demoProfile.intimacyGrade ? .red : .gray)
                        .font(.title2)
                }
            }
            
            Text("等级 \(demoManager.demoProfile.intimacyGrade)")
                .font(.caption)
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - 底部按钮区域
    private var bottomButtonArea: some View {
        VStack(spacing: 16) {
            // 继续与木木互动按钮
            Button(action: {
                // 返回主页面继续互动
                dismiss()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    Text("继续与木木互动")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 退出Demo按钮
            Button(action: {
                demoManager.exitDemo()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    Text("退出Demo")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - 预览
struct DemoVoiceCompletedView_Previews: PreviewProvider {
    static var previews: some View {
        DemoVoiceCompletedView()
    }
} 