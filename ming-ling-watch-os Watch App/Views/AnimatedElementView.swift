import SwiftUI

struct AnimatedElementView: View {
    @Binding var selectedElement: String
    @State private var animationOffset: CGFloat = 0
    @State private var isAnimating = false
    
    let elements = ["金", "木", "水", "火", "土"]
    let elementColors: [String: Color] = [
        "金": .yellow,
        "木": .green,
        "水": .blue,
        "火": .red,
        "土": .orange
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("五行健康")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 动画元素选择器
            HStack(spacing: 15) {
                ForEach(elements, id: \.self) { element in
                    ElementButton(
                        element: element,
                        isSelected: selectedElement == element,
                        color: elementColors[element] ?? .gray
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedElement = element
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // 选中元素的描述
            VStack(spacing: 8) {
                Text(selectedElement)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(elementColors[selectedElement])
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Text(getElementDescription(selectedElement))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func getElementDescription(_ element: String) -> String {
        switch element {
        case "金":
            return "肺与大肠，呼吸系统健康"
        case "木":
            return "肝与胆，情绪调节平衡"
        case "水":
            return "肾与膀胱，精力充沛"
        case "火":
            return "心与小肠，血液循环"
        case "土":
            return "脾与胃，消化系统"
        default:
            return ""
        }
    }
}

struct ElementButton: View {
    let element: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Text(element)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : color)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isSelected ? color : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: 2)
                        )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .shadow(color: isSelected ? color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 