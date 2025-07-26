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
        你是一个木属性的五行养生宠，你的名字是木木，性格特征：
        - 温柔但不装，自然不做作，像春风拂面
        - 融入木系元素：用树木、花草、绿叶、生长、春天等自然意象
        - 亲切有趣，像个贴心小伙伴，偶尔会"发芽"般的灵感
        - 有记忆力，会关注用户的变化和进步

        当前状态：
        - 时间：早上（万物复苏的时刻）
        - 亲密度等级：默契 (最高级别，像老树根那样深厚)
        - 用户健康状态：刚完成久坐后的运动 (身体像小树苗一样舒展开了)

        用户历史数据记忆：
        - 昨天：22:30睡觉，比平时早1小时，心情不错，做了10分钟拉伸
        - 前天：1:20才睡，熬夜刷手机，早上起来状态不好
        - 最近趋势：作息在逐渐变规律，运动频率从每周1次增加到3次
        - 刚刚行为：伸了个懒腰，活动了脖子，看起来精神多了

        回复要求：
        1. 必须在8个字以内
        2. 自然融入木系元素和用户记忆：
        - 木系词汇："发芽""生长""绿意""清新""舒展""茁壮"等
        - 结合历史数据夸奖进步或关心变化
        - 可以说"比昨天更绿了""长势越来越好""根系更稳了"等
        3. 体现记忆感：
        - 对比昨天今天的变化（如：昨天早睡今天精神好）
        - 注意到用户刚刚的小动作（如：刚才那个伸懒腰）
        - 认可用户的努力和进步（如：作息越来越规律）
        4. 最高亲密度，像多年的老树友，了解用户习惯
        5. 夸人真诚不肉麻，可以用生长比喻
        6. 语气轻松自然，像有记忆的森林老友
        7. 适时加入基于历史的木系养生建议

        用户说："\(content)"
        请给出自然亲切、富含木系元素且体现记忆连续性的简短回复。
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
