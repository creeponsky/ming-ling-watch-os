import SwiftUI

// MARK: - Demo健康检测页面
struct DemoHealthDetectionView: View {
    @StateObject private var demoManager = DemoManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showStepCount = false

    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题栏
                titleBar
                
                // 主要内容区域
                mainContentArea
                
                // 底部按钮区域
                bottomButtonArea
                
                // 添加底部间距确保可以滚动到底部
                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(PetUtils.getElementBackgroundColor(for: "木"))

        .navigationBarHidden(true)
        .onAppear {
            setupView()
        }
        .onDisappear {
            // 不再需要清理计时器，由DemoManager管理
        }
        .onChange(of: demoManager.demoState) { _ in
            onDemoStateChanged()
        }
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
                .foregroundColor(PetUtils.getElementTextColor(for: "木"))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 退出Demo按钮
            Button(action: {
                demoManager.exitDemo()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                    Text("退出Demo")
                        .font(.caption2)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
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
    
    // MARK: - 主要内容区域
    private var mainContentArea: some View {
        VStack(spacing: 24) {
            if showStepCount {
                // 步数记录显示
                stepCountDisplay
            } else {
                // 久坐检测介绍
                sedentaryDetectionIntro
            }
        }
    }
    
    // MARK: - 久坐检测介绍
    private var sedentaryDetectionIntro: some View {
        Button(action: {
            print("🔘 点击久坐检测介绍按钮")
            startSedentaryDetection()
        }) {
            ZStack {
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 40))
                        .foregroundColor(PetUtils.getElementDialogColor(for: "木"))
                    
                    Text("久坐检测")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(PetUtils.getElementTextColor(for: "木"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(PetUtils.getElementDialogColor(for: "木").opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(PetUtils.getElementDialogColor(for: "木"), lineWidth: 3)
                        )
                )
                
                // 倒计时显示
                if (demoManager.isStepMonitoringActive && demoManager.countdownSeconds < 60) || demoManager.demoState == .sedentaryTrigger {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(demoManager.demoState == .sedentaryTrigger ? "\(demoManager.sedentaryCountdown)s" : "\(demoManager.countdownSeconds)s")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(PetUtils.getElementDialogColor(for: "木"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(PetUtils.getElementDialogColor(for: "木").opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(PetUtils.getElementDialogColor(for: "木"), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(demoManager.demoState != .mainPage && demoManager.demoState != .voiceInteraction && demoManager.demoState != .voiceCompleted || demoManager.demoState == .sedentaryTrigger)
    }
    
    // MARK: - 步数记录显示
    private var stepCountDisplay: some View {
        VStack(spacing: 16) {
            // 步数圆圈
            ZStack {
                Circle()
                    .stroke(PetUtils.getElementDialogColor(for: "木").opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(1.0, Double(demoManager.demoProfile.stepCount) / 20.0))
                    .stroke(PetUtils.getElementDialogColor(for: "木"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: demoManager.demoProfile.stepCount)
                
                VStack(spacing: 4) {
                    Text("\(demoManager.demoProfile.stepCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(PetUtils.getElementTextColor(for: "木"))
                    
                    Text("步数")
                        .font(.caption)
                        .foregroundColor(PetUtils.getElementTextColor(for: "木").opacity(0.7))
                }
            }
            
            Text("目标: 20步")
                .font(.caption)
                .foregroundColor(PetUtils.getElementTextColor(for: "木").opacity(0.7))
            
            if demoManager.demoProfile.stepCount >= 20 {
                Text("🎉 目标完成！")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .scaleEffect(1.1)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: demoManager.demoProfile.stepCount)
            }
        }
    }
    
    // MARK: - Demo状态信息
    private var demoStatusInfo: some View {
        EmptyView()
    }
    
        // MARK: - 底部按钮区域
    private var bottomButtonArea: some View {
        VStack(spacing: 12) {
            if showStepCount {
                // 返回主页面按钮
                Button(action: {
                    print("🔘 点击返回主页面按钮")
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("返回主页面")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text("回到Demo主界面")
                                .font(.caption)
                                .foregroundColor(.blue.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 设置视图
    private func setupView() {
        // 如果已经在步数检测阶段，显示步数记录
        if demoManager.demoState == .stepDetection {
            showStepCount = true
        }
    }
    
    // MARK: - 监听Demo状态变化
    private func onDemoStateChanged() {
        if demoManager.demoState == .stepDetection && !showStepCount {
            withAnimation {
                showStepCount = true
            }
        }
    }
    
    // MARK: - 开始久坐检测
    private func startSedentaryDetection() {
        print("🔘 开始久坐检测流程")
        
        // 立即触发DemoManager的久坐检测
        demoManager.triggerSedentaryDetection()
        
        // 不立即显示步数记录界面，等待倒计时结束后由DemoManager控制
    }
    
    // MARK: - 开始步数模拟
    private func startStepCountSimulation() {
        // 这个方法现在由DemoManager处理，这里只是显示界面
        print("🎬 步数检测界面已显示，等待DemoManager处理")
    }
}

// MARK: - 预览
struct DemoHealthDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        DemoHealthDetectionView()
    }
} 