import SwiftUI

// MARK: - 亲密值变化通知视图
struct IntimacyChangeView: View {
    let points: Int
    let isPositive: Bool
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isPositive ? "heart.fill" : "heart.slash")
                .foregroundColor(isPositive ? .red : .gray)
                .font(.caption)
            
            Text(isPositive ? "+\(points)" : "\(points)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isPositive ? .red : .gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPositive ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPositive ? Color.red.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = true
            }
            
            // 3秒后自动隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - 亲密值变化管理器
class IntimacyChangeManager: ObservableObject {
    static let shared = IntimacyChangeManager()
    
    @Published var currentChange: IntimacyChange?
    
    private init() {}
    
    func showChange(points: Int, isPositive: Bool) {
        currentChange = IntimacyChange(points: points, isPositive: isPositive)
        
        // 3秒后清除
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.currentChange = nil
        }
    }
}

// MARK: - 亲密值变化模型
struct IntimacyChange: Identifiable {
    let id = UUID()
    let points: Int
    let isPositive: Bool
    let timestamp = Date()
}

// MARK: - 预览
struct IntimacyChangeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            IntimacyChangeView(points: 10, isPositive: true)
            IntimacyChangeView(points: 5, isPositive: false)
        }
        .padding()
    }
} 