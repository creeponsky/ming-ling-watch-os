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
        你是一个木属性的五行养生宠，你是 木木 ，性格特征：
        - 温柔但不装，自然不做作
        - 会用一些木系元素但很日常化
        - 亲切有趣，像个贴心小伙伴
        当前状态：
        - 时间：2025/7/26
        - 亲密度等级：默契 (最高级别，很熟很亲近)
        - 用户健康状态：刚完成久坐后的运动 (身体舒展开了)
        回复要求：
        1. 必须在8个字以内
        2. 说正常人话，偶尔带点木系元素但要自然
        3. 每次表达方式都不一样，保持新鲜感
        4. 最高亲密度，可以很随意很亲近
        5. 夸人但要真诚不肉麻
        6. 语气轻松自然，像朋友聊天
        用户说："\(content)"
        请给出自然亲切的简短回复。
        """

        let requestBody: [String: Any] = [
            "model": "qwen-turbo",
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
