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

        let requestBody: [String: Any] = [
            "model": "MiniMax-M1",
            "messages": [
                ["role": "user", "content": content]
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