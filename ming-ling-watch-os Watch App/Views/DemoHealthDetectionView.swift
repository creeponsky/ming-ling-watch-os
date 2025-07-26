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
        .disabled(
            demoManager.demoProfile.hasCompletedDemo || 
            demoManager.demoProfile.stepGoalCompleted ||
            (demoManager.demoState != .mainPage && demoManager.demoState != .voiceInteraction) ||
            demoManager.demoState == .sedentaryTrigger
        )
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
                    .trim(from: 0, to: min(1.0, Double(demoManager.demoProfile.stepCount) / 10.0))
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
            
            Text("目标: 10步")
                .font(.caption)
                .foregroundColor(PetUtils.getElementTextColor(for: "木").opacity(0.7))
            
            if demoManager.demoProfile.stepCount >= 10 {
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
        print("🎬 DemoHealthDetectionView 设置视图 - 当前状态: \(demoManager.demoState.rawValue)")
        
        // 重新计算倒计时，确保准确性
        demoManager.recalculateCountdown()
        
        // 检查当前状态并设置正确的显示
        switch demoManager.demoState {
        case .stepDetection:
            // 如果在步数检测阶段，显示步数记录
            showStepCount = true
            print("🎬 当前在步数检测阶段，显示步数记录")
        case .sedentaryTrigger:
            // 如果在久坐触发阶段，显示久坐检测界面
            showStepCount = false
            print("🎬 当前在久坐触发阶段，显示久坐检测界面")
        case .mainPage, .voiceInteraction:
            // 如果在主页面或语音交互阶段，检查是否已完成步数目标
            if demoManager.demoProfile.stepGoalCompleted {
                showStepCount = true
                print("🎬 步数目标已完成，显示步数记录")
            } else {
                showStepCount = false
                print("🎬 在主页面状态，显示久坐检测界面")
            }
        default:
            showStepCount = false
            print("🎬 其他状态，显示久坐检测界面")
        }
    }
    
    // MARK: - 监听Demo状态变化
    private func onDemoStateChanged() {
        print("🎬 DemoHealthDetectionView 状态变化: \(demoManager.demoState.rawValue)")
        
        switch demoManager.demoState {
        case .stepDetection:
            // 进入步数检测阶段，显示步数记录
            if !showStepCount {
                withAnimation {
                    showStepCount = true
                }
                print("🎬 切换到步数记录显示")
            }
        case .sedentaryTrigger:
            // 进入久坐触发阶段，显示久坐检测界面
            if showStepCount {
                withAnimation {
                    showStepCount = false
                }
                print("🎬 切换到久坐检测显示")
            }
        case .mainPage, .voiceInteraction:
            // 如果已完成步数目标，继续显示步数记录；否则显示久坐检测
            let shouldShowSteps = demoManager.demoProfile.stepGoalCompleted
            if showStepCount != shouldShowSteps {
                withAnimation {
                    showStepCount = shouldShowSteps
                }
                print("🎬 根据完成状态切换显示: \(shouldShowSteps ? "步数记录" : "久坐检测")")
            }

        default:
            break
        }
    }
    
    // MARK: - 开始久坐检测
    private func startSedentaryDetection() {
        print("🔘 开始久坐检测流程")
        
        // 检查是否已经完成过Demo
        guard !demoManager.demoProfile.hasCompletedDemo && !demoManager.demoProfile.stepGoalCompleted else {
            print("⚠️ Demo已完成或步数目标已达成，不能重新开始检测")
            return
        }
        
        // 检查当前状态是否允许开始检测
        guard demoManager.demoState == .mainPage || demoManager.demoState == .voiceInteraction else {
            print("⚠️ 当前状态(\(demoManager.demoState.rawValue))不允许开始久坐检测")
            return
        }
        
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