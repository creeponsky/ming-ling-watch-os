import SwiftUI
import WatchKit

// MARK: - 录音状态枚举
enum RecordingState {
    case idle         // 空闲状态
    case recording    // 录音中
    case processing   // 处理中（转录、AI回复、语音合成）
    case playing      // 播放中
    case error        // 错误状态
}

// MARK: - 录音指示器视图
struct RecordingIndicatorView: View {
    let recordingState: RecordingState
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // 录音状态指示器（右上角）
            if recordingState == .recording {
                VStack {
                    HStack {
                        // 小圆点指示器
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .opacity(0.8)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                                value: recordingState
                            )
                        
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            
            // 处理状态 Loading（左下角）
            if recordingState == .processing {
                VStack {
                    Spacer()
                    HStack {
                        // 非常不起眼的转圈 loading
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .trim(from: 0, to: 0.3)
                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                    .rotationEffect(.degrees(rotationAngle))
                                    .animation(
                                        .linear(duration: 1.0)
                                        .repeatForever(autoreverses: false),
                                        value: rotationAngle
                                    )
                            )
                            .onAppear {
                                rotationAngle = 360
                            }
                            .onDisappear {
                                rotationAngle = 0
                            }
                        
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

#Preview {
    RecordingIndicatorView(recordingState: .recording)
} 