import Foundation

// MARK: - API Response Structures
struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

// MARK: - API Service
class ChatAPIService: ObservableObject {
    static let shared = ChatAPIService()

    @Published var responseContent: String = ""
    @Published var errorMessage: String? = nil
    @Published var isRequesting: Bool = false

    private init() {}

    func sendMessage(content: String) {
        self.isRequesting = true
        self.errorMessage = nil
        self.responseContent = ""

        guard let url = URL(string: "https://0-0.pro/v1/chat/completions") else {
            self.errorMessage = "Invalid URL"
            self.isRequesting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer sk-7qaHhZxF52d2va8ckALDvsXEtdjzpF0IL1Qy4B7KeLlvXFAx", forHTTPHeaderField: "Authorization")

        let prompt = """
在你是一个木属性的五行养生宠物，性格特征：
- 木：温文尔雅，措辞优美，富有诗意

当前状态：
- 时间：2025/7/25
- 亲密度等级：亲密
- 用户健康状态：正常
- 用户最近行为：刚吃饭

回复要求：
1. 必须在5个字以内
2. 符合木属性的性格
3. 根据时间段调整语气（深夜更轻柔）
4. 亲密度越高，语气越亲昵
5. 如果用户状态不佳，语气要更关怀但不说教
6. 永远积极正面，不批评不责备

用户说："\(content)"

请给出最合适的简短回复。
        """

        let requestBody: [String: Any] = [
            "model": "MiniMax-M1",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 4096
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            self.errorMessage = "Failed to encode request body: \(error.localizedDescription)"
            self.isRequesting = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isRequesting = false

                if let error = error {
                    self.errorMessage = "Request failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Invalid response from server"
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                do {
                    let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                    if let firstChoice = chatResponse.choices.first {
                        self.responseContent = firstChoice.message.content
                    } else {
                        self.errorMessage = "No content in response"
                    }
                } catch {
                    self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}