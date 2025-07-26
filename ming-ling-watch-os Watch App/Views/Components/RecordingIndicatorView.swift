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
    
    var body: some View {
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
    }
}

#Preview {
    RecordingIndicatorView(recordingState: .recording)
} 